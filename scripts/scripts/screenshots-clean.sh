#!/bin/bash

# Define your directories
SOURCE_DIR="$HOME/Pictures/Screenshots/hypr-screenshots"
DEST_DIR="$HOME/Pictures/hypr-screenshots/OLD-CLEAN"

# Create destination if it doesn't exist
mkdir -p "$DEST_DIR"

# Find and move files:
# -maxdepth 1 : Stay in the top folder only
# -type f     : Only look for files (not folders)
# ! -newermt  : Not newer than (modified before) April 1st, 2026
find "$SOURCE_DIR" -maxdepth 1 -type f ! -newermt "2026-04-01" -exec mv -t "$DEST_DIR" {} +

echo "Done! Photos older than April 1st have been moved."