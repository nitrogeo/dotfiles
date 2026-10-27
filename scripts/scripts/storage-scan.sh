#!/usr/bin/env bash
# ============================================================================
#  storage-scan.sh — READ-ONLY storage scanner
# ----------------------------------------------------------------------------
#  Successor to ~/scripts/storage-report.sh (ChatGPT).
#  - Never deletes or modifies anything.
#  - Sorts largest -> smallest.
#  - Hides entries smaller than --min-size (default 50M).
#  - Covers everything the old scanner did, plus the paths that actually
#    bloated this machine (Zen/Helium/Chrome, Zed, Codex, Steam, Bottles,
#    Slack/Discord, Codex, Go/Rust/Cargo, Trash, etc).
#  - Writes a plain-text report under reports/ unless --no-report.
#
#  Usage:
#    ./storage-scan.sh                     # user-space scan, no sudo
#    ./storage-scan.sh --system            # + /var /opt /usr journal lsof
#    ./storage-scan.sh --min-size 100 --top 20
#    ./storage-scan.sh --quick             # skip the slow find/deep scans
#    ./storage-scan.sh --no-report
#
#  Exit: 0 always unless bad arguments.
# ============================================================================
set -uo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
DEFAULT_PROJECT_DIR="$HOME/Documents/(01)-dev-git/@projects/storage-management-megafix"
PROJECT_DIR="${STORAGE_MEGAFIX_DIR:-$DEFAULT_PROJECT_DIR}"
# If the project dir is missing, fall back to the script-relative layout
# (useful while the scripts still live inside the project).
if [[ ! -d "$PROJECT_DIR/config" ]]; then
  candidate="$(cd -- "$SCRIPT_DIR/.." && pwd)"
  [[ -d "$candidate/config" ]] && PROJECT_DIR="$candidate"
fi

MIN_SIZE_MB=50
TOP_N=15
SYSTEM=0
QUICK=0
REPORT=1
REPORT_DIR="$PROJECT_DIR/reports"

usage() {
  sed -n '2,25p' "$0" | sed 's/^# \{0,1\}//'
  cat <<'EOF'

Options:
  --system            Also scan /var /opt /usr, journal, pacman, lsof (asks sudo)
  --min-size MB       Hide anything smaller than MB (default: 50)
  --top N             Show at most N entries per section (default: 15)
  --quick             Skip slow large-file scan + deep system scans
  --report-dir DIR     Where to write reports (default: <project>/reports)
  --no-report         Do not write a report file
  -h, --help          This help

Environment:
  STORAGE_MEGAFIX_DIR  Project dir for config/reports/logs
                       (default: ~/Documents/(01)-dev-git/@projects/storage-management-megafix)
EOF
}

die() { printf 'ERROR: %s\n' "$*" >&2; exit 2; }
is_uint() { [[ "$1" =~ ^[0-9]+$ ]]; }

while (( $# )); do
  case "$1" in
    --system)       SYSTEM=1 ;;
    --quick)        QUICK=1 ;;
    --no-report)    REPORT=0 ;;
    --min-size)     [[ $# -ge 2 ]] || die "--min-size needs a value"
                    is_uint "$2" || die "--min-size must be a number (MB)"
                    MIN_SIZE_MB="$2"; shift ;;
    --top)          [[ $# -ge 2 ]] || die "--top needs a value"
                    is_uint "$2" || die "--top must be a number"
                    TOP_N="$2"; shift ;;
    --report-dir)   [[ $# -ge 2 ]] || die "--report-dir needs a value"
                    REPORT_DIR="$2"; shift ;;
    -h|--help)      usage; exit 0 ;;
    *)              die "unknown option: $1 (try --help)" ;;
  esac
  shift
done

MIN_BYTES=$(( MIN_SIZE_MB * 1024 * 1024 ))
[[ "$MIN_BYTES" -gt 0 ]] || MIN_BYTES=1

# ---------------------------------------------------------------------------
# Output / formatting
# ---------------------------------------------------------------------------
if [[ -t 1 ]]; then
  BOLD=$'\033[1m'; DIM=$'\033[2m'; CYAN=$'\033[36m'; YEL=$'\033[33m'
  RED=$'\033[31m'; GRN=$'\033[32m'; RST=$'\033[0m'
else
  BOLD=''; DIM=''; CYAN=''; YEL=''; RED=''; GRN=''; RST=''
fi

if (( REPORT )); then
  mkdir -p -- "$REPORT_DIR" || die "cannot create report dir: $REPORT_DIR"
  REPORT_FILE="$REPORT_DIR/scan-$(date +%F-%H%M%S).txt"
  exec > >(tee -a -- "$REPORT_FILE") 2>&1
fi

human() {
  local b="${1:-0}"
  numfmt --to=iec-i --suffix=B --format='%.1f' "$b" 2>/dev/null || printf '%sB' "$b"
}

disp_path() {
  local p="$1"
  printf '%s' "$p" | sed "s|^${HOME}|~|"
}

rule() { printf '%s\n' "${DIM}────────────────────────────────────────────────────────────────────────${RST}"; }

section() {
  printf '\n%s\n' "${BOLD}${CYAN}== $* ==${RST}"
}

note() { printf '  %s\n' "${DIM}$*${RST}"; }

warn() { printf '  %s\n' "${YEL}WARN: $*${RST}"; }

# `du` command used by scan_dirs. System sections temporarily swap in sudo.
DU_CMD=(du)

# ---------------------------------------------------------------------------
# Scanners
# ---------------------------------------------------------------------------
# scan_dirs LABEL PATH DEPTH [SKIP_ROOT]
scan_dirs() {
  local label="$1" path="$2" depth="${3:-1}" skip_root="${4:-1}"
  section "$label"
  if [[ ! -e "$path" ]]; then
    note "(missing) $path"
    return 0
  fi

  local tmp; tmp=$(mktemp) || return 0
  "${DU_CMD[@]}" -x -d "$depth" -B1 -- "$path" 2>/dev/null > "$tmp"

  local total
  total=$("${DU_CMD[@]}" -s -B1 -- "$path" 2>/dev/null | cut -f1)
  if [[ -n "${total:-}" ]] && (( total >= MIN_BYTES )); then
    printf '  %-12s %s %s\n' "$(human "$total")" "$(disp_path "$path")" "${DIM}(total)${RST}"
  fi

  awk -F'\t' -v root="$path" -v min="$MIN_BYTES" -v skip="$skip_root" '
    ($1 >= min) && (!(skip && $2 == root)) { print }
  ' "$tmp" |
    sort -t $'\t' -k1,1nr |
    head -n "$TOP_N" |
    while IFS=$'\t' read -r bytes p; do
      printf '  %-12s %s\n' "$(human "$bytes")" "$(disp_path "$p")"
    done

  if awk -F'\t' -v root="$path" -v min="$MIN_BYTES" -v skip="$skip_root" '
      ($1 < min) && (!(skip && $2 == root)) { found=1 } END { exit !found }
    ' "$tmp"; then
    note "(entries under ${MIN_SIZE_MB}M hidden)"
  fi
  rm -f -- "$tmp"
}

# scan_each LABEL PATH...
scan_each() {
  local label="$1"; shift
  section "$label"
  local tmp; tmp=$(mktemp) || return 0
  local p b
  for p in "$@"; do
    [[ -e "$p" ]] || continue
    b=$(du -s -B1 -- "$p" 2>/dev/null | cut -f1)
    [[ -n "${b:-}" ]] || continue
    (( b >= MIN_BYTES )) || continue
    printf '%s\t%s\n' "$b" "$p" >> "$tmp"
  done
  if [[ -s "$tmp" ]]; then
    sort -t $'\t' -k1,1nr "$tmp" | head -n "$TOP_N" |
      while IFS=$'\t' read -r b p; do
        printf '  %-12s %s\n' "$(human "$b")" "$(disp_path "$p")"
      done
  else
    note "(nothing >= ${MIN_SIZE_MB}M)"
  fi
  rm -f -- "$tmp"
}

# scan_files LABEL PATH
scan_files() {
  local label="$1" path="$2"
  section "$label"
  [[ -d "$path" ]] || { note "(missing) $path"; return 0; }
  local out; out=$(mktemp) || return 0
  find "$path" -xdev -type f -size +$((MIN_BYTES - 1))c -printf '%s\t%p\n' 2>/dev/null \
    | sort -t $'\t' -k1,1nr | head -n "$TOP_N" > "$out"
  if [[ -s "$out" ]]; then
    while IFS=$'\t' read -r b p; do
      printf '  %-12s %s\n' "$(human "$b")" "$(disp_path "$p")"
    done < "$out"
  else
    note "(no files >= ${MIN_SIZE_MB}M)"
  fi
  rm -f -- "$out"
}

# ---------------------------------------------------------------------------
# Watchlist
# ---------------------------------------------------------------------------
RECLAIMABLE=0

paths() { printf '%s\n' "$@"; }

# watch_item CLASS DESCRIPTION COMMAND...
# The command must print one path per line.
watch_item() {
  local class="$1" desc="$2"; shift 2
  local total=0 p b
  while IFS= read -r p; do
    [[ -e "$p" ]] || continue
    b=$(du -s -B1 -- "$p" 2>/dev/null | cut -f1)
    b=${b:-0}
    total=$(( total + b ))
  done < <("$@")

  (( total >= MIN_BYTES )) || return 0
  printf '%s\t%s\t%s\n' "$total" "$class" "$desc" >> "$WATCH_TMP"
  case "$class" in
    SAFE|REBUILDABLE) RECLAIMABLE=$(( RECLAIMABLE + total )) ;;
  esac
}

# ---------------------------------------------------------------------------
# Header
# ---------------------------------------------------------------------------
printf '%s\n' "${BOLD}╔══════════════════════════════════════════════════════════════════════╗${RST}"
printf '%s\n' "${BOLD}║  R2-D2 STORAGE SCAN — READ ONLY                                      ║${RST}"
printf '%s\n' "${BOLD}║  $(date '+%Y-%m-%d %H:%M:%S %Z')  •  $(hostname)${RST}"
printf '%s\n' "${BOLD}╚══════════════════════════════════════════════════════════════════════╝${RST}"
note "min size: ${MIN_SIZE_MB}M | top: ${TOP_N} | system: $([[ $SYSTEM == 1 ]] && echo yes || echo no) | quick: $([[ $QUICK == 1 ]] && echo yes || echo no)"
note "Nothing in this script deletes or modifies files."

# ---------------------------------------------------------------------------
# Filesystem
# ---------------------------------------------------------------------------
section "FILESYSTEM"
df -h / 2>/dev/null
echo
df -i / 2>/dev/null

section "LOCAL MOUNTS"
findmnt -t ext4,btrfs,xfs,f2fs,vfat,ntfs 2>/dev/null || true

# ---------------------------------------------------------------------------
# System top-level (sudo only with --system)
# ---------------------------------------------------------------------------
if (( SYSTEM )); then
  if ! sudo -v; then
    warn "sudo failed; system sections will be skipped"
    SYSTEM=0
  fi
fi

if (( SYSTEM )); then
  DU_CMD=(sudo du)
  scan_dirs "ROOT TOP-LEVEL" "/" 1
  DU_CMD=(du)
else
  section "ROOT TOP-LEVEL"
  note "(run with --system for a complete sudo scan of /)"
  du -x -d1 -B1 -- / 2>/dev/null | sort -t $'\t' -k1,1nr | head -n "$TOP_N" |
    while IFS=$'\t' read -r b p; do
      (( b >= MIN_BYTES )) || continue
      [[ "$p" == "/" ]] && continue
      printf '  %-12s %s\n' "$(human "$b")" "$p"
    done
fi

# ---------------------------------------------------------------------------
# Home
# ---------------------------------------------------------------------------
scan_dirs "HOME TOP-LEVEL" "$HOME" 1

scan_each "USER DATA DIRECTORIES" \
  "$HOME/Desktop" "$HOME/Documents" "$HOME/Downloads" "$HOME/Music" \
  "$HOME/Pictures" "$HOME/Videos" "$HOME/Applications" "$HOME/appsgit" \
  "$HOME/packettracer" "$HOME/Projects" "$HOME/scripts" "$HOME/dotfiles"

scan_dirs "~/.local" "$HOME/.local" 2
scan_dirs "~/.config" "$HOME/.config" 2
scan_dirs "~/.cache" "$HOME/.cache" 2
scan_dirs "~/.var + flatpak apps" "$HOME/.var" 2

# ---------------------------------------------------------------------------
# Browsers
# ---------------------------------------------------------------------------
scan_each "BROWSER ROOTS" \
  "$HOME/.zen" "$HOME/.config/zen" "$HOME/.cache/zen" \
  "$HOME/.config/net.imput.helium" "$HOME/.cache/net.imput.helium" \
  "$HOME/.mozilla" "$HOME/.cache/mozilla" \
  "$HOME/.config/google-chrome" "$HOME/.cache/google-chrome" \
  "$HOME/.config/chromium" "$HOME/.config/BraveSoftware" \
  "$HOME/.config/vivaldi" "$HOME/.config/microsoft-edge" \
  "$HOME/.floorp" "$HOME/.config/floorp"

if (( ! QUICK )); then
  scan_dirs "Zen profiles" "$HOME/.zen" 2
  scan_dirs "Helium profiles" "$HOME/.config/net.imput.helium" 1
  scan_dirs "Chrome profiles" "$HOME/.config/google-chrome" 1
  scan_dirs "Firefox profiles" "$HOME/.mozilla/firefox" 1
fi

# ---------------------------------------------------------------------------
# Development / toolchains
# ---------------------------------------------------------------------------
scan_each "DEVELOPMENT / TOOLCHAINS" \
  "$HOME/.nvm" "$HOME/.rustup" "$HOME/.cargo" "$HOME/go" \
  "$HOME/.vscode" "$HOME/.lmstudio" "$HOME/.codex" \
  "$HOME/.local/share/zed" "$HOME/.config/Code" "$HOME/.config/opencode" \
  "$HOME/.local/share/opencode" "$HOME/.jdks" "$HOME/.cache/yay"

if (( ! QUICK )); then
  scan_dirs "Steam" "$HOME/.local/share/Steam" 2
  scan_dirs "Bottles" "$HOME/.var/app/com.usebottles.bottles" 1
  scan_each "GAMES / APP RUNTIMES" \
    "$HOME/.local/share/lutris" "$HOME/.local/share/osu" \
    "$HOME/.var/app/com.usebottles.bottles"
fi

# ---------------------------------------------------------------------------
# Mail
# ---------------------------------------------------------------------------
scan_dirs "THUNDERBIRD" "$HOME/.thunderbird" 2

# ---------------------------------------------------------------------------
# User-content breakdowns
# ---------------------------------------------------------------------------
scan_dirs "Documents subdirectories" "$HOME/Documents" 1
scan_dirs "Pictures subdirectories" "$HOME/Pictures" 1
scan_dirs "Downloads subdirectories" "$HOME/Downloads" 1
scan_dirs "Videos subdirectories" "$HOME/Videos" 1
scan_dirs "Music subdirectories" "$HOME/Music" 1

# ---------------------------------------------------------------------------
# Large files
# ---------------------------------------------------------------------------
if (( ! QUICK )); then
  scan_files "LARGEST FILES IN HOME (>= ${MIN_SIZE_MB}M)" "$HOME"
else
  section "LARGEST FILES IN HOME"
  note "(skipped by --quick)"
fi

# ---------------------------------------------------------------------------
# System detail
# ---------------------------------------------------------------------------
if (( SYSTEM )); then
  DU_CMD=(sudo du)
  scan_dirs "/var" "/var" 2
  scan_dirs "/opt" "/opt" 2
  scan_dirs "/usr" "/usr" 1
  DU_CMD=(du)

  section "JOURNAL"
  journalctl --disk-usage 2>/dev/null || note "(journalctl unavailable)"

  section "PACMAN CACHE"
  sudo du -sh /var/cache/pacman/pkg 2>/dev/null || note "(unavailable)"

  section "FLATPAK (top by size)"
  flatpak list --columns=application,size 2>/dev/null | head -n 25 || note "(flatpak unavailable)"

  section "DELETED BUT STILL OPEN (top 25)"
  sudo lsof +L1 2>/dev/null | tail -n 25 || note "(lsof unavailable)"
else
  section "SYSTEM DETAIL"
  note "(skipped — re-run with --system for /var /opt /usr, journal, pacman, lsof)"
fi

# ---------------------------------------------------------------------------
# Bloat watchlist
# ---------------------------------------------------------------------------
section "BLOAT WATCHLIST — known to grow on this machine"
note "SAFE = cache, re-downloaded | REBUILDABLE = fetched/rebuilt | REVIEW = ask first | PROTECTED = never auto-delete"
printf '  %-12s %-12s %s\n' "SIZE" "CLASS" "WHAT"
rule
WATCH_TMP=$(mktemp) || WATCH_TMP=/dev/null

watch_item SAFE "yay build cache" \
  paths "$HOME/.cache/yay"
watch_item SAFE "Spotify cache" \
  paths "$HOME/.cache/spotify"
watch_item SAFE "VS Code cached VSIX installers" \
  paths "$HOME/.config/Code/CachedExtensionVSIXs"
watch_item SAFE "Slack caches" \
  paths "$HOME/.config/Slack/Cache" "$HOME/.config/Slack/Code Cache" \
        "$HOME/.config/Slack/GPUCache" "$HOME/.config/Slack/Service Worker/CacheStorage" \
        "$HOME/.config/Slack/logs"
watch_item SAFE "Discord caches" \
  paths "$HOME/.config/discord/Cache" "$HOME/.config/discord/Code Cache" \
        "$HOME/.config/discord/GPUCache" "$HOME/.config/discord/logs" \
        "$HOME/.config/discord/discord_asset_cache" "$HOME/.config/discord/component_crx_cache"
watch_item SAFE "Obsidian caches" \
  paths "$HOME/.config/obsidian/Cache" "$HOME/.config/obsidian/Code Cache" \
        "$HOME/.config/obsidian/GPUCache"
watch_item SAFE "Helium caches" \
  find "$HOME/.config/net.imput.helium" -type d \
       \( -name Cache -o -name 'Code Cache' -o -name GPUCache -o -name ShaderCache -o -name GrShaderCache \) \
       -prune -print 2>/dev/null
watch_item SAFE "Chrome caches" \
  find "$HOME/.config/google-chrome" -type d \
       \( -name Cache -o -name 'Code Cache' -o -name GPUCache -o -name ShaderCache -o -name GrShaderCache \) \
       -prune -print 2>/dev/null
watch_item SAFE "Firefox site Cache API" \
  find "$HOME/.mozilla" -type d -path '*/storage/*/cache' -prune -print 2>/dev/null
watch_item SAFE "Zen site Cache API" \
  find "$HOME/.zen" -type d -path '*/storage/*/cache' -prune -print 2>/dev/null
watch_item SAFE "Zen HTTP cache" \
  paths "$HOME/.cache/zen"
watch_item SAFE "Steam app/HTML cache" \
  paths "$HOME/.local/share/Steam/appcache" "$HOME/.local/share/Steam/config/htmlcache"
watch_item SAFE "Steam obsolete runtime" \
  paths "$HOME/.local/share/Steam/ubuntu12_32/steam-runtime.old"
watch_item SAFE "Trash" \
  paths "$HOME/.local/share/Trash"
watch_item SAFE "Pacman package cache" \
  paths "/var/cache/pacman/pkg"
watch_item SAFE "Pacman AUR/yay cache (root)" \
  paths "/var/cache/yay"

watch_item REBUILDABLE "Zed agent registry (old versions)" \
  paths "$HOME/.local/share/zed/external_agents/registry"
watch_item REBUILDABLE "Zed extension build cache" \
  paths "$HOME/.local/share/zed/extensions/work"
watch_item REBUILDABLE "Zed Copilot cache" \
  paths "$HOME/.local/share/zed/copilot"
watch_item REVIEW "Codex downloaded packages" \
  paths "$HOME/.codex/packages"
watch_item REBUILDABLE "Go module cache" \
  paths "$HOME/go/pkg/mod"
watch_item REBUILDABLE "Cargo registry cache" \
  paths "$HOME/.cargo/registry"
watch_item REVIEW "Rust toolchains" \
  paths "$HOME/.rustup/toolchains"
watch_item REVIEW "nvm Node versions" \
  paths "$HOME/.nvm/versions/node"

watch_item REVIEW "Downloads (review, do not auto-delete)" \
  paths "$HOME/Downloads"
watch_item REVIEW "Screenshots (archive/compress)" \
  paths "$HOME/Pictures/Screenshots"
watch_item REVIEW "Thunderbird mail store (compact)" \
  paths "$HOME/.thunderbird"
watch_item REVIEW "Steam games" \
  paths "$HOME/.local/share/Steam/steamapps/common"
watch_item REVIEW "Bottles prefixes" \
  paths "$HOME/.var/app/com.usebottles.bottles"
watch_item REVIEW "Documents" \
  paths "$HOME/Documents"

# Print the watchlist largest -> smallest.
if [[ -s "$WATCH_TMP" ]]; then
  sort -t $'\t' -k1,1nr "$WATCH_TMP" |
    while IFS=$'\t' read -r b class desc; do
      printf '  %-12s %-12s %s\n' "$(human "$b")" "$class" "$desc"
    done
fi
rm -f -- "$WATCH_TMP" 2>/dev/null || true

if (( ! QUICK )); then
  section "SUSPICIOUS / OLD BACKUP DIRS"
  find "$HOME/.mozilla" "$HOME/.zen" "$HOME/.config" -maxdepth 4 -type d \
       \( -iname '*backup*' -o -iname '*old*' -o -iname '*copy*' -o -iname '*stupid*' \) \
       -prune -print 2>/dev/null | while IFS= read -r p; do
    b=$(du -s -B1 -- "$p" 2>/dev/null | cut -f1); b=${b:-0}
    (( b >= MIN_BYTES )) || continue
    printf '%s\t%s\n' "$b" "$p"
  done | sort -t $'\t' -k1,1nr | head -n "$TOP_N" |
    while IFS=$'\t' read -r b p; do
      printf '  %-12s %s\n' "$(human "$b")" "$(disp_path "$p")"
    done
fi

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
section "SUMMARY"
home_total=$(du -s -B1 -- "$HOME" 2>/dev/null | cut -f1); home_total=${home_total:-0}
avail_kb=$(df --output=avail / | tail -1); avail_kb=${avail_kb:-0}
used_pct=$(df --output=pcent / | tail -1 | tr -d ' %')
printf '  %-24s %s\n' "Home total:" "$(human "$home_total")"
printf '  %-24s %s\n' "Root used:" "${used_pct}%"
printf '  %-24s %s\n' "Root available:" "$(human $((avail_kb * 1024)))"
printf '  %-24s %s\n' "Estimated safe reclaim:" "$(human "$RECLAIMABLE")"
note "Estimate = SAFE + REBUILDABLE watchlist items only. Close browsers before clearing browser caches."

if (( avail_kb < 10 * 1024 * 1024 )); then
  printf '  %s\n' "${RED}WARNING: less than 10G free.${RST}"
fi

if (( REPORT )); then
  printf '\nReport saved: %s\n' "$REPORT_FILE"
fi

exit 0
