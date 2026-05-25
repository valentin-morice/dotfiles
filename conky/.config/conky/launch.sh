#!/bin/bash
# Kill any existing conky instances, then start one per section.
killall -q conky
while pgrep -x conky >/dev/null; do sleep 0.1; done

for section in mail disk cpu mem power; do
    conky -d -c "$HOME/.config/conky/${section}.conf" >/dev/null 2>&1
done
