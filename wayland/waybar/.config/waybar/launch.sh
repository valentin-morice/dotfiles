#!/usr/bin/env bash
# Bring up / reload waybar.
#
# The bar's *lifetime* belongs to waybar.service (common/systemd) — systemd is
# what restarts it after the waybar 0.15.0 network-module segfault. This script
# is that unit's client, and its ExecStartPre. Two callers, two modes:
#   - no args: theme-render (after a theme switch) and sway's exec_always. Bump
#     the style overlay to recolour a running bar, then ensure the unit is up.
#   - --prepare: called by the unit itself. ONLY guarantees the theme-rendered
#     files exist, so the unit still works when sway-session.target starts it
#     directly and this script never runs in the no-arg mode.
# --prepare must never touch systemctl: it runs inside waybar.service's own start
# job, so starting the unit from there would deadlock against it.

overlay="$HOME/.config/waybar/style-live.css"

prepare() {
    # waybar's config + style are theme-rendered; on a first login they may not be
    # written yet (sway fires exec_always alongside theme-render, not after it).
    # Generate them on demand so the bar never starts configless. Guarded on the
    # config being absent because theme-render serialises itself behind a
    # blocking flock (-w 15) — an unconditional call would make every crash
    # restart queue behind any in-flight theme switch.
    [ -f "$HOME/.config/waybar/config" ] || "$HOME/.local/bin/theme-render" --no-reload >/dev/null 2>&1 || true
    # Bootstrap only. Bumping the overlay is the no-arg path's job, below.
    [ -f "$overlay" ] || printf '@import "style.css";\n' > "$overlay"
}

case "${1:-}" in
    --prepare) prepare; exit 0 ;;
    "") ;;
    *) echo "usage: launch.sh [--prepare]" >&2; exit 2 ;;
esac

prepare

# waybar is launched against the overlay (style-live.css), which just @imports
# style.css — that overlay is the file waybar's reload_style_on_change watches.
# On a theme switch theme-render has already re-rendered style.css; rewriting the
# overlay IN PLACE (truncate+write) bumps its mtime and trips waybar's watch, so
# it re-imports the fresh style.css and hot-applies the CSS with no widget reset
# (no flicker), unlike SIGUSR2. It must stay a truncate+write and never become a
# write-temp-then-mv: a rename swaps the inode out from under the inotify watch
# and silently kills live recolour for the rest of the bar's life.
# Unconditional, and ordered before the start below, so a rapid second theme
# switch can't have its recolour swallowed.
printf '@import "style.css";\n' > "$overlay"

# Idempotent: a no-op when the bar is already up, a cold start when it isn't
# (e.g. it hit the unit's restart limit). systemd now enforces the single
# instance that the old flock + pgrep guard hand-rolled, and owns the process, so
# waybar no longer inherits a theme-render lock fd — neither guard is needed.
# `start`, never `restart`: restarting would kill and respawn the bar on every
# theme switch, reintroducing exactly the flicker the overlay bump avoids.
systemctl --user start waybar.service
