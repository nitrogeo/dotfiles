#!/usr/bin/env bash
# Restrict hypr-autoscroll (middle-click autoscroll) to browser windows.
#
# hypr-autoscroll has no per-window option, so this listens on Hyprland's
# event socket and flips plugin:hypr_autoscroll:enabled when focus moves
# between a browser and anything else.
#
# Browsers: Zen, Helium, Firefox (add classes to BROWSER_RE below).

set -u

BROWSER_RE='^(zen|zen-browser|helium|helium-browser|firefox|firefox-developer-edition|firefoxdeveloperedition)$'

state=""

current_class() {
    hyprctl activewindow -j 2>/dev/null | jq -r '.class // empty'
}

want_for_class() {
    local class="${1,,}"
    if [[ "$class" =~ $BROWSER_RE ]]; then
        echo true
    else
        echo false
    fi
}

apply() {
    local want="$1"
    [[ "$want" == "$state" ]] && return
    # Only mark the state once Hyprland accepted the keyword. If the plugin is
    # not loaded yet the keyword fails and we retry on the next event.
    if hyprctl keyword plugin:hypr_autoscroll:enabled "$want" >/dev/null 2>&1; then
        state="$want"
        printf '[autoscroll-browsers] enabled=%s class=%s\n' "$want" "${2:-}" >&2
    fi
}

apply_want() {
    local class="$1"
    apply "$(want_for_class "$class")" "$class"
}

# Wait for the plugin to register its config key (hyprpm reload is async).
for _ in $(seq 1 50); do
    hyprctl getoption plugin:hypr_autoscroll:enabled >/dev/null 2>&1 && break
    sleep 0.2
done

apply_want "$(current_class)"

SOCK="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/hypr/${HYPRLAND_INSTANCE_SIGNATURE:-}/.socket2.sock"

if [[ ! -S "$SOCK" ]]; then
    inst="$(hyprctl instances -j 2>/dev/null | jq -r '.[0].instance // empty')"
    [[ -n "$inst" ]] && SOCK="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/hypr/$inst/.socket2.sock"
fi

while true; do
    if [[ ! -S "$SOCK" ]]; then
        sleep 1
        continue
    fi

    while IFS= read -r line; do
        case "$line" in
            activewindow\>\>*)
                payload="${line#activewindow>>}"
                apply_want "${payload%%,*}"
                ;;
            configreloaded\>\>*)
                # A config reload resets the keyword to the file value, so drop
                # the cached state and force a re-apply.
                state=""
                apply_want "$(current_class)"
                ;;
        esac
    done < <(socat -u UNIX-CONNECT:"$SOCK" -)

    sleep 1
done
