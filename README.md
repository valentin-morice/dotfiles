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
alacritty  bash  claude  conky  dunst  fastfetch  git  i3
lazydocker  lazygit  picom  polybar  redshift  rofi  tmux  zsh
```

## Install

```sh
git clone git@github.com:valentin-morice/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
stow */          # symlink every package into $HOME (target is the parent dir, ~)
```

Stow each package individually with `stow <name>`, or remove one with `stow -D <name>`.

### Dependencies

Core: `i3-wm polybar rofi alacritty dunst picom conky redshift fastfetch zsh tmux stow feh`
Shell CLI: `zoxide fzf fd eza bat git-delta` (plus `nvm`, `bun`)
TUIs/other: `lazygit lazydocker flameshot` · tray via `snixembed` (AUR)
Signing/secrets: `1password` + `1password-cli` (SSH agent & commit signing)

## Post-install (not tracked in the repo)

A few things are deliberately left out and must be set up locally:

- **Conky mail widget** needs `~/.config/conky/imap.env` (gitignored). Create it with:
  ```sh
  IMAP_USER=you@example.com
  IMAP_HOST=imap.example.com
  IMAP_PASS=your-app-password
  ```
  Then build the helper (Go required): `cd ~/.config/conky/imap && go build -o ~/.local/bin/conky-mail-label`.
- **Wallpaper** is not included; i3 expects one under `~/Pictures/Wallpapers/`.
- **Commit signing** uses a 1Password-held SSH key (`op-ssh-sign`). Because this repo *tracks its own `~/.gitconfig`* via symlink, a history rewrite (e.g. `git rebase`) rewinds that file mid-operation and breaks identity/signing. Fix on a fresh clone — set them in the repo's **local** config:
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
