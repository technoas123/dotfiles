#!/usr/bin/env bash

BAR_HEIGHT=44
TRIGGER_HEIGHT=5
BAR_STATE="visible"

is_mouse_top() {
    eval "$(xdotool getmouselocation --shell 2>/dev/null)"
    [ -n "$Y" ] && [ "$Y" -le "$TRIGGER_HEIGHT" ]
}

is_window_overlapping() {
    local win
    win=$(xdotool getactivewindow 2>/dev/null)
    [ -z "$win" ] && return 1

    local win_class
    win_class=$(xprop -id "$win" WM_CLASS 2>/dev/null)
    if [[ "$win_class" =~ "polybar" ]] || [[ "$win_class" =~ "Plank" ]] || [[ "$win_class" =~ "xfdesktop" ]]; then
        return 1
    fi

    local state
    state=$(xprop -id "$win" _NET_WM_STATE 2>/dev/null)
    if [[ "$state" =~ "_NET_WM_STATE_MAXIMIZED" ]] || [[ "$state" =~ "_NET_WM_STATE_FULLSCREEN" ]]; then
        return 0
    fi

    eval "$(xdotool getwindowgeometry --shell "$win" 2>/dev/null)"
    if [ -n "$Y" ] && [ "$Y" -lt "$BAR_HEIGHT" ]; then
        return 0
    fi

    return 1
}

while true; do
    if is_mouse_top; then
        if [ "$BAR_STATE" = "hidden" ]; then
            polybar-msg cmd show >/dev/null 2>&1
            BAR_STATE="visible"
        fi
    elif is_window_overlapping; then
        if [ "$BAR_STATE" = "visible" ]; then
            polybar-msg cmd hide >/dev/null 2>&1
            BAR_STATE="hidden"
        fi
    else
        if [ "$BAR_STATE" = "hidden" ]; then
            polybar-msg cmd show >/dev/null 2>&1
            BAR_STATE="visible"
        fi
    fi
    sleep 0.15
done
