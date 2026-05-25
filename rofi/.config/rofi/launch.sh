#!/bin/sh
# Thin rofi wrapper (keeps the ~/.config/<tool>/launch.sh convention).
# The old XDG_DATA_DIRS flatpak fix was removed: ly's setup_cmd=/etc/ly/setup.sh
# already sources /etc/profile.d/flatpak.sh, so flatpak .desktop files are
# visible to `drun` session-wide. See memory feedback_session_env.

# power-profile is a script modi whose path must be absolute — rofi (launched
# from i3) won't expand ~ or search PATH for it. Expand $HOME here so the config
# stays free of a hardcoded username. -modi here overrides the config's list.
exec rofi -modi "drun,window,power-profile:$HOME/.local/bin/profile-select" "$@"
