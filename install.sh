#!/usr/bin/env bash
# dotfiles/install.sh — driftwm + waybar (bookmark bar).
# Arch-based (CachyOS). Idempotent: safe to re-run.
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC="$REPO/config"
X="$HOME/.config"

# sudo only when not already root
SUDO=()
[ "$(id -u)" -eq 0 ] || SUDO=(sudo)
pac() { "${SUDO[@]}" pacman -S --needed "$@"; }

echo "==> 1/3 packages"
# bar + apps
pac waybar waybar-weather cava playerctl swaync grim slurp kitty rofi fish jq
# driftwm is an AUR package — build it if it isn't already installed.
if ! command -v driftwm >/dev/null; then
  if command -v yay >/dev/null; then
    echo "    building driftwm from the AUR (first build takes a while)..."
    yay -S driftwm
  else
    echo "    driftwm not installed and yay not found. Install it from the AUR:"
    echo "      yay -S driftwm   (https://aur.archlinux.org/packages/driftwm)"
    echo "    then re-run this script."
  fi
else
  echo "    driftwm already installed."
fi
# optional: the alternate hyprland bar (uncomment to also install hyprland)
# pac hyprland

echo "==> 2/3 copy files into $X"
for d in driftwm hypr waybar; do
  cp -a "$SRC/$d/." "$X/$d"   # additive: keeps your existing themes / hyprland scripts
done
# the live bar + style:
ln -sfn "$X/driftwm/waybar/config" "$X/waybar/config"            # active bar = driftwm
ln -sfn "$X/waybar/style/Dusky-07_minimal_h.css" "$X/waybar/style.css"
chmod +x "$X/driftwm/waybar/bookmark.py"

echo "==> 3/3 enable driftwm.service (starts on login)"
if command -v driftwm >/dev/null; then
  systemctl --user daemon-reload
  systemctl --user enable driftwm.service
fi

echo
echo "done."
echo "  active bar -> $(readlink -f "$X/waybar/config")"
echo "  save a bookmark:  super+shift+N   (bar shows '◈ N' while a window is focused)"
echo
echo "  switch to the hypr bar:       ln -sfn $X/hypr/waybar/config $X/waybar/config && pkill waybar"
echo "  switch back to driftwm:      ln -sfn $X/driftwm/waybar/config   $X/waybar/config && pkill waybar"
