#!/usr/bin/env bash

set -u

LOG_FILE="$HOME/.cache/eww/dunst-history.log"

mkdir -p "$HOME/.cache/eww"

log() {
    echo "$(date '+%F %T') [dunst-history-clear] $*" >> "$LOG_FILE"
}

if ! command -v dunstctl >/dev/null 2>&1; then
    log "dunstctl missing"
    exit 1
fi

if dunstctl close-all >/dev/null 2>&1 && dunstctl history-clear >/dev/null 2>&1; then
    log "history cleared"
else
    log "failed to clear history"
    exit 1
fi
