#!/usr/bin/env bash

set -u

DIR="$HOME/Pictures/Wallpaper"
ARCHIVO_GUARDADO="$HOME/.config/hypr/fondo_actual"
HYPRPAPER_CFG="$HOME/.config/hypr/hyprpaper.conf"
LOG_FILE="$HOME/.cache/hypr/wallpaper.log"

mkdir -p "$HOME/.cache/hypr"

log() {
	echo "$(date '+%F %T') [random_wallpaper] $*" >> "$LOG_FILE"
}

for cmd in find shuf swww; do
	if ! command -v "$cmd" >/dev/null 2>&1; then
		log "missing dependency: $cmd"
		exit 1
	fi
done

if [[ ! -d "$DIR" ]]; then
	log "wallpaper directory not found: $DIR"
	exit 1
fi

RANDOM_PIC=$(find "$DIR" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" \) | shuf -n 1)

if [[ -z "$RANDOM_PIC" ]]; then
	log "no wallpapers found in: $DIR"
	exit 1
fi

ln -sfn "$RANDOM_PIC" "$ARCHIVO_GUARDADO" || log "warning: symlink update failed"

if ! swww img "$RANDOM_PIC" \
    --transition-type wipe \
    --transition-angle 30 \
    --transition-duration 1.5 \
    --transition-fps 60 2>>"$LOG_FILE"; then
    log "swww failed, trying to restart daemon..."
    swww-daemon &
    sleep 0.5
    swww img "$RANDOM_PIC" --transition-type wipe --transition-angle 30 --transition-duration 1.5
fi
log "applied wallpaper: $RANDOM_PIC"

