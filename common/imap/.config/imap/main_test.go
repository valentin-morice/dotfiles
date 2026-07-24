package main

import "testing"

func TestSanitizeSubject(t *testing.T) {
	tests := []struct {
		name string
		in   string
		want string
	}{
		{"plain ascii untouched", "Inbox zero", "Inbox zero"},
		{"empty", "", ""},
		{"tab, newline and CR become spaces", "a\tb\nc\rd", "a b c d"},
		{"ESC becomes space", "x\x1by", "x y"},
		{"DEL (0x7f) becomes space", "a\x7fb", "a b"},
		{"0x1f is control, 0x20 is not", "a\x1f\x20b", "a  b"},
		{"multibyte runes above 0x20 preserved", "café ☕ 日本語", "café ☕ 日本語"},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			if got := sanitizeSubject(tt.in); got != tt.want {
				t.Errorf("sanitizeSubject(%q) = %q, want %q", tt.in, got, tt.want)
			}
		})
	}
}

func TestTruncateRunes(t *testing.T) {
	tests := []struct {
		name string
		in   string
		n    int
		want string
	}{
		{"shorter than limit untouched", "hello", 10, "hello"},
		{"equal to limit untouched", "hello", 5, "hello"},
		{"longer gets ellipsis in the last slot", "hello", 3, "he…"},
		{"n=1 yields first rune, no ellipsis", "hello", 1, "h"},
		{"n=0 yields empty", "hello", 0, ""},
		// Counted in runes, not bytes: byte-slicing "日本語テスト" at 3 would cut
		// mid-rune; rune-slicing keeps two whole runes plus the ellipsis.
		{"multibyte counted by rune", "日本語テスト", 3, "日本…"},
		{"multibyte exactly at limit untouched", "café", 4, "café"},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			if got := truncateRunes(tt.in, tt.n); got != tt.want {
				t.Errorf("truncateRunes(%q, %d) = %q, want %q", tt.in, tt.n, got, tt.want)
			}
		})
	}
}

func TestImapAddr(t *testing.T) {
	tests := []struct {
		name string
		host string
		want string
	}{
		{"bare host gets default 993", "imap.example.com", "imap.example.com:993"},
		{"explicit 993 kept", "imap.example.com:993", "imap.example.com:993"},
		{"explicit non-default port kept", "imap.example.com:143", "imap.example.com:143"},
		{"bracketed IPv6 with port kept", "[::1]:993", "[::1]:993"},
		{"bare IPv6 gets bracketed default port", "::1", "[::1]:993"},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			if got := imapAddr(tt.host); got != tt.want {
				t.Errorf("imapAddr(%q) = %q, want %q", tt.host, got, tt.want)
			}
		})
	}
}
