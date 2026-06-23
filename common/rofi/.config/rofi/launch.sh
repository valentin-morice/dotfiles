#!/bin/sh
# Launcher dispatcher (lives under rofi/ for path stability — both WM configs
# call ~/.config/rofi/launch.sh). Picks the backend by session type:
#   Wayland/sway -> fuzzel (native Wayland)
#   X11/i3       -> rofi   (fuzzel can't run on X11)
#
# Invoked as: launch.sh -show <mode>     (mode: drun|window|clipboard|profile|power-menu)
# Wi-Fi/Bluetooth menus were dropped in favour of the nmtui / bluetuith TUIs
# (bound directly in the WM configs), so they're no longer modes here.
#
# rofi side keeps the script-mode modi (clip-menu/profile-select/power-menu).
# fuzzel has no script-mode/tabs, so each mode maps to a small dmenu wrapper in
# ~/.local/bin/fuzzel-*. drun is fuzzel's own native app launcher.

bin="$HOME/.local/bin"

# Extract the mode following -show (default: drun).
mode=drun
prev=
for a in "$@"; do
    [ "$prev" = "-show" ] && { mode="$a"; break; }
    prev="$a"
done

if [ -z "${WAYLAND_DISPLAY:-}" ]; then
    # X11 / i3 fallback — unchanged rofi behaviour (absolute script-modi paths;
    # -modi here overrides the config's list). profile = CPU power profile;
    # power-menu = lock/suspend/reboot/…
    exec rofi -modi "drun,window,clipboard:$bin/clip-menu,profile:$bin/profile-select,power-menu:$bin/power-menu" "$@"
fi

# Wayland / sway — fuzzel.
case "$mode" in
    drun)       exec fuzzel --prompt 'drun ❯ ' ;;
    window)     exec "$bin/fuzzel-window" ;;
    clipboard)  exec "$bin/fuzzel-clip" ;;
    profile)    exec "$bin/fuzzel-profile" ;;
    power-menu) exec "$bin/fuzzel-power" ;;
    *)          exec fuzzel ;;
esac
