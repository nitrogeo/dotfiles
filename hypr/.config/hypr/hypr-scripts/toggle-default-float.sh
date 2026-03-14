#!/bin/bash

FLAG="/tmp/hypr_floating_mode"

if [ ! -f "$FLAG" ]; then
    # Switch to Floating
    hyprctl keyword windowrule "float,^.*$"
    touch "$FLAG"
    notify-send "Hyprland" "Mode: Global FLOAT" -i dialogue-information
else
    # Switch to Tiling
    hyprctl reload # Easiest way to clear the dynamic global float rule
    rm "$FLAG"
    notify-send "Hyprland" "Mode: Global TILE" -i dialogue-information
fi