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

for cmd in find shuf ln pkill nohup hyprpaper; do
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

if ! ln -sfn "$RANDOM_PIC" "$ARCHIVO_GUARDADO"; then
	log "failed to update symlink: $ARCHIVO_GUARDADO"
	exit 1
fi

pkill -x hyprpaper 2>/dev/null || true
nohup hyprpaper -c "$HYPRPAPER_CFG" >/tmp/hyprpaper.log 2>&1 &
log "applied wallpaper: $RANDOM_PIC"

