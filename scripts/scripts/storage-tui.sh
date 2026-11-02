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

# Grouped menu. `gum choose` only takes one --header, so the section titles are
# ordinary rows marked with ─────. Picking one just redraws the menu; it never
# becomes a --category value. Real actions are indented under their heading.
main_menu() {
  local h_review h_clean
  h_review=$(gum style --bold --foreground 99 "review  ────────────────────────────")
  h_clean=$(gum style --bold --foreground 99 "cleanup / clear  ───────────────────")

  gum choose \
    --header "What do you want to do?" \
    --cursor.foreground 212 \
    --height 12 \
    "$h_review" \
    "  (og) Review only — list, deletes nothing" \
    "  (new) Growth graph — not built yet" \
    "$h_clean" \
    "  Quick safe clean — caches + dev (recommended)" \
    "  Caches only" \
    "  Dev / toolchain only" \
    "  Steam cache only (never games)"
}

while :; do
  # gum exits non-zero on Esc/Ctrl-C, so an empty result is a cancel either way
  raw=$(main_menu) || { gum style --foreground 240 "Cancelled."; exit 0; }
  [[ -z "${raw//[[:space:]]/}" ]] && { gum style --foreground 240 "Cancelled."; exit 0; }

  # strip ANSI (headings are styled) then leading indent, so matching is plain text
  choice=$(printf '%s' "$raw" | sed 's/\x1b\[[0-9;]*[a-zA-Z]//g')
  choice="${choice#"${choice%%[![:space:]]*}"}"

  case "$choice" in
    *──*)  continue ;;                          # heading row: reopen the menu
    "(og) Review"*)        CATS=(review); break ;;
    "(new) Growth graph"*)
      gum style --foreground 240 "Growth graph is still a plan — docs/plan-self-service-cleaner.md"
      continue ;;
    "Quick safe clean"*)   CATS=(caches dev); break ;;
    "Caches only"*)        CATS=(caches); break ;;
    "Dev / toolchain"*)    CATS=(dev); break ;;
    "Steam cache only"*)   CATS=(steam); break ;;
    *) gum style --foreground 240 "Unrecognised choice — nothing done."; exit 0 ;;
  esac
done

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
