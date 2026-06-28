#!/bin/bash
# Script para listar salidas de audio disponibles (sinks de PulseAudio/PipeWire)
# Devuelve JSON array con nombre, descripción y si es la activa

get_sinks() {
    local default_sink=$(pactl get-default-sink)
    local sinks="["
    local first=true

    while IFS=$'\t' read -r name desc; do
        [ -z "$name" ] && continue
        local active="false"
        [ "$name" = "$default_sink" ] && active="true"
        
        # Limpiar descripción
        desc=$(echo "$desc" | sed 's/"/\\"/g')
        
        if [ "$first" = true ]; then
            first=false
        else
            sinks+=","
        fi
        sinks+="{\"name\": \"$name\", \"desc\": \"$desc\", \"active\": $active}"
    done < <(pactl list sinks short 2>/dev/null | while read -r idx name driver fmt ch; do
        desc=$(pactl list sinks 2>/dev/null | grep -A1 "Name: $name" | grep "Description:" | sed 's/.*Description: //')
        printf '%s\t%s\n' "$name" "$desc"
    done)

    sinks+="]"
    echo "$sinks"
}

get_sinks
