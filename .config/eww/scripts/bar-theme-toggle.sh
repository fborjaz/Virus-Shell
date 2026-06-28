#!/usr/bin/env bash

set -u

STATE_FILE="$HOME/.config/eww/.bar_mode"
LOG_FILE="$HOME/.cache/eww/theme.log"

mkdir -p "$HOME/.cache/eww"

log() {
    echo "$(date '+%F %T') [bar-theme] $*" >> "$LOG_FILE"
}

read_mode() {
    if [[ -f "$STATE_FILE" ]]; then
        mode="$(tr -d '[:space:]' < "$STATE_FILE")"
        if [[ "$mode" == "compact" || "$mode" == "full" ]]; then
            echo "$mode"
            return
        fi
    fi
    echo "full"
}

apply_mode() {
    local mode="$1"
    if [[ "$mode" == "compact" ]]; then
        eww update bar_full=false >/dev/null 2>&1 || true
    else
        eww update bar_full=true >/dev/null 2>&1 || true
    fi
    log "applied mode: $mode"
}

current_mode="$(read_mode)"

if [[ "${1:-}" == "--apply" ]]; then
    apply_mode "$current_mode"
    exit 0
fi

if [[ "$current_mode" == "full" ]]; then
    next_mode="compact"
else
    next_mode="full"
fi

printf '%s\n' "$next_mode" > "$STATE_FILE"
apply_mode "$next_mode"
