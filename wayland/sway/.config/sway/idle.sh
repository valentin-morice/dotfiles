#!/usr/bin/env bash
# Idle + lock daemon (swayidle). Consolidates what was three X tools on i3:
# xidlehook (idle warn/lock), xss-lock (lock before suspend), and
# loginctl lock-session routing. Started from the sway config via exec_always;
# self-guards against duplicate instances so a config reload refreshes it.
#
# Timeline (mirrors the old idle-lock.sh):
#   540s idle -> dim backlight + warning notification
#   600s idle -> un-dim, then lock at full brightness
# Also locks before sleep, and on the logind Lock signal (so $mod+Shift+x via
# `loginctl lock-session`, and the power-menu's lock entry, route here too).
#
# Subcommands (invoked by swayidle's own timers, not by hand):
#   warn   -> dim + notify
#   unwarn -> restore brightness + clear the notification
#   lock   -> unwarn, then run the themed locker (swaylock, detached)
#
# Requires: swayidle, swaylock(-effects), dunst (dunstify), brightnessctl, lock.
#
# Regression vs xidlehook: no --not-when-audio (swayidle has no audio inhibit).
# Fullscreen media that grabs the Wayland idle-inhibit protocol (mpv, browsers)
# still suppresses idle, covering the common case.

set -euo pipefail

idfile="${XDG_RUNTIME_DIR:-/tmp}/idle-lock.id"
lock="$HOME/.local/bin/lock"

case "${1:-}" in
    warn)
        # Dim as the visible warning (saving the level so `unwarn` restores it).
        brightnessctl -s set 10% >/dev/null 2>&1 || true
        # --print-id so `unwarn` can close exactly this notification.
        dunstify --print-id -u critical \
            "Locking in 1 minute" \
            "Move the mouse or press a key to stay awake." > "$idfile"
        exit 0 ;;
    unwarn)
        brightnessctl -r >/dev/null 2>&1 || true
        [ -r "$idfile" ] && dunstify -C "$(cat "$idfile")" 2>/dev/null
        rm -f "$idfile"
        exit 0 ;;
    lock)
        # Undo the pre-lock dim so the lock screen shows at full brightness,
        # then lock. --fork so swaylock daemonises and this returns promptly —
        # required for the before-sleep path (a blocking lock would stall sleep).
        "$0" unwarn
        exec "$lock" --fork ;;
esac

# No arg: (re)start the daemon as a single instance.
pkill -x swayidle 2>/dev/null || true

exec swayidle -w \
    timeout 540 "$0 warn" resume "$0 unwarn" \
    timeout 600 "$0 lock" \
    before-sleep "$0 lock" \
    lock "$0 lock"
