#!/usr/bin/env bash
# Idle-lock daemon (xidlehook): warn 1 minute before locking, then run the
# themed locker. Started from the i3 config via exec_always; self-guards against
# duplicate instances so a config reload refreshes it cleanly.
#
# Division of labour: xss-lock still handles the SUSPEND path; X's built-in
# screensaver is turned off in the i3 config (xset s off) so it no longer trips
# xss-lock on idle — this daemon owns idle-locking instead, so there's no
# double-lock.
#
# xidlehook --timer values are DELTAS: the first is seconds since the user went
# idle; each later one is seconds since the previous timer fired.
#   540s idle  -> warning notification
#   +60s       -> lock
# Become active after the warning and the canceller dismisses the notification.
#
# Requires: xidlehook, dunst (dunstify), brightnessctl, the `lock` script.
# --not-when-audio needs xidlehook built with PulseAudio support; drop it if
# your build lacks it.

idfile="${XDG_RUNTIME_DIR:-/tmp}/idle-lock.id"

case "${1:-}" in
    warn)
        # Dim the backlight as the visible warning (saving the current level so
        # `unwarn` can put it back exactly), and post a notification alongside.
        brightnessctl -s set 10% >/dev/null 2>&1 || true
        # --print-id prints the server-assigned id; stash it so `unwarn` can
        # close exactly this notification (a fixed replace-id isn't reliable).
        dunstify --print-id -u critical \
            "Locking in 1 minute" \
            "Move the mouse or press a key to stay awake." > "$idfile"
        exit 0 ;;
    unwarn)
        brightnessctl -r >/dev/null 2>&1 || true
        [ -r "$idfile" ] && dunstify -C "$(cat "$idfile")" 2>/dev/null
        rm -f "$idfile"
        exit 0 ;;
esac

# No arg: (re)start the daemon as a single instance.
pkill -x xidlehook 2>/dev/null || true

exec xidlehook \
    --not-when-fullscreen \
    --not-when-audio \
    --timer 540 "$0 warn" "$0 unwarn" \
    --timer 60  "$HOME/.local/bin/lock" ''
