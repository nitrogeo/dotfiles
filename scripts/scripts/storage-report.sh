#!/usr/bin/env bash

# R2-D2 Storage Report
# Disk-usage scanner only — DOES NOT delete or modify files.

set -u

echo "========================================"
echo " R2-D2 LOCAL STORAGE REPORT"
echo " $(date)"
echo "========================================"
echo

# ------------------------------------------------------------
# SUDO
# ------------------------------------------------------------

echo "This report needs sudo to inspect system directories."
echo "If the sudo credential isn't already cached, the terminal will prompt for your user password."
sudo -v || {
    echo
    echo "ERROR: sudo authentication failed."
    exit 1
}

echo
echo "Starting storage scan..."
echo

# ------------------------------------------------------------
# FILESYSTEM
# ------------------------------------------------------------

echo "=== FILESYSTEM ==="
df -h /
echo

# ------------------------------------------------------------
# TOP-LEVEL SYSTEM DIRECTORIES
# ------------------------------------------------------------

echo "=== LOCAL TOP-LEVEL DIRECTORIES ==="
sudo du -xhx / --max-depth=1 2>/dev/null | sort -h
echo

# ------------------------------------------------------------
# HOME
# ------------------------------------------------------------

echo "=== HOME ==="
du -xhx "$HOME" --max-depth=1 2>/dev/null | sort -h
echo

# ------------------------------------------------------------
# USER DATA DIRECTORIES
# ------------------------------------------------------------

echo "=== USER DATA DIRECTORIES ==="

for dir in \
    "$HOME/Desktop" \
    "$HOME/Documents" \
    "$HOME/Downloads" \
    "$HOME/Music" \
    "$HOME/Pictures" \
    "$HOME/Videos" \
    "$HOME/Applications" \
    "$HOME/appsgit" \
    "$HOME/packettracer"
do
    if [[ -d "$dir" ]]; then
        du -shx "$dir" 2>/dev/null
    fi
done | sort -h

echo

# ------------------------------------------------------------
# LOCAL DATA
# ------------------------------------------------------------

echo "=== ~/.local ==="
du -xhx "$HOME/.local" --max-depth=2 2>/dev/null | sort -h | tail -40
echo

# ------------------------------------------------------------
# CONFIG
# ------------------------------------------------------------

echo "=== ~/.config ==="
du -xhx "$HOME/.config" --max-depth=2 2>/dev/null | sort -h | tail -40
echo

# ------------------------------------------------------------
# CACHE
# ------------------------------------------------------------

echo "=== ~/.cache ==="
du -xhx "$HOME/.cache" --max-depth=2 2>/dev/null | sort -h | tail -40
echo

# ------------------------------------------------------------
# FLATPAK / USER APP DATA
# ------------------------------------------------------------

echo "=== ~/.var ==="
du -xhx "$HOME/.var" --max-depth=2 2>/dev/null | sort -h | tail -40
echo

# ------------------------------------------------------------
# BROWSERS
# ------------------------------------------------------------

echo "=== BROWSER / WEB APP DATA ==="

for dir in \
    "$HOME/.zen" \
    "$HOME/.config/zen" \
    "$HOME/.config/net.imput.helium" \
    "$HOME/.cache/zen" \
    "$HOME/.cache/net.imput.helium" \
    "$HOME/.mozilla" \
    "$HOME/.config/chromium" \
    "$HOME/.config/google-chrome" \
    "$HOME/.config/BraveSoftware" \
    "$HOME/.config/vivaldi" \
    "$HOME/.config/microsoft-edge"
do
    if [[ -d "$dir" ]]; then
        du -shx "$dir" 2>/dev/null
    fi
done | sort -h

echo

# ------------------------------------------------------------
# DEVELOPMENT / TOOLCHAINS
# ------------------------------------------------------------

echo "=== DEVELOPMENT / TOOLCHAINS ==="

for dir in \
    "$HOME/.nvm" \
    "$HOME/.rustup" \
    "$HOME/.cargo" \
    "$HOME/go" \
    "$HOME/.vscode" \
    "$HOME/.lmstudio"
do
    if [[ -d "$dir" ]]; then
        du -shx "$dir" 2>/dev/null
    fi
done | sort -h

echo

# ------------------------------------------------------------
# /var
# ------------------------------------------------------------

echo "=== /var ==="
sudo du -xhx /var --max-depth=2 2>/dev/null | sort -h | tail -40
echo

# ------------------------------------------------------------
# /opt
# ------------------------------------------------------------

echo "=== /opt ==="
sudo du -xhx /opt --max-depth=2 2>/dev/null | sort -h | tail -40
echo

# ------------------------------------------------------------
# LARGE LOCAL FILES
# ------------------------------------------------------------

echo "=== LARGE LOCAL FILES (>1G) ==="
find "$HOME" -xdev -type f -size +1G \
    -exec ls -lh {} \; 2>/dev/null
echo

# ------------------------------------------------------------
# PACMAN CACHE
# ------------------------------------------------------------

echo "=== PACMAN CACHE ==="
sudo du -sh /var/cache/pacman/pkg 2>/dev/null
echo

# ------------------------------------------------------------
# JOURNAL
# ------------------------------------------------------------

echo "=== JOURNAL ==="
journalctl --disk-usage 2>/dev/null
echo

# ------------------------------------------------------------
# DELETED BUT STILL OPEN
# ------------------------------------------------------------

echo "=== DELETED BUT STILL OPEN (top 25) ==="
sudo lsof +L1 2>/dev/null | tail -25
echo

# ------------------------------------------------------------
# LOCAL MOUNTS
# ------------------------------------------------------------

echo "=== LOCAL MOUNTS ==="
findmnt -t ext4,btrfs,xfs,f2fs,vfat,ntfs 2>/dev/null
echo

# ------------------------------------------------------------
# END
# ------------------------------------------------------------

echo "========================================"
echo " END REPORT"
echo "========================================"

