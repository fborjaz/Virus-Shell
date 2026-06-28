#!/usr/bin/env bash

set -u

DIR="$HOME/Pictures/Wallpaper"
ARCHIVO_GUARDADO="$HOME/.config/hypr/fondo_actual"
HYPRPAPER_CFG="$HOME/.config/hypr/hyprpaper.conf"
LOG_FILE="$HOME/.cache/hypr/wallpaper.log"

mkdir -p "$HOME/.cache/hypr"

log() {
    echo "$(date '+%F %T') [select_wallpaper] $*" >> "$LOG_FILE"
}

for cmd in find sort rofi ln pkill nohup hyprpaper; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        log "missing dependency: $cmd"
        exit 1
    fi
done

if [[ ! -d "$DIR" ]]; then
    log "wallpaper directory not found: $DIR"
    exit 1
fi

SELECCION=$(find "$DIR" -maxdepth 1 -type f \( -iname "*.png" -o -iname "*.jpg" -o -iname "*.jpeg" \) -printf "%f\n" | sort | rofi -dmenu -i -p "🖼️ Seleccionar Fondo:")

if [[ -z "$SELECCION" ]]; then
    log "selection canceled"
    exit 0
fi

WALL="$DIR/$SELECCION"
if [[ ! -f "$WALL" ]]; then
    log "selected file does not exist: $WALL"
    exit 1
fi

if command -v wal >/dev/null 2>&1; then
    wal -q -i "$WALL" -n || log "wal failed for: $WALL"
else
    log "wal not installed; skipping palette generation"
fi

if ! ln -sfn "$WALL" "$ARCHIVO_GUARDADO"; then
    log "failed to update symlink: $ARCHIVO_GUARDADO"
    exit 1
fi

pkill -x hyprpaper 2>/dev/null || true
nohup hyprpaper -c "$HYPRPAPER_CFG" >/tmp/hyprpaper.log 2>&1 &
log "applied wallpaper: $WALL"