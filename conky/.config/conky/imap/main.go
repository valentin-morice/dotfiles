// imap-daemon: holds an IMAP IDLE connection and writes the unread
// count + 3 most-recent unread (From | Subject) to a state file. Conky reads
// that file via ${execi cat ...}.
package main

import (
	"fmt"
	"log"
	"os"
	"path/filepath"
	"sort"
	"strings"
	"time"

	"github.com/emersion/go-imap/v2"
	"github.com/emersion/go-imap/v2/imapclient"
)

const (
	idleTimeout = 25 * time.Minute
	retryDelay  = 10 * time.Second
	subjectMax  = 36
)

func main() {
	log.SetFlags(log.LstdFlags | log.Lmicroseconds)

	user := mustEnv("IMAP_USER")
	pass := mustEnv("IMAP_PASS")
	host := mustEnv("IMAP_HOST")
	stateFile := envOr("STATE_FILE", defaultStateFile())

	for {
		if err := session(user, pass, host, stateFile); err != nil {
			log.Printf("session ended: %v", err)
			writeError(stateFile)
			time.Sleep(retryDelay)
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

	c, err := imapclient.DialTLS(host, opts)
	if err != nil {
		return fmt.Errorf("dial %s: %w", host, err)
	}
	defer c.Close()

	if err := c.Login(user, pass).Wait(); err != nil {
		return fmt.Errorf("login: %w", err)
	}
	defer func() { _ = c.Logout().Wait() }()

	if _, err := c.Select("INBOX", nil).Wait(); err != nil {
		return fmt.Errorf("select INBOX: %w", err)
	}

	log.Printf("connected to %s as %s", host, user)

	for {
		if err := refresh(c, stateFile); err != nil {
			return fmt.Errorf("refresh: %w", err)
		}

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

		if err := idleCmd.Close(); err != nil {
			return fmt.Errorf("idle close: %w", err)
		}
		if err := idleCmd.Wait(); err != nil {
			return fmt.Errorf("idle wait: %w", err)
		}
	}
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
			subject = truncateRunes(strings.TrimSpace(msgs[0].Envelope.Subject), subjectMax)
		}
	}

	if err := writeAtomic(stateFile, fmt.Sprintf("%d\n%s\n", count, subject)); err != nil {
		return fmt.Errorf("write state: %w", err)
	}
	log.Printf("refreshed: %d unread; subject=%q", count, subject)
	return nil
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
