#!/bin/bash
CURRENT_LAYOUT=$(hyprctl getoption general:layout -j | jq -r '.str')

if [ "$CURRENT_LAYOUT" = "dwindle" ]; then
    hyprctl keyword general:layout "scrolling"
    notify-send "Hyprland" "Layout: Scrolling" -i input-mouse
else
    hyprctl keyword general:layout "dwindle"
    notify-send "Hyprland" "Layout: Dwindle" -i input-mouse
fi