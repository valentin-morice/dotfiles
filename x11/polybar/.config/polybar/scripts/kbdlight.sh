#!/bin/bash
v=$(cat /sys/class/leds/tpacpi::kbd_backlight/brightness)
case "$v" in
    0) echo "%{F#888888}OFF%{F-}" ;;
    1) echo "LO" ;;
    2) echo "HI" ;;
    *) echo "$v" ;;
esac
