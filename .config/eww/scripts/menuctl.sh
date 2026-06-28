#!/usr/bin/env bash

set -u

LOCK_FILE="/tmp/eww-menuctl.lock"
LOG_FILE="$HOME/.cache/eww/menuctl.log"
EWW_BIN="/usr/bin/eww"

mkdir -p "$HOME/.cache/eww"

exec 9>"$LOCK_FILE"
if ! flock -n 9; then
    exit 0
fi

log() {
    echo "$(date '+%F %T') [menuctl] $*" >> "$LOG_FILE"
}

if ! command -v "$EWW_BIN" >/dev/null 2>&1; then
    log "eww binary not found"
    exit 1
fi

if "$EWW_BIN" active-windows 2>/dev/null | grep -q '^menuctl:'; then
    "$EWW_BIN" update menurev=false >/dev/null 2>&1 || log "failed to set menurev=false"
    (sleep 0.2 && "$EWW_BIN" close menuctl >/dev/null 2>&1) &
    log "closing menuctl"
else
    if "$EWW_BIN" open menuctl >/dev/null 2>&1; then
        "$EWW_BIN" update menurev=true >/dev/null 2>&1 || log "failed to set menurev=true"
        log "opening menuctl"
    else
        sleep 0.3
        if "$EWW_BIN" open menuctl >/dev/null 2>&1; then
            "$EWW_BIN" update menurev=true >/dev/null 2>&1 || log "failed to set menurev=true"
            log "opening menuctl after retry"
        else
            log "failed to open menuctl"
            exit 1
        fi
    fi
fi
