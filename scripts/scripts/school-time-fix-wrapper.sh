#!/bin/bash
# Wrapper: after Hyprland loads, check NTP/time-sync AND run HTTP time fix.
# For no-battery laptop where system time doesn't update reliably.

# 1. Check NTP / time-sync service status (systemd-timesyncd or timedatectl)
if command -v timedatectl >/dev/null 2>&1; then
    sync_status=$(timedatectl show --property=NTP --value 2>/dev/null || echo "unknown")
    echo "[time-check] NTP sync status: $sync_status"
fi

# 2. Run school-time-fix (gets time from HTTP packet via curl to google.com)
# Using the original script's method — curl HTTP Date header — since NTP may still fail.
/home/nitro/dotfiles/scripts/scripts/school-time-fix.sh || echo "[time-check] school-time-fix.sh exited with error (expected if sudo/time set fails)"
