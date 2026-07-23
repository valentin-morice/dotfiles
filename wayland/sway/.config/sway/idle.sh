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
# The idle-*timeout* actions above no-op while a screen recording is running
# (see recording_active) so a hands-off capture isn't dimmed/locked/suspended
# mid-shot. Locking before sleep and on the logind Lock signal is deliberately
# NOT suppressed by recording — otherwise a suspend mid-recording would resume
# unlocked. So the idle timer routes to `idle-lock` (suppressible), while
# $mod+Shift+x via `loginctl lock-session`, the power-menu's lock entry, and
# before-sleep route to the unconditional `lock`.
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
# recording would dim/lock/DPMS-off mid-capture. Every idle *timeout* action
# below checks this and no-ops while recording (the timers still run; they just
# do nothing), which is simpler and dependency-free versus a Wayland inhibitor.
# NOTE: the `lock` subcommand does NOT check this — see idle-lock vs lock below.
recording_active() { pgrep -x wf-recorder >/dev/null 2>&1; }

# True (exit 0) when on wall power. Scans every "Mains" power supply by type
# rather than hardcoding an adapter name (AC/AC0/ADP0/ADP1/… vary by vendor), so
# battery-only suspend works across machines. If a mains adapter exists but none
# report online we're genuinely on battery; if there's no mains adapter at all
# (desktop/VM) we can't tell, so treat as AC and let the 2h backstop handle it.
on_ac() {
    local ps type online found=0
    for ps in /sys/class/power_supply/*; do
        [ -r "$ps/type" ] || continue
        read -r type < "$ps/type" || continue
        [ "$type" = "Mains" ] || continue
        found=1
        read -r online 2>/dev/null < "$ps/online" || continue
        [ "$online" = "1" ] && return 0
    done
    [ "$found" = "1" ] && return 1
    return 0
}

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
        # Only restore brightness if a warn actually dimmed THIS cycle (the
        # idfile marks it). Otherwise a manual `lock` ($mod+Shift+x), which also
        # routes through unwarn, would `brightnessctl -r` a stale level saved by
        # some earlier idle warn — snapping the panel to a days-old brightness.
        if [ -r "$idfile" ]; then
            brightnessctl -r >/dev/null 2>&1 || true
            dunstify -C "$(cat "$idfile")" 2>/dev/null || true
        fi
        rm -f "$idfile"
        exit 0 ;;
    idle-lock)
        # Idle-timer entry point: suppressed during a recording (so a hands-off
        # capture isn't locked mid-shot), then delegates to the unconditional
        # `lock`. Passes --grace so a quick keypress can dismiss the lock right
        # after an idle timeout — safe here because idle-lock (600s) is ~20 min
        # before suspend (1800s), so the grace window always elapses first.
        recording_active && exit 0
        exec "$0" lock --grace ;;
    lock)
        # Unconditional lock — used by the idle timer (via idle-lock, which adds
        # --grace), before sleep, and the logind Lock signal. Deliberately NOT
        # guarded by recording_active: a suspend mid-recording must still resume
        # locked. before-sleep/logind pass NO --grace, so those locks require a
        # password immediately (a grace window can survive a suspend).
        # Undo the pre-lock dim so the lock screen shows at full brightness,
        # then lock. --fork so swaylock daemonises and this returns promptly —
        # required for the before-sleep path (a blocking lock would stall sleep).
        "$0" unwarn
        exec "$lock" --fork ${2:+"$2"} ;;
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
        on_ac || systemctl suspend
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
    timeout 600 "$0 idle-lock" \
    timeout 630 "$0 dpms-off" resume "$0 dpms-on" \
    timeout 1800 "$0 maybe-suspend" \
    timeout 7200 "$0 deep-suspend" \
    before-sleep "$0 lock" \
    lock "$0 lock"
