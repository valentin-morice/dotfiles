// imap-daemon: holds an IMAP IDLE connection and writes the unread count and the
// most-recent unread subject to a state file (line 1 = count, line 2 = subject).
// The waybar custom/mail module reads that file.
package main

import (
	"crypto/tls"
	"fmt"
	"log"
	"net"
	"os"
	"path/filepath"
	"sort"
	"strings"
	"time"

	"github.com/emersion/go-imap/v2"
	"github.com/emersion/go-imap/v2/imapclient"
)

const (
	idleTimeout  = 25 * time.Minute
	retryBase    = 10 * time.Second
	retryMax     = 5 * time.Minute
	settledAfter = 1 * time.Minute  // a session lasting this long resets the backoff
	netTimeout   = 2 * time.Minute  // connect/login/refresh watchdog (NOT the IDLE wait)
	keepAlive    = 30 * time.Second // TCP keepalive idle period (see dialTLSKeepAlive)
	subjectMax   = 36
)

func main() {
	log.SetFlags(log.LstdFlags | log.Lmicroseconds)

	user := mustEnv("IMAP_USER")
	pass := mustEnv("IMAP_PASS")
	host := mustEnv("IMAP_HOST")
	stateFile := envOr("STATE_FILE", defaultStateFile())

	backoff := retryBase
	for {
		start := time.Now()
		if err := session(user, pass, host, stateFile); err != nil {
			log.Printf("session ended: %v", err)
			writeError(stateFile)
		}
		// A session that stayed up a while was a transient blip -> reset the
		// backoff. One that failed fast (e.g. rejected credentials) grows it
		// toward the cap, so we stop re-logging-in every retryBase forever and
		// risking a server-side rate-limit or account lockout.
		if time.Since(start) >= settledAfter {
			backoff = retryBase
		}
		log.Printf("reconnecting in %s", backoff)
		time.Sleep(backoff)
		if backoff < retryMax {
			backoff *= 2
			if backoff > retryMax {
				backoff = retryMax
			}
		}
	}
}

func session(user, pass, host, stateFile string) error {
	notify := make(chan struct{}, 16)
	opts := &imapclient.Options{
		UnilateralDataHandler: &imapclient.UnilateralDataHandler{
			Mailbox: func(data *imapclient.UnilateralDataMailbox) {
				if data.NumMessages != nil {
					select {
					case notify <- struct{}{}:
					default:
					}
				}
			},
			Expunge: func(seqNum uint32) {
				select {
				case notify <- struct{}{}:
				default:
				}
			},
			Fetch: func(msg *imapclient.FetchMessageData) {
				// Drain the message data so the IMAP reader isn't blocked,
				// then signal a refresh (flag changes during IDLE arrive as
				// FETCH responses — e.g. marking a message as \Seen).
				for msg.Next() != nil {
				}
				select {
				case notify <- struct{}{}:
				default:
				}
			},
		},
	}

	c, err := dialTLSKeepAlive(host, opts)
	if err != nil {
		return fmt.Errorf("dial %s: %w", host, err)
	}
	defer c.Close()

	// Watchdog: a stalled-but-open socket during connect/login/refresh would
	// block session() forever, so the backoff loop never runs and only the bar's
	// staleness marker notices. Closing the conn unblocks the pending Wait() with
	// an error. The long IDLE wait is deliberately NOT guarded (it legitimately
	// blocks up to idleTimeout) — the guard is stopped before each IDLE and reset
	// around each refresh.
	guard := time.AfterFunc(netTimeout, func() { c.Close() })
	defer guard.Stop()

	if err := c.Login(user, pass).Wait(); err != nil {
		return fmt.Errorf("login: %w", err)
	}
	defer func() { _ = c.Logout().Wait() }()

	if _, err := c.Select("INBOX", nil).Wait(); err != nil {
		return fmt.Errorf("select INBOX: %w", err)
	}

	log.Printf("connected to %s as %s", host, user)

	for {
		guard.Reset(netTimeout) // cover the refresh...
		if err := refresh(c, stateFile); err != nil {
			return fmt.Errorf("refresh: %w", err)
		}
		guard.Stop() // ...but not the IDLE wait below.

		idleCmd, err := c.Idle()
		if err != nil {
			return fmt.Errorf("idle start: %w", err)
		}

		select {
		case <-notify:
		case <-time.After(idleTimeout):
		}

		// Drain any pending notifications so the next IDLE doesn't fire immediately.
		for {
			select {
			case <-notify:
				continue
			default:
			}
			break
		}

		// Exit IDLE, but with a hard bound. Close (send DONE) and Wait (await
		// completion) both do network I/O, and this runs with the watchdog
		// stopped (see above). If the connection was silently killed mid-IDLE —
		// a laptop suspend tears down wifi (NetworkManager 'sleeping'), leaving a
		// dead socket on resume — go-imap can block here forever, freezing the
		// whole daemon (and the widget, until it's manually restarted). Bound the
		// teardown: if it doesn't finish within netTimeout, force the socket shut
		// and return so the reconnect loop runs. Any goroutine still stuck on the
		// dead connection is unblocked by that Close (and is at worst one leaked
		// goroutine per suspend, reclaimed when the session is replaced).
		teardown := make(chan error, 1)
		go func() {
			if cerr := idleCmd.Close(); cerr != nil {
				teardown <- cerr
				return
			}
			teardown <- idleCmd.Wait()
		}()
		select {
		case err := <-teardown:
			if err != nil {
				c.Close() // conn is likely dead; keep the deferred Logout from hanging too
				return fmt.Errorf("idle stop: %w", err)
			}
		case <-time.After(netTimeout):
			c.Close() // unblock the stuck teardown goroutine, then reconnect
			return fmt.Errorf("idle stop timed out after %s", netTimeout)
		}
	}
}

// dialTLSKeepAlive connects with implicit TLS like imapclient.DialTLS, but on a
// dialer with TCP keepalive enabled. The IDLE wait below is deliberately left
// unguarded by the AfterFunc watchdog (it legitimately blocks up to idleTimeout),
// so a silently dropped socket mid-IDLE would otherwise go unnoticed until the
// 25-minute ceiling. SO_KEEPALIVE makes the kernel probe the dead peer and fail
// the blocked read within a couple of minutes, unblocking IDLE so the reconnect
// loop runs. go-imap's own DialTLS uses a bare dialer with no keepalive, hence
// this replacement rather than a plain option.
func dialTLSKeepAlive(host string, opts *imapclient.Options) (*imapclient.Client, error) {
	addr := host
	if _, _, err := net.SplitHostPort(host); err != nil {
		addr = net.JoinHostPort(host, "993") // default implicit-TLS IMAP port
	}
	dialer := &net.Dialer{Timeout: netTimeout, KeepAlive: keepAlive}
	// nil-ServerName config: tls.DialWithDialer fills ServerName from addr's host.
	conn, err := tls.DialWithDialer(dialer, "tcp", addr, &tls.Config{NextProtos: []string{"imap"}})
	if err != nil {
		return nil, err
	}
	return imapclient.New(conn, opts), nil
}

func refresh(c *imapclient.Client, stateFile string) error {
	criteria := &imap.SearchCriteria{
		NotFlag: []imap.Flag{imap.FlagSeen},
	}
	searchData, err := c.UIDSearch(criteria, nil).Wait()
	if err != nil {
		return fmt.Errorf("search: %w", err)
	}
	uids := searchData.AllUIDs()
	count := len(uids)

	var subject string
	if count > 0 {
		sort.Slice(uids, func(i, j int) bool { return uids[i] < uids[j] })
		var uidSet imap.UIDSet
		uidSet.AddNum(uids[len(uids)-1])
		msgs, err := c.Fetch(uidSet, &imap.FetchOptions{Envelope: true}).Collect()
		if err != nil {
			return fmt.Errorf("fetch envelope: %w", err)
		}
		if len(msgs) > 0 && msgs[0].Envelope != nil {
			subject = truncateRunes(sanitizeSubject(strings.TrimSpace(msgs[0].Envelope.Subject)), subjectMax)
		}
	}

	if err := writeAtomic(stateFile, fmt.Sprintf("%d\n%s\n", count, subject)); err != nil {
		return fmt.Errorf("write state: %w", err)
	}
	log.Printf("refreshed: %d unread; subject=%q", count, subject)
	return nil
}

// sanitizeSubject maps control characters (a malformed header, embedded tab/ESC/
// CR) to spaces so they can't reach the state file the bar renders as JSON.
func sanitizeSubject(s string) string {
	return strings.Map(func(r rune) rune {
		if r < 0x20 || r == 0x7f {
			return ' '
		}
		return r
	}, s)
}

func truncateRunes(s string, n int) string {
	r := []rune(s)
	if len(r) <= n {
		return s
	}
	if n <= 1 {
		return string(r[:n])
	}
	return string(r[:n-1]) + "…"
}

func writeAtomic(path, content string) error {
	dir := filepath.Dir(path)
	tmp, err := os.CreateTemp(dir, ".imap-*.tmp")
	if err != nil {
		return err
	}
	tmpName := tmp.Name()
	defer os.Remove(tmpName)
	if _, err := tmp.WriteString(content); err != nil {
		tmp.Close()
		return err
	}
	if err := tmp.Close(); err != nil {
		return err
	}
	return os.Rename(tmpName, path)
}

func writeError(stateFile string) {
	_ = writeAtomic(stateFile, "?\n")
}

func defaultStateFile() string {
	// Prefer the per-user runtime dir (0700, tmpfs) over the world-writable,
	// predictable-name /tmp path. waybar-mail reads the same preference order,
	// with the /tmp path kept as a fallback for pre-rebuild compatibility.
	if x := os.Getenv("XDG_RUNTIME_DIR"); x != "" {
		return filepath.Join(x, "imap.txt")
	}
	return fmt.Sprintf("/tmp/imap-%s.txt", os.Getenv("USER"))
}

func mustEnv(k string) string {
	v := os.Getenv(k)
	if v == "" {
		log.Fatalf("missing required env var: %s", k)
	}
	return v
}

func envOr(k, def string) string {
	if v := os.Getenv(k); v != "" {
		return v
	}
	return def
}
