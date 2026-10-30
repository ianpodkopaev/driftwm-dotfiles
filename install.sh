#!/usr/bin/env bash
# dotfiles/install.sh — driftwm + waybar.
#
# Each WM owns its own FULL, self-contained waybar dir (config + modules +
# all styles + wallust + bookmark.py):
#   ~/.config/driftwm/waybar/
#   ~/.config/hypr/waybar/
# A launcher (~/.local/bin/start-waybar) points waybar at whichever WM is
# running, and an XDG autostart entry (driftwm runs xdg-desktop-autostart)
# starts it on login. There is NO ~/.config/waybar dir.
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC="$REPO/config"
BIN="$HOME/.local/bin"
X="$HOME/.config"
AUTOSTART="$X/autostart"

SUDO=()
[ "$(id -u)" -eq 0 ] || SUDO=(sudo)
pac() { "${SUDO[@]}" pacman -S --needed "$@"; }

echo "==> 1/3 packages"
pac waybar waybar-weather cava playerctl swaync grim slurp kitty rofi fish jq
pac cliphist wl-clipboard
pac gtklock swayidle imagemagick
if ! command -v driftwm >/dev/null 2>&1; then
  if command -v yay >/dev/null 2>&1; then yay -S driftwm
  else echo "   driftwm not installed and yay not found:  yay -S driftwm  (AUR)"; fi
fi

echo "==> 2/3 full waybar into each WM dir + launcher + autostart"
mkdir -p "$BIN" "$AUTOSTART" "$X/driftwm" "$X/hypr/scripts"
# full, self-contained waybar into each WM dir
cp -a "$SRC/driftwm/waybar/." "$X/driftwm/waybar"
cp -a "$SRC/hypr/waybar/."   "$X/hypr/waybar"
chmod +x "$X/driftwm/waybar/"*.py "$X/driftwm/waybar/bookmark-watch" \
         "$X/hypr/waybar/"*.py 2>/dev/null || true
# driftwm keybindings (super+N bookmark jump/toggle)
cp "$SRC/driftwm/config.toml" "$X/driftwm/config.toml"
# clipboard picker the super+alt+v binding spawns (rofi + cliphist + wl-copy)
cp "$SRC/hypr/scripts/ClipManager.sh" "$X/hypr/scripts/ClipManager.sh"
chmod +x "$X/hypr/scripts/ClipManager.sh"
# remove any stale shared dir from an older install (now redundant)
rm -rf "$X/waybar"
# launcher + bookmark toggle -> $BIN
cp "$REPO/start-waybar" "$BIN/start-waybar"
cp "$REPO/driftwm-bookmark" "$BIN/driftwm-bookmark"
cp "$REPO/lock-screen" "$BIN/lock-screen"
cp "$REPO/start-idle" "$BIN/start-idle"
chmod +x "$BIN/start-waybar" "$BIN/driftwm-bookmark" \
         "$BIN/lock-screen" "$BIN/start-idle"
# lockscreen theme (gtklock); background.jpg is generated on first lock
mkdir -p "$X/gtklock"
cp -a "$SRC/gtklock/." "$X/gtklock"
# XDG autostart (picked up by driftwm's xdg-desktop-autostart.target)
cat > "$AUTOSTART/waybar.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=Waybar
Comment=The bar — follows the active WM (driftwm or hyprland)
Exec=$BIN/start-waybar
X-GNOME-Autostart-enabled=true
EOF
cat > "$AUTOSTART/swayidle.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=Idle (swayidle + gtklock)
Comment=Lock on idle / before sleep (driftwm)
Exec=$BIN/start-idle
X-GNOME-Autostart-enabled=true
EOF
cat > "$AUTOSTART/cliphist.desktop" <<'EOF'
[Desktop Entry]
Type=Application
Name=Clipboard history (cliphist)
Comment=Feed copied text and images to cliphist (driftwm)
Exec=sh -c "wl-paste --type text --watch cliphist store & wl-paste --type image --watch cliphist store"
X-GNOME-Autostart-enabled=true
EOF

echo "==> 3/3 driftwm.service"
if command -v driftwm >/dev/null 2>&1; then
  systemctl --user daemon-reload
  systemctl --user enable driftwm.service
fi

echo
echo "done.  bar follows the active WM — no ~/.config/waybar:"
echo "  driftwm  ->  $X/driftwm/waybar"
echo "  hyprland ->  $X/hypr/waybar"
echo "  manual:   $BIN/start-waybar"
