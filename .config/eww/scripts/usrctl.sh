#!/usr/bin/env bash

set -u

LOCK_FILE="/tmp/eww-usrctl.lock"
LOG_FILE="$HOME/.cache/eww/usrctl.log"
EWW_BIN="/usr/bin/eww"

mkdir -p "$HOME/.cache/eww"

exec 9>"$LOCK_FILE"
if ! flock -n 9; then
    exit 0
fi

log() {
    echo "$(date '+%F %T') [usrctl] $*" >> "$LOG_FILE"
}

if ! command -v "$EWW_BIN" >/dev/null 2>&1; then
    log "eww binary not found"
    exit 1
fi

if "$EWW_BIN" active-windows 2>/dev/null | grep -q '^usrctl:'; then
    "$EWW_BIN" update ctlrev=false >/dev/null 2>&1 || log "failed to set ctlrev=false"
    (sleep 0.3 && "$EWW_BIN" close usrctl >/dev/null 2>&1) &
    log "closing usrctl"
else
    if "$EWW_BIN" open usrctl >/dev/null 2>&1; then
        "$EWW_BIN" update ctlrev=true >/dev/null 2>&1 || log "failed to set ctlrev=true"
        log "opening usrctl"
    else
        sleep 0.3
        if "$EWW_BIN" open usrctl >/dev/null 2>&1; then
            "$EWW_BIN" update ctlrev=true >/dev/null 2>&1 || log "failed to set ctlrev=true"
            log "opening usrctl after retry"
        else
            log "failed to open usrctl"
            exit 1
        fi
    fi
fi
