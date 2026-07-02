#!/bin/bash

# Clear terminal for a clean look
# clear


echo "========================================" # ~40 = signs idk
echo "      System Time Verification      "
echo "========================================"
echo ""
# echo -n "Is the system time/clock right? (y/n): "
echo -n "Do you need to fix the system clock? (y/n): "
read -r answer


if [[ "$answer" =~ ^[Nn]$ ]]; then
    echo ""
    echo "nvm lol"
    echo ""
    # 5-second countdown timer
    for i in {5..1}; do
        echo -ne "Closing terminal in $i seconds...\r"
        sleep 1
    done
    exit 0

elif [[ "$answer" =~ ^[Yy]$ ]]; then
    echo ""
    echo "--- Enter Correct Details ---"

    read -p "Month (MM, e.g., 06): " month
    read -p "Day (DD, e.g., 21): " day
    read -p "Year (YYY, e.g., 2026): " year
    read -p "Hour (1-12): " hour
    read -p "Minute (MM, e.g. 35): " minute
    # read -p "Second (MM, e.g. 35): " second
    read -p "AM or PM (am/a/pm/p): " ampm

    # Convert AM/PM to uppercase so the date command reads it perfectly
    ampm_upper=$(echo "$ampm" | tr '[:lower:]' '[:upper:]')

    # Construct a format GNU date loves: YYY-MM-DD hh:mm AM/PM
    date_string="${year}-${month}-${day} ${hour}:${minute} ${ampm_upper}"

    echo ""
    echo "Updating system time to: $date_string"
    echo ""
    echo "Please enter your sudo password below."
    echo ""

    # Set system time and immediately sync it to the hardware clock (RTC)
    sudo date -s "$date_string" && sudo hwclock --systohc
    sleep 1
    bash /home/nitro/.config/waybar/scripts/nitrolaunch.sh &

    echo ""
    # 5-second countdown timer
    for t in {5..1}; do
        echo -n "Time successfully updated! " 
        echo -ne "Closing in $t seconds...\r"
        sleep 1
    done
    exit 0

else
    echo ""
    echo "Invalid input. Exiting..."
    sleep 2
    exit 1
fi


# notes:
#   - wanna have a and p be valid input for the am/pm prompt
#   - wanna have if invalid input it tells u what was invalid then takes u back to the main menu
#   - add test function lol - main menu

