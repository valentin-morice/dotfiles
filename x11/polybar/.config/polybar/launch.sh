#!/usr/bin/env bash
# Relaunch polybar. A theme switch can fire this from two places at almost the
# same instant (theme-render's explicit call + i3's reload), so guard the
# kill/wait/spawn critical section with a non-blocking lock: the first caller
# relaunches the bar, any concurrent caller exits as a no-op. Without this the
# kill-wait-spawn window races and you intermittently get two bars.
exec 9>"${XDG_RUNTIME_DIR:-/tmp}/polybar-launch.lock"
flock -n 9 || exit 0

killall -q polybar
while pgrep -x polybar >/dev/null; do sleep 0.2; done
# 9>&- so polybar doesn't inherit the lock fd and hold it for its whole life,
# which would make every later relaunch no-op.
polybar main -r >>/tmp/polybar.log 2>&1 9>&- &
