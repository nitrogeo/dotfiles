#!/bin/bash
# 1.28.2026

sleep 10
date -s "$(curl -skI google.com | grep -i '^Date:' | cut -d' ' -f2-)"
chronyc makestep

notify-send "Time Synced" "School Wi-Fi timeserver block bypassed successfully!" --icon=clock