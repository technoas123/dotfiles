#!/usr/bin/env bash

ACTION=$1

case "$ACTION" in
    history)
        if pgrep -x "dunst" >/dev/null; then
            dunstctl history-pop
        else
            ~/.config/polybar/scripts/notification-rofi.sh
        fi
        ;;
    toggle-dnd)
        CURRENT=$(xfconf-query -c xfce4-notifyd -p /do-not-disturb 2>/dev/null || echo "false")
        if [ "$CURRENT" = "true" ]; then
            xfconf-query -c xfce4-notifyd -p /do-not-disturb -s false
            notify-send "Notifications" "Do Not Disturb disabled."
        else
            xfconf-query -c xfce4-notifyd -p /do-not-disturb -s true
        fi
        ;;
    close-all)
        pkill -f "xfce4-notifyd" 2>/dev/null
        ;;
esac
