#!/usr/bin/env bash

set -u

LOG_FILE="$HOME/.cache/eww/dunst-history.log"
MAX_ITEMS=20

mkdir -p "$HOME/.cache/eww"

log() {
    echo "$(date '+%F %T') [dunst-history] $*" >> "$LOG_FILE"
}

escape_text() {
    local text="$1"
    text="${text//$'\\'/\\\\}"
    text="${text//\"/\\\"}"
    text="${text//$'\n'/ }"
    text="${text//$'\r'/ }"
    printf '%s' "$text"
}

if ! command -v dunstctl >/dev/null 2>&1; then
    log "dunstctl missing"
    printf '(box :class "notif-empty" (label :text "Dunst no disponible"))'
    exit 0
fi

history_json="$(dunstctl history 2>/dev/null || true)"
if [[ -z "$history_json" ]]; then
    log "empty history payload"
    printf '(box :class "notif-empty" (label :text "Sin notificaciones"))'
    exit 0
fi

entries="$(printf '%s' "$history_json" | jq -r --argjson max "$MAX_ITEMS" '
    .data | flatten | .[:$max] | map([
        (.id.data // 0 | tostring),
        (.summary.data // ""),
        (.body.data // ""),
        (.appname.data // ""),
        (.urgency.data // "NORMAL")
    ] | @tsv) | .[]
' 2>/dev/null || true)"

if [[ -z "$entries" ]]; then
    log "no parsed entries"
    printf '(box :class "notif-empty" (label :text "Sin notificaciones"))'
    exit 0
fi

output='(box :orientation "v" :space-evenly false :spacing 8'
while IFS=$'\t' read -r id summary body app urgency; do
    [[ -z "${id:-}" ]] && continue
    summary_esc="$(escape_text "${summary:-}")"
    body_esc="$(escape_text "${body:-}")"
    app_esc="$(escape_text "${app:-}")"
    urgency_class="notif-item"
    case "${urgency:-NORMAL}" in
        CRITICAL) urgency_class="notif-item notif-critical" ;;
        LOW) urgency_class="notif-item notif-low" ;;
    esac

    output+=" (box :class \"${urgency_class}\" :orientation \"v\" :space-evenly false :spacing 4"
    output+="   (box :class \"notif-item-head\" :orientation \"h\" :space-evenly false :spacing 8"
    output+="     (label :class \"notif-item-title\" :hexpand true :xalign 0 :text \"${summary_esc:-Sin título}\")"
    output+="     (label :class \"notif-item-app\" :text \"${app_esc:-}\")"
    output+="   )"
    output+="   (label :class \"notif-item-body\" :wrap true :xalign 0 :text \"${body_esc:-}\")"
    output+=" )"
done <<< "$entries"
output+=')'

printf '%s\n' "$output"
