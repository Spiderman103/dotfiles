#!/bin/bash
# Night mode toggle for Sway

# Kill ALL gammastep processes first
pkill -9 gammastep

# Check state file
STATE_FILE="/tmp/night-mode-state"

if [ -f "$STATE_FILE" ]; then
    # Night mode is ON, turn it OFF
    gammastep -x
    rm "$STATE_FILE"
    notify-send "Night Mode" "Disabled" -t 2000
else
    # Night mode is OFF, turn it ON
    gammastep -O 3500 &
    touch "$STATE_FILE"
    notify-send "Night Mode" "Enabled (3500K)" -t 2000
fi
