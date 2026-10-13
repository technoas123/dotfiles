#!/usr/bin/env bash
FILE="/sys/class/power_supply/BAT1/charge_control_end_threshold"
CURRENT=$(cat "$FILE" 2>/dev/null || echo 100)

if [ "$CURRENT" -eq 80 ]; then
    echo 100 | sudo /usr/bin/tee "$FILE" > /dev/null
    notify-send -i battery "Battery Threshold" "Charge limit set to 100%" -u low
else
    echo 80 | sudo /usr/bin/tee "$FILE" > /dev/null
    notify-send -i battery "Battery Threshold" "Charge limit set to 80%" -u low
fi
