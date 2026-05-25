#!/bin/sh
# Thin rofi wrapper (keeps the ~/.config/<tool>/launch.sh convention).
# The old XDG_DATA_DIRS flatpak fix was removed: ly's setup_cmd=/etc/ly/setup.sh
# already sources /etc/profile.d/flatpak.sh, so flatpak .desktop files are
# visible to `drun` session-wide. See memory feedback_session_env.

exec rofi "$@"
