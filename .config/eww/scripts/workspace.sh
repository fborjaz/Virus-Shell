#!/usr/bin/env bash

set -u

LOCK_FILE="/tmp/eww-workspace.lock"
LOG_FILE="$HOME/.cache/eww/workspace.log"
EWW_BIN="/usr/bin/eww"
MAX_WS=5
INTERVAL=1

mkdir -p "$HOME/.cache/eww"

exec 9>"$LOCK_FILE"
if ! flock -n 9; then
    exit 0
fi

log() {
    echo "$(date '+%F %T') [workspace] $*" >> "$LOG_FILE"
}

for cmd in hyprctl jq "$EWW_BIN"; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        log "missing dependency: $cmd"
        exit 1
    fi
done

SOCKET_PATH="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/hypr/${HYPRLAND_INSTANCE_SIGNATURE:-}/.socket2.sock"
HAS_SOCAT=0
if command -v socat >/dev/null 2>&1; then
    HAS_SOCAT=1
fi

class_to_icon() {
    local cls
    cls="$(echo "${1:-}" | tr '[:upper:]' '[:lower:]')"
    case "$cls" in
        brave*|chromium*|google-chrome*|firefox*) echo "" ;;
        code*|vscode*|vscodium*) echo "" ;;
        kitty*|alacritty*|wezterm*|foot*) echo "" ;;
        thunar*|dolphin*|nautilus*|nemo*) echo "" ;;
        vesktop*|discord*) echo "" ;;
        spotify*) echo "" ;;
        steam*) echo "" ;;
        obs*) echo "󰐾" ;;
        *) echo "󰣆" ;;
    esac
}

build_markup() {
    local workspace_data clients_data current_workspace output i windows app_class icon ws_class
    local highest_with_apps display_max ws_id ws_windows
    declare -A ws_windows_map
    declare -A ws_class_map

    workspace_data="$(hyprctl workspaces -j 2>/dev/null || echo '[]')"
    clients_data="$(hyprctl clients -j 2>/dev/null || echo '[]')"
    current_workspace="$(hyprctl monitors -j 2>/dev/null | jq -r '[.[] | select(.focused == true) | (.activeWorkspace.id // 0)][0] // empty')"
    if [[ -z "${current_workspace:-}" || ! "$current_workspace" =~ ^[0-9]+$ ]]; then
        current_workspace="$(hyprctl activeworkspace -j 2>/dev/null | jq -r '.id // 1')"
    fi

    while IFS=$'\t' read -r ws_id ws_windows; do
        [[ -z "${ws_id:-}" ]] && continue
        [[ "$ws_id" =~ ^[0-9]+$ ]] || continue
        [[ "$ws_windows" =~ ^[0-9]+$ ]] || ws_windows=0
        ws_windows_map["$ws_id"]="$ws_windows"
    done < <(echo "$workspace_data" | jq -r '.[] | select((.id // 0) > 0) | [(.id // 0), (.windows // 0)] | @tsv')

    while IFS=$'\t' read -r ws_id app_class; do
        [[ -z "${ws_id:-}" ]] && continue
        [[ "$ws_id" =~ ^[0-9]+$ ]] || continue
        ws_class_map["$ws_id"]="$app_class"
    done < <(echo "$clients_data" | jq -r '
        [.[] | select(.mapped == true and (.workspace.id // 0) > 0) | {id: .workspace.id, class: (.class // "")}] 
        | sort_by(.id)
        | group_by(.id)
        | .[]
        | [.[0].id, .[0].class]
        | @tsv
    ')

    highest_with_apps=0
    for ws_id in "${!ws_windows_map[@]}"; do
        ws_windows="${ws_windows_map[$ws_id]}"
        if [[ "$ws_windows" =~ ^[0-9]+$ ]] && (( ws_windows > 0 )) && (( ws_id > highest_with_apps )); then
            highest_with_apps=$ws_id
        fi
    done

    if (( highest_with_apps > MAX_WS )); then
        display_max=$highest_with_apps
    else
        display_max=$MAX_WS
    fi

    output='(box :class "ws" :halign "center" :orientation "h" :spacing 8 :space-evenly "false"'
    for ((i=1; i<=display_max; i++)); do
        windows="${ws_windows_map[$i]:-0}"
        app_class="${ws_class_map[$i]:-}"

        if [[ "$current_workspace" == "$i" ]]; then
            ws_class="visiting"
        elif [[ "$windows" -gt 0 ]]; then
            ws_class="occupied"
        else
            ws_class="free"
        fi

        if [[ -n "$app_class" ]]; then
            icon="$(class_to_icon "$app_class")"
        elif [[ "$windows" -gt 0 ]]; then
            icon="󰣆"
        elif [[ "$current_workspace" == "$i" ]]; then
            icon="●"
        else
            icon="○"
        fi

        output+=" (eventbox :onclick \"hyprctl dispatch workspace $i\" :cursor \"pointer\" :class \"$ws_class\" (label :class \"ws-icon\" :text \"$icon\"))"
    done
    output+=')'

    printf '%s\n' "$output"
}

update_workspace_output() {
    local new_output
    new_output="$(build_markup)"
    if [[ "$new_output" != "$last_output" ]]; then
        if "$EWW_BIN" update workspaces-output="$new_output" >/dev/null 2>&1; then
            last_output="$new_output"
        else
            log "failed to update workspaces-output"
        fi
    fi
}

event_loop() {
    local line event_name

    while true; do
        if [[ ! -S "$SOCKET_PATH" ]]; then
            log "socket unavailable: $SOCKET_PATH"
            return 1
        fi

        log "event mode enabled"
        while IFS= read -r line; do
            event_name="${line%%>>*}"
            case "$event_name" in
                workspace|workspacev2|focusedmon|openwindow|closewindow|movewindow|activewindow|activewindowv2|createworkspace|createworkspacev2|destroyworkspace|destroyworkspacev2)
                    update_workspace_output
                    ;;
            esac
        done < <(socat -u UNIX-CONNECT:"$SOCKET_PATH" - 2>/dev/null)

        log "socket stream ended, retrying"
        sleep 1
    done
}

poll_loop() {
    log "polling mode enabled"
    while true; do
        update_workspace_output
        sleep "$INTERVAL"
    done
}

last_output=""
update_workspace_output

if [[ "$HAS_SOCAT" -eq 1 && -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]]; then
    event_loop || poll_loop
else
    poll_loop
fi
