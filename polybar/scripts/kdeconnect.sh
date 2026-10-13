#!/usr/bin/env bash

DEV_ID="6e1c3faeb2514b8b98bdbc222cadd68c"

# Check if reachable via kdeconnect-cli
if ! kdeconnect-cli -a 2>/dev/null | grep -q "$DEV_ID.*reachable"; then
    # Disconnected state: dimmed mobile glyph
    echo "%{F#4C566A}%{F-}"
    exit 0
fi

# Query battery charge using native busctl session bus
BAT_LEVEL=$(busctl --user call org.kde.kdeconnect.daemon "/modules/kdeconnect/devices/${DEV_ID}/battery" \
    org.freedesktop.DBus.Properties Get ss org.kde.kdeconnect.device.battery charge 2>/dev/null | awk '{print $3}')

# Output formatted string with universal mobile phone glyph ()
if [ -n "$BAT_LEVEL" ] && [ "$BAT_LEVEL" -ge 0 ] 2>/dev/null; then
    echo "%{F#88C0D0}%{F-} ${BAT_LEVEL}%"
else
    echo "%{F#88C0D0}%{F-} CMF"
fi
