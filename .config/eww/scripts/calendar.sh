#!/usr/bin/env bash

set -u

LOCK_FILE="/tmp/eww-calendar.lock"
LOG_FILE="$HOME/.cache/eww/calendar.log"
EWW_BIN="/usr/bin/eww"

mkdir -p "$HOME/.cache/eww"

exec 9>"$LOCK_FILE"
if ! flock -n 9; then
    exit 0
fi

log() {
    echo "$(date '+%F %T') [calendar] $*" >> "$LOG_FILE"
}

if ! command -v "$EWW_BIN" >/dev/null 2>&1; then
    log "eww binary not found"
    exit 1
fi

if "$EWW_BIN" active-windows 2>/dev/null | grep -q '^calendar:'; then
    "$EWW_BIN" update calrev=false >/dev/null 2>&1 || log "failed to set calrev=false"
    (sleep 0.2 && "$EWW_BIN" close calendar >/dev/null 2>&1) &
    log "closing calendar"
else
    if "$EWW_BIN" open calendar >/dev/null 2>&1; then
        "$EWW_BIN" update calrev=true >/dev/null 2>&1 || log "failed to set calrev=true"
        log "opening calendar"
    else
        log "failed to open calendar"
        exit 1
    fi
fi
