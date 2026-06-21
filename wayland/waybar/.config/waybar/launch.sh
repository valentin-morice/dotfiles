#!/usr/bin/env bash
# Relaunch waybar. Like the old polybar launcher: a theme switch can fire this
# from two places at once (theme-render's explicit call + sway's exec_always on
# reload), so guard the kill/wait/spawn with a non-blocking lock — the first
# caller relaunches, any concurrent caller exits as a no-op. theme-render
# re-renders the whole config (pango accent prefixes are theme-coloured), so a
# full restart is needed, not just a SIGUSR2 CSS reload.
exec 9>"${XDG_RUNTIME_DIR:-/tmp}/waybar-launch.lock"
flock -n 9 || exit 0

# waybar's config + style are theme-rendered; on a first login they may not be
# written yet (sway fires this exec_always alongside theme-render, not after it).
# Generate them on demand so the bar never starts configless.
[ -f "$HOME/.config/waybar/config" ] || "$HOME/.local/bin/theme-render" --no-reload >/dev/null 2>&1 || true

killall -q waybar
while pgrep -x waybar >/dev/null; do sleep 0.2; done
# 9>&- so waybar doesn't inherit the lock fd and hold it for its whole life.
waybar >>/tmp/waybar.log 2>&1 9>&- &
