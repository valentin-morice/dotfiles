# Centralized color palette. Consumed by theme-render via envsubst.
# Phase 1: single palette (the existing dark look, consolidated). Phase 2
# will promote this to palettes/<name>.sh and add a theme abstraction.

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
