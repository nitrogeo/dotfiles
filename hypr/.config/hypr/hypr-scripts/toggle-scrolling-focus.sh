#!/bin/bash

# Fetch the current value. We'll check for "custom" (plugin) output.
# 'tr -d' removes quotes/whitespace that can break 'if' statements.
VAL=$(hyprctl getoption scrolling:follow_focus -j | jq -r '.custom')

if [ "$VAL" = "true" ] || [ "$VAL" = "1" ]; then
    hyprctl keyword scrolling:follow_focus false
    notify-send -u low -t 2000 "Scrolling Layout" "Follow Focus: DISABLED"
else
    hyprctl keyword scrolling:follow_focus true
    notify-send -u low -t 2000 "Scrolling Layout" "Follow Focus: ENABLED"
fi