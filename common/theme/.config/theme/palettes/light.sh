# Light theme palette — cool-neutral, designed to mirror the dark theme.
# Same accent hues (blue + gold) deepened for legibility on a light ground;
# surfaces carry a faint cool tint so they sit with the powder-blue wallpaper.
# Sourced via load.sh; consumed by theme-render.

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

# Frozen prefix colours — IDENTICAL across light/dark by design (see dark.sh for
# the rationale: keeps the rendered waybar *config* byte-identical between themes
# so a switch only touches the CSS, which reloads live without a flicker/reset).
export THEME_accent_fixed=#3a7bc8
export THEME_muted_fixed=#808488
# Frozen secondary (gold) counterpart to accent_fixed — identical across themes.
export THEME_secondary_fixed=#c0851f
# Frozen red — the REC recording label. Identical across themes (see dark.sh).
export THEME_urgent_fixed=#d63b30

# Terminal ANSI 16-color palette (consumed by alacritty.colors.toml.tmpl).
# black stays dark and white stays light in BOTH themes so palette-driven TUIs
# (nmtui/newt, bluetooth TUIs) that paint with ANSI 0/7 stay legible; the six
# hues track the theme accents. blue == accent by design. On the pale ground the
# bright hues deepen (rather than lighten) so they keep contrast.
export THEME_ansi_black=#1d2329
export THEME_ansi_red=#c8332b
export THEME_ansi_green=#2f7d4f
export THEME_ansi_yellow=#b5790a
export THEME_ansi_blue=#2f6fb3
export THEME_ansi_magenta=#8b4f9e
export THEME_ansi_cyan=#2b8a92
export THEME_ansi_white=#e9eef2
export THEME_ansi_bright_black=#6b7680
export THEME_ansi_bright_red=#9e2820
export THEME_ansi_bright_green=#246b41
export THEME_ansi_bright_yellow=#946309
export THEME_ansi_bright_blue=#265d99
export THEME_ansi_bright_magenta=#74448a
export THEME_ansi_bright_cyan=#237076
export THEME_ansi_bright_white=#ffffff

# Borders
export THEME_border=#d3dae0
export THEME_border_inactive=#c2cad1
export THEME_border_unfocused=#dde2e7
export THEME_border_med=#c2cad1
export THEME_urgent_dark=#9e2820

# Bare (no #) forms for fuzzel's RRGGBBAA colours
# (fuzzel.ini.tmpl appends an "ff" alpha to each).
export THEME_fg_bare=1d2329
export THEME_bg_bare=f4f6f8
export THEME_accent_bare=2f6fb3
export THEME_secondary_bare=b5790a
export THEME_muted_bare=6b7680
export THEME_urgent_bare=c8332b
# Extra bare forms consumed by fuzzel (mirror THEME_bg_sel/fg_soft/muted_dim/border)
export THEME_bg_sel_bare=d4e2ee
export THEME_fg_soft_bare=333b42
export THEME_muted_dim_bare=9aa4ad
export THEME_border_bare=d3dae0

# GTK / Qt. Light uses the plain (built-in) Adwaita name; dark uses Adwaita-dark
# (see dark.sh) so GTK3 reloads on the name change. GTK4/libadwaita + Qt follow
# gsettings color-scheme / the portal.
export THEME_gtk_theme=Adwaita
export THEME_gtk_prefer_dark=0
export THEME_gtk_icon=Papirus
export THEME_gtk_color_scheme=prefer-light

# VSCodium theme applied by theme-render (Claude Code follows the terminal via "auto")
export THEME_vscode="Light 2026"

# Wallpaper (applied by theme-render)
export THEME_wallpaper="$HOME/Pictures/Wallpapers/scott-webb-2X6nZA0jmvU-unsplash.jpg"
