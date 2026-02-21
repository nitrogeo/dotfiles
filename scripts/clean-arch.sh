# from https://gemini.google.com/app/6e34b9a86f6665a3
# on 1.26.2026 ~9:40pm


# //////////////


#!/bin/bash


# This checks if the first argument ($1) is "auto"
if [ "$1" == "auto" ]; then
    TRIGGER="Automatically (Sunday Prompt)"
else
    TRIGGER="Manually Triggered"
fi


echo ""
echo "--- Arch Stowage Analysis ---"
echo "Source: $TRIGGER" # States how cleanup was triggered~
echo ""

# Capture BEFORE sizes (in KB) - 2>/dev/null hides permission errors
BEFORE_USER=$(du -s ~/.cache 2>/dev/null | awk '{print $1}')
BEFORE_PAC=$(du -s /var/cache/pacman/pkg 2>/dev/null | awk '{print $1}')

# Robust journal size check
JOURNAL_RAW=$(journalctl --disk-usage | grep -oP '\d+(\.\d+)?[G|M|K]')

echo "Current User Cache: $(du -sh ~/.cache 2>/dev/null | cut -f1)"
echo "Current Pacman Cache: $(du -sh /var/cache/pacman/pkg 2>/dev/null | cut -f1)"
echo "Current System Logs: $JOURNAL_RAW"
echo "----------------------------"
echo ""


# read -p "Do you want to proceed with cleanup? (y/n): " confirm
read -p "Do you want to pwoceed wit cweanup UwU? (y/n): " confirm
if [[ $confirm == [yY] || $confirm == [yY][eE][sS] ]]; then
    echo "--- Starting Arch Cleanup ---"
    echo "%%%%%%%%%%%%%%%%%%%%%%%%%%%%%"
    echo ""
    echo ""

    # 1. Vacuum System Logs to 2 weeks
    # sudo journalctl --vacuum-time=2weeks


    echo ""
    # echo "############################"
    echo "%%%%% Clearing Pacman cache..."
    # echo "############################"
    echo ""
    # 2. Clean Pacman cache (keeps latest 2 versions)
    if command -v paccache &> /dev/null; then
        sudo paccache -r 2>/dev/null
    else
        sudo pacman -Sc --noconfirm
    fi


    echo ""
    # echo "############################"
    echo "%%%%% Clearing yay/AUR build cache..."
    # echo "############################"
    echo ""
    # 3. Clean yay (AUR) build cache
    yay -Sc --noconfirm


    # 3.5 Remove orphaned packages (with confirmation!)
    echo ""
    echo ""
    echo "############################"
    echo ""
    echo "Checking for orphaned packages..."
    ORPHANS=$(pacman -Qdtq)
    if [[ -n "$ORPHANS" ]]; then
        echo "The following orphaned packages were found:"
        echo "$ORPHANS"
        echo ""
        read -p "Do you want to remove these orphaned packages UwU? (y/n): " orphan_confirm
        if [[ $orphan_confirm == [yY] || $orphan_confirm == [yY][eE][sS] ]]; then
            sudo pacman -Rns $ORPHANS --noconfirm
        else
            echo "Skipping removal of orphaned packages~"
            echo "----------------------------"
            echo ""
        fi
    else
        echo "No orphaned packages found~"
        echo ""
        echo "############################"
        echo ""
        echo ""
    fi



    read -p "Do you want to remove da Spotify cache UwU? (y/n): " app_cache_confirm
        if [[ $app_cache_confirm == [yY] || $app_cache_confirm == [yY][eE][sS] ]]; then
            # 4. Clear App Caches
            echo "Clearing Spotify caches..."
            rm -rf ~/.cache/spotify/*
            # rm -rf ~/.cache/BraveSoftware
            # rm -rf ~/.cache/mozilla/firefox/*.default-release/cache2/*

            echo ""
            echo ""
            echo "%%%%%%%%%%%%%%%%%%%%%%%%%%%%%"
            echo "--- Cleanup Complete! ---"
        else
            echo "Skipping removal of app caches~"
            echo "----------------------------"
            echo ""
        fi

    # Capture AFTER sizes (always do this after cleanup operations)
    AFTER_USER=$(du -s ~/.cache 2>/dev/null | awk '{print $1}')
    AFTER_PAC=$(du -s /var/cache/pacman/pkg 2>/dev/null | awk '{print $1}')

    # Ensure variables have numeric values (default to 0 if empty)
    BEFORE_USER=${BEFORE_USER:-0}
    BEFORE_PAC=${BEFORE_PAC:-0}
    AFTER_USER=${AFTER_USER:-0}
    AFTER_PAC=${AFTER_PAC:-0}

    # Calculate total space saved
    TOTAL_KB=$(( BEFORE_USER - AFTER_USER + BEFORE_PAC - AFTER_PAC ))

    # Logic to switch between MB and GB
    if [ "${TOTAL_KB:-0}" -gt 1048576 ]; then
        # If over 1GB, show GB
        RESULT=$(echo "scale=2; $TOTAL_KB / 1024 / 1024" | bc)
        echo "You just saved approximately ${RESULT}GB! happy computing~."
    else
        # Show MB
        RESULT=$(( TOTAL_KB / 1024 ))
        echo "You just saved approximately ${RESULT}MB! happy computing~"
    fi
else
    echo "Cleanup cancelled~"
fi