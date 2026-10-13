#!/usr/bin/env bash

# 1. Kill duplicate panels/bars cleanly
killall -q xfce4-panel 2>/dev/null
pkill -9 -f "polybar-autohide.sh" 2>/dev/null
killall -q polybar 2>/dev/null
while pgrep -u $UID -x polybar >/dev/null; do sleep 0.1; done

# 2. Launch Polybar
polybar mybar -c "$HOME/.config/polybar/config.ini" >> /tmp/polybar.log 2>&1 &

# 3. Brief pause before starting autohide
sleep 0.8
~/.config/polybar/scripts/polybar-autohide.sh &
