#!/usr/bin/env bash
# Aplica el tema SDDM Catppuccin Mocha (requiere sudo)

set -e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
THEME_DIR="/usr/share/sddm/themes/where_is_my_sddm_theme"

# 1. Instalar el tema si no está
if [[ ! -d "$THEME_DIR" ]]; then
    echo "Instalando where-is-my-sddm-theme..."
    PKG="$HOME/.cache/yay/where-is-my-sddm-theme-git/where-is-my-sddm-theme-git-1:r118.2fddf85-1-any.pkg.tar.zst"
    if [[ -f "$PKG" ]]; then
        sudo pacman -U "$PKG" --noconfirm
    else
        yay -S --noconfirm where-is-my-sddm-theme-git
    fi
fi

# 2. Copiar wallpaper al tema
WALLPAPER=""
for F in \
    "$HOME/Pictures/Wallpaper/One_Piece06.jpg" \
    "$HOME/Pictures/Wallpaper/wallpaper.jpg" \
    "$(readlink -f "$HOME/.config/hypr/fondo_actual" 2>/dev/null)"; do
    [[ -f "$F" ]] && WALLPAPER="$F" && break
done

if [[ -n "$WALLPAPER" ]]; then
    sudo cp "$WALLPAPER" "$THEME_DIR/background.jpg"
    echo "✓ Wallpaper: $(basename "$WALLPAPER")"
else
    echo "! No se encontró wallpaper, se usará fondo negro"
fi

# 3. Copiar configuración del tema
sudo cp "$SCRIPT_DIR/theme/theme.conf.user" "$THEME_DIR/theme.conf.user"
echo "✓ theme.conf.user aplicado"

# 4. Activar el tema en SDDM
sudo mkdir -p /etc/sddm.conf.d
sudo cp "$SCRIPT_DIR/sddm.conf" /etc/sddm.conf.d/virus-shell.conf
echo "✓ SDDM configurado"

echo ""
echo "✓ SDDM listo. El cambio se verá en el próximo reinicio o al hacer:"
echo "  sudo systemctl restart sddm"
