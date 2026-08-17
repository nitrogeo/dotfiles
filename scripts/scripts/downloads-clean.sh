#!/bin/bash

# updated 8.14.2026

# Define paths
DOWNLOADS="$HOME/Downloads"
IMAGE_DIR="$HOME/Pictures/@downloads-images"
DOC_DIR="$HOME/Documents/@downloads-docs"
VID_DIR="$HOME/Documents/@downloads-videos"

# Create target directories if they don't exist
mkdir -p "$IMAGE_DIR"
mkdir -p "$DOC_DIR"
mkdir -p "$VID_DIR"

# Move Images and Videos (older than 2 days)
# Extensions: jpg, jpeg, png, gif, webp, svg, mp4, mkv, mov, avi
# avif, heic added 8.14.2026
find "$DOWNLOADS" -maxdepth 1 -type f -mtime +1 -regextype posix-extended \
    -iregex ".*\.(jpg|jpeg|png|gif|webp|svg|mp4|mkv|mov|avi|avif|heic)" \
    -exec mv -t "$IMAGE_DIR" {} +

# Move Documents (older than 2 days)
# Extensions: pdf, docx, doc, xlsx, xls, pptx, txt, csv
find "$DOWNLOADS" -maxdepth 1 -type f -mtime +1 -regextype posix-extended \
    -iregex ".*\.(pdf|docx|doc|xlsx|xls|pptx|txt|csv)" \
    -exec mv -t "$DOC_DIR" {} +

# Move Videos (older than 2 days) // added 8.14.2026
# Extensions: mp4, mkv, mov, avi, webm
find "$DOWNLOADS" -maxdepth 1 -type f -mtime +1 -regextype posix-extended \
    -iregex ".*\.(mp4|mkv|mov|avi|webm)" \
    -exec mv -t "$VID_DIR" {} +


echo "Downloads organized! Files from the last 48 hours were left alone. Leftovers remain in $DOWNLOADS."
