#!/usr/bin/env bash

# Define options for the dashboard
options=" Apps\\n   Power\\n   Music\\n   Brightness\\n Volume\\n   Screenshot"

# Get selection from rofi
chosen="$(echo -e "$options" | rofi -dmenu -p "Dashboard" -theme ~/.config/rofi/applets/type-1/style-1.rasi)"

case $chosen in
    *"Apps"*)
        ~/.config/rofi/applets/bin/apps.sh
        ;;
    *"Power"*)
        ~/.config/rofi/applets/bin/powermenu.sh
        ;;
    *"Music"*)
        ~/.config/rofi/applets/bin/mpd.sh
        ;;
    *"Brightness"*)
        ~/.config/rofi/applets/bin/brightness.sh
        ;;
    *"Volume"*)
        ~/.config/rofi/applets/bin/volume.sh
        ;;
    *"Screenshot"*)
        ~/.config/rofi/applets/bin/screenshot.sh
        ;;
es:
