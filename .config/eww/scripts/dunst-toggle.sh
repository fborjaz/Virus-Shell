#!/usr/bin/env bash

set -u

if ! command -v dunstctl >/dev/null 2>&1; then
    exit 0
fi

current="$(dunstctl is-paused 2>/dev/null || echo false)"

if [[ "$current" == "true" ]]; then
    dunstctl set-paused false >/dev/null 2>&1
else
    dunstctl set-paused true >/dev/null 2>&1
fi
