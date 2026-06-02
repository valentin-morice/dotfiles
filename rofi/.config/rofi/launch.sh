#!/bin/sh
# Thin rofi wrapper (keeps the ~/.config/<tool>/launch.sh convention).
# The old XDG_DATA_DIRS flatpak fix was removed: ly's setup_cmd=/etc/ly/setup.sh
# already sources /etc/profile.d/flatpak.sh, so flatpak .desktop files are
# visible to `drun` session-wide. See memory feedback_session_env.

# clipboard / profile / power-menu are script modi whose paths must be
# absolute — rofi (launched from i3) won't expand ~ or search PATH for them.
# Expand $HOME here so the config stays free of a hardcoded username. -modi here
# overrides the config's list. (profile = CPU power profile; power-menu =
# lock/suspend/reboot/… — distinct things.)
bin="$HOME/.local/bin"
exec rofi -modi "drun,window,clipboard:$bin/clip-menu,wifi:$bin/wifi-menu,bluetooth:$bin/bt-menu,profile:$bin/profile-select,power-menu:$bin/power-menu" "$@"
