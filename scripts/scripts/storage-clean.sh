#!/usr/bin/env bash
# ============================================================================
#  storage-clean.sh — auditable storage cleaner
# ----------------------------------------------------------------------------
#  Successor to ~/scripts/clean-arch.sh (Gemini). Improvements:
#    - DRY RUN BY DEFAULT; only --apply mutates anything.
#    - Explicit categories; no "clean everything" surprise.
#    - Reads config/protected-paths.txt and refuses to delete inside them.
#    - Browser caches are allowlisted subdirectories only; profile data is
#      never touched (cookies/logins/history/extensions stay).
#    - Skips browser/app caches while the app is running.
#    - Logs every removal (size + path + description) BEFORE deleting.
#    - Uses paccache instead of `rm -rf /var/cache/pacman/pkg/*`.
#    - Fixes the broken if/else from the Gemini script.
#    - Before/after df + human-readable "saved" summary.
#
#  Usage:
#    ./storage-clean.sh --list
#    ./storage-clean.sh --category caches                 # preview
#    ./storage-clean.sh --category caches --apply         # asks first
#    ./storage-clean.sh --all-safe --apply --yes          # no prompt
#    ./storage-clean.sh --category dev --apply
#    ./storage-clean.sh --category system --system --apply
#    ./storage-clean.sh --category review                 # list only
#    ./storage-clean.sh --category custom --apply         # config/custom-steps.conf
#
#  Categories:
#    caches   yay/Spotify/VS Code VSIX, Slack/Discord/Obsidian, browser caches
#    dev      Zed old agents/builds/copilot, Codex old releases, Cargo, Go
#    steam    obsolete runtime + Steam HTML/app cache (NOT games)
#    system   journal, paccache, flatpak unused (needs --system / sudo)
#    trash    empty ~/.local/share/Trash (explicit only)
#    review   list big user-data candidates; deletes NOTHING
#    custom   run audited lines from config/custom-steps.conf
#
#  Environment:
#    STORAGE_MEGAFIX_DIR  project dir for config/logs
#                         (default: ~/Documents/(01)-dev-git/@projects/storage-management-megafix)
#
#  Safety: --min-size (default 50M) skips tiny targets.
# ============================================================================
set -uo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
DEFAULT_PROJECT_DIR="$HOME/Documents/(01)-dev-git/@projects/storage-management-megafix"
PROJECT_DIR="${STORAGE_MEGAFIX_DIR:-$DEFAULT_PROJECT_DIR}"
# If the project dir is missing, fall back to the script-relative layout.
if [[ ! -d "$PROJECT_DIR/config" ]]; then
  candidate="$(cd -- "$SCRIPT_DIR/.." && pwd)"
  [[ -d "$candidate/config" ]] && PROJECT_DIR="$candidate"
fi
CONFIG_DIR="$PROJECT_DIR/config"
LOG_DIR="$PROJECT_DIR/logs"

APPLY=0
ASSUME_YES=0
SYSTEM=0
ALL_SAFE=0
MIN_SIZE_MB=50
LIST_ONLY=0
DRY_RUN=1
PLANNED_BYTES=0
ACTUAL_BYTES=0
NON_SIZE_ACTIONS=0
LOG_FILE=""
CATEGORIES=()

usage() {
  sed -n '2,40p' "$0" | sed 's/^# \{0,1\}//'
}

die() { printf 'ERROR: %s\n' "$*" >&2; exit 2; }
is_uint() { [[ "$1" =~ ^[0-9]+$ ]]; }

while (( $# )); do
  case "$1" in
    --apply)        APPLY=1 ;;
    --yes|-y)       ASSUME_YES=1 ;;
    --system)       SYSTEM=1 ;;
    --list)         LIST_ONLY=1 ;;
    --all-safe)     CATEGORIES+=(caches dev steam trash); ALL_SAFE=1 ;;
    --category)     [[ $# -ge 2 ]] || die "--category needs a value"
                    CATEGORIES+=("$2"); shift ;;
    --min-size)     [[ $# -ge 2 ]] || die "--min-size needs a value"
                    is_uint "$2" || die "--min-size must be a number (MB)"
                    MIN_SIZE_MB="$2"; shift ;;
    -h|--help)      usage; exit 0 ;;
    *)              die "unknown option: $1 (try --help)" ;;
  esac
  shift
done

MIN_BYTES=$(( MIN_SIZE_MB * 1024 * 1024 ))
(( MIN_BYTES > 0 )) || MIN_BYTES=1

# ---------------------------------------------------------------------------
# Formatting
# ---------------------------------------------------------------------------
if [[ -t 1 ]]; then
  BOLD=$'\033[1m'; DIM=$'\033[2m'; CYAN=$'\033[36m'; YEL=$'\033[33m'
  RED=$'\033[31m'; GRN=$'\033[32m'; RST=$'\033[0m'
else
  BOLD=''; DIM=''; CYAN=''; YEL=''; RED=''; GRN=''; RST=''
fi

human() {
  local b="${1:-0}"
  numfmt --to=iec-i --suffix=B --format='%.1f' "$b" 2>/dev/null || printf '%sB' "$b"
}

disp_path() { printf '%s' "$1" | sed "s|^${HOME}|~|"; }
section() { printf '\n%s\n' "${BOLD}${CYAN}== $* ==${RST}"; }
note()    { printf '  %s\n' "${DIM}$*${RST}"; }
warn()    { printf '  %s\n' "${YEL}WARN: $*${RST}"; }
rule()    { printf '%s\n' "${DIM}────────────────────────────────────────────────────────────────────────${RST}"; }

# ---------------------------------------------------------------------------
# Protected paths
# ---------------------------------------------------------------------------
PROTECTED_PATHS=()

load_protected() {
  local file="$CONFIG_DIR/protected-paths.txt" line
  [[ -f "$file" ]] || { warn "missing $file; relying on hardcoded rules"; return 0; }
  while IFS= read -r line || [[ -n "$line" ]]; do
    line="${line%%#*}"
    line="$(printf '%s' "$line" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')"
    [[ -z "$line" ]] && continue
    case "$line" in
      "~")   line="$HOME" ;;
      "~/"*) line="$HOME/${line#\~/}" ;;
    esac
    PROTECTED_PATHS+=("$(realpath -m -- "$line")")
  done < "$file"
}

# path_allowed PATH ALLOW_INSIDE_PROTECTED
path_allowed() {
  local p="$1" allow="${2:-0}" rp pp
  rp=$(realpath -m -- "$p" 2>/dev/null) || return 1
  for pp in "${PROTECTED_PATHS[@]}"; do
    if [[ "$rp" == "$pp" || "$rp" == "$pp"/* ]]; then
      (( allow )) && return 0
      return 1
    fi
  done
  return 0
}

# ---------------------------------------------------------------------------
# Deletion primitives (all no-ops during preview)
# ---------------------------------------------------------------------------
record() { printf 'REMOVE\t%s\t%s\t%s\n' "$1" "$2" "$3" >> "$LOG_FILE"; }

remove_path() {
  local class="$1" desc="$2" path="$3" allow="${4:-0}" bytes
  [[ -e "$path" ]] || return 0
  bytes=$(du -s -B1 -- "$path" 2>/dev/null | cut -f1); bytes=${bytes:-0}
  (( bytes >= MIN_BYTES )) || return 0
  if ! path_allowed "$path" "$allow"; then
    warn "protected, skipped: $(disp_path "$path")"
    return 0
  fi
  printf '  %-12s %-11s %s %s\n' "$(human "$bytes")" "[$class]" "$desc" "${DIM}$(disp_path "$path")${RST}"
  if (( DRY_RUN )); then
    PLANNED_BYTES=$(( PLANNED_BYTES + bytes ))
  else
    record "$bytes" "$path" "$desc"
    if rm -rf -- "$path" 2>/dev/null; then
      ACTUAL_BYTES=$(( ACTUAL_BYTES + bytes ))
    else
      warn "failed to remove: $(disp_path "$path")"
    fi
  fi
}

remove_contents() {
  local class="$1" desc="$2" path="$3" allow="${4:-0}" bytes
  [[ -d "$path" ]] || return 0
  bytes=$(du -s -B1 -- "$path" 2>/dev/null | cut -f1); bytes=${bytes:-0}
  (( bytes >= MIN_BYTES )) || return 0
  if ! path_allowed "$path" "$allow"; then
    warn "protected, skipped: $(disp_path "$path")"
    return 0
  fi
  printf '  %-12s %-11s %s %s\n' "$(human "$bytes")" "[$class]" "$desc" "${DIM}$(disp_path "$path")${RST}"
  if (( DRY_RUN )); then
    PLANNED_BYTES=$(( PLANNED_BYTES + bytes ))
  else
    record "$bytes" "$path" "$desc"
    if find "$path" -mindepth 1 -maxdepth 1 -exec rm -rf -- {} + 2>/dev/null; then
      ACTUAL_BYTES=$(( ACTUAL_BYTES + bytes ))
    else
      warn "failed to clear: $(disp_path "$path")"
    fi
  fi
}

is_running() { pgrep -f -- "$1" >/dev/null 2>&1; }

clean_named_caches() {
  local root="$1" desc="$2" d
  [[ -d "$root" ]] || return 0
  while IFS= read -r d; do
    remove_contents SAFE "$desc" "$d" 1
  done < <(find "$root" -type d \
      \( -name Cache -o -name 'Code Cache' -o -name GPUCache \
         -o -name ShaderCache -o -name GrShaderCache \) \
      -prune -print 2>/dev/null)
}

clean_site_caches() {
  local root="$1" desc="$2" d
  [[ -d "$root" ]] || return 0
  while IFS= read -r d; do
    remove_contents SAFE "$desc" "$d" 1
  done < <(find "$root" -type d -path '*/storage/*/cache' -prune -print 2>/dev/null)
}

# ---------------------------------------------------------------------------
# Categories
# ---------------------------------------------------------------------------
do_caches() {
  section "CACHES"
  remove_contents SAFE "yay build cache" "$HOME/.cache/yay" 0
  remove_contents SAFE "Spotify cache" "$HOME/.cache/spotify" 0
  remove_contents SAFE "VS Code cached VSIX installers" "$HOME/.config/Code/CachedExtensionVSIXs" 0
  remove_contents SAFE "Thumbnail cache (regenerates)" "$HOME/.cache/thumbnails" 0
  remove_contents SAFE "Sublime Text cache" "$HOME/.cache/sublime-text" 0

  if is_running "slack"; then
    warn "Slack is running; close it to clean Slack caches."
  else
    remove_contents SAFE "Slack Cache" "$HOME/.config/Slack/Cache" 0
    remove_contents SAFE "Slack Code Cache" "$HOME/.config/Slack/Code Cache" 0
    remove_contents SAFE "Slack GPUCache" "$HOME/.config/Slack/GPUCache" 0
    remove_contents SAFE "Slack Service Worker cache" "$HOME/.config/Slack/Service Worker/CacheStorage" 0
    remove_contents SAFE "Slack logs" "$HOME/.config/Slack/logs" 0
  fi

  if is_running "discord"; then
    warn "Discord is running; close it to clean Discord caches."
  else
    remove_contents SAFE "Discord Cache" "$HOME/.config/discord/Cache" 0
    remove_contents SAFE "Discord Code Cache" "$HOME/.config/discord/Code Cache" 0
    remove_contents SAFE "Discord GPUCache" "$HOME/.config/discord/GPUCache" 0
    remove_contents SAFE "Discord asset cache" "$HOME/.config/discord/discord_asset_cache" 0
    remove_contents SAFE "Discord logs" "$HOME/.config/discord/logs" 0
  fi

  if is_running "obsidian"; then
    warn "Obsidian is running; close it to clean Obsidian caches."
  else
    remove_contents SAFE "Obsidian Cache" "$HOME/.config/obsidian/Cache" 0
    remove_contents SAFE "Obsidian Code Cache" "$HOME/.config/obsidian/Code Cache" 0
    remove_contents SAFE "Obsidian GPUCache" "$HOME/.config/obsidian/GPUCache" 0
  fi

  if is_running "helium|net.imput.helium"; then
    warn "Helium is running; close it to clean Helium caches."
  else
    clean_named_caches "$HOME/.config/net.imput.helium" "Helium cache"
  fi

  if is_running "google-chrome|chromium"; then
    warn "Chrome/Chromium is running; close it to clean their caches."
  else
    clean_named_caches "$HOME/.config/google-chrome" "Chrome cache"
    clean_named_caches "$HOME/.config/chromium" "Chromium cache"
  fi

  if is_running "firefox"; then
    warn "Firefox is running; close it to clean Firefox site caches."
  else
    clean_site_caches "$HOME/.mozilla" "Firefox site cache"
  fi

  if is_running "zen-bin"; then
    warn "Zen is running; quit it fully to clean Zen caches."
  else
    clean_site_caches "$HOME/.zen" "Zen site cache"
    remove_contents SAFE "Zen HTTP cache" "$HOME/.cache/zen" 0
  fi
}

do_dev() {
  section "DEV / TOOLCHAIN CACHES"

  local reg="$HOME/.local/share/zed/external_agents/registry/opencode" keep d
  if [[ -d "$reg" ]]; then
    keep=$(find "$reg" -mindepth 1 -maxdepth 1 -type d -name 'v_*' -printf '%f\n' 2>/dev/null | sort -V | tail -1)
    [[ -n "$keep" ]] || return 0
    for d in "$reg"/v_*; do
      [[ -e "$d" ]] || continue
      [[ "$(basename "$d")" == "$keep" ]] && continue
      remove_path REBUILDABLE "old Zed opencode agent $(basename "$d")" "$d" 0
    done
  fi

  remove_contents REBUILDABLE "Zed extension build cache" "$HOME/.local/share/zed/extensions/work" 0
  remove_path     REBUILDABLE "Zed Copilot cache" "$HOME/.local/share/zed/copilot" 0
  remove_path     REBUILDABLE "Zed npx agent cache" "$HOME/.local/share/zed/external_agents/registry/npx" 0

  # Codex: keep the newest release in each package family.
  local rel keep_rel
  for rel in "$HOME/.codex/packages/standalone/releases" "$HOME/.codex/packages/app-server-daemon/releases"; do
    [[ -d "$rel" ]] || continue
    keep_rel=$(find "$rel" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' 2>/dev/null | sort -V | tail -1)
    [[ -n "$keep_rel" ]] || continue
    for d in "$rel"/*; do
      [[ -e "$d" ]] || continue
      [[ "$(basename "$d")" == "$keep_rel" ]] && continue
      remove_path REBUILDABLE "old Codex release $(basename "$d")" "$d" 0
    done
  done

  remove_contents REBUILDABLE "Cargo registry cache" "$HOME/.cargo/registry/cache" 0
  remove_contents REBUILDABLE "Cargo registry sources" "$HOME/.cargo/registry/src" 0

  # Go module cache. `go clean -modcache` handles read-only module files.
  if [[ -d "$HOME/go/pkg/mod" ]]; then
    local gb
    gb=$(du -s -B1 -- "$HOME/go/pkg/mod" 2>/dev/null | cut -f1); gb=${gb:-0}
    if (( gb >= MIN_BYTES )); then
      printf '  %-12s %-11s %s %s\n' "$(human "$gb")" "[REBUILDABLE]" "Go module cache" "${DIM}~/go/pkg/mod${RST}"
      if (( DRY_RUN )); then
        PLANNED_BYTES=$(( PLANNED_BYTES + gb ))
      else
        record "$gb" "$HOME/go/pkg/mod" "Go module cache"
        if command -v go >/dev/null 2>&1; then
          go clean -modcache && ACTUAL_BYTES=$(( ACTUAL_BYTES + gb ))
        else
          chmod -R u+w "$HOME/go/pkg/mod" 2>/dev/null
          rm -rf -- "$HOME/go/pkg/mod" 2>/dev/null && ACTUAL_BYTES=$(( ACTUAL_BYTES + gb ))
        fi
      fi
    fi
  fi
}

do_steam() {
  section "STEAM"
  remove_path     SAFE "Steam obsolete runtime" "$HOME/.local/share/Steam/ubuntu12_32/steam-runtime.old" 0
  remove_contents SAFE "Steam HTML cache" "$HOME/.local/share/Steam/config/htmlcache" 0
  remove_contents SAFE "Steam app cache" "$HOME/.local/share/Steam/appcache" 0
  note "Games, compatdata and workshop content are NOT touched."
}

do_system() {
  section "SYSTEM"
  if (( ! SYSTEM )); then
    warn "system category requires --system (and sudo). Skipped."
    return 0
  fi
  NON_SIZE_ACTIONS=1
  if (( ! DRY_RUN )); then
    sudo -v || { warn "sudo failed; system cleanup skipped."; return 0; }
  fi

  if (( DRY_RUN )); then
    note "would run: sudo journalctl --vacuum-size=200M"
    journalctl --disk-usage 2>/dev/null || true
  else
    sudo journalctl --vacuum-size=200M
  fi

  if command -v paccache >/dev/null 2>&1; then
    if (( DRY_RUN )); then
      note "would run: sudo paccache -r   (keeps latest versions)"
    else
      sudo paccache -r
    fi
  else
    if (( DRY_RUN )); then
      note "would run: sudo pacman -Sc --noconfirm   (paccache not installed)"
    else
      sudo pacman -Sc --noconfirm
    fi
  fi

  if (( DRY_RUN )); then
    note "would run: flatpak uninstall --unused --noninteractive"
  else
    flatpak uninstall --unused --noninteractive 2>/dev/null || true
  fi

  local orphans
  orphans=$(pacman -Qdtq 2>/dev/null || true)
  if [[ -n "$orphans" ]]; then
    section "ORPHANED PACKAGES (review only)"
    printf '%s\n' "$orphans" | sed 's/^/  /'
    note "Not auto-removed. If you want them gone: sudo pacman -Rns \$(pacman -Qdtq)"
  else
    note "No orphaned packages."
  fi
}

do_trash() {
  section "TRASH"
  remove_contents REVIEW "Trash" "$HOME/.local/share/Trash" 0
}

do_review() {
  section "REVIEW ONLY — nothing here is deleted"
  local p b
  for p in "$HOME/Downloads" "$HOME/Pictures/Screenshots" "$HOME/.thunderbird" \
           "$HOME/.rustup/toolchains" "$HOME/.var/app/com.usebottles.bottles" \
           "$HOME/.local/share/Steam/steamapps/common" "$HOME/Documents"; do
    [[ -e "$p" ]] || continue
    b=$(du -s -B1 -- "$p" 2>/dev/null | cut -f1); b=${b:-0}
    (( b >= MIN_BYTES )) || continue
    printf '  %-12s %s\n' "$(human "$b")" "$(disp_path "$p")"
  done

  section "BIG DOWNLOAD FILES (review)"
  find "$HOME/Downloads" -xdev -type f -size +$((MIN_BYTES - 1))c -printf '%s\t%p\n' 2>/dev/null |
    sort -t $'\t' -k1,1nr | head -n 20 |
    while IFS=$'\t' read -r b p; do
      printf '  %-12s %s\n' "$(human "$b")" "$(disp_path "$p")"
    done

  section "SUSPICIOUS BACKUP DIRS (review)"
  find "$HOME/.mozilla" "$HOME/.zen" "$HOME/.config" -maxdepth 4 -type d \
       \( -iname '*backup*' -o -iname '*old*' -o -iname '*copy*' -o -iname '*stupid*' \) \
       -prune -print 2>/dev/null | while IFS= read -r p; do
    b=$(du -s -B1 -- "$p" 2>/dev/null | cut -f1); b=${b:-0}
    (( b >= MIN_BYTES )) || continue
    printf '%s\t%s\n' "$b" "$p"
  done | sort -t $'\t' -k1,1nr | head -n 15 |
    while IFS=$'\t' read -r b p; do
      printf '  %-12s %s\n' "$(human "$b")" "$(disp_path "$p")"
    done

  note "Move/archive/compress these manually, or ask me to review them one by one."
}

do_custom() {
  section "CUSTOM STEPS"
  local conf="$CONFIG_DIR/custom-steps.conf" cat desc cmd
  if [[ ! -f "$conf" ]]; then
    note "No $conf"
    return 0
  fi
  note "Only lines with category 'custom' are run. Audit this file first!"
  while IFS='|' read -r cat desc cmd; do
    cat="$(printf '%s' "$cat" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')"
    [[ -z "$cat" || "$cat" == \#* ]] && continue
    [[ "$cat" == "custom" ]] || continue
    desc="$(printf '%s' "$desc" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')"
    cmd="$(printf '%s' "$cmd" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')"
    [[ -z "$cmd" ]] && continue
    NON_SIZE_ACTIONS=1
    if (( DRY_RUN )); then
      printf '  [CUSTOM] %s :: %s\n' "$desc" "$cmd"
    else
      printf '  [CUSTOM] %s\n' "$desc"
      printf 'CUSTOM\t%s\n' "$cmd" >> "$LOG_FILE"
      bash -c "$cmd"
    fi
  done < "$conf"
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
load_protected

if (( LIST_ONLY )); then
  cat <<'EOF'
Categories:
  caches   yay/Spotify/VS Code VSIX, Slack/Discord/Obsidian, browser caches
  dev      Zed old agents/builds/copilot, Codex old releases, Cargo, Go
  steam    obsolete runtime + Steam HTML/app cache (NOT games)
  system   journal, paccache, flatpak unused (needs --system / sudo)
  trash    empty ~/.local/share/Trash (explicit only)
  review   list big user-data candidates; deletes NOTHING
  custom   run audited lines from config/custom-steps.conf
EOF
  exit 0
fi

if (( ${#CATEGORIES[@]} == 0 )); then
  usage
  echo
  echo "Nothing selected. Try: $0 --list"
  exit 0
fi

if (( ALL_SAFE && SYSTEM )); then
  found_system=0
  for c in "${CATEGORIES[@]}"; do [[ "$c" == system ]] && found_system=1; done
  (( found_system )) || CATEGORIES+=(system)
fi

for c in "${CATEGORIES[@]}"; do
  case "$c" in
    caches|dev|steam|system|trash|review|custom) ;;
    *) die "unknown category: $c (try --list)" ;;
  esac
done

printf '%s\n' "${BOLD}╔══════════════════════════════════════════════════════════════════════╗${RST}"
printf '%s\n' "${BOLD}║  R2-D2 STORAGE CLEANER                                               ║${RST}"
printf '%s\n' "${BOLD}║  $(date '+%Y-%m-%d %H:%M:%S %Z')  •  $(hostname)${RST}"
printf '%s\n' "${BOLD}╚══════════════════════════════════════════════════════════════════════╝${RST}"
printf '  mode: %s | categories: %s | min: %sM\n' \
  "$([[ $APPLY == 1 ]] && echo 'PREVIEW then APPLY' || echo 'PREVIEW ONLY')" \
  "${CATEGORIES[*]}" "$MIN_SIZE_MB"
note "Protected paths: $CONFIG_DIR/protected-paths.txt"

run_categories() {
  local c
  for c in "${CATEGORIES[@]}"; do
    case "$c" in
      caches) do_caches ;;
      dev)    do_dev ;;
      steam)  do_steam ;;
      system) do_system ;;
      trash)  do_trash ;;
      review) do_review ;;
      custom) do_custom ;;
    esac
  done
}

# ---- preview pass ---------------------------------------------------------
DRY_RUN=1
PLANNED_BYTES=0
NON_SIZE_ACTIONS=0
run_categories
printf '\n'
rule
printf '  Planned reclaim: %s\n' "$(human "$PLANNED_BYTES")"
rule

if (( ! APPLY )); then
  note "Dry run only. Re-run with --apply to execute."
  exit 0
fi

if (( PLANNED_BYTES == 0 && NON_SIZE_ACTIONS == 0 )); then
  note "Nothing above the ${MIN_SIZE_MB}M threshold. Nothing to do."
  exit 0
fi

if (( ! ASSUME_YES )); then
  printf '\nProceed with the removals above? [y/N] '
  read -r answer
  [[ "$answer" =~ ^[yY] ]] || { echo "Cancelled."; exit 0; }
fi

# ---- apply pass -----------------------------------------------------------
mkdir -p -- "$LOG_DIR" || die "cannot create log dir: $LOG_DIR"
LOG_FILE="$LOG_DIR/clean-$(date +%F-%H%M%S).log"
{
  printf 'storage-clean.sh\n'
  printf 'date: %s\n' "$(date '+%F %T %Z')"
  printf 'categories: %s\n' "${CATEGORIES[*]}"
  printf 'min-size: %sM\n' "$MIN_SIZE_MB"
  printf '%s\n' '--- removals ---'
} >> "$LOG_FILE"

BEFORE_KB=$(df --output=avail / | tail -1); BEFORE_KB=${BEFORE_KB:-0}
DRY_RUN=0
ACTUAL_BYTES=0
printf '\n%s\n' "${BOLD}Applying...${RST}"
run_categories
AFTER_KB=$(df --output=avail / | tail -1); AFTER_KB=${AFTER_KB:-0}
GAINED_KB=$(( AFTER_KB - BEFORE_KB ))

printf '\n'
rule
printf '  %-22s %s\n' "Removed (estimated):" "$(human "$ACTUAL_BYTES")"
printf '  %-22s %s\n' "Disk gained:" "$(human $(( GAINED_KB * 1024 )))"
printf '  %-22s %s\n' "Free now:" "$(human $(( AFTER_KB * 1024 )))"
printf '  %-22s %s\n' "Log:" "$(disp_path "$LOG_FILE")"
rule
df -h / | tail -1
