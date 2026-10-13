#!/usr/bin/env bash

# 1. Handle interactive actions if passed as an argument
case "$1" in
    toggle)
        pactl set-source-mute @DEFAULT_SOURCE@ toggle
        ;;
    up)
        pactl set-source-volume @DEFAULT_SOURCE@ +5%
        ;;
    down)
        pactl set-source-volume @DEFAULT_SOURCE@ -5%
        ;;
esac

# 2. Query default source status
MUTED=$(pactl get-source-mute @DEFAULT_SOURCE@ 2>/dev/null | awk '{print $2}')
VOL=$(pactl get-source-volume @DEFAULT_SOURCE@ 2>/dev/null | awk -F'/' '{print $2}' | head -n 1 | tr -d ' %')

if [ -z "$VOL" ]; then
    echo "%{F#4C566A} OFF%{F-}"
    exit 0
fi

# 3. Format output
if [ "$MUTED" = "yes" ]; then
    # Muted: Nord red/dim icon with MUT label
    echo "%{F#BF616A}%{F-} %{F#4C566A}MUT%{F-}"
else
    # Active: Nord frost cyan icon with volume percentage
    echo "%{F#88C0D0}%{F-} ${VOL}%"
fi
