# from https://gemini.google.com/app/6e34b9a86f6665a3
# on 1.26.2026 ~9:40pm


# //////////////


!/bin/bash

echo ""
echo "--- Arch Stowage Analysis ---"

# Calculate current cache sizes
USER_CACHE=$(du -sh ~/.cache | cut -f1)
PAC_CACHE=$(du -sh /var/cache/pacman/pkg | cut -f1)

# FIXED: This looks for the actual size value (e.g., 4.0G) instead of the word 'system'
JOURNAL_SIZE=$(journalctl --disk-usage | grep -oP '\d+(\.\d+)?[G|M|K]')


echo "Current User Cache: $USER_CACHE"
echo "Current Pacman Cache: $PAC_CACHE"
echo "Current System Logs: $JOURNAL_SIZE"
echo "----------------------------"
echo ""

# read -p "Do you want to proceed with cleanup? (y/n): " confirm
read -p "Do you want to pwoceed wit cweanup UwU? (y/n): " confirm
if [[ $confirm == [yY] || $confirm == [yY][eE][sS] ]]; then
    echo "--- Starting Arch Cleanup ---"

    # 1. Vacuum System Logs to 2 weeks
    # sudo journalctl --vacuum-time=2weeks


    # 2. Clean Pacman cache (keeps latest 2 versions)
    if command -v paccache &> /dev/null; then
        sudo paccache -r
    else
        sudo pacman -Sc
    fi


    # 3. Clean yay (AUR) build cache
    yay -Scc --noconfirm


    # 4. Clear App Caches
    echo "Clearing Browser and Spotify caches..."
    rm -rf ~/.cache/spotify/*
    rm -rf ~/.cache/BraveSoftware
    # rm -rf ~/.cache/mozilla/firefox/*.default-release/cache2/*

    echo "--- Cleanup Complete! ---"
else
    echo "Cleanup cancelled~"
fi