#!/usr/bin/env bash

set -euo pipefail

SCREENSHOT_DIR="$HOME/Pictures/Screenshots/hypr-screenshots"

echo "========================================"
echo " SCREENSHOT MONTH SORTER"
echo "========================================"
echo
echo "Only loose files in:"
echo "  $SCREENSHOT_DIR"
echo "will be moved."
echo
echo "Existing folders and everything inside them"
echo "will be left completely untouched."
echo

if [[ ! -d "$SCREENSHOT_DIR" ]]; then
    echo "ERROR: Screenshot directory does not exist."
    exit 1
fi

cd "$SCREENSHOT_DIR"

count=0

# IMPORTANT:
# -maxdepth 1 means we ONLY see files directly in this folder.
# Files inside existing YYYY-MM/ folders are never touched.

# Keep the current day and previous 2 days untouched.
# Only sort screenshots that are 3+ days old.
# Sort everything older than that.

cutoff_date="$(date -d '2 days ago' +%Y-%m-%d)"

while IFS= read -r -d '' file; do
    timestamp="$(stat -c %Y -- "$file")"
    file_date="$(date -d "@$timestamp" +%Y-%m-%d)"

    # Skip today, yesterday, and 2 days ago.
    if [[ "$file_date" >= "$cutoff_date" ]]; then
        continue
    fi

    month="$(date -d "@$timestamp" +%Y-%m)"

    mkdir -p -- "$month"
    mv -- "$file" "$month/"

    ((count+=1))

done < <(find . -maxdepth 1 -type f -print0)

echo
echo "========================================"

if (( count == 0 )); then
    echo "Nothing to sort."
else
    echo "Sorted $count loose screenshot(s)."
fi

echo "========================================"