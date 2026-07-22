# dotfiles

Personal configuration for an **Arch Linux + sway (Wayland)** desktop, managed with [GNU Stow](https://www.gnu.org/software/stow/). An **i3 (X11)** session is kept side-by-side as a fallback. Commits are SSH-signed.

<!-- Optional: drop a screenshot of the rice here -->
<!-- ![desktop](docs/screenshot.png) -->

## Stack

| Role | Tool (Wayland / sway) | Fallback (X11 / i3) |
|------|------|------|
| Window manager | sway (mod = <kbd>Super</kbd>) | i3 |
| Status bar | waybar | polybar |
| Launcher | rofi 2.0+ (`Super+d`, native Wayland) | rofi |
| Terminal | alacritty (`Super+Return`) | — |
| Notifications | dunst | — |
| Compositor | sway (built-in) | picom |
| Mail alert | waybar `custom/mail` (Go IMAP helper) | conky |
| Lock / idle | swaylock + swayidle | i3lock-color + xss-lock + xidlehook |
| Screenshots | grim + slurp + satty | flameshot |
| Clipboard | wl-clipboard + cliphist (text & images) | xclip + clipnotify |
| Color temperature | gammastep | redshift |
| System info | fastfetch | — |
| Shell | zsh + Oh My Zsh | — |
| Multiplexer | tmux | — |
| Git/Docker TUIs | lazygit, lazydocker | — |
| AI coding | Claude Code (custom statusline) | — |

The IMAP mail backend (`imap-daemon` + `imap.service`) is display-agnostic and shared by both sessions. Pick **sway** or **i3** at the ly login screen.

Font: **JetBrainsMono Nerd Font**.

## Layout

One Stow package per tool, each mirroring `$HOME`, grouped into three Stow
*directories* by session: `common/` (both), `x11/` (i3), `wayland/` (sway).
For example `wayland/sway/.config/sway/config` → `~/.config/sway/config`
(stowed with `stow -d wayland sway`).

```
common/   alacritty  bash  bin  claude  git  imap  lazydocker  lazygit
          rofi  systemd  theme  tmux  zsh
x11/      conky  flameshot  i3  polybar  redshift
wayland/  gammastep  sway  waybar
```

`install.sh` stows all three groups (side-by-side), so both sessions are
selectable at the ly login screen. The IMAP mail backend (`common/imap` → the
`imap-daemon` Go module at `~/.config/imap/`, plus its `imap.env` secret) is
display-agnostic: it writes `/tmp/imap-$USER.txt`, which both the Wayland
`waybar` `custom/mail` module and the X11 `conky` mail widget just read. So it
lives in `common/` and a Wayland-only setup needs nothing from `x11/`.

`dunst`, `fastfetch`, `picom`, and `bluetuith` have no package of their own — their configs are *generated* by `theme-render` from the active palette, not stowed. (`bluetuith` renders in truecolor so it can't follow the terminal palette, and it rewrites its config in HJSON on exit; the template carries its keybindings too, and it picks up colours on next launch.) The `sway` colours (`colors.conf`), and the whole `waybar` `config` + `style.css`, are likewise theme-rendered (gitignored). Each package ships the `~/.local/bin` helpers its config calls: `sway` → `idle.sh` (swayidle) + `screenshot`; `waybar` → `launch.sh` + `waybar-mail`. (`verify-wayland`, a one-off migration self-test, lives in the opt-in `bin` package.)

Packages bundle their own `~/.local/bin` helpers where the config needs them: `conky` ships `conky-bar`, `conky-mail-label`, `conky-mail-subject`, `cpu-temp` (its widgets call these), and `theme` ships `theme-switch`/`theme-render`/`lock`. These deploy automatically with their package.

`systemd` holds the `imap.service` user unit that runs the shared mail daemon (`imap-daemon`, built from the `common/imap` package). It's stowed by `install.sh`, but **enabling** it is left to you (it needs real IMAP credentials first — see Post-install).

`common/bin` holds the remaining personal `~/.local/bin` helpers that aren't tied to one config: volume/brightness/mic notifiers, a clipboard notifier + history browser, rofi menus (power-profile, power, wifi, bluetooth), and the `verify-wayland` self-test. It's tracked for version control but **opt-in**: `install.sh` does not deploy it. Enable it with `stow -d common bin`.

## Install

```sh
git clone git@github.com:valentin-morice/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
./install.sh
```

`install.sh` is idempotent: it installs every dependency (routing both repo and
AUR packages through your AUR helper), stows all packages (except the opt-in
`bin`), pins the repo-local git signing identity, scaffolds the conky mail
secret, builds the `imap-daemon` mail backend, and renders the theme. Re-run it
any time. It requires an AUR helper (`paru`/`yay`) to already be present, and
should be run as your normal user — not with sudo. It does **not** enable the
mail daemon's user service (it'd restart-loop without real credentials) — do
that yourself after filling in `imap.env` (see Post-install).

### Manual install

Without the script, stow each group (the `-d` flag is the Stow directory; the
target is `$HOME`):

```sh
stow -d common  -t ~ alacritty bash claude git lazydocker lazygit rofi systemd theme tmux zsh
stow -d x11     -t ~ conky flameshot i3 polybar redshift
stow -d wayland -t ~ gammastep sway waybar
```

Stow one package with `stow -d <group> <name>`, remove one with `stow -d <group> -D <name>`. Then install the dependencies below and follow Post-install.

### Dependencies

Wayland core: `sway swaybg swayidle swaylock-effects waybar gammastep grim slurp satty jq wl-clipboard cliphist wtype rofi xorg-xwayland xdg-desktop-portal-wlr` (`satty`, `swaylock-effects` are AUR; `rofi` 2.0+ from the repo has native Wayland, replacing the old `rofi-wayland` fork; `cliphist` is the Wayland clipboard history, `wtype` lets the emoji picker type its pick)
X11 fallback core: `i3-wm polybar picom conky redshift feh xss-lock i3lock-color xidlehook xorg-xset` (`i3lock-color`, `xidlehook` are AUR)
WM-neutral: `alacritty dunst fastfetch zsh tmux stow`
Hardware keys: `playerctl` (media) · `brightnessctl` (brightness, also used by the idle-dim) · a PulseAudio-compatible server for `pactl` volume control (e.g. `pipewire-pulse`)
Shell CLI: `zoxide fzf fd eza bat git-delta` (plus `nvm`, `bun`)
TUIs/other: `lazygit lazydocker flameshot` · X11 tray via `snixembed` (AUR; sway's waybar uses a native SNI tray)
Build: `go` — compiles `imap-daemon`, the mail backend (see Post-install)
Theming: `xdg-desktop-portal-gtk gnome-themes-extra papirus-icon-theme` — live GTK/Qt light-dark on `theme-switch` (Qt via `QT_QPA_PLATFORMTHEME=xdgdesktopportal`; GTK3 via the xdg settings portal on Wayland, and `xsettingsd` on X11)
Signing/secrets: `1password` + `1password-cli` (SSH agent & commit signing)
`bin` helpers (opt-in package): `power-profiles-daemon` (profile-select) · `wl-clipboard`/`xclip` + `clipnotify` (clip-notify / clip-menu) · `grim slurp satty` (screenshot) · `networkmanager` (wifi-menu) · `bluez-utils` (bt-menu) · `libnotify` for `notify-send` (volume/brightness/mic notifiers) — `pactl`/`brightnessctl` are already listed above

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
  The daemon writes `/tmp/imap-$USER.txt`; the waybar `custom/mail` module (`waybar-mail`, in the `waybar` package) and conky's `conky-mail-label`/`conky-mail-subject` wrappers (in the `conky` package) just read it — already in place, no extra step.
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
