#!/bin/bash

# Target device confirmed from your hardware list
DEVICE="elan0712:00-04f3:30fd-touchpad"
STATE_FILE="/tmp/touchpad_state"

# If the state file doesn't exist, assume it's currently enabled
if [ ! -f $STATE_FILE ]; then
    echo "enabled" > $STATE_FILE
fi

CURRENT=$(cat $STATE_FILE)

if [ "$CURRENT" == "enabled" ]; then
    hyprctl keyword "device[$DEVICE]:enabled" false
    echo "disabled" > $STATE_FILE
    notify-send "Trackpad" "Disabled" -i input-touchpad-symbolic
else
    hyprctl keyword "device[$DEVICE]:enabled" true
    echo "enabled" > $STATE_FILE
    notify-send "Trackpad" "Enabled" -i input-touchpad-symbolic
fi