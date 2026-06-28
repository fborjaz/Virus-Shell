#!/usr/bin/env bash

set -u

LOCK_FILE="/tmp/eww-getvol.lock"
LOG_FILE="$HOME/.cache/eww/getvol.log"
EWW_BIN="/usr/bin/eww"

mkdir -p "$HOME/.cache/eww"

# Avoid duplicate listeners.
exec 9>"$LOCK_FILE"
if ! flock -n 9; then
    exit 0
fi

log() {
    echo "$(date '+%F %T') [getvol] $*" >> "$LOG_FILE"
}

for cmd in pamixer pactl stdbuf grep "$EWW_BIN"; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        log "missing dependency: $cmd"
        exit 1
    fi
done

apply_volume_state() {
    local vol
    local mute

    vol="$(pamixer --get-volume 2>/dev/null || echo 0)"
    mute="$(pamixer --get-mute 2>/dev/null || echo true)"

    if [[ "$mute" == "true" ]]; then
        "$EWW_BIN" update volico="󰖁" >/dev/null 2>&1 || log "failed to update volico"
        "$EWW_BIN" update volmute="true" >/dev/null 2>&1 || log "failed to update volmute"
        vol="0"
    else
        "$EWW_BIN" update volico="󰕾" >/dev/null 2>&1 || log "failed to update volico"
        "$EWW_BIN" update volmute="false" >/dev/null 2>&1 || log "failed to update volmute"
    fi

    "$EWW_BIN" update get_vol="$vol" >/dev/null 2>&1 || log "failed to update get_vol"
}

apply_volume_state

while true; do
    pactl subscribe 2>/dev/null | stdbuf -oL grep --line-buffered "Event 'change' on sink" | while read -r _; do
        apply_volume_state
    done
    log "pactl subscribe ended, retrying"
    sleep 1
done
