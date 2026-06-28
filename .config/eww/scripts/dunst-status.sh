#!/usr/bin/env bash

set -u

if ! command -v dunstctl >/dev/null 2>&1; then
    echo '{"icon":"󰂚","waiting":"0","history":"0","total":"0","paused":"false","size":"sm"}'
    exit 0
fi

paused="$(dunstctl is-paused 2>/dev/null || echo false)"
waiting="$(dunstctl count waiting 2>/dev/null || echo 0)"
history="$(dunstctl count history 2>/dev/null || echo 0)"

case "$waiting" in
    ''|*[!0-9]*) waiting="0" ;;
esac

case "$history" in
    ''|*[!0-9]*) history="0" ;;
esac

total=$((waiting + history))

if [[ "$paused" == "true" ]]; then
    icon="󰂛"
else
    icon="󰂚"
fi

if (( total <= 2 )); then
    size="sm"
elif (( total <= 6 )); then
    size="md"
elif (( total <= 10 )); then
    size="lg"
else
    size="xl"
fi

printf '{"icon":"%s","waiting":"%s","history":"%s","total":"%s","paused":"%s","size":"%s"}\n' "$icon" "$waiting" "$history" "$total" "$paused" "$size"
