# dotfiles

Personal configuration for an **Arch Linux + sway (Wayland)** desktop, managed with [GNU Stow](https://www.gnu.org/software/stow/). Commits are SSH-signed.

<!-- Optional: drop a screenshot of the rice here -->
<!-- ![desktop](docs/screenshot.png) -->

## Stack

| Role | Tool |
|------|------|
| Window manager | sway (mod = <kbd>Super</kbd>) |
| Status bar | waybar |
| Launcher | rofi (`Super+d`) |
| Terminal | alacritty (`Super+Return`) |
| Notifications | dunst |
| Compositor | sway (built-in) |
| Mail alert | waybar `custom/mail` (Go IMAP helper) |
| Lock / idle | swaylock-effects + swayidle |
| Screenshots | grim + slurp |
| Clipboard | wl-clipboard + cliphist (text & images) |
| Color temperature | gammastep |
| System info | fastfetch |
| Shell | zsh + Oh My Zsh |
| Multiplexer | tmux |
| Git/Docker TUIs | lazygit, lazydocker |
| AI coding | Claude Code (custom statusline) |

Pick **sway** at the ly login screen.

Font: **JetBrainsMono Nerd Font**.

## Layout

One Stow package per tool, each mirroring `$HOME`, grouped into two Stow
*directories*: `common/` (WM-neutral) and `wayland/` (sway session).
For example `wayland/sway/.config/sway/config` → `~/.config/sway/config`
(stowed with `stow -d wayland sway`).

```
common/   alacritty  applications  bash  bin  claude  git  imap  lazydocker
          lazygit  systemd  theme  tmux  xdg  zsh
wayland/  gammastep  kanshi  portal  sway  waybar
```

The IMAP mail backend (`common/imap` → the `imap-daemon` Go module at
`~/.config/imap/`, plus its `imap.env` secret) is display-agnostic: it writes
`$XDG_RUNTIME_DIR/imap.txt`, which the `waybar` `custom/mail` module just reads.

`dunst`, `fastfetch`, and `bluetuith` have no package of their own — their configs are *generated* by `theme-render` from the active palette, not stowed. (`bluetuith` renders in truecolor so it can't follow the terminal palette, and it rewrites its config in HJSON on exit; the template carries its keybindings too, and it picks up colours on next launch.) The `sway` colours (`colors.conf`), and the whole `waybar` `config` + `style.css`, are likewise theme-rendered (gitignored). Each package ships the `~/.local/bin` helpers its config calls: `sway` → `idle.sh` (swayidle) + `screenshot` / `screenrecord` / `dropdown-term` / `keybind-help`; `waybar` → `launch.sh` + `waybar-mail` / `-dnd` / `-nightlight` / `-recording`. (`verify-wayland`, a session self-test, lives in the `bin` package.)

Packages bundle their own `~/.local/bin` helpers where the config needs them: `theme` ships `theme-switch`/`theme-render`/`lock`. These deploy automatically with their package.

`systemd` holds the `imap.service` user unit that runs the shared mail daemon (`imap-daemon`, built from the `common/imap` package). It's stowed by `install.sh`, but **enabling** it is left to you (it needs real IMAP credentials first — see Post-install).

`common/bin` holds the remaining personal `~/.local/bin` helpers that aren't tied to one config: volume/brightness/mic notifiers, the DND toggle, a clipboard notifier + history browser, the rofi menus (clipboard, power-profile, power, window, emoji) + their shared `rofi-card-theme.sh`, and the `verify-wayland` self-test. It **is** deployed by `install.sh` — the always-stowed `sway`/`waybar`/`dunst` configs bind and exec these helpers, so leaving it out would ship dead keys and menus.

## Install

```sh
git clone git@github.com:valentin-morice/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
./install.sh
```

`install.sh` is idempotent: it installs every dependency (routing both repo and
AUR packages through your AUR helper), stows all packages, pins the repo-local
git signing identity, scaffolds the IMAP mail secret (chmod 600), builds the
`imap-daemon` mail backend, enables the `batsignal`/`thunar` session units, and
renders the theme. Re-run it any time. It requires an AUR helper (`paru`/`yay`)
to already be present, and should be run as your normal user — not with sudo. It
does **not** enable the mail daemon's user service (it'd restart-loop without
real credentials) — do that yourself after filling in `imap.env` (see
Post-install).

### Manual install

Without the script, stow each group (the `-d` flag is the Stow directory; the
target is `$HOME`):

```sh
stow -d common  -t ~ alacritty applications bash bin claude git imap lazydocker lazygit systemd theme tmux xdg zsh
stow -d wayland -t ~ gammastep kanshi portal sway waybar
```

Stow one package with `stow -d <group> <name>`, remove one with `stow -d <group> -D <name>`. Then install the dependencies below and follow Post-install.

### Dependencies

Wayland core: `sway swaybg swayidle swaylock-effects waybar gammastep grim slurp jq wl-clipboard cliphist wtype rofi xorg-xwayland xdg-desktop-portal-wlr` (`swaylock-effects` is AUR; `rofi` is the launcher/dmenu backend; `cliphist` is the clipboard history, `wtype` lets the emoji picker type its pick)
Session plumbing the sway config execs: `awww` (wallpaper daemon, AUR) `wf-recorder` (screen recording) `kanshi` (output profiles) `dex` (XDG autostart) `polkit-gnome` (auth agent) `sway-audio-idle-inhibit-git` (AUR) `batsignal` (battery notifier, AUR) `xdg-user-dirs`
Apps + font: `chromium thunar thunar-volman gvfs zathura zathura-pdf-mupdf nsxiv vscodium-bin` (`vscodium-bin` is AUR) · `ttf-jetbrains-mono-nerd` — the font every config names
WM-neutral: `alacritty dunst fastfetch zsh tmux stow`
Hardware keys: `playerctl` (media) · `brightnessctl` (brightness, also used by the idle-dim) · a PulseAudio-compatible server for `pactl` volume control (e.g. `pipewire-pulse`)
Shell CLI: `zoxide fzf fd eza bat git-delta` (plus `nvm`, `bun`)
TUIs/other: `lazygit lazydocker` (`lazydocker` is AUR)
Build: `go` — compiles `imap-daemon`, the mail backend (see Post-install)
Theming: `xdg-desktop-portal-gtk gnome-themes-extra papirus-icon-theme` — live GTK/Qt light-dark on `theme-switch` (Qt via `QT_QPA_PLATFORMTHEME=xdgdesktopportal`; GTK3 via the xdg settings portal)
Signing/secrets: `1password` + `1password-cli` (SSH agent & commit signing)
`bin` helpers: `power-profiles-daemon` (rofi-profile) · `wl-clipboard` + `cliphist` + `imagemagick` (clip-notify / rofi-clip; imagemagick thumbnails image clips) · `libnotify` for `notify-send` (volume/brightness/mic notifiers) — `pactl`/`brightnessctl` are already listed above

## Post-install (not tracked in the repo)

`install.sh` automates the first and third items below (scaffolding `imap.env`,
building the helper, and pinning the local git identity). They're documented
here for the manual path and for reference. The **wallpaper** is always manual.

- **Mail backend** needs `~/.config/imap/imap.env` (gitignored, in the
  `common/imap` package). The script writes a template; fill in real values:
  ```sh
  IMAP_USER=you@example.com
  IMAP_HOST=imap.example.com
  IMAP_PASS=your-app-password
  ```
  Then build the daemon (Go required): `cd ~/.config/imap && go build -o ~/.local/bin/imap-daemon`. It's run by the tracked `imap.service` user unit (`systemd` package) — once `imap.env` holds real values, enable it:
  ```sh
  systemctl --user enable --now imap.service
  ```
  The daemon writes `$XDG_RUNTIME_DIR/imap.txt`; the waybar `custom/mail` module (`waybar-mail`, in the `waybar` package) just reads it — already in place, no extra step.
- **Wallpaper** is not included; drop one under `~/Pictures/Wallpapers/` (path set per-palette in `~/.config/theme/palettes/*.sh`).
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
