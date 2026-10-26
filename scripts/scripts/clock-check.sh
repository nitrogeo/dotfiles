#!/bin/bash
# Improved clock-check.sh using Gum (charmbracelet/gum) for interactive TUI.
# Keeps Bash, no GTK/Zenity/Electron/QML. Keeps existing date/hwclock behavior.

set -uo pipefail
# Do NOT add `set -e` blindly — Gum cancellation (exit 130/1) is expected.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DRY_RUN=0

# ------------------------------------------------------------------
# Dependency check
# ------------------------------------------------------------------
check_deps() {
    local missing=()
    if ! command -v gum >/dev/null 2>&1; then
        missing+=("gum (install: pacman -S gum  or  brew install gum)")
    fi
    if ! command -v date >/dev/null 2>&1; then
        missing+=("date (GNU coreutils)")
    fi
    if ! command -v hwclock >/dev/null 2>&1; then
        missing+=("hwclock (util-linux)")
    fi
    if ! command -v sudo >/dev/null 2>&1; then
        missing+=("sudo")
    fi
    if [[ ${#missing[@]} -gt 0 ]]; then
        echo "Missing dependencies:"
        for m in "${missing[@]}"; do echo "  - $m"; done
        echo ""
        echo "Please install them before running this script. No packages will be installed automatically."
        exit 1
    fi
}

# ------------------------------------------------------------------
# Show current time / timezone cleanly
# ------------------------------------------------------------------
show_current() {
    echo "Current system time:  $(date '+%A, %B %d, %Y  %I:%M %p %Z')"
    echo "Timezone: $(date '+%Z')  (UTC offset: $(date '+%z'))"
}

# ------------------------------------------------------------------
# Main menu
# ------------------------------------------------------------------
main_menu() {
    local header_box
    header_box=$(gum style --foreground 226 --border-foreground 212 --border double \
        --background 55 --align center --width 55 --padding "1 3" \
        '  SYSTEM CLOCK FIX  ' '  (Gum TUI)  ')
    echo "$header_box"
    echo ""
    show_current
    echo ""

    local choice
    choice=$(gum choose --header "Select an action:" \
        --cursor "> " --cursor-prefix "  " \
        --unselected-prefix "  " --selected-prefix "  > " \
        --height 5 \
        "Set clock manually" "Test / preview only" "Exit")

    local status=$?
    if [[ $status -ne 0 ]]; then
        # 130 = Ctrl+C (SIGINT), 1 = abort (Escape/etc for gum choose)
        echo ""
        echo "Cancelled. Exiting."
        exit 0
    fi

    case "$choice" in
        "Set clock manually")
            if [[ $DRY_RUN -eq 1 ]]; then
                echo "[DRY-RUN] Manual set mode selected. No writes will occur."
            fi
            manual_set_flow
            ;;
        "Test / preview only")
            dry_run_flow
            ;;
        "Exit")
            echo "Exiting."
            exit 0
            ;;
        *)
            echo "Unexpected selection. Exiting."
            exit 1
            ;;
    esac
}

# ------------------------------------------------------------------
# Helper: trim whitespace
# ------------------------------------------------------------------
trim() {
    local var="$1"
    var="${var#"${var%%[![:space:]]*}"}"
    var="${var%"${var##*[![:space:]]}"}"
    printf '%s' "$var"
}

# ------------------------------------------------------------------
# Manual entry flow (prefilled defaults)
# ------------------------------------------------------------------
manual_set_flow() {
    # Prefill with current system values
    local cur_year cur_month cur_day cur_hour cur_min cur_ampm
    cur_year=$(date '+%Y')
    cur_month=$(date '+%-m')  # no leading zero; we'll allow either
    cur_day=$(date '+%-d')
    cur_hour=$(date '+%-I')   # 12-hour, no leading zero
    cur_min=$(date '+%-M')
    cur_ampm=$(date '+%p')

    echo ""
    echo "=== CURRENT TIME: $(date '+%A %B %d %Y %I:%M:%S %p %Z') ==="
    echo "--- Manual Clock Entry ---"
    echo "Each field shows its CURRENT value. Edit only what needs changing."
    echo "Leave blank (press Enter) to keep the current value."
    echo ""

    # Month (with colored heading)
    local month_input
    echo "$(gum style --foreground 212 --bold '[MONTH]' --padding "0 1") — Month (1-12, e.g. 10 = October) | $(gum style --foreground 226 --bold "Current: $cur_month")"
    month_input=$(gum input --placeholder "Enter month number (or blank to keep $cur_month)" --value "$cur_month" --width 30)
    local status=$?
    if [[ $status -ne 0 ]]; then echo "Input cancelled."; return 1; fi
    month_input=$(trim "$month_input")
    [[ -z "$month_input" ]] && month_input="$cur_month"

    # Day (with colored heading)
    echo "$(gum style --foreground 63 --bold '[DAY]' --padding "0 1") — Day of month (1-31, e.g. 25 = the 25th) | $(gum style --foreground 226 --bold "Current: $cur_day")"
    local day_input
    day_input=$(gum input --placeholder "Enter day (or blank to keep $cur_day)" --value "$cur_day" --width 30)
    status=$?
    if [[ $status -ne 0 ]]; then echo "Input cancelled."; return 1; fi
    day_input=$(trim "$day_input")
    [[ -z "$day_input" ]] && day_input="$cur_day"

    # Year (with colored heading)
    echo "$(gum style --foreground 45 --bold '[YEAR]' --padding "0 1") — 4-digit year (e.g. 2026) | $(gum style --foreground 226 --bold "Current: $cur_year")"
    local year_input
    year_input=$(gum input --placeholder "Enter year (or blank to keep $cur_year)" --value "$cur_year" --width 30)
    status=$?
    if [[ $status -ne 0 ]]; then echo "Input cancelled."; return 1; fi
    year_input=$(trim "$year_input")
    [[ -z "$year_input" ]] && year_input="$cur_year"

    # Hour (with colored heading)
    echo "$(gum style --foreground 226 --bold '[HOUR]' --padding "0 1") — Hour (1-12, e.g. 3 = 3:00) | $(gum style --foreground 212 --bold "Current: $cur_hour")"
    local hour_input
    hour_input=$(gum input --placeholder "Enter hour 1-12 (or blank to keep $cur_hour)" --value "$cur_hour" --width 30)
    status=$?
    if [[ $status -ne 0 ]]; then echo "Input cancelled."; return 1; fi
    hour_input=$(trim "$hour_input")
    [[ -z "$hour_input" ]] && hour_input="$cur_hour"

    # Minute (with colored heading)
    echo "$(gum style --foreground 63 --bold '[MINUTE]' --padding "0 1") — Minute (0-59, e.g. 05 = 5 min past) | $(gum style --foreground 226 --bold "Current: $cur_min")"
    local minute_input
    minute_input=$(gum input --placeholder "Enter minute 0-59 (or blank to keep $cur_min)" --value "$cur_min" --width 30)
    status=$?
    if [[ $status -ne 0 ]]; then echo "Input cancelled."; return 1; fi
    minute_input=$(trim "$minute_input")
    [[ -z "$minute_input" ]] && minute_input="$cur_min"

    # Seconds (optional) — with skip button
    local cur_sec
    cur_sec=$(date '+%S')
    echo "$(gum style --foreground 212 --bold '[SECONDS]' --padding "0 1") — Optional second (0-59) | $(gum style --foreground 226 --bold "Current: $cur_sec")"
    local sec_choice
    sec_choice=$(gum choose --header "Enter second or skip?" --cursor "> " \
        --unselected-prefix "  " --selected-prefix "  > " --height 4 \
        "Enter value" "Skip — set to 00")
    local sec_status=$?
    if [[ $sec_status -ne 0 ]]; then echo "Seconds skipped/cancelled."; return 1; fi

    local second_input
    if [[ "$sec_choice" == "Skip — set to 00" ]]; then
        second_input="00"
    else
        second_input=$(gum input --placeholder "Enter second 0-59 (blank = 00)" --value "$cur_sec" --width 30)
        status=$?
        if [[ $status -ne 0 ]]; then echo "Seconds input cancelled."; return 1; fi
        second_input=$(trim "$second_input")
        [[ -z "$second_input" ]] && second_input="00"
    fi

    # AM/PM (with heading and current)
    echo "$(gum style --foreground 63 --bold '[AM/PM]' --padding "0 1") — AM or PM | $(gum style --foreground 226 --bold "Current: $cur_ampm")"
    local ampm_input
    local default_ampm_idx=0
    if [[ "${cur_ampm^^}" == "PM" ]]; then default_ampm_idx=1; fi
    # gum choose doesn't support default selection easily; we'll build a simple menu.
    ampm_input=$(gum choose --header "AM or PM?" --cursor "> " \
        --unselected-prefix "  " --selected-prefix "  > " --height 4 \
        "AM" "PM")
    status=$?
    if [[ $status -ne 0 ]]; then echo "AM/PM selection cancelled."; return 1; fi

    # Normalize and validate
    local norm_ampm
    if [[ "$ampm_input" == "AM" ]]; then norm_ampm="AM"; else norm_ampm="PM"; fi

    # Validate complete date/time
    if ! validate_complete "$month_input" "$day_input" "$year_input" "$hour_input" "$minute_input" "$norm_ampm"; then
        echo ""
        echo "Validation failed. Let's try again from the beginning."
        echo ""
        # Restart this flow (not the whole questionnaire from scratch, but re-enter)
        # Per user instruction: "Keep valid previous answers when correcting an invalid field."
        # For simplicity with Gum input flow, we restart the manual flow but keep defaults.
        # A full per-field retry loop could be added; for maintainability we keep it simple here.
        manual_set_flow_retry "$month_input" "$day_input" "$year_input" "$hour_input" "$minute_input" "$norm_ampm"
        return 0
    fi

    # Build canonical representation (12-hour internal for display; 24-hour for GNU date)
    # We'll store 24-hour equivalent for validation and command use.
    local hour_24=$hour_input
    if [[ "$norm_ampm" == "PM" && "$hour_24" != "12" ]]; then
        hour_24=$((10#$hour_24 + 12))
    elif [[ "$norm_ampm" == "AM" && "$hour_24" == "12" ]]; then
        hour_24=0
    fi
    # Pad
    local hour_24_padded
    printf -v hour_24_padded "%02d" "$hour_24"
    local minute_padded
    printf -v minute_padded "%02d" "$minute_input"
    local month_padded
    printf -v month_padded "%02d" "$month_input"
    local day_padded
    printf -v day_padded "%02d" "$day_input"

    # Seconds: optional, 0-59 (blank = 00; validated separately)
    local sec_padded="00"
    if [[ -n "$second_input" && "$second_input" != "00" ]]; then
        if ! [[ "$second_input" =~ ^[0-9]+$ ]]; then
            echo "Error: Seconds must be 0-59 if provided, got: $second_input"
            return 1
        fi
        local sec_num=$((10#$second_input))
        if [[ $sec_num -lt 0 || $sec_num -gt 59 ]]; then
            echo "Error: Seconds must be 0-59, got: $sec_num"
            return 1
        fi
        printf -v sec_padded "%02d" "$sec_num"
    else
        sec_padded="00"
    fi

    # Canonical internal format for GNU date: YYYY-MM-DD HH:MM:SS (using sec_padded)
    local date_string_24h="${year_input}-${month_padded}-${day_padded} ${hour_24_padded}:${minute_padded}:${sec_padded}"

    # Confirm parsing matches intended components (defense against loose parsing)
    if ! verify_gnu_date_matches "$date_string_24h" "$month_input" "$day_input" "$year_input" "$hour_24_padded" "$minute_padded"; then
        echo ""
        echo "Internal verification failed: GNU date interpreted the input differently."
        echo "Intended: month=$month_input day=$day_input year=$year_input hour=$hour_24_padded minute=$minute_padded"
        echo ""
        manual_set_flow_retry "$month_input" "$day_input" "$year_input" "$hour_input" "$minute_input" "$norm_ampm"
        return 0
    fi

    # Preview
    preview_flow "$date_string_24h" "$norm_ampm"
}

# ------------------------------------------------------------------
# Retry flow that keeps previous answers
# ------------------------------------------------------------------
manual_set_flow_retry() {
    local prev_month="$1" prev_day="$2" prev_year="$3" prev_hour="$4" prev_min="$5" prev_ampm="$6"
    # Allow user to go back to main menu mid-edit
    local choice
    choice=$(gum choose --header "Fix invalid fields or go back?" --cursor "> " \
        --unselected-prefix "  " --selected-prefix "  > " --height 4 \
        "Continue editing" "Back to main menu")
    local status=$?
    if [[ $status -ne 0 ]]; then
        echo "Cancelled. Going back to menu..."
        main_menu
        return 0
    fi
    if [[ "$choice" == "Back to main menu" ]]; then
        echo "Going back to main menu."
        main_menu
        return 0
    fi
    echo "Let's fix the invalid field(s). Previous answers kept as defaults."
    # For simplicity, call full flow with same defaults; user can correct only broken part.
    manual_set_flow_prefilled "$prev_month" "$prev_day" "$prev_year" "$prev_hour" "$prev_min" "$prev_ampm"
}

manual_set_flow_prefilled() {
    local default_month="$1" default_day="$2" default_year="$3"
    local default_hour="$4" default_min="$5" default_ampm="$6"
    # Allow user to go back mid-correction
    local back_choice
    back_choice=$(gum choose --header "Continue correcting or go back?" --cursor "> " \
        --unselected-prefix "  " --selected-prefix "  > " --height 4 \
        "Continue correcting" "Back to main menu")
    local back_status=$?
    if [[ $back_status -ne 0 ]]; then
        echo "Going back to menu..."
        main_menu
        return 0
    fi
    if [[ "$back_choice" == "Back to main menu" ]]; then
        echo "Going back to main menu."
        main_menu
        return 0
    fi

    # Re-ask each input using previous as default; user only changes what needs fixing.
    # For brevity, we reuse manual_set_flow but seed with the passed values.
    # This is a simplified retry: full flow with preserved defaults.
    echo "--- Correcting Input ---"
    echo "Previous: month=$default_month day=$default_day year=$default_year hour=$default_hour min=$default_min ampm=$default_ampm"
    echo "Edit only the fields that need fixing."
    echo ""

    local month_input day_input year_input hour_input minute_input ampm_input

    month_input=$(gum input --placeholder "Month (1-12)" --value "$default_month" --width 20)
    local status=$?
    [[ $status -ne 0 ]] && { echo "Cancelled."; return 1; }
    month_input=$(trim "$month_input")
    [[ -z "$month_input" ]] && month_input="$default_month"

    day_input=$(gum input --placeholder "Day (1-31)" --value "$default_day" --width 20)
    status=$?
    [[ $status -ne 0 ]] && { echo "Cancelled."; return 1; }
    day_input=$(trim "$day_input")
    [[ -z "$day_input" ]] && day_input="$default_day"

    year_input=$(gum input --placeholder "Year (4 digits)" --value "$default_year" --width 20)
    status=$?
    [[ $status -ne 0 ]] && { echo "Cancelled."; return 1; }
    year_input=$(trim "$year_input")
    [[ -z "$year_input" ]] && year_input="$default_year"

    hour_input=$(gum input --placeholder "Hour (1-12)" --value "$default_hour" --width 20)
    status=$?
    [[ $status -ne 0 ]] && { echo "Cancelled."; return 1; }
    hour_input=$(trim "$hour_input")
    [[ -z "$hour_input" ]] && hour_input="$default_hour"

    minute_input=$(gum input --placeholder "Minute (0-59)" --value "$default_min" --width 20)
    status=$?
    [[ $status -ne 0 ]] && { echo "Cancelled."; return 1; }
    minute_input=$(trim "$minute_input")
    [[ -z "$minute_input" ]] && minute_input="$default_min"

    ampm_input=$(gum choose --header "AM or PM?" --cursor "> " \
        "AM" "PM")
    status=$?
    [[ $status -ne 0 ]] && { echo "Cancelled."; return 1; }

    local norm_ampm="AM"
    [[ "$ampm_input" == "PM" ]] && norm_ampm="PM"

    # Validate
    if ! validate_complete "$month_input" "$day_input" "$year_input" "$hour_input" "$minute_input" "$norm_ampm"; then
        echo ""
        echo "Still invalid after correction. Let's go back to the menu."
        manual_set_flow_retry "$month_input" "$day_input" "$year_input" "$hour_input" "$minute_input" "$norm_ampm"
        return 0
    fi

    # Build and confirm same as main flow
    local hour_24=$hour_input
    if [[ "$norm_ampm" == "PM" && "$hour_24" != "12" ]]; then
        hour_24=$((10#$hour_24 + 12))
    elif [[ "$norm_ampm" == "AM" && "$hour_24" == "12" ]]; then
        hour_24=0
    fi
    local hour_24_padded minute_padded month_padded day_padded
    printf -v hour_24_padded "%02d" "$hour_24"
    printf -v minute_padded "%02d" "$minute_input"
    printf -v month_padded "%02d" "$month_input"
    printf -v day_padded "%02d" "$day_input"

    local date_string_24h="${year_input}-${month_padded}-${day_padded} ${hour_24_padded}:${minute_padded}:00"

    if ! verify_gnu_date_matches "$date_string_24h" "$month_input" "$day_input" "$year_input" "$hour_24_padded" "$minute_padded"; then
        echo "Verification failed again. Back to menu."
        manual_set_flow_retry "$month_input" "$day_input" "$year_input" "$hour_input" "$minute_input" "$norm_ampm"
        return 0
    fi

    preview_flow "$date_string_24h" "$norm_ampm"
}

# ------------------------------------------------------------------
# Validation logic (canonical, no eval, handles leap year)
# ------------------------------------------------------------------
validate_complete() {
    local month_raw="$1" day_raw="$2" year_raw="$3" hour_raw="$4" minute_raw="$5" ampm_raw="$6"

    # Trim whitespace
    month_raw=$(trim "$month_raw")
    day_raw=$(trim "$day_raw")
    year_raw=$(trim "$year_raw")
    hour_raw=$(trim "$hour_raw")
    minute_raw=$(trim "$minute_raw")
    ampm_raw=$(trim "$ampm_raw")

    # Numeric checks with explicit base (avoid octal trap)
    if [[ -z "$month_raw" || -z "$day_raw" || -z "$year_raw" || -z "$hour_raw" || -z "$minute_raw" || -z "$ampm_raw" ]]; then
        echo "Error: All fields are required (no empty values)."
        return 1
    fi

    # Month: 1-12
    if ! [[ "$month_raw" =~ ^[0-9]+$ ]]; then
        echo "Error: Month must be a number (1-12), got: $month_raw"
        return 1
    fi
    local m_num=$((10#$month_raw))
    if [[ $m_num -lt 1 || $m_num -gt 12 ]]; then
        echo "Error: Month must be 1-12, got: $m_num"
        return 1
    fi

    # Year: 4 digits
    if ! [[ "$year_raw" =~ ^[0-9]{4}$ ]]; then
        echo "Error: Year must be exactly 4 digits (e.g. 2026), got: $year_raw"
        return 1
    fi
    local y_num=$year_raw

    # Hour: 1-12
    if ! [[ "$hour_raw" =~ ^[0-9]+$ ]]; then
        echo "Error: Hour must be a number (1-12), got: $hour_raw"
        return 1
    fi
    local h_num=$((10#$hour_raw))
    if [[ $h_num -lt 1 || $h_num -gt 12 ]]; then
        echo "Error: Hour must be 1-12, got: $h_num"
        return 1
    fi

    # Minute: 0-59
    if ! [[ "$minute_raw" =~ ^[0-9]+$ ]]; then
        echo "Error: Minute must be a number (0-59), got: $minute_raw"
        return 1
    fi
    local min_num=$((10#$minute_raw))
    if [[ $min_num -lt 0 || $min_num -gt 59 ]]; then
        echo "Error: Minute must be 0-59, got: $min_num"
        return 1
    fi

    # AM/PM normalization (case-insensitive, aliases: a/am/p/pm)
    local ampm_upper
    ampm_upper=$(echo "$ampm_raw" | tr '[:lower:]' '[:upper:]')
    local norm_ampm=""
    case "$ampm_upper" in
        A|AM) norm_ampm="AM" ;;
        P|PM) norm_ampm="PM" ;;
        *) echo "Error: AM/PM must be AM/PM (or a/am/p/pm), got: $ampm_raw"; return 1 ;;
    esac

    # Day validation for month/year (leap year aware)
    local max_day=31
    case $m_num in
        4|6|9|11) max_day=30 ;;
        2)
            # Leap year check
            local leap=0
            if (( y_num % 4 == 0 )); then
                if (( y_num % 100 == 0 )); then
                    if (( y_num % 400 == 0 )); then leap=1; else leap=0; fi
                else
                    leap=1
                fi
            fi
            if [[ $leap -eq 1 ]]; then max_day=29; else max_day=28; fi
            ;;
    esac

    local d_num=$((10#$day_raw))
    if [[ $d_num -lt 1 || $d_num -gt $max_day ]]; then
        echo "Error: Day $d_num is invalid for month $m_num, year $y_num (max $max_day days)."
        return 1
    fi

    # 12-hour time rules: 12 AM = midnight (00:00), 12 PM = noon (12:00)
    # Our input is 1-12; we handle conversion separately in the flow, but validation confirms range.
    echo "OK"
    return 0
}

# ------------------------------------------------------------------
# Verify GNU date interprets the string back to intended components
# ------------------------------------------------------------------
verify_gnu_date_matches() {
    local date_str="$1"  # 24h string: YYYY-MM-DD HH:MM:SS
    local expected_month="$2"
    local expected_day="$3"
    local expected_year="$4"
    local expected_hour="$5"
    local expected_minute="$6"

    # Parse back with GNU date (strict)
    local parsed_year parsed_month parsed_day parsed_hour parsed_minute parsed_second
    parsed_year=$(date -d "$date_str" '+%Y' 2>/dev/null || echo "ERROR")
    if [[ "$parsed_year" == "ERROR" ]]; then
        echo "GNU date rejected the string: $date_str"
        return 1
    fi
    parsed_month=$(date -d "$date_str" '+%m')
    parsed_day=$(date -d "$date_str" '+%d')
    parsed_hour=$(date -d "$date_str" '+%H')
    parsed_minute=$(date -d "$date_str" '+%M')

    # Remove leading zeros for comparison (avoid octal)
    local pm=$((10#$parsed_month))
    local pd=$((10#$parsed_day))
    local py=$parsed_year
    local ph=$((10#$parsed_hour))
    local pmin=$((10#$parsed_minute))

    local em=$((10#$expected_month))
    local ed=$((10#$expected_day))
    local ey=$expected_year
    local eh=$((10#$expected_hour))
    local emin=$((10#$expected_minute))

    if [[ "$py" != "$ey" || "$pm" != "$em" || "$pd" != "$ed" || "$ph" != "$eh" || "$pmin" != "$emin" ]]; then
        echo "Verification mismatch: GNU date parsed $date_str as year=$py month=$pm day=$pd hour=$ph minute=$pmin"
        echo "Expected: year=$ey month=$em day=$ed hour=$eh minute=$emin"
        return 1
    fi
    return 0
}

# ------------------------------------------------------------------
# Preview flow (show weekday, date, 12-hour time, timezone, unambiguous)
# ------------------------------------------------------------------
preview_flow() {
    local date_24h="$1"
    local ampm="$2"

    # Generate a readable 12-hour preview string with weekday
    local preview_12h
    preview_12h=$(date -d "$date_24h" '+%A, %B %d, %Y  %I:%M %p %Z')

    # Colorful preview box (pipe multiline text to gum style)
    local preview_box
    preview_box=$(printf "  PREVIEW  \n  %s  \n  (Canonical: %s / %s)  \n  Seconds: 00  \n" "$preview_12h" "$date_24h" "$ampm" | gum style --foreground 226 --border-foreground 45 --border double --align center --width 60 --padding "1 3")
    echo ""
    echo "$preview_box"
    echo ""

    # Check time-sync status (inform only, never disable/change)
    if command -v timedatectl >/dev/null 2>&1; then
        local sync_status
        sync_status=$(timedatectl show --property=NTP --value 2>/dev/null || echo "unknown")
        echo "Time-sync (NTP) status: $sync_status"
    # Colorful NTP warning
    if [[ "$sync_status" == "yes" || "$sync_status" == "active" ]]; then
        local warn_box
        warn_box=$(gum style --foreground 196 --border-foreground 196 --border rounded \
            --width 60 --padding "1 2" \
            'WARNING: NTP active — manual change may be overwritten by time-sync.')
        echo "$warn_box"
    fi
    fi

    echo ""
    local action_header
    action_header=$(gum style --foreground 226 --bold 'Apply / Edit / Cancel' --width 40 --padding "0 1")
    echo "$action_header"
    echo ""
    local action
    action=$(gum choose --header "Select action (cursor arrows + Enter)" --cursor "> " \
        --unselected-prefix "  " --selected-prefix "  > " --height 4 \
        "Apply" "Edit" "Cancel")
    local status=$?
    if [[ $status -ne 0 ]]; then
        echo "Cancelled (escape/abort)."
        exit 0
    fi

    case "$action" in
        "Apply")
            apply_changes "$date_24h" "$ampm"
            ;;
        "Edit")
            # Go back to manual input to edit (keep previous values conceptually; here we restart manual flow for simplicity)
            echo "Going back to edit..."
            manual_set_flow_retry "$(date -d "$date_24h" '+%-m')" \
                "$(date -d "$date_24h" '+%-d')" \
                "$(date -d "$date_24h" '+%Y')" \
                "$(date -d "$date_24h" '+%-I')" \
                "$(date -d "$date_24h" '+%-M')" \
                "$ampm"
            ;;
        "Cancel")
            echo "Cancelled. No changes applied."
            exit 0
            ;;
        *)
            echo "Unexpected action. Exiting."
            exit 1
            ;;
    esac
}

# ------------------------------------------------------------------
# Apply changes safely (only after explicit Apply; dry-run skips)
# ------------------------------------------------------------------
apply_changes() {
    local date_24h="$1"
    local ampm_display="$2"

    if [[ $DRY_RUN -eq 1 ]]; then
        echo "[DRY-RUN] Would apply the following (no actual writes):"
        echo "  Command: sudo date -s \"$date_24h\""
        echo "  Command: sudo hwclock --systohc"
        echo "  AM/PM display: $ampm_display"
        echo "[DRY-RUN] No clock-changing operations executed."
        return 0
    fi

    echo "Applying system time..."
    echo "  sudo date -s \"$date_24h\""
    local output
    output=$(sudo date -s "$date_24h" 2>&1)
    local exit_code=$?
    if [[ $exit_code -ne 0 ]]; then
        echo ""
        echo "ERROR: Setting system clock FAILED."
        echo "Exit code: $exit_code"
        echo "Output: $output"
        echo "Hardware clock will NOT be updated (date failed)."
        echo ""
        # Show current state after failure (if date changed partially, report it)
        echo "Current system time after attempt: $(date '+%A, %B %d, %Y  %I:%M %p %Z')"
        return 1
    else
        echo "System clock set successfully."
        echo "Output: $output"
    fi

    echo ""
    echo "Synchronizing hardware clock (RTC)..."
    echo "  sudo hwclock --systohc"
    local hw_output
    hw_output=$(sudo hwclock --systohc 2>&1)
    local hw_exit=$?
    if [[ $hw_exit -ne 0 ]]; then
        echo ""
        echo "WARNING: Hardware clock update FAILED (partial success)."
        echo "System clock was set, but RTC sync did not complete."
        echo "Exit code: $hw_exit"
        echo "Output: $hw_output"
        echo ""
        echo "Current time: $(date '+%A, %B %d, %Y  %I:%M %p %Z')"
    else
        echo "Hardware clock synchronized successfully."
        echo "Output: $hw_output"
        echo ""
        echo "Updated system time: $(date '+%A, %B %d, %Y  %I:%M %p %Z')"
    fi

    echo ""
    local done_box
    done_box=$(gum style --foreground 45 --border-foreground 45 --border rounded \
        --align center --width 55 --padding "1 2" \
        '  DONE  ' '  Clock updated / previewed safely  ')
    echo "$done_box"
}

# ------------------------------------------------------------------
# Dry-run / preview-only mode
# ------------------------------------------------------------------
dry_run_flow() {
    echo ""
    echo "========================================"
    echo "         DRY-RUN MODE                 "
    echo "========================================"
    echo "No clock changes will occur."
    echo "This exercises input, validation, editing, and preview flow only."
    echo ""
    show_current
    echo ""

    # For dry-run, we simulate the manual flow but skip apply.
    DRY_RUN=1
    manual_set_flow
    DRY_RUN=0
}

# ------------------------------------------------------------------
# Command-line: --dry-run
# ------------------------------------------------------------------
if [[ "${1:-}" == "--dry-run" ]]; then
    check_deps
    dry_run_flow
    exit 0
fi

# ------------------------------------------------------------------
# Noninteractive guard
# ------------------------------------------------------------------
if [[ -t 0 && -t 1 ]]; then
    : # interactive terminal: proceed
else
    # If stdin is not a tty, gum will hang waiting for input.
    # We don't fully block all noninteractive cases (gum requires interaction),
    # but we fail clearly if stdin is redirected and user tries to pipe in nothing.
    if [[ ! -t 0 ]]; then
        echo "Error: This script requires an interactive terminal (gum TUI)."
        echo "Run with '--dry-run' for safe non-writing testing."
        exit 1
    fi
fi

# ------------------------------------------------------------------
# Main entry
# ------------------------------------------------------------------
check_deps
main_menu


