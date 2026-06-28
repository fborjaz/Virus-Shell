#!/bin/bash

# Script para generar workspaces dinámicos estilo Monasm
print_workspaces() {
    # Obtiene el workspace activo
    active_ws=$(hyprctl activeworkspace -j | jq -r '.id')
    
    # Obtiene todos los workspaces que existen
    existing_ws=$(hyprctl workspaces -j | jq -r '.[].id' | sort -n)
    
    # Genera la estructura Yuck
    buf="(box :class 'ws-container' :orientation 'h' :spacing 8 :space-evenly false "
    
    # Iteramos del 1 al 9 (workspaces estándar)
    for i in {1..9}; do
        # Verifica si el workspace existe
        ws_exists=$(echo "$existing_ws" | grep -c "^${i}$")
        
        if [ "$i" -eq "$active_ws" ]; then
            # Workspace activo - con animación
            buf="$buf (eventbox :cursor 'pointer' :onclick 'hyprctl dispatch workspace $i' (label :class 'ws visiting' :text \"$i\"))"
        elif [ "$ws_exists" -gt 0 ]; then
            # Workspace con ventanas - visible pero no activo
            buf="$buf (eventbox :cursor 'pointer' :onclick 'hyprctl dispatch workspace $i' (label :class 'ws occupied' :text \"$i\"))"
        else
            # Workspace vacío - translúcido
            buf="$buf (eventbox :cursor 'pointer' :onclick 'hyprctl dispatch workspace $i' (label :class 'ws free' :text \"$i\"))"
        fi
    done
    
    buf="$buf)"
    echo "$buf"
}

# Ejecuta una vez al inicio
print_workspaces

# Escucha cambios en Hyprland para actualizar al instante
socat -u UNIX-CONNECT:$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock - 2>/dev/null | while read -r line; do
    print_workspaces
done