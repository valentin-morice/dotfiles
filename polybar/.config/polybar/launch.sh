#!/usr/bin/env bash
killall -q polybar
while pgrep -x polybar >/dev/null; do sleep 0.2; done
polybar main -r >>/tmp/polybar.log 2>&1 &
