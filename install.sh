#!/usr/bin/env bash
# Virus-Shell — Script de Instalación
# Replica exactamente la configuración de Hyprland + Eww + Kitty en Arch Linux

set -e

REPO_URL="https://github.com/fborjaz/Virus-Shell.git"
REPO_DIR="$HOME/Virus-Shell"
CFG="$HOME/.config"
WALLPAPER_DIR="$HOME/Pictures/Wallpaper"
FONT_DIR="$HOME/.local/share/fonts"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; RESET='\033[0m'

ok()   { echo -e "${GREEN}  ✓ $*${RESET}"; }
warn() { echo -e "${YELLOW}  ! $*${RESET}"; }
err()  { echo -e "${RED}  ✗ $*${RESET}"; exit 1; }
step() { echo -e "\n${CYAN}${BOLD}==> $*${RESET}"; }

# ── Verificar Arch Linux ──────────────────────────────────────────────────────
command -v pacman &>/dev/null || err "Este script requiere Arch Linux (pacman)."

echo -e "${YELLOW}${BOLD}"
cat << 'EOF'
╔═══════════════════════════════════════════════════════╗
║              VIRUS-SHELL  —  INSTALL                  ║
║  Hyprland · Eww · Kitty · swaync · wlogout · pywal   ║
║                                                        ║
║  AVISO: sobreescribirá archivos en ~/.config           ║
╚═══════════════════════════════════════════════════════╝
EOF
echo -e "${RESET}"
read -rp "¿Continuar la instalación? [s/N] " RESP
[[ "$RESP" =~ ^[sS]$ ]] || { echo "Cancelado."; exit 0; }

# ── Paquetes oficiales ────────────────────────────────────────────────────────
step "Instalando paquetes del sistema (pacman)..."
PKGS=(
    # Compositor y herramientas Hypr
    hyprland hypridle hyprlock

    # Terminal y barra
    kitty eww

    # Notificaciones y lanzadores
    rofi

    # Control de hardware
    pamixer playerctl brightnessctl pipewire wireplumber

    # Capturas de pantalla
    grim slurp wl-clipboard

    # Herramientas de sistema
    fastfetch neovim ranger thunar jq curl wget git socat

    # Autenticación y servicios
    polkit-gnome gnome-keyring

    # Iconos
    papirus-icon-theme

    # Fuentes base y íconos
    noto-fonts noto-fonts-emoji ttf-font-awesome

    # Red
    networkmanager

    # pywal (colores dinámicos)
    python-pywal
)
sudo pacman -S --needed --noconfirm "${PKGS[@]}" || warn "Algunos paquetes no se instalaron (revisa manualmente)"

# ── Paquetes AUR ──────────────────────────────────────────────────────────────
step "Instalando paquetes AUR..."
AUR_PKGS=(
    swww                          # Wallpaper con transiciones animadas
    wlogout                       # Pantalla de logout con íconos
    swayosd                       # OSD de volumen/brillo
    swaynotificationcenter        # Centro de notificaciones (swaync)
    catppuccin-gtk-theme-mocha    # Tema GTK Catppuccin Mocha
    papirus-folders-git           # Colores de carpetas Catppuccin
    miku-cursor-git               # Cursor miku
)

if command -v yay &>/dev/null; then
    yay -S --needed --noconfirm "${AUR_PKGS[@]}" || warn "Algunos AUR fallaron — instala manualmente los que falten"
elif command -v paru &>/dev/null; then
    paru -S --needed --noconfirm "${AUR_PKGS[@]}" || warn "Algunos AUR fallaron — instala manualmente los que falten"
else
    warn "No se encontró yay ni paru. Instala manualmente desde AUR:"
    for P in "${AUR_PKGS[@]}"; do warn "  → $P"; done
fi

# ── Clonar / actualizar repositorio ──────────────────────────────────────────
step "Descargando Virus-Shell..."
if [[ -d "$REPO_DIR/.git" ]]; then
    git -C "$REPO_DIR" pull --ff-only && ok "Repositorio actualizado"
else
    git clone "$REPO_URL" "$REPO_DIR" && ok "Repositorio clonado en $REPO_DIR"
fi

# ── Backup de configuración actual ───────────────────────────────────────────
step "Haciendo backup de tu configuración actual..."
BACKUP="$HOME/.config-backup-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP"
for DIR in eww hypr kitty; do
    [[ -d "$CFG/$DIR" ]] && cp -r "$CFG/$DIR" "$BACKUP/" && ok "Backup: $DIR"
done
[[ -d "$BACKUP" ]] && ok "Backup guardado en $BACKUP"

# ── Copiar configuraciones ────────────────────────────────────────────────────
step "Copiando configuraciones a ~/.config/..."
mkdir -p "$CFG"
for DIR in eww hypr kitty swaync wlogout gtk-3.0 gtk-4.0; do
    rm -rf "$CFG/$DIR"
    cp -r "$REPO_DIR/.config/$DIR" "$CFG/"
    ok "Copiado: $DIR"
done

# Copiar otras configs si existen en el repo
for EXTRA in dunst rofi fastfetch nvim; do
    [[ -d "$REPO_DIR/.config/$EXTRA" ]] && cp -r "$REPO_DIR/.config/$EXTRA" "$CFG/" && ok "Copiado: $EXTRA"
done

# Aplicar colores de carpetas Papirus con tema Catppuccin
if command -v papirus-folders &>/dev/null; then
    papirus-folders -C cat-mocha-blue --theme Papirus-Dark 2>/dev/null && ok "Carpetas Papirus: Catppuccin Mocha Blue"
fi

# ── Instalar fuentes ──────────────────────────────────────────────────────────
step "Instalando fuente Monocraft / Minecraft..."
mkdir -p "$FONT_DIR"
find "$REPO_DIR/font" -type f \( -name "*.ttc" -o -name "*.ttf" -o -name "*.otf" \) \
    -exec cp {} "$FONT_DIR/" \; 2>/dev/null && ok "Fuentes copiadas"
fc-cache -f && ok "Caché de fuentes actualizado"

# ── Permisos de scripts ───────────────────────────────────────────────────────
step "Configurando permisos de scripts..."
find "$CFG/hypr/scripts"  -name "*.sh" -exec chmod +x {} \; 2>/dev/null && ok "Scripts hypr"
find "$CFG/eww/scripts"   -name "*.sh" -exec chmod +x {} \; 2>/dev/null && ok "Scripts eww"
[[ -f "$REPO_DIR/install.sh" ]] && chmod +x "$REPO_DIR/install.sh"

# ── Fondos de pantalla ────────────────────────────────────────────────────────
step "Configurando fondos de pantalla..."
mkdir -p "$WALLPAPER_DIR"
mkdir -p "$HOME/.cache/hypr"

# Copiar wallpaper por defecto incluido en el repo
DEFAULT_WALL=""
for F in "$REPO_DIR/wallpaper.jpg" "$REPO_DIR/wallpaper.png" "$REPO_DIR/preview.gif"; do
    [[ -f "$F" ]] && cp "$F" "$WALLPAPER_DIR/" && DEFAULT_WALL="$WALLPAPER_DIR/$(basename "$F")" && break
done

# Crear el symlink fondo_actual
if [[ -n "$DEFAULT_WALL" ]]; then
    ln -sfn "$DEFAULT_WALL" "$CFG/hypr/fondo_actual"
    ok "Wallpaper por defecto: $(basename "$DEFAULT_WALL")"
    ok "Symlink: $CFG/hypr/fondo_actual → $DEFAULT_WALL"
else
    warn "No se encontró wallpaper por defecto. Agrega imágenes a: $WALLPAPER_DIR"
    warn "Luego ejecuta: ~/.config/hypr/scripts/random_wallpaper.sh"
fi

# ── Ajustar rutas hardcodeadas al usuario actual ──────────────────────────────
step "Ajustando rutas para el usuario '$(whoami)'..."
USER_HOME="$HOME"
# Reemplaza /home/virus (usuario original) con el home actual
find "$CFG/hypr" "$CFG/eww" -type f \( -name "*.conf" -o -name "*.sh" -o -name "*.yuck" \) \
    -exec sed -i "s|/home/virus|$USER_HOME|g" {} \; 2>/dev/null
ok "Rutas actualizadas a $USER_HOME"

# ── pywal — generar esquema de colores inicial ────────────────────────────────
step "Generando esquema de colores con pywal..."
mkdir -p "$HOME/.cache/wal"
if [[ -n "$DEFAULT_WALL" ]] && command -v wal &>/dev/null; then
    wal -i "$DEFAULT_WALL" -n -q && ok "Colores generados desde wallpaper"
else
    warn "Ejecuta 'wal -i <ruta-imagen>' para generar colores de Hyprland"
fi

# ── Monitor en hyprpaper.conf ─────────────────────────────────────────────────
step "Ajustando configuración de monitor..."
MONITOR=$(hyprctl monitors 2>/dev/null | grep "Monitor" | awk '{print $2}' | head -1 || echo "")
if [[ -n "$MONITOR" && "$MONITOR" != "HDMI-A-1" ]]; then
    sed -i "s|monitor = HDMI-A-1|monitor = $MONITOR|g" "$CFG/hypr/hyprpaper.conf"
    ok "Monitor detectado y configurado: $MONITOR"
else
    warn "Monitor no detectado (¿estás fuera de Hyprland?). El fondo genérico (monitor =) funcionará igual."
fi

# ── Cursor ────────────────────────────────────────────────────────────────────
if [[ -d "$HOME/.icons/miku-cursor" ]] || ls /usr/share/icons/miku* &>/dev/null 2>&1; then
    ok "Cursor miku encontrado"
else
    warn "Cursor 'miku-cursor' no encontrado. Instálalo desde AUR: miku-cursor-git"
    warn "Mientras tanto hyprland usará el cursor por defecto"
fi

# ── Listo ─────────────────────────────────────────────────────────────────────
echo ""
echo -e "${GREEN}${BOLD}╔═══════════════════════════════════════════╗"
echo -e "║         ✓  INSTALACIÓN COMPLETA           ║"
echo -e "╚═══════════════════════════════════════════╝${RESET}"
echo ""
echo -e "  ${BOLD}Próximos pasos:${RESET}"
echo -e "  1. Agrega tus wallpapers a: ${CYAN}~/Pictures/Wallpaper/${RESET}"
echo -e "  2. Inicia Hyprland:         ${CYAN}Hyprland${RESET}"
echo -e "  3. Wallpaper aleatorio:     ${CYAN}Super + Alt + W${RESET}"
echo -e "  4. Elegir wallpaper:        ${CYAN}Super + Alt + S${RESET}"
echo -e "  5. Si los colores no cargan: ${CYAN}wal -i ~/Pictures/Wallpaper/<imagen>${RESET}"
echo ""
