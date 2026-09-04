#!/usr/bin/env bash

# 8.23.2026 btw

echo "========================================"
echo " R2-D2 LOCAL STORAGE REPORT"
echo " $(date)"
echo "========================================"
echo

echo "=== FILESYSTEM ==="
df -h /
echo

echo "=== LOCAL TOP-LEVEL DIRECTORIES ==="
sudo du -xhx / --max-depth=1 2>/dev/null | sort -h
echo

echo "=== HOME ==="
du -xhx "$HOME" --max-depth=1 2>/dev/null | sort -h
echo

echo "=== /var ==="
sudo du -xhx /var --max-depth=2 2>/dev/null | sort -h | tail -30
echo

echo "=== /opt ==="
sudo du -xhx /opt --max-depth=2 2>/dev/null | sort -h | tail -30
echo

echo "=== LARGE LOCAL FILES (>1G) ==="
find "$HOME" -xdev -type f -size +1G -exec ls -lh {} \; 2>/dev/null
echo

echo "=== PACMAN CACHE ==="
sudo du -sh /var/cache/pacman/pkg 2>/dev/null
echo

echo "=== JOURNAL ==="
journalctl --disk-usage 2>/dev/null
echo

echo "=== DELETED BUT STILL OPEN (top 25) ==="
sudo lsof +L1 2>/dev/null | tail -25
echo

echo "=== LOCAL MOUNTS ==="
findmnt -t ext4,btrfs,xfs,f2fs,vfat,ntfs 2>/dev/null
echo

echo "========================================"
echo " END REPORT"
echo "========================================"