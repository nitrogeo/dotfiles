#!/bin/bash

# Check if a browser name was provided
if [ -z "$1" ]; then
    echo "Usage: ./set-browser.sh <browser-name>"
    echo "Example: ./set-browser.sh firefox.desktop"
    exit 1
fi

BROWSER=$1

# List of MIME types to update
MIME_TYPES=(
    "application/x-extension-html"
    "application/x-extension-htm"
    "application/x-extension-shtml"
    "application/x-extension-xhtml"
    "application/x-extension-xht"
    "text/html"
    "x-scheme-handler/http"
    "x-scheme-handler/https"
)

echo "Setting default browser to: $BROWSER"

for TYPE in "${MIME_TYPES[@]}"; do
    handlr set "$TYPE" "$BROWSER"
done

echo "Done!"