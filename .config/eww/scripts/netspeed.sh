#!/bin/bash
# Script para monitorear velocidad de red (download/upload) en enp4s0
# Emite JSON continuamente via deflisten

IFACE="enp4s0"

get_speed() {
    local rx1=$(cat /sys/class/net/$IFACE/statistics/rx_bytes 2>/dev/null || echo 0)
    local tx1=$(cat /sys/class/net/$IFACE/statistics/tx_bytes 2>/dev/null || echo 0)
    sleep 1
    local rx2=$(cat /sys/class/net/$IFACE/statistics/rx_bytes 2>/dev/null || echo 0)
    local tx2=$(cat /sys/class/net/$IFACE/statistics/tx_bytes 2>/dev/null || echo 0)

    local rx_rate=$(( (rx2 - rx1) ))
    local tx_rate=$(( (tx2 - tx1) ))

    # Formatear a unidades legibles
    if [ $rx_rate -ge 1048576 ]; then
        local rx_fmt="$(awk "BEGIN{printf \"%.1f\", $rx_rate/1048576}")M/s"
    elif [ $rx_rate -ge 1024 ]; then
        local rx_fmt="$(awk "BEGIN{printf \"%.0f\", $rx_rate/1024}")K/s"
    else
        local rx_fmt="${rx_rate}B/s"
    fi

    if [ $tx_rate -ge 1048576 ]; then
        local tx_fmt="$(awk "BEGIN{printf \"%.1f\", $tx_rate/1048576}")M/s"
    elif [ $tx_rate -ge 1024 ]; then
        local tx_fmt="$(awk "BEGIN{printf \"%.0f\", $tx_rate/1024}")K/s"
    else
        local tx_fmt="${tx_rate}B/s"
    fi

    local state=$(cat /sys/class/net/$IFACE/operstate 2>/dev/null)
    local icon="󰈀"
    [ "$state" != "up" ] && icon="󰈂"

    # Obtener IP y velocidad del enlace
    local ip=$(ip -4 addr show $IFACE 2>/dev/null | grep -oP 'inet \K[\d.]+' | head -1)
    [ -z "$ip" ] && ip="N/A"
    local link_speed=$(cat /sys/class/net/$IFACE/speed 2>/dev/null || echo "0")
    [ "$link_speed" = "" ] && link_speed="0"

    echo "{\"icon\": \"$icon\", \"down\": \"$rx_fmt\", \"up\": \"$tx_fmt\", \"state\": \"$state\", \"ip\": \"$ip\", \"link\": \"${link_speed}Mbps\"}"
}

while true; do
    get_speed
done
