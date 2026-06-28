#!/bin/bash
# Script para monitorear volumen del micrófono activo

get_mic() {
    local vol=$(pamixer --default-source --get-volume 2>/dev/null || echo "0")
    local mute=$(pamixer --default-source --get-mute 2>/dev/null || echo "false")
    if [ "$mute" = "true" ]; then
        /usr/bin/eww update micico="󰍭"
        /usr/bin/eww update micmute="true"
        vol="0"
    else
        /usr/bin/eww update micico="󰍬"
        /usr/bin/eww update micmute="false"
    fi
    /usr/bin/eww update get_mic_vol="$vol"
}

# Ejecutar al inicio
get_mic

# Escuchar cambios en sources
pactl subscribe | stdbuf -oL grep --line-buffered "Event 'change' on source" | while read -r _; do
    get_mic
done
