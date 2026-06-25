#!/bin/bash

# Get the first currently connected bluetooth device (MAC + name)
device=$(bluetoothctl devices Connected | head -n1)

# If nothing is connected, show a notification and exit
[ -z "$device" ] && notify-send "Bluetooth" "No connected device found" -i bluetooth && exit 1

# Extract the MAC address (2nd column) and device name (3rd column onwards)
mac=$(echo "$device" | awk '{print $2}')
name=$(echo "$device" | awk '{for(i=3;i<=NF;i++) printf "%s ", $i; print ""}' | xargs)

# Notify that we're starting the reconnect
notify-send "Bluetooth" "Reconnecting $name..." -i bluetooth

# Disconnect the device (suppress output)
bluetoothctl disconnect "$mac" > /dev/null 2>&1

# Give it a second to fully disconnect before reconnecting
sleep 1

# Reconnect the device (suppress output)
bluetoothctl connect "$mac" > /dev/null 2>&1

# Check if the reconnect actually succeeded
connected=$(bluetoothctl info "$mac" | grep -q "Connected: yes" && echo "yes")
if [ "$connected" = "yes" ]; then
  notify-send "Bluetooth" "$name reconnected successfully" -i bluetooth
else
  notify-send "Bluetooth" "Failed to reconnect $name" -i bluetooth -u critical
fi
