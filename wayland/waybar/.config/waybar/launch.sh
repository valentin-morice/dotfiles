#!/usr/bin/env bash
# Bring up / reload waybar.
#
# A theme switch rewrites style.css then calls this to hot-apply it; sway's
# exec_always also calls this on reload/login. Two concerns, handled separately:
#   - the style-overlay bump (the recolour trigger) runs UNCONDITIONALLY, so a
#     rapid second switch can't have its recolour swallowed by the spawn lock;
#   - the actual waybar spawn is guarded by a non-blocking lock + a pgrep check
#     so two near-simultaneous callers never start a second bar.

overlay="$HOME/.config/waybar/style-live.css"

# waybar's config + style are theme-rendered; on a first login they may not be
# written yet (sway fires this exec_always alongside theme-render, not after it).
# Generate them on demand so the bar never starts configless.
[ -f "$HOME/.config/waybar/config" ] || "$HOME/.local/bin/theme-render" --no-reload >/dev/null 2>&1 || true

# waybar is launched against the overlay (style-live.css), which just @imports
# style.css — that overlay is the file waybar's reload_style_on_change watches.
# On a theme switch theme-render has already re-rendered style.css; rewriting the
# overlay (truncate+write) bumps its mtime and trips waybar's watcher, so it
# re-imports the fresh style.css and hot-applies the CSS in place — no widget
# reset (no flicker), unlike SIGUSR2. Kept OUTSIDE the spawn lock so it always
# fires. The config never changes (frozen prefixes), so it's never reloaded.
printf '@import "style.css";\n' > "$overlay"

# Spawn at most one waybar: only the caller that both wins the lock and finds no
# running instance starts it. 9>&- keeps waybar from inheriting the lock fd and
# holding it for its whole life. Log to XDG_STATE_HOME (truncated per spawn, so
# it stays bounded) rather than an unbounded, predictable-name /tmp file.
logdir="${XDG_STATE_HOME:-$HOME/.local/state}"
mkdir -p "$logdir"
exec 9>"${XDG_RUNTIME_DIR:-/tmp}/waybar-launch.lock"
if flock -n 9 && ! pgrep -x waybar >/dev/null; then
    waybar -s "$overlay" >"$logdir/waybar.log" 2>&1 9>&- &
fi
