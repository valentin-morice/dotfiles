# Dark theme palette. Sourced via load.sh and consumed by theme-render
# (and the polybar scripts) through envsubst. To add a theme, copy this file
# to palettes/<name>.sh, change the values, and run `theme-switch <name>`.

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

# Bare (no #) forms for conky lua string fields
export THEME_fg_bare=ffffff
export THEME_bg_bare=0d0d0d
export THEME_accent_bare=5294e2
export THEME_secondary_bare=e0a552
export THEME_muted_bare=888888
export THEME_urgent_bare=ff5555

# RGB components for the conky cairo border (matches THEME_border_med)
export THEME_border_r=0x44
export THEME_border_g=0x44
export THEME_border_b=0x44

# Compositor shadow (picom)
export THEME_shadow_color=#000000
export THEME_shadow_opacity=0.35

# GTK / Qt (Adwaita; dark via prefer-dark flag + gsettings color-scheme)
export THEME_gtk_prefer_dark=1
export THEME_gtk_icon=Papirus-Dark
export THEME_gtk_color_scheme=prefer-dark

# VSCodium theme applied by theme-render (Claude Code follows the terminal via "auto")
export THEME_vscode="Dark 2026"

# Wallpaper (applied by theme-render via feh)
export THEME_wallpaper="$HOME/Pictures/Wallpapers/harald-pliessnig-YSTegVN35Ss-unsplash.jpg"
