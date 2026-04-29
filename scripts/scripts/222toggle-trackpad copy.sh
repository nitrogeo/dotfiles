#!/bin/bash
# Replace THE_NAME_YOU_COPIED with your actual device name from hyprctl devices
HYPR_DEVICE="elan0712:00-04f3:30fd-touchpad"

STATE=$(hyprctl -j devices | jq -r ".mice[] | select(.name == \"$HYPR_DEVICE\") | .enabled")

if [ "$STATE" = "true" ]; then
    hyprctl keyword "device[$HYPR_DEVICE]:enabled" false
    notify-send "Touchpad" "Disabled" -i input-touchpad-symbolic
else
    hyprctl keyword "device[$HYPR_DEVICE]:enabled" true
    notify-send "Touchpad" "Enabled" -i input-touchpad-symbolic
fi

