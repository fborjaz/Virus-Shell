#!/bin/bash
# Script para monitorear el estado de Ethernet
# Devuelve JSON con icono, estado e IP

get_ethernet() {
    local iface="enp4s0"
    local state=$(cat /sys/class/net/$iface/operstate 2>/dev/null)

    if [[ "$state" == "up" ]]; then
        local ip=$(ip -4 addr show "$iface" | grep -oP 'inet \K[\d.]+' | head -1)
        local speed=$(cat /sys/class/net/$iface/speed 2>/dev/null || echo "?")
        echo "{\"icon\": \"󰈀\", \"status\": \"Connected\", \"ip\": \"${ip:-N/A}\", \"speed\": \"${speed}Mbps\"}"
    else
        echo "{\"icon\": \"󰈂\", \"status\": \"Disconnected\", \"ip\": \"N/A\", \"speed\": \"N/A\"}"
    fi
}

get_ethernet
