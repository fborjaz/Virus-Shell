#!/bin/bash
# ─────────────────────────────────────────────────
# Script de sonido para notificaciones de Dunst
# Reproduce un sonido al mismo volumen del sistema
# ─────────────────────────────────────────────────

SOUND_DIR="/usr/share/sounds/freedesktop/stereo"

# Dunst pasa estas variables de entorno al script:
#   DUNST_APP_NAME, DUNST_SUMMARY, DUNST_BODY, DUNST_URGENCY

# No reproducir sonido para apps silenciosas
case "$DUNST_APP_NAME" in
    "volume"|"brightness"|"progress")
        exit 0
        ;;
esac

# Obtener volumen actual del sistema (0-100) y convertir a escala PulseAudio (0-65536)
SYS_VOL=$(pamixer --get-volume 2>/dev/null || echo 80)
PA_VOL=$(( SYS_VOL * 65536 / 100 ))

# Elegir sonido según urgencia
case "$DUNST_URGENCY" in
    "LOW")
        SOUND="${SOUND_DIR}/message.oga"
        ;;
    "NORMAL")
        SOUND="${SOUND_DIR}/message-new-instant.oga"
        ;;
    "CRITICAL")
        SOUND="${SOUND_DIR}/dialog-warning.oga"
        ;;
    *)
        SOUND="${SOUND_DIR}/bell.oga"
        ;;
esac

# Reproducir sonido al volumen del sistema
if [[ -f "$SOUND" ]]; then
    paplay --volume="$PA_VOL" "$SOUND" &
fi
