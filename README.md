# dotfiles

Personal configuration for an **Arch Linux + i3** desktop, managed with [GNU Stow](https://www.gnu.org/software/stow/). Commits are SSH-signed.

<!-- Optional: drop a screenshot of the rice here -->
<!-- ![desktop](docs/screenshot.png) -->

## Stack

| Role | Tool |
|------|------|
| Window manager | i3 (mod = <kbd>Super</kbd>) |
| Status bar | polybar |
| Launcher | rofi (`Super+d`) |
| Terminal | alacritty (`Super+Return`) |
| Notifications | dunst |
| Compositor | picom (glx backend; vsync left to AMD TearFree) |
| Desktop widgets | conky (incl. a Go IMAP unread-mail helper) |
| Color temperature | redshift |
| System info | fastfetch |
| Shell | zsh + Oh My Zsh |
| Multiplexer | tmux |
| Git/Docker TUIs | lazygit, lazydocker |
| AI coding | Claude Code (custom statusline) |

Font: **JetBrainsMono Nerd Font**.

## Layout

One Stow package per tool, each mirroring `$HOME`. For example `i3/.config/i3/config` → `~/.config/i3/config`.

```
alacritty  bash  claude  conky  flameshot  git  i3
lazydocker  lazygit  polybar  redshift  rofi  theme  tmux  zsh
```

`dunst`, `fastfetch`, and `picom` have no package of their own — their configs are *generated* by `theme-render` from the active palette, not stowed.

## Install

```sh
git clone git@github.com:valentin-morice/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
./install.sh
```

`install.sh` is idempotent: it installs every dependency (routing both repo and
AUR packages through your AUR helper), stows all packages, pins the repo-local
git signing identity, scaffolds the conky mail secret, builds the mail helper,
and renders the theme. Re-run it any time. It requires an AUR helper
(`paru`/`yay`) to already be present, and should be run as your normal user —
not with sudo.

### Manual install

Without the script: `stow */` symlinks every package into `$HOME` (the target
is the parent dir, `~`). Stow one package with `stow <name>`, remove one with
`stow -D <name>`. Then install the dependencies below and follow Post-install.

### Dependencies

Core: `i3-wm polybar rofi alacritty dunst picom conky redshift fastfetch zsh tmux stow feh`
Hardware keys: `playerctl` (media) · `brightnessctl` (brightness, also used by the idle-dim) · a PulseAudio-compatible server for `pactl` volume control (e.g. `pipewire-pulse`)
Shell CLI: `zoxide fzf fd eza bat git-delta` (plus `nvm`, `bun`)
TUIs/other: `lazygit lazydocker flameshot` · tray via `snixembed` (AUR)
Build: `go` — compiles the conky mail helper (see Post-install)
Theming: `xsettingsd xdg-desktop-portal-gtk gnome-themes-extra papirus-icon-theme` — live GTK/Qt light-dark on `theme-switch` (GTK3 via Adwaita/Adwaita-dark name-switch over xsettingsd; Qt via `QT_QPA_PLATFORMTHEME=xdgdesktopportal`)
Lock/idle: `xss-lock i3lock-color xidlehook` (last two AUR) · `xorg-xset` — themed lock + warn-then-lock idle daemon (dims via `brightnessctl`, above)
Signing/secrets: `1password` + `1password-cli` (SSH agent & commit signing)

## Post-install (not tracked in the repo)

`install.sh` automates the first and third items below (scaffolding `imap.env`,
building the helper, and pinning the local git identity). They're documented
here for the manual path and for reference. The **wallpaper** is always manual.

- **Conky mail widget** needs `~/.config/conky/imap.env` (gitignored). The
  script writes a template; fill in real values:
  ```sh
  IMAP_USER=you@example.com
  IMAP_HOST=imap.example.com
  IMAP_PASS=your-app-password
  ```
  Then build the helper (Go required): `cd ~/.config/conky/imap && go build -o ~/.local/bin/conky-mail-label`.
- **Wallpaper** is not included; i3 expects one under `~/Pictures/Wallpapers/` (path set per-palette in `~/.config/theme/palettes/*.sh`).
- **Commit signing** uses a 1Password-held SSH key (`op-ssh-sign`). Because this repo *tracks its own `~/.gitconfig`* via symlink, a history rewrite (e.g. `git rebase`) rewinds that file mid-operation and breaks identity/signing. Fix on a fresh clone — set them in the repo's **local** config (the script reads these straight from the tracked gitconfig):
  ```sh
  git config --local user.name "valentin"
  git config --local user.email "valentin@morice.live"
  git config --local user.signingkey "ssh-ed25519 AAAA…"
  git config --local gpg.format ssh
  git config --local gpg.ssh.program /opt/1Password/op-ssh-sign
  git config --local commit.gpgsign true
  ```

## Conventions

Helper sources live under `~/.config/<tool>/`; built binaries go to `~/.local/bin/`.
