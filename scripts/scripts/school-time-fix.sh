#!/bin/bash

echo "This time-fix script needs sudo to inspect system directories~"
echo "If the sudo credential isn't already cached, the terminal will prompt for your user password."
sudo -v || {
    echo
    echo "ERROR: sudo authentication failed."
    exit 1
}

sleep 10

DATE=$(curl -fsSI --max-time 10 https://google.com | awk -F': ' 'tolower($1) == "date" {print $2}' | tr -d '\r')

if [ -z "$DATE" ]; then
    notify-send "Time Sync Failed" "Couldn't retrieve Google's time" --icon=dialog-error
    exit 1
fi

if sudo date -s "$DATE"; then
    notify-send "Time Synced" "System clock synced from Google's HTTP Date header successfully!" --icon=clock
else
    notify-send "Time Sync Failed" "Couldn't set the system clock" --icon=dialog-error
    exit 1
fi