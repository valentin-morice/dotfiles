# Light theme palette — cool-neutral, designed to mirror the dark theme.
# Same accent hues (blue + gold) deepened for legibility on a light ground;
# surfaces carry a faint cool tint so they sit with the powder-blue wallpaper.
# Sourced via load.sh; consumed by theme-render and the polybar scripts.

# Backgrounds / foregrounds
export THEME_bg=#f4f6f8
export THEME_bg_alt=#e9eef2
export THEME_bg_alt2=#e4e9ee
export THEME_bg_sel=#d4e2ee
export THEME_fg=#1d2329
export THEME_fg_soft=#333b42
export THEME_muted=#6b7680
export THEME_muted_dim=#9aa4ad
export THEME_muted_warm=#8b939b
export THEME_highlight=#9aa4ad

# Accents (same hues as dark, deepened for contrast on light)
export THEME_accent=#2f6fb3
export THEME_secondary=#b5790a
export THEME_urgent=#c8332b

# Borders
export THEME_border=#d3dae0
export THEME_border_inactive=#c2cad1
export THEME_border_unfocused=#dde2e7
export THEME_border_med=#c2cad1
export THEME_urgent_dark=#9e2820

# Bare (no #) forms for conky lua string fields
export THEME_fg_bare=1d2329
export THEME_bg_bare=f4f6f8
export THEME_accent_bare=2f6fb3
export THEME_secondary_bare=b5790a
export THEME_muted_bare=6b7680
export THEME_urgent_bare=c8332b

# RGB components for the conky cairo border (matches THEME_border_med #c2cad1)
export THEME_border_r=0xc2
export THEME_border_g=0xca
export THEME_border_b=0xd1

# Compositor shadow (picom) — softer on the light ground so it doesn't read heavy
export THEME_shadow_color=#000000
export THEME_shadow_opacity=0.18

# VSCodium theme applied by theme-render (Claude Code follows the terminal via "auto")
export THEME_vscode="Light 2026"

# Wallpaper (applied by theme-render via feh)
export THEME_wallpaper="$HOME/Pictures/Wallpapers/scott-webb-2X6nZA0jmvU-unsplash.jpg"
