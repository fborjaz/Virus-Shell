#!/usr/bin/env bash

set -u

LOG_FILE="$HOME/.cache/eww/dunst-history.log"
EWW_BIN="/usr/bin/eww"
WINDOW_NAME="notif_history"

mkdir -p "$HOME/.cache/eww"

log() {
    echo "$(date '+%F %T') [dunst-history-toggle] $*" >> "$LOG_FILE"
}

if ! command -v "$EWW_BIN" >/dev/null 2>&1; then
    log "eww missing"
    exit 1
fi

if "$EWW_BIN" active-windows 2>/dev/null | grep -q "^${WINDOW_NAME}:"; then
    "$EWW_BIN" update notif_history_rev=false >/dev/null 2>&1 || true
    (sleep 0.28 && "$EWW_BIN" close "$WINDOW_NAME" >/dev/null 2>&1) &
    log "closed $WINDOW_NAME"
else
    "$EWW_BIN" open "$WINDOW_NAME" >/dev/null 2>&1 || log "failed to open $WINDOW_NAME"
    "$EWW_BIN" update notif_history_rev=true >/dev/null 2>&1 || true
    log "opened $WINDOW_NAME"
fi
