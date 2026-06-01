# zsh environment — sourced for EVERY zsh (login, non-login terminals, scripts)
# and captured into the graphical session by ly's login-shell env grab.
# Interactive-only config (prompt, aliases, completions) stays in .zshrc.

typeset -U path PATH          # keep PATH entries unique even if re-sourced

# User-installed binaries (moved here from .zshrc so GUI apps get it too)
export PATH="$HOME/.local/bin:$PATH"

# Bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# Qt apps follow the freedesktop appearance color-scheme via the xdg-desktop-
# portal theme plugin, so they flip light/dark live on theme-switch (Qt 6.8+,
# incl. QtWebEngine prefers-color-scheme — fixes zapzap's half-themed window).
# theme-render drives it through the gsettings color-scheme. Force Fusion so the
# style follows the scheme cleanly. Needs: xdg-desktop-portal + -gtk backend.
export QT_QPA_PLATFORMTHEME=xdgdesktopportal
export QT_STYLE_OVERRIDE=Fusion
