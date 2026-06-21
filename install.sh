#!/usr/bin/env bash
# Bootstrap this dotfiles repo on a fresh Arch machine (sway/Wayland primary,
# i3/X11 kept as a side-by-side fallback).
#
#   ./install.sh
#
# Idempotent: re-running skips already-installed packages, restows symlinks,
# and never clobbers existing secrets. Safe to run as your normal user — the
# AUR helper escalates with sudo where it needs to; do not run this with sudo.
#
# What it does NOT do (deliberately — see the closing notes it prints):
#   - install an audio server for pactl (system-dependent; avoids conflicts)
#   - install nvm / bun / Oh My Zsh (each has its own installer)
#   - place a wallpaper

set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# --- pretty output --------------------------------------------------------
if [ -t 1 ]; then
    c_info=$'\033[34m'; c_ok=$'\033[32m'; c_warn=$'\033[33m'; c_err=$'\033[31m'; c_off=$'\033[0m'
else
    c_info=; c_ok=; c_warn=; c_err=; c_off=
fi
info() { printf '%s==>%s %s\n' "$c_info" "$c_off" "$*"; }
ok()   { printf '%s ok %s %s\n' "$c_ok"   "$c_off" "$*"; }
warn() { printf '%s !! %s %s\n' "$c_warn" "$c_off" "$*" >&2; }
die()  { printf '%serr%s %s\n' "$c_err"  "$c_off" "$*" >&2; exit 1; }

# --- preflight ------------------------------------------------------------
info "Preflight checks"

command -v pacman >/dev/null || die "pacman not found — this script targets Arch Linux."

# An AUR helper is required: several packages (i3lock-color, xidlehook,
# snixembed, lazydocker, 1password*) live in the AUR. paru/yay install repo
# and AUR packages alike, so we route everything through it.
AUR=""
for h in paru yay; do
    if command -v "$h" >/dev/null; then AUR="$h"; break; fi
done
[ -n "$AUR" ] || die "No AUR helper (paru/yay) found. Install one first, e.g.:
    sudo pacman -S --needed base-devel git
    git clone https://aur.archlinux.org/paru.git && cd paru && makepkg -si"
ok "Using AUR helper: $AUR"

[ "$(basename "$REPO")" = ".dotfiles" ] || \
    warn "Repo dir is '$REPO', not ~/.dotfiles — stow targets \$HOME so this is fine, just unusual."
[ -d "$REPO/.git" ] || warn "No .git in $REPO — the git-identity step will be skipped."

# --- packages -------------------------------------------------------------
# Repo + AUR mixed; the helper sorts them out. --needed makes this idempotent.
PACKAGES=(
    # Wayland / sway session  (satty, swaylock-effects are AUR)
    # rofi 2.0+ (repo) has native Wayland upstream — the old rofi-wayland fork
    # is no longer needed.
    sway swaybg swayidle swaylock-effects waybar gammastep
    grim slurp satty wl-clipboard jq
    rofi xorg-xwayland xdg-desktop-portal-wlr
    # X11 / i3 session — kept for the side-by-side fallback during migration
    i3-wm polybar picom conky redshift feh
    # WM-neutral desktop  (rofi-wayland above provides the rofi binary)
    alacritty dunst fastfetch
    # shell / CLI
    zsh tmux stow zoxide fzf fd eza bat git-delta
    # TUIs / tray  (lazydocker, snixembed are AUR)
    lazygit lazydocker flameshot snixembed
    # hardware keys
    playerctl brightnessctl
    # build / vcs
    go github-cli
    # theming
    xsettingsd xdg-desktop-portal-gtk gnome-themes-extra papirus-icon-theme
    # lock / idle  (i3lock-color, xidlehook are AUR; X11 fallback path)
    xss-lock i3lock-color xidlehook xorg-xset
    # secrets / signing  (both AUR)
    1password 1password-cli
)
info "Installing ${#PACKAGES[@]} packages via $AUR (already-present ones are skipped)"
"$AUR" -S --needed "${PACKAGES[@]}"
ok "Packages installed"

# --- stow -----------------------------------------------------------------
# Packages are grouped: common/ (both sessions), x11/ (i3), wayland/ (sway).
# We deploy all three so either session is selectable at the ly login screen
# (side-by-side). --restow re-links cleanly on a re-run; one package per dir.
# `common/bin` (personal ~/.local/bin helpers) is tracked but deliberately NOT
# deployed here — enable it by hand with `stow -d common bin`.
info "Stowing packages into \$HOME (common + x11 + wayland)"
cd "$REPO"
for group in common x11 wayland; do
    pkgs=()
    for d in "$group"/*/; do
        name="$(basename "$d")"
        [ "$group/$name" = "common/bin" ] && continue
        pkgs+=("$name")
    done
    [ "${#pkgs[@]}" -gt 0 ] && stow --restow --dir="$group" --target="$HOME" -- "${pkgs[@]}"
done
ok "Symlinks in place (skipped 'common/bin' — run 'stow -d common bin' to deploy those helpers)"

# --- git identity (the gitconfig-symlink fixup) ---------------------------
# ~/.gitconfig is itself tracked + symlinked here, so a history rewrite (rebase)
# rewinds it mid-operation and breaks signing. Pin the identity in the repo's
# LOCAL config, reading the exact values from the tracked gitconfig so there's
# a single source of truth.
if [ -d "$REPO/.git" ]; then
    info "Setting repo-local git identity + 1Password SSH signing"
    src="$REPO/git/.gitconfig"
    git -C "$REPO" config --local user.name        "$(git config --file "$src" user.name)"
    git -C "$REPO" config --local user.email       "$(git config --file "$src" user.email)"
    git -C "$REPO" config --local user.signingkey  "$(git config --file "$src" user.signingkey)"
    git -C "$REPO" config --local gpg.format       "$(git config --file "$src" gpg.format)"
    git -C "$REPO" config --local gpg.ssh.program  "$(git config --file "$src" gpg.ssh.program)"
    git -C "$REPO" config --local commit.gpgsign   "$(git config --file "$src" commit.gpgsign)"
    ok "git identity pinned to repo-local config"
fi

# --- conky mail helper: secret scaffold + build ---------------------------
imap_env="$HOME/.config/imap/imap.env"
if [ ! -f "$imap_env" ]; then
    info "Scaffolding $imap_env (gitignored secret — edit it before use)"
    mkdir -p "$(dirname "$imap_env")"
    cat > "$imap_env" <<'EOF'
IMAP_USER=you@example.com
IMAP_HOST=imap.example.com
IMAP_PASS=your-app-password
EOF
    warn "Edit $imap_env with real IMAP credentials, or the mail widget stays blank."
else
    ok "imap.env already present — left untouched"
fi

imap_src="$HOME/.config/imap"
if [ -d "$imap_src" ]; then
    info "Building imap-daemon (the shared mail backend)"
    # The Go module builds the daemon that writes /tmp/imap-$USER.txt; the
    # waybar custom/mail module (waybar-mail) and conky's conky-mail-label /
    # conky-mail-subject wrappers just read that file. The daemon is run via the
    # imap.service user unit (systemd package).
    ( cd "$imap_src" && go build -o "$HOME/.local/bin/imap-daemon" )
    ok "imap-daemon built to ~/.local/bin/"
fi

# The imap.service user unit is stowed (systemd package) above. Reload so
# systemd picks it up, but don't auto-enable: with placeholder credentials it
# would just restart-loop. Enable it yourself once imap.env holds real values.
if command -v systemctl >/dev/null; then
    systemctl --user daemon-reload 2>/dev/null || true
fi

# --- generate the non-stowed (theme-rendered) configs ---------------------
# dunst, picom, fastfetch, gtk, xsettingsd, etc. are produced by theme-render
# from the active palette (defaults to dark). --no-reload just writes files —
# it won't try to poke daemons that aren't running yet.
info "Rendering theme configs (default palette: dark)"
mkdir -p "$HOME/.cache/theme"
[ -f "$HOME/.cache/theme/current" ] || printf 'dark\n' > "$HOME/.cache/theme/current"
if "$HOME/.config/theme/theme-render" --no-reload; then
    ok "Theme configs rendered"
else
    warn "theme-render reported errors (commonly a missing wallpaper) — configs were still written."
fi

# --- done -----------------------------------------------------------------
cat <<EOF

${c_ok}Bootstrap complete.${c_off} A few things are intentionally left to you:

  • Wallpaper   — drop one under ~/Pictures/Wallpapers/ (path is set per-palette
                  in ~/.config/theme/palettes/*.sh).
  • IMAP creds  — edit ~/.config/imap/imap.env, then start the mail daemon:
                  systemctl --user enable --now imap.service
  • bin helpers — \`stow -d common bin\` to deploy the personal ~/.local/bin scripts
                  (volume/mic/brightness notifiers, clipboard notifier +
                  history browser, rofi power-profile / power menu pickers).
                  Conky's own helpers are already deployed with the conky
                  package.
  • Audio       — pactl volume keys need a PulseAudio-compatible server
                  (e.g. pipewire-pulse); not auto-installed to avoid conflicts.
  • Optional    — nvm, bun, and Oh My Zsh each have their own installers.
  • Session     — pick "sway" at the ly login screen for the Wayland session
                  (or "i3" for the X11 fallback). Both are themed.
  • Log out/in  — so the Qt portal env (QT_QPA_PLATFORMTHEME) and the
                  xdg-desktop-portal autostarts take effect.
EOF
