#!/usr/bin/env bash
# Bring up / reload waybar. A theme switch can fire this from two places at once
# (theme-render's explicit call + sway's exec_always on reload), so guard with a
# non-blocking lock — the first caller acts, any concurrent caller exits as a
# no-op.
exec 9>"${XDG_RUNTIME_DIR:-/tmp}/waybar-launch.lock"
flock -n 9 || exit 0

# waybar's config + style are theme-rendered; on a first login they may not be
# written yet (sway fires this exec_always alongside theme-render, not after it).
# Generate them on demand so the bar never starts configless.
[ -f "$HOME/.config/waybar/config" ] || "$HOME/.local/bin/theme-render" --no-reload >/dev/null 2>&1 || true

# waybar is launched against an overlay style (style-live.css) that just @imports
# style.css, NOT style.css directly. The overlay is the file waybar's
# reload_style_on_change watches: on a theme switch theme-render rewrites style.css
# (per-theme bg/fg/workspace), then we rewrite the overlay to bump its mtime,
# which trips waybar's watcher → it re-parses the overlay, re-imports the fresh
# style.css, and hot-applies the CSS in place. No widget reset (so no flicker),
# unlike SIGUSR2; the recolour is instant — no animation. The config never
# changes (frozen prefixes), so it's never reloaded.
overlay="$HOME/.config/waybar/style-live.css"

if pgrep -x waybar >/dev/null; then
    # Theme switch: style.css is already re-rendered; bump the overlay so the
    # style watcher hot-applies it. Rewriting (truncate+write) reliably fires the
    # file monitor even though the content is unchanged.
    printf '@import "style.css";\n' > "$overlay"
else
    # Login: overlay just @imports the rendered style; spawn waybar against it.
    printf '@import "style.css";\n' > "$overlay"
    # 9>&- so waybar doesn't inherit the lock fd and hold it for its whole life.
    waybar -s "$overlay" >>/tmp/waybar.log 2>&1 9>&- &
fi
