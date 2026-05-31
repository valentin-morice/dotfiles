#!/bin/bash
. "$HOME/.config/theme/palette.sh"
ssid=$(nmcli -t -f IN-USE,SSID dev wifi 2>/dev/null | awk -F: '$1=="*"{print $2; exit}')
if [ -n "$ssid" ]; then
    echo "$ssid"
else
    echo "%{F${THEME_muted}}OFFLINE%{F-}"
fi
