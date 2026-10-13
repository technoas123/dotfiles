#!/usr/bin/env bash

DB="$HOME/.cache/xfce4/notifyd/log.sqlite"

if [ ! -f "$DB" ]; then
    notify-send "Notifications" "No notification history found."
    exit 0
fi

# Fetch the last 15 notifications from SQLite
ENTRIES=$(sqlite3 "$DB" "SELECT id, strftime('%H:%M', datetime(timestamp, 'unixepoch', 'localtime')), app_name, summary FROM log ORDER BY timestamp DESC LIMIT 15;" 2>/dev/null)

if [ -z "$ENTRIES" ]; then
    notify-send "Notifications" "History is empty."
    exit 0
fi

# Format lines for Rofi
MENU_ITEMS="󰎟 Clear All Notifications\n"
while IFS="|" read -r id time app summary; do
    MENU_ITEMS+="${time}  [${app}]  ${summary} (ID:${id})\n"
done <<< "$ENTRIES"

SELECTED=$(echo -e "$MENU_ITEMS" | rofi -dmenu -i -p "Notifications" -theme-str 'window {width: 480px; height: 380px;} listview {lines: 8;}')

[ -z "$SELECTED" ] && exit 0

if [[ "$SELECTED" =~ "Clear All Notifications" ]]; then
    sqlite3 "$DB" "DELETE FROM log;"
    notify-send "Notifications" "All notification logs cleared."
    exit 0
fi

# Extract ID and show full message body
NOTE_ID=$(echo "$SELECTED" | grep -o 'ID:[0-9]*' | cut -d: -f2)
if [ -n "$NOTE_ID" ]; then
    BODY=$(sqlite3 "$DB" "SELECT body FROM log WHERE id=${NOTE_ID};" 2>/dev/null)
    SUMMARY=$(sqlite3 "$DB" "SELECT summary FROM log WHERE id=${NOTE_ID};" 2>/dev/null)
    [ -z "$BODY" ] && BODY="No additional details."
    rofi -e "$SUMMARY: $BODY"
fi
