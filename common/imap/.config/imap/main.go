// imap-daemon: holds an IMAP IDLE connection and writes the unread count and the
// most-recent unread subject to a state file (line 1 = count, line 2 = subject).
// The waybar custom/mail module reads that file.
package main

import (
	"crypto/tls"
	"errors"
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
	"github.com/godbus/dbus/v5"
)

// errResumed unblocks the IDLE wait when logind reports a resume from suspend.
var errResumed = errors.New("resumed from suspend")

const (
	idleTimeout  = 25 * time.Minute
	retryBase    = 10 * time.Second
	retryMax     = 5 * time.Minute
	settledAfter = 1 * time.Minute  // a session lasting this long resets the backoff
	netTimeout   = 2 * time.Minute  // connect/login/refresh watchdog (NOT the IDLE wait)
	keepAlive    = 30 * time.Second // TCP keepalive idle period (see dialTLSKeepAlive)
	subjectMax   = 36

	// How long an outage must last before the bar is told about it. Resuming or
	// booting reliably beats the network by a few seconds — DNS is by far the
	// most common failure here — and painting "?" for that is a flash of alarm
	// for something that fixes itself. Below this we leave the last good count
	// on the bar; a count a few seconds stale is a better lie than "broken".
	// Sized to span the first three attempts (t=0, +10s, +30s under the backoff).
	// The gate is only evaluated when an attempt fails, so the first "?" actually
	// lands on the first failure at or after this — t=70s with the current
	// backoff, not t=45s. That lag is the point, not a rounding error.
	errorGrace = 45 * time.Second
)

func main() {
	log.SetFlags(log.LstdFlags | log.Lmicroseconds)

	user := mustEnv("IMAP_USER")
	pass := mustEnv("IMAP_PASS")
	host := mustEnv("IMAP_HOST")
	stateFile := envOr("STATE_FILE", defaultStateFile())

	// Resume notifications are an optimisation, not a requirement: on failure we
	// keep a nil channel, whose receive blocks forever, so the select below falls
	// back to the old TCP-keepalive/idleTimeout recovery path unchanged.
	var resume <-chan struct{}
	if ch, err := watchResume(); err != nil {
		log.Printf("resume watch unavailable (%v) — falling back to keepalive recovery", err)
	} else {
		resume = ch
	}

	// Start of the current outage; the zero value means "healthy". Deliberately
	// measured from the first failure rather than from the last good refresh:
	// after a long suspend the last refresh is hours old, so a last-good clock
	// would already be past errorGrace and every resume would flash "?" — the
	// exact case this exists to prevent. refresh() zeroes it on success.
	var outageSince time.Time

	backoff := retryBase
	for {
		start := time.Now()
		err := session(user, pass, host, stateFile, resume, &outageSince)
		// A resume is an expected, self-inflicted teardown, not a failure: don't
		// paint the bar with "?" and don't back off — the whole point is to be
		// reconnected before the user looks at it. If the network isn't up yet
		// the reconnect fails on its own and takes the normal error path below.
		if errors.Is(err, errResumed) {
			log.Printf("session ended: %v — reconnecting now", err)
			backoff = retryBase
			continue
		}
		if err != nil {
			log.Printf("session ended: %v", err)
			if outageSince.IsZero() {
				outageSince = time.Now()
			}
			// Only tell the bar once the outage has outlived the grace window.
			// Short reconnects stay invisible; a real outage still surfaces, and
			// keeps being re-asserted on each retry so the state file stays fresh
			// (which is what keeps the bar's own staleness check from firing on
			// top of it and reporting the same problem twice).
			if time.Since(outageSince) >= errorGrace {
				writeError(stateFile)
			}
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

func session(user, pass, host, stateFile string, resume <-chan struct{}, outageSince *time.Time) error {
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

	// Drop any resume signal that arrived while we were connecting: it refers to
	// a socket this session doesn't own, and acting on it would tear down the
	// fresh connection we just built.
	select {
	case <-resume:
	default:
	}

	for {
		guard.Reset(netTimeout) // cover the refresh...
		if err := refresh(c, stateFile, outageSince); err != nil {
			return fmt.Errorf("refresh: %w", err)
		}
		guard.Stop() // ...but not the IDLE wait below.

		idleCmd, err := c.Idle()
		if err != nil {
			return fmt.Errorf("idle start: %w", err)
		}

		select {
		case <-notify:
		case <-resume:
			// Suspend tears down wifi, so the socket is dead on resume — but
			// nothing here would notice promptly. idleTimeout is a monotonic
			// timer, and CLOCK_MONOTONIC excludes suspended time, so the 25-min
			// ceiling is effectively paused while asleep; TCP keepalive is the
			// only other escape and needs KEEPIDLE + probes x intvl (30s + 9x75s
			// = ~12 min on stock kernel settings) to fail the blocked read. Both
			// leave the state file stale, which the bar correctly renders as "?".
			// Close the socket now so the blocked IDLE read fails immediately and
			// the reconnect happens while the lid is still coming up.
			c.Close()
			return errResumed
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

// watchResume reports each resume from suspend/hibernate, as announced by
// logind's PrepareForSleep signal on the system bus (true = going to sleep,
// false = just resumed; we only care about the latter). This is the only prompt
// signal available: the socket dies during suspend, but neither the monotonic
// idleTimeout nor TCP keepalive notices for many minutes afterwards.
//
// The returned channel has depth 1 and is filled non-blockingly, so a resume
// that lands while a session is mid-refresh is remembered but never coalesces
// into a backlog of redundant reconnects.
func watchResume() (<-chan struct{}, error) {
	conn, err := dbus.SystemBus()
	if err != nil {
		return nil, fmt.Errorf("system bus: %w", err)
	}
	if err := conn.AddMatchSignal(
		dbus.WithMatchObjectPath("/org/freedesktop/login1"),
		dbus.WithMatchInterface("org.freedesktop.login1.Manager"),
		dbus.WithMatchMember("PrepareForSleep"),
	); err != nil {
		return nil, fmt.Errorf("match PrepareForSleep: %w", err)
	}

	sigs := make(chan *dbus.Signal, 8)
	conn.Signal(sigs)

	out := make(chan struct{}, 1)
	go func() {
		for sig := range sigs {
			if len(sig.Body) == 0 {
				continue
			}
			sleeping, ok := sig.Body[0].(bool)
			if !ok || sleeping {
				continue // the pre-sleep edge; the socket is still alive here
			}
			select {
			case out <- struct{}{}:
			default: // one pending resume is as good as two
			}
		}
	}()
	return out, nil
}

// dialTLSKeepAlive connects with implicit TLS like imapclient.DialTLS, but on a
// dialer with TCP keepalive enabled. The IDLE wait is deliberately left unguarded
// by the AfterFunc watchdog (it legitimately blocks up to idleTimeout), so a
// silently dropped socket mid-IDLE would otherwise go unnoticed until the 25-minute
// ceiling. SO_KEEPALIVE makes the kernel probe the dead peer and eventually fail
// the blocked read, unblocking IDLE so the reconnect loop runs.
//
// Note this is the SLOW path, not the primary one: Go sets only TCP_KEEPIDLE from
// Dialer.KeepAlive, leaving tcp_keepalive_intvl/probes at kernel defaults, so
// detection takes 30s + 9x75s ~= 12 minutes. Suspend — the common case — is
// handled promptly by watchResume instead; keepalive remains the backstop for
// drops with no resume event (NAT timeouts, an AP vanishing).
//
// go-imap's own DialTLS uses a bare dialer with no keepalive, hence this
// replacement rather than a plain option.
func dialTLSKeepAlive(host string, opts *imapclient.Options) (*imapclient.Client, error) {
	dialer := &net.Dialer{Timeout: netTimeout, KeepAlive: keepAlive}
	// nil-ServerName config: tls.DialWithDialer fills ServerName from addr's host.
	conn, err := tls.DialWithDialer(dialer, "tcp", imapAddr(host), &tls.Config{NextProtos: []string{"imap"}})
	if err != nil {
		return nil, err
	}
	return imapclient.New(conn, opts), nil
}

// imapAddr returns host unchanged when it already carries a port, otherwise it
// appends the default implicit-TLS IMAP port (993). Split out from
// dialTLSKeepAlive so the port-defaulting is unit-testable without a network.
func imapAddr(host string) string {
	if _, _, err := net.SplitHostPort(host); err == nil {
		return host
	}
	return net.JoinHostPort(host, "993")
}

// refresh writes the current unread count/subject and, on success, clears the
// caller's outage marker — the single place that can prove the daemon is healthy,
// since a session only ever *returns* when something has gone wrong.
func refresh(c *imapclient.Client, stateFile string, outageSince *time.Time) error {
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
	*outageSince = time.Time{} // healthy again; the next failure starts a fresh grace window
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
