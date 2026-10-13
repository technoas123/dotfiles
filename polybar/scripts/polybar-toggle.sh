#!/usr/bin/env bash

# Find Polybar X11 Window ID
WIN_ID=$(xdotool search --class "polybar" | head -n 1)

if [ -z "$WIN_ID" ]; then
    # If not running, start it
    ~/.config/polybar/launch.sh
    exit 0
fi

# Check if the window is currently visible/mapped
IS_VISIBLE=$(xprop -id "$WIN_ID" _NET_WM_STATE 2>/dev/null)

if xdotool getwindowgeometry "$WIN_ID" >/dev/null 2>&1; then
    # Window exists; try native IPC toggle first
    polybar-msg cmd toggle >/dev/null 2>&1
    
    # If override-redirect prevented unmapping, force X11 window state
    if xwininfo -id "$WIN_ID" | grep -q "IsViewable"; then
        xdotool windowunmap "$WIN_ID" 2>/dev/null
    fi
else
    xdotool windowmap "$WIN_ID" 2>/dev/null || polybar-msg cmd toggle >/dev/null 2>&1
fi
