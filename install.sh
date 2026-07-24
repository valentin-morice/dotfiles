#!/usr/bin/env bash
# Bootstrap this dotfiles repo on a fresh Arch machine (sway/Wayland).
#
#   ./install.sh
#
# Idempotent: re-running skips already-installed packages, restows symlinks,
# and never clobbers existing secrets. Safe to run as your normal user — the
# AUR helper escalates with sudo where it needs to; do not run this with sudo.
#
# Env:
#   DOTFILES_SKIP_PACKAGES=1  Skip the AUR-helper preflight and the package
#                             install entirely; only stow/build/render. Handy
#                             for re-runs, no-AUR machines, and the CI bootstrap
#                             job (which pre-installs the few build deps itself).
#
# What it does NOT do (deliberately — see the closing notes it prints):
#   - install an audio server for pactl (system-dependent; avoids conflicts)
#   - install nvm / bun / Oh My Zsh (each has its own installer)
#   - place a wallpaper

set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKIP_PACKAGES="${DOTFILES_SKIP_PACKAGES:-}"

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

# An AUR helper is required: several packages (swaylock-effects, bluetuith,
# lazydocker, 1password*) live in the AUR. paru/yay install repo
# and AUR packages alike, so we route everything through it.
AUR=""
if [ -n "$SKIP_PACKAGES" ]; then
    warn "DOTFILES_SKIP_PACKAGES set — skipping AUR-helper check and package install."
else
    for h in paru yay; do
        if command -v "$h" >/dev/null; then AUR="$h"; break; fi
    done
    [ -n "$AUR" ] || die "No AUR helper (paru/yay) found. Install one first, e.g.:
    sudo pacman -S --needed base-devel git
    git clone https://aur.archlinux.org/paru.git && cd paru && makepkg -si"
    ok "Using AUR helper: $AUR"
fi

[ "$(basename "$REPO")" = ".dotfiles" ] || \
    warn "Repo dir is '$REPO', not ~/.dotfiles — stow targets \$HOME so this is fine, just unusual."
[ -d "$REPO/.git" ] || warn "No .git in $REPO — the git-identity step will be skipped."

# --- packages -------------------------------------------------------------
# Repo + AUR mixed; the helper sorts them out. --needed makes this idempotent.
PACKAGES=(
    # Wayland / sway session  (swaylock-effects is AUR); rofi is the launcher
    # and the dmenu backend for the ~/.local/bin/rofi-* menus.
    sway swaybg swayidle swaylock-effects waybar gammastep
    grim slurp wl-clipboard jq rofi
    # cliphist: Wayland clipboard history (text + images; skips password-manager
    # clips). wtype: lets the emoji picker type its pick (optional). imagemagick:
    # thumbnails image clips in the rofi-clip menu.
    cliphist wtype imagemagick
    xorg-xwayland xdg-desktop-portal-wlr
    # Network / Bluetooth TUIs (opened in a floating terminal from $mod+n /
    # $mod+b). bluetuith is AUR.
    networkmanager bluetuith
    # Desktop
    alacritty dunst fastfetch
    # shell / CLI
    zsh tmux stow zoxide fzf fd eza bat git-delta
    # TUIs  (lazydocker is AUR)
    lazygit lazydocker
    # hardware keys
    playerctl brightnessctl
    # build / vcs
    go github-cli
    # theming
    xdg-desktop-portal-gtk gnome-themes-extra papirus-icon-theme
    # apps the sway session launches + mimeapps maps: chromium browser, thunar
    # file manager (+ volman for removable media, gvfs for trash/mounts), zathura
    # PDF reader + mupdf backend, nsxiv image viewer, mpv (the video/audio handler
    # in mimeapps.list), vscodium editor (AUR).
    chromium thunar thunar-volman gvfs zathura zathura-pdf-mupdf nsxiv mpv vscodium-bin
    # session plumbing the sway config execs: awww wallpaper daemon (AUR), dex
    # XDG-autostart, polkit auth agent, audio idle-inhibit (AUR), kanshi outputs.
    awww dex polkit-gnome sway-audio-idle-inhibit-git kanshi
    # screen recording, battery notifier (AUR), XDG user dirs, and THE font every
    # config names (without it fontconfig substitutes garbage glyphs).
    wf-recorder batsignal xdg-user-dirs ttf-jetbrains-mono-nerd
    # secrets / signing  (both AUR)
    1password 1password-cli
)
if [ -n "$SKIP_PACKAGES" ]; then
    info "Skipping install of ${#PACKAGES[@]} packages (DOTFILES_SKIP_PACKAGES set)"
else
    info "Installing ${#PACKAGES[@]} packages via $AUR (already-present ones are skipped)"
    "$AUR" -S --needed "${PACKAGES[@]}"
    ok "Packages installed"
fi

# --- stow -----------------------------------------------------------------
# Packages are grouped: common/ (WM-neutral) and wayland/ (sway session).
# --restow re-links cleanly on a re-run; one package per dir. `common/bin` IS
# deployed: the always-stowed sway/waybar/dunst configs bind and exec its helpers
# (volume/brightness/mic notifiers, the rofi-* menus, clip-notify, dunst-dmenu),
# so leaving it out would ship dead keys and menus.
info "Stowing packages into \$HOME (common + wayland)"
cd "$REPO"
for group in common wayland; do
    pkgs=()
    for d in "$group"/*/; do
        pkgs+=("$(basename "$d")")
    done
    # No `--` before the package list: GNU stow 2.4 rejects it ("No packages to
    # stow") — its option parser doesn't treat `--` as end-of-options. The names
    # are directory basenames (never dash-prefixed), so it was never needed.
    [ "${#pkgs[@]}" -gt 0 ] && stow --restow --dir="$group" --target="$HOME" "${pkgs[@]}"
done
ok "Symlinks in place"

# --- git identity (the gitconfig-symlink fixup) ---------------------------
# ~/.gitconfig is itself tracked + symlinked here, so a history rewrite (rebase)
# rewinds it mid-operation and breaks signing. Pin the identity in the repo's
# LOCAL config, reading the exact values from the tracked gitconfig so there's
# a single source of truth.
if [ -d "$REPO/.git" ]; then
    info "Setting repo-local git identity + 1Password SSH signing"
    # NOTE: the tracked gitconfig lives under common/ since the repo was regrouped
    # (it used to be $REPO/git). Read each key into a var and DIE if it's missing
    # rather than pin an empty value: `git config --file <missing>` fails inside a
    # command substitution, which set -e does NOT catch, so a wrong path here
    # would silently pin empty user.name/email/signingkey and break commits.
    src="$REPO/common/git/.gitconfig"
    [ -r "$src" ] || die "tracked gitconfig not found at $src — cannot pin identity."
    for key in user.name user.email user.signingkey gpg.format gpg.ssh.program commit.gpgsign; do
        val=$(git config --file "$src" "$key") \
            || die "missing '$key' in $src — refusing to pin an empty git identity."
        git -C "$REPO" config --local "$key" "$val"
    done
    ok "git identity pinned to repo-local config"
fi

# --- mail helper: secret scaffold + build ---------------------------------
imap_env="$HOME/.config/imap/imap.env"
if [ ! -f "$imap_env" ]; then
    info "Scaffolding $imap_env (gitignored secret — edit it before use)"
    mkdir -p "$(dirname "$imap_env")"
    cat > "$imap_env" <<'EOF'
IMAP_USER=you@example.com
IMAP_HOST=imap.example.com
IMAP_PASS=your-app-password
EOF
    chmod 600 "$imap_env"   # it holds a plaintext password; imap.service assumes 600
    warn "Edit $imap_env with real IMAP credentials, or the mail widget stays blank."
else
    ok "imap.env already present — left untouched"
fi

imap_src="$HOME/.config/imap"
if [ -d "$imap_src" ]; then
    info "Building imap-daemon (the shared mail backend)"
    # The Go module builds the daemon that writes $XDG_RUNTIME_DIR/imap.txt; the
    # waybar custom/mail module (waybar-mail) just reads that file. The daemon
    # is run via the imap.service user unit (systemd package).
    ( cd "$imap_src" && go build -o "$HOME/.local/bin/imap-daemon" )
    ok "imap-daemon built to ~/.local/bin/"
fi

# The imap.service user unit is stowed (systemd package) above. Reload so
# systemd picks it up, but don't auto-enable: with placeholder credentials it
# would just restart-loop. Enable it yourself once imap.env holds real values.
if command -v systemctl >/dev/null; then
    systemctl --user daemon-reload 2>/dev/null || true
    # Enable the session units that are WantedBy=sway-session.target (no sudo).
    # imap.service is deliberately NOT enabled here — it would restart-loop on the
    # placeholder credentials (enable it after filling in imap.env; see below).
    for unit in batsignal.service thunar.service; do
        systemctl --user enable "$unit" >/dev/null 2>&1 \
            && ok "enabled $unit" \
            || warn "could not enable $unit yet (its package may not be installed — re-run install.sh)"
    done
fi

# --- generate the non-stowed (theme-rendered) configs ---------------------
# dunst, fastfetch, gtk, waybar, etc. are produced by theme-render
# from the active palette (defaults to dark). --no-reload just writes files —
# it won't try to poke daemons that aren't running yet.
info "Rendering theme configs (default palette: dark)"
mkdir -p "$HOME/.cache/theme"
[ -f "$HOME/.cache/theme/current" ] || printf 'dark\n' > "$HOME/.cache/theme/current"
if "$HOME/.config/theme/theme-render" --no-reload; then
    ok "Theme configs rendered"
else
    warn "theme-render failed. A missing wallpaper is harmless (configs were still written); an 'undefined palette var' error means nothing was written — fix the palette and re-run."
fi

# --- done -----------------------------------------------------------------
cat <<EOF

${c_ok}Bootstrap complete.${c_off} A few things are intentionally left to you:

  • Wallpaper   — drop one under ~/Pictures/Wallpapers/ (path is set per-palette
                  in ~/.config/theme/palettes/*.sh).
  • IMAP creds  — edit ~/.config/imap/imap.env, then start the mail daemon:
                  systemctl --user enable --now imap.service
  • Audio       — pactl volume keys need a PulseAudio-compatible server
                  (e.g. pipewire-pulse); not auto-installed to avoid conflicts.
  • Optional    — nvm, bun, and Oh My Zsh each have their own installers.
  • Session     — pick "sway" at the ly login screen.
  • Log out/in  — so the Qt portal env (QT_QPA_PLATFORMTHEME) and the
                  xdg-desktop-portal autostarts take effect.
EOF
