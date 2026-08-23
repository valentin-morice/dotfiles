# zsh environment — sourced for EVERY zsh (login, non-login terminals, scripts)
# and captured into the graphical session by ly's login-shell env grab.
# Interactive-only config (prompt, aliases, completions) stays in .zshrc.

typeset -U path PATH          # keep PATH entries unique even if re-sourced

# User-installed binaries (moved here from .zshrc so GUI apps get it too)
export PATH="$HOME/.local/bin:$PATH"

# Bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# Rust/Cargo binaries (rustlings, cargo-installed tools). In .zshenv (not .zshrc)
# so they're on PATH for GUI-launched and non-interactive contexts too — matters
# for building/running the Rust GUI projects from a launcher-spawned terminal.
export PATH="$HOME/.cargo/bin:$PATH"

# nvm default node on PATH for EVERY shell (incl. non-interactive & scripts),
# so node/npm/npx are real binaries that child processes inherit — agents and
# `sh -c 'node ...'` no longer fall through to the system node. This only
# prepends a dir (cheap); full nvm stays lazy-loaded in .zshrc. Resolves the
# default alias chain (default -> lts/* -> lts/krypton -> vX) without sourcing
# nvm; runs in an anonymous fn so locals don't leak into the environment.
export NVM_DIR="$HOME/.nvm"
() {
  local target=default hops=0
  while [[ $target != v[0-9]* && hops -lt 8 && -r $NVM_DIR/alias/$target ]]; do
    target="$(<$NVM_DIR/alias/$target)"
    (( hops++ ))
  done
  [[ $target == v[0-9]* && -d $NVM_DIR/versions/node/$target/bin ]] &&
    path=("$NVM_DIR/versions/node/$target/bin" $path)
}

# 1Password SSH agent — SSH auth + commit signing (op-ssh-sign). In .zshenv (not
# .zshrc) so non-interactive git-over-SSH, scripts, and GUI-launched git tools
# reach the agent too — the same reason PATH lives here.
export SSH_AUTH_SOCK="$HOME/.1password/agent.sock"

# Preferred editor, exported here so git commit / lazygit / sudoedit inherit it
# in every shell and GUI-launched context. nvim if present, else vim, else vi.
if (( $+commands[nvim] )); then
  export EDITOR=nvim VISUAL=nvim
elif (( $+commands[vim] )); then
  export EDITOR=vim VISUAL=vim
else
  export EDITOR=vi VISUAL=vi
fi

# Qt apps follow the freedesktop appearance color-scheme via the xdg-desktop-
# portal theme plugin, so they flip light/dark live on theme-switch (Qt 6.8+,
# incl. QtWebEngine prefers-color-scheme — fixes zapzap's half-themed window).
# theme-render drives it through the gsettings color-scheme. Force Fusion so the
# style follows the scheme cleanly. Needs: xdg-desktop-portal + -gtk backend.
export QT_QPA_PLATFORMTHEME=xdgdesktopportal
export QT_STYLE_OVERRIDE=Fusion

# Prefer native Wayland for Firefox and Electron apps under sway.
# Qt auto-detects Wayland when WAYLAND_DISPLAY is set, so no QT_QPA_PLATFORM here.
export MOZ_ENABLE_WAYLAND=1
export ELECTRON_OZONE_PLATFORM_HINT=auto

# Default browser for terminal apps that honour $BROWSER (xdg-open already
# resolves firefox via mimeapps.list). Keeps CLI tools off any stale fallback.
export BROWSER=firefox
