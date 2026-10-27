#!/usr/bin/env bash
# ============================================================================
#  storage-tui.sh — gum front-end for storage-clean.sh
# ----------------------------------------------------------------------------
#  Menu-driven wrapper. Never deletes anything itself; it calls the audited
#  ~/scripts/storage-clean.sh (preview -> confirm -> apply).
#
#  Design choices that fixed the 10.26 bugs:
#    - single-select presets instead of --no-limit multi-select
#      (space-toggle was unreliable; Enter always picks the highlight)
#    - treat an empty/whitespace choice as "cancel" (no empty --category)
#
#  Usage:  ~/scripts/storage-tui.sh
# ============================================================================
set -uo pipefail

CLEAN="${STORAGE_CLEAN:-$HOME/scripts/storage-clean.sh}"

command -v gum >/dev/null 2>&1 || { echo "gum is not installed (pacman -S gum)"; exit 1; }
[[ -x "$CLEAN" ]] || { echo "missing: $CLEAN"; exit 1; }

header() {
  local free used pct
  free=$(df -h / | awk 'NR==2{print $4}')
  used=$(df -h / | awk 'NR==2{print $3}')
  pct=$(df -h /  | awk 'NR==2{print $5}')
  gum style --border rounded --border-foreground 212 --padding "0 2" --margin "0 0 1 0" \
    "$(gum style --bold --foreground 212 'R2-D2 STORAGE TUI')" \
    "" "Disk: $used used • $free free ($pct)"
}

header

choice=$(gum choose \
  --header "What do you want to clear?" \
  --cursor.foreground 212 \
  "Quick safe clean  — caches + dev (recommended)" \
  "Caches only" \
  "Dev / toolchain only" \
  "Steam cache only (never games)" \
  "Review only (list, deletes nothing)")

# empty / Esc / Ctrl-C -> cancel cleanly
choice="${choice//[[:space:]]/}"
case "$choice" in
  "" ) gum style --foreground 240 "Cancelled."; exit 0 ;;
esac

case "$choice" in
  Quick*) CATS=(caches dev) ;;
  Caches*) CATS=(caches) ;;
  Dev*) CATS=(dev) ;;
  Steam*) CATS=(steam) ;;
  Review*) CATS=(review) ;;
  *) gum style --foreground 240 "Cancelled."; exit 0 ;;
esac

args=()
for c in "${CATS[@]}"; do args+=(--category "$c"); done

gum spin --spinner dot --title "Scanning (read-only)…" -- sleep 0.3
PREVIEW=$("$CLEAN" "${args[@]}" 2>&1)

if ! printf '%s' "$PREVIEW" | grep -q 'Planned reclaim'; then
  printf '%s\n' "$PREVIEW"
  gum style --foreground 240 "No candidates above the threshold."
  exit 0
fi

printf '%s\n' "$PREVIEW" | gum pager

if gum confirm --default=no --affirmative="Yes, apply" --negative="No, cancel" \
  "Apply this batch now?"; then
  gum spin --spinner dot --title "Applying…" -- sleep 0.3
  "$CLEAN" "${args[@]}" --apply --yes 2>&1
  gum style --border rounded --border-foreground 82 --padding "0 2" --margin "1 0 0 0" \
    "$(gum style --bold --foreground 82 'Done.')  Free now: $(df -h / | awk 'NR==2{print $4}')"
else
  gum style --foreground 240 "Cancelled — nothing deleted."
fi
