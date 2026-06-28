#!/usr/bin/env bash

set -u

LOG_FILE="$HOME/.cache/eww/togglevol.log"
EWW_BIN="/usr/bin/eww"

mkdir -p "$HOME/.cache/eww"

log() {
    echo "$(date '+%F %T') [togglevol] $*" >> "$LOG_FILE"
}

for cmd in pamixer "$EWW_BIN"; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        log "missing dependency: $cmd"
        exit 1
    fi
done

if ! pamixer -t >/dev/null 2>&1; then
    log "pamixer toggle failed"
    exit 1
fi

sleep 0.1
vol="$(pamixer --get-volume 2>/dev/null || echo 0)"
mute="$(pamixer --get-mute 2>/dev/null || echo true)"

if [[ "$mute" == "true" ]]; then
    "$EWW_BIN" update volico="󰖁" volmute="true" get_vol="0" >/dev/null 2>&1 || log "failed to update muted state"
else
    "$EWW_BIN" update volico="󰕾" volmute="false" get_vol="$vol" >/dev/null 2>&1 || log "failed to update unmuted state"
fi
