#!/usr/bin/env bash

if pgrep -x "dunst" >/dev/null; then
    WAITING=$(dunstctl count waiting 2>/dev/null || echo 0)
    PAUSED=$(dunstctl is-paused 2>/dev/null || echo "false")

    if [ "$PAUSED" = "true" ]; then
        # Do Not Disturb / Muted
        echo "%{F#4C566A}󰂛%{F-}"
    elif [ "$WAITING" -gt 0 ]; then
        # Unread notifications waiting
        echo "%{F#D08770}󱅫%{F-} ${WAITING}"
    else
        # Normal idle state
        echo "%{F#88C0D0}󰂚%{F-}"
    fi
else
    # Fallback for xfce4-notifyd / standard FreeDesktop
    DND=$(xfconf-query -c xfce4-notifyd -p /do-not-disturb 2>/dev/null || echo "false")
    if [ "$DND" = "true" ]; then
        echo "%{F#4C566A}󰂛%{F-}"
    else
        echo "%{F#88C0D0}󰂚%{F-}"
    fi
fi
