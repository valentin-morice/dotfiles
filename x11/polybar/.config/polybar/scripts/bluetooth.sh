#!/bin/bash
. "$HOME/.config/theme/load.sh"
if ! bluetoothctl show 2>/dev/null | grep -q "Powered: yes"; then
    echo "%{F${THEME_muted}}OFF%{F-}"
    exit
fi
device=$(bluetoothctl devices Connected 2>/dev/null | head -1 | cut -d' ' -f3-)
echo "${device:-ON}"
