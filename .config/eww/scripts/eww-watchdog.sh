#!/usr/bin/env bash

set -u

LOCK_FILE="/tmp/eww-watchdog.lock"
LOG_FILE="$HOME/.cache/eww/watchdog.log"
BAR_WINDOW="bar_widget"
CHECK_INTERVAL=4

mkdir -p "$HOME/.cache/eww"

# Prevent multiple watchdog instances.
exec 9>"$LOCK_FILE"
if ! flock -n 9; then
    exit 0
fi

while true; do
    eww_count="$(pgrep -xc eww 2>/dev/null || echo 0)"
    if [[ "${eww_count:-0}" -gt 1 ]]; then
        pkill -x eww >/dev/null 2>&1 || true
        eww daemon >/dev/null 2>&1
        echo "$(date '+%F %T') [watchdog] deduplicated eww daemons" >> "$LOG_FILE"
        sleep 1
    fi

    if ! pgrep -x eww >/dev/null 2>&1; then
        eww daemon >/dev/null 2>&1
        echo "$(date '+%F %T') [watchdog] eww daemon restarted" >> "$LOG_FILE"
        sleep 1
    fi

    if ! eww active-windows 2>/dev/null | grep -q "^${BAR_WINDOW}:"; then
        eww open "$BAR_WINDOW" >/dev/null 2>&1
        echo "$(date '+%F %T') [watchdog] reopened ${BAR_WINDOW}" >> "$LOG_FILE"
    fi

    sleep "$CHECK_INTERVAL"
done
