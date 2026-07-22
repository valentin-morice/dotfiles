# Dark theme palette. Sourced via load.sh and consumed by theme-render
# through envsubst. To add a theme, copy this file to palettes/<name>.sh,
# change the values, and run `theme-switch <name>`.

# Backgrounds / foregrounds
export THEME_bg=#0d0d0d
export THEME_bg_alt=#141414
export THEME_bg_alt2=#1a1a1a
export THEME_bg_sel=#1c1c1c
export THEME_fg=#ffffff
export THEME_fg_soft=#d4d4d4
export THEME_muted=#888888
export THEME_muted_dim=#6e6e6e
export THEME_muted_warm=#aaaaaa
export THEME_highlight=#6c6c6c

# Accents
export THEME_accent=#5294e2
export THEME_secondary=#e0a552
export THEME_urgent=#ff5555

# Frozen prefix colours — IDENTICAL across light/dark by design. The waybar
# accent/muted text prefixes (VOL/WIFI/BT/BAT/MAIL + the MUTED/OFFLINE/… state
# words) live in the *config*, which has no flicker-free in-place reload. Pinning
# them to one cross-theme value keeps the rendered config byte-identical between
# themes, so a theme switch only rewrites the CSS — which waybar live-applies via
# reload_style_on_change with no reset. Mid-blue / mid-grey read on both grounds.
export THEME_accent_fixed=#3a7bc8
export THEME_muted_fixed=#808488
# Frozen secondary (gold) counterpart to accent_fixed — a deep gold that reads
# on both grounds (bright on near-black, dark enough on near-white).
export THEME_secondary_fixed=#c0851f
# Frozen red — the REC recording label. One value for both grounds (bright enough
# on near-black, dark enough on near-white), like the other *_fixed prefixes.
export THEME_urgent_fixed=#d63b30

# Terminal ANSI 16-color palette (consumed by alacritty.colors.toml.tmpl).
# black stays dark and white stays light in BOTH themes so palette-driven TUIs
# (nmtui/newt, bluetooth TUIs) that paint with ANSI 0/7 stay legible; the six
# hues track the theme accents. blue == accent by design.
export THEME_ansi_black=#1a1a1a
export THEME_ansi_red=#ff5555
export THEME_ansi_green=#6cc08b
export THEME_ansi_yellow=#e0a552
export THEME_ansi_blue=#5294e2
export THEME_ansi_magenta=#b48ead
export THEME_ansi_cyan=#5fb3c4
export THEME_ansi_white=#d4d4d4
export THEME_ansi_bright_black=#888888
export THEME_ansi_bright_red=#ff7b7b
export THEME_ansi_bright_green=#87d0a3
export THEME_ansi_bright_yellow=#ecc07d
export THEME_ansi_bright_blue=#6ba3e8
export THEME_ansi_bright_magenta=#c8a0c8
export THEME_ansi_bright_cyan=#7fc8d6
export THEME_ansi_bright_white=#ffffff

# Borders
export THEME_border=#1f1f1f
export THEME_border_inactive=#333333
export THEME_border_unfocused=#222222
export THEME_border_med=#444444
export THEME_urgent_dark=#900000

# Bare (no #) forms for fuzzel's RRGGBBAA colours
# (fuzzel.ini.tmpl appends an "ff" alpha to each).
export THEME_fg_bare=ffffff
export THEME_bg_bare=0d0d0d
export THEME_accent_bare=5294e2
export THEME_secondary_bare=e0a552
export THEME_muted_bare=888888
export THEME_urgent_bare=ff5555
# Extra bare forms consumed by fuzzel (mirror THEME_bg_sel/fg_soft/muted_dim/border)
export THEME_bg_sel_bare=1c1c1c
export THEME_fg_soft_bare=d4d4d4
export THEME_muted_dim_bare=6e6e6e
export THEME_border_bare=1f1f1f

# GTK / Qt. GTK3 reloads reliably only on a theme-NAME change, so dark uses the
# named Adwaita-dark (needs gnome-themes-extra) rather than the prefer-dark flag
# alone; GTK4/libadwaita + Qt follow gsettings color-scheme / the portal.
export THEME_gtk_theme=Adwaita-dark
export THEME_gtk_prefer_dark=1
export THEME_gtk_icon=Papirus-Dark
export THEME_gtk_color_scheme=prefer-dark

# VSCodium theme applied by theme-render (Claude Code follows the terminal via "auto")
export THEME_vscode="Dark 2026"

# Wallpaper (applied by theme-render)
export THEME_wallpaper="$HOME/Pictures/Wallpapers/harald-pliessnig-YSTegVN35Ss-unsplash.jpg"
