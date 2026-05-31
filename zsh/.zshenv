# zsh environment — sourced for EVERY zsh (login, non-login terminals, scripts)
# and captured into the graphical session by ly's login-shell env grab.
# Interactive-only config (prompt, aliases, completions) stays in .zshrc.

typeset -U path PATH          # keep PATH entries unique even if re-sourced

# User-installed binaries (moved here from .zshrc so GUI apps get it too)
export PATH="$HOME/.local/bin:$PATH"

# Bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# Qt apps read their palette from qt6ct, whose Fusion colour scheme theme-render
# regenerates from the active palette on each toggle. Needs: qt6ct (extra repo).
# (Qt5 apps would need qt5ct + this set to qt5ct instead.)
export QT_QPA_PLATFORMTHEME=qt6ct
