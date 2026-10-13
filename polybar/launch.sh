#!/usr/bin/env bash

# 1. Kill any existing instances cleanly
pkill -9 -f "polybar-autohide.sh" 2>/dev/null
killall -q polybar 2>/dev/null
while pgrep -u $UID -x polybar >/dev/null; do sleep 0.1; done

# 2. Launch single Polybar instance
polybar mybar -c "$HOME/.config/polybar/config.ini" >> /tmp/polybar.log 2>&1 &
POLYBAR_PID=$!

# 3. Wait until Polybar creates its X11 window
for i in {1..20}; do
    if xdotool search --class "polybar" >/dev/null 2>&1; then
        break
    fi
    sleep 0.1
done

# 4. Start autohide daemon targeted to this instance
~/.config/polybar/scripts/polybar-autohide.sh &
