#!/usr/bin/env bash

DEVICE_ID=$(kdeconnect-cli -a --id-only 2>/dev/null | head -n 1)

case "$1" in
    gui)
        kdeconnect-app >/dev/null 2>&1 &
        ;;
    ring)
        if [ -n "$DEVICE_ID" ]; then
            kdeconnect-cli --device "$DEVICE_ID" --ring
            notify-send -i kdeconnect "KDE Connect" "Pinging phone..." -u low
        fi
        ;;
    sms)
        kdeconnect-sms >/dev/null 2>&1 &
        ;;
esac
