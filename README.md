# driftwm + waybar dotfiles

A dotfiles repo for a **driftwm** (trackpad-first *infinite canvas* Wayland
compositor) session with a **waybar** that shows the current driftwm **bookmark**.
Each WM owns its own *self-contained* full waybar dir, and a small launcher points
waybar at whichever WM is running — so driftwm and hyprland each get a complete,
independent bar. There is **no** shared `~/.config/waybar` dir.

## How it works
- Every WM has a complete waybar under `~/.config/<wm>/waybar/`
  (config + module bank + all styles + wallust palette + its own `bookmark.py`).
- Waybar always reads the config via a launcher that picks the **running** WM:
  `~/.local/bin/start-waybar` runs `waybar --config ~/.config/<wm>/waybar/config
  --style ~/.config/<wm>/waybar/style/Dusky-07_minimal_h.css`.
- CSS `@import`s resolve relative to each theme file's own dir, so every dir is
  fully portable and self-contained (no cross-WM refs, no shared bank).
- Under driftwm the bar autostarts via an XDG `.desktop` file
  (`~/.config/autostart/waybar.desktop`); driftwm runs `xdg-desktop-autostart`.

## Layout (repo)
```
config/
  driftwm/waybar/          # FULL waybar for driftwm
    config                 # includes ../driftwm/waybar/Modules*
    bookmark.py            # prints "◈ N" (active bookmark, focused window)
    Modules*  UserModules  # module bank (incl. custom/bookmark)
    configs/ dusky/ wallust/  style/   # all themes
  hypr/waybar/             # FULL waybar for hyprland (identical look)
start-waybar               # launcher: waybar -> the active WM's dir
README.md  install.sh  .gitignore
```

## Required packages
| Package | Role |
|---|---|
| **driftwm** (AUR) | compositor + `driftwm msg` + `driftwm.service` |
| `waybar` | the bar (v0.15) |
| `kitty` | terminal (set as `TERMINAL`) |
| `rofi` | launcher (`super+d`) |
| `fish` | shell |

Bar modules:
| Package | Used by |
|---|---|
| `waybar-weather` | `custom/weather2` |
| `cava` | audio visualizer |
| `playerctl` | media controls |
| `swaync` | `swaync-client` (notifications, `super+shift+n`) |
| `grim`, `slurp` | screenshots (`super+shift+s`) |
| `jq` | waybar-weather / scripts |

Optional: `hyprland` (for the alternate bar), `btop` (monitor window).

> `driftwm` is **not** in the official repos — install it from the AUR:
> `yay -S driftwm` ([aur.archlinux.org/packages/driftwm](https://aur.archlinux.org/packages/driftwm)).

## Install
```sh
git clone <your-url> ~/dotfiles
cd ~/dotfiles && bash install.sh
```
`install.sh` (idempotent):
1. `pacman -S` the deps; installs `driftwm` from the AUR if missing.
2. Copies the full waybar into `~/.config/driftwm/waybar/` and
   `~/.config/hypr/waybar/`, deploys `~/.local/bin/start-waybar` and the
   XDG autostart entry, and removes any stale shared `~/.config/waybar`
   (redundant now). Your `~/.config/hypr/scripts/*.sh` stay untouched (not in repo).
3. Enables `driftwm.service` (starts on login).

## Keybindings
| Key | Action |
|---|---|
| `super+1..0` | Jump to bookmark N |
| `super+shift+1..0` | Save the current view as bookmark N |
| `super+Return` | Terminal |
| `super+d` | rofi launcher |
| `super+shift+s` | Region screenshot (`grim` + `slurp`) |
| `super+shift+n` | Mark notification |

`focus_follows_mouse = true` gives hover focus (sloppy) instead of click.

## Bookmark behaviour
The bar shows `◈ N` only while a window has focus. On the empty canvas (no
focused window) the module emits nothing and waybar hides it
(`hide-empty-text: true`). Save a bookmark by hovering where you want a "home"
view and pressing `super+shift+N`. Under hyprland the bookmark module runs but
`driftwm msg` isn't there, so it shows nothing — it degrades gracefully.

## Switching the bar (driftwm ↔ hyprland)
The launcher follows the running compositor automatically. To run the other
bar manually (e.g. you're on hyprland):
```sh
~/.local/bin/start-waybar          # re-points at whichever WM is running
# or explicitly:
waybar --config ~/.config/driftwm/waybar/config \
       --style ~/.config/driftwm/waybar/style/Dusky-07_minimal_h.css
waybar --config ~/.config/hypr/waybar/config \
       --style ~/.config/hypr/waybar/style/Dusky-07_minimal_h.css
```
To change the active theme, edit `THEME=` in `~/.local/bin/start-waybar`
(same theme name is shipped in both dirs).

## Notes
- Each WM dir is self-contained: nothing is shared between
  `~/.config/driftwm/waybar` and `~/.config/hypr/waybar`, and neither depends on
  a `~/.config/waybar` module bank.
- Several bar modules call `~/.config/hypr/scripts/*.sh` (brightness, volume,
  logout, wallpaper…). Those scripts are **not** in this repo; under driftwm the
  matching buttons do nothing (waybar degrades gracefully — no crash). Keep your
  existing `~/.config/hypr/` dotfiles alongside to make them work.
- The built‑in `hyprland/window` and `hyprland/workspaces` waybar modules disable
  themselves when hyprland isn't running — the bar never breaks.
- The full local waybar (all modules + all ~70 themes from
  [LinuxBeginnings](https://github.com/LinuxBeginnings/waybar)) is committed, so a
  fresh install gets the complete bar — nothing extra to fetch.
