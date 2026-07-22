#!/usr/bin/env bash
# Idle + lock daemon (swayidle). Consolidates what was three X tools on i3:
# xidlehook (idle warn/lock), xss-lock (lock before suspend), and
# loginctl lock-session routing. Started from the sway config via exec_always;
# self-guards against duplicate instances so a config reload refreshes it.
#
# Timeline (mirrors the old idle-lock.sh):
#   540s idle  -> dim backlight + warning notification
#   600s idle  -> un-dim, then lock at full brightness
#   630s idle  -> panel off (any input powers it back on)
#   1800s idle -> suspend, battery only (already locked since 600s)
#   7200s idle -> suspend regardless of power (AC backstop; already locked)
# All of the above no-op while a screen recording is running (see
# recording_active). Also locks before sleep, and on the logind Lock signal (so
# $mod+Shift+x via `loginctl lock-session`, and the power-menu's lock entry,
# route here too).
#
# Subcommands (invoked by swayidle's own timers, not by hand):
#   warn         -> dim + notify
#   unwarn       -> restore brightness + clear the notification
#   lock         -> unwarn, then run the themed locker (swaylock, detached)
#   dpms-off/on  -> panel power off / on
#   maybe-suspend-> suspend if on battery;  deep-suspend -> suspend unconditionally
#
# Requires: swayidle, swaylock(-effects), dunst (dunstify), brightnessctl, lock.
#
# Regression vs xidlehook: no --not-when-audio (swayidle has no audio inhibit).
# Fullscreen media that grabs the Wayland idle-inhibit protocol (mpv, browsers)
# still suppresses idle, covering the common case.

set -euo pipefail

idfile="${XDG_RUNTIME_DIR:-/tmp}/idle-lock.id"
lock="$HOME/.local/bin/lock"

# True while a screen recording is in progress. wf-recorder generates no input
# and doesn't grab the idle-inhibit protocol, so without this a hands-off
# recording would dim/lock/DPMS-off mid-capture. Every idle *action* below
# checks this and no-ops while recording (the timers still run; they just do
# nothing), which is simpler and dependency-free versus a Wayland inhibitor.
recording_active() { pgrep -x wf-recorder >/dev/null 2>&1; }

case "${1:-}" in
    warn)
        recording_active && exit 0
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
        recording_active && exit 0
        # Undo the pre-lock dim so the lock screen shows at full brightness,
        # then lock. --fork so swaylock daemonises and this returns promptly —
        # required for the before-sleep path (a blocking lock would stall sleep).
        "$0" unwarn
        exec "$lock" --fork ;;
    dpms-off)
        # Panel off (any input powers it back on). A subcommand rather than an
        # inline swaymsg so recording can suppress it.
        recording_active && exit 0
        exec swaymsg "output * power off" ;;
    dpms-on)
        exec swaymsg "output * power on" ;;
    maybe-suspend)
        # Deep-idle: suspend after 30 min, but only on battery. The session is
        # already locked (600s), and before-sleep re-locks idempotently.
        recording_active && exit 0
        if [ "$(cat /sys/class/power_supply/AC/online)" = "0" ]; then
            systemctl suspend
        fi
        exit 0 ;;
    deep-suspend)
        # AC backstop: suspend after 2h regardless of power source so an idle
        # machine on wall power doesn't burn all night (battery already suspended
        # at 30min via maybe-suspend). Already locked; before-sleep re-locks.
        recording_active && exit 0
        systemctl suspend
        exit 0 ;;
esac

# No arg: (re)start the daemon as a single instance.
pkill -x swayidle 2>/dev/null || true

exec swayidle -w \
    timeout 540 "$0 warn" resume "$0 unwarn" \
    timeout 600 "$0 lock" \
    timeout 630 "$0 dpms-off" resume "$0 dpms-on" \
    timeout 1800 "$0 maybe-suspend" \
    timeout 7200 "$0 deep-suspend" \
    before-sleep "$0 lock" \
    lock "$0 lock"
