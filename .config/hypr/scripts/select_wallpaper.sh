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

for cmd in find sort rofi swww; do
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

ln -sfn "$WALL" "$ARCHIVO_GUARDADO" || log "warning: symlink update failed"

if ! swww img "$WALL" \
    --transition-type outer \
    --transition-duration 1.2 \
    --transition-fps 60 2>>"$LOG_FILE"; then
    log "swww failed, trying to restart daemon..."
    swww-daemon &
    sleep 0.5
    swww img "$WALL" --transition-type outer --transition-duration 1.2
fi
log "applied wallpaper: $WALL"