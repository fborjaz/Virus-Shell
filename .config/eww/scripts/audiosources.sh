#!/bin/bash
# Script para listar entradas de audio disponibles (sources/microfonos de PipeWire/PulseAudio)
# Devuelve JSON array con nombre, descripción y si es la activa

get_sources() {
    local default_source=$(pactl get-default-source)
    local sources="["
    local first=true

    while IFS=$'\t' read -r name desc; do
        [ -z "$name" ] && continue
        # Saltar monitors (son capturas internas, no micrófonos)
        echo "$name" | grep -q "\.monitor$" && continue
        local active="false"
        [ "$name" = "$default_source" ] && active="true"
        
        # Limpiar descripción
        desc=$(echo "$desc" | sed 's/"/\\"/g')
        
        if [ "$first" = true ]; then
            first=false
        else
            sources+=","
        fi
        sources+="{\"name\": \"$name\", \"desc\": \"$desc\", \"active\": $active}"
    done < <(pactl list sources short 2>/dev/null | while read -r idx name driver fmt ch; do
        desc=$(pactl list sources 2>/dev/null | grep -A1 "Name: $name" | grep "Description:" | sed 's/.*Description: //')
        printf '%s\t%s\n' "$name" "$desc"
    done)

    sources+="]"
    echo "$sources"
}

get_sources
