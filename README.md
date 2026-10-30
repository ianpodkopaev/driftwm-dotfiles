# driftwm + waybar dotfiles

A dotfiles repo for a **driftwm** (trackpad-first *infinite canvas* Wayland compositor)
session with a **waybar** that shows the current driftwm **bookmark**. An unmodified
waybar config is kept for **hyprland** so switching WMs doesn't break the bar.

## What you get
- `driftwm` configured for trackpad navigation, hover focus (`focus_follows_mouse`),
  and **10 bookmarks** (`super+1..0`), plus bookmarks 5–0 that driftwm doesn't ship
  by default (its defaults only cover 1–4).
- A waybar (Dusky‑07‑minimal theme) that prints `◈ N` — the active bookmark —
  **only while a window is focused**; it hides itself on the empty canvas.
- A separate, unmodified hyprland bar config so the shared waybar files stay
  inert under hyprland (and under driftwm, the hyprland‑only modules disable
  themselves automatically).

## Layout
```
config/
  driftwm/
    config.toml               # the active WM config
    waybar/config             # driftwm bar (active; shows the bookmark)
    waybar/bookmark.py        # module script -> prints the active bookmark
  hypr/
    waybar/config             # unmodified hypr bar (no bookmark)
  waybar/                       # full local waybar (everything at ~/.config/waybar)
    Modules*  UserModules       # module bank (incl. custom/bookmark) + configs/, dusky/, wallust/
    style/                      # all ~70 themes (incl. the active Dusky-07_minimal_h.css)
```

## Required packages

| Package | Role |
|---|---|
| **driftwm** (AUR) | The compositor + `driftwm msg` CLI + `driftwm.service` |
| `waybar` | The bar (v0.15) |
| `kitty` | Terminal (set as `TERMINAL`) |
| `rofi` | Launcher (`super+d`) |
| `fish` | Shell |

Bar modules:

| Package | Used by |
|---|---|
| `waybar-weather` | `custom/weather2` |
| `cava` | audio visualizer |
| `playerctl` | media controls |
| `swaync` | `swaync-client` (notifications, `super+shift+n`) |
| `grim`, `slurp` | screenshots (`super+shift+s`) |
| `jq` | waybar‑weather / scripts |

Optional: `hyprland` (for the alternate bar), `btop` (monitor window).

> `driftwm` is **not** in the official repos. Install it from the AUR with
> `yay -S driftwm` — [aur.archlinux.org/packages/driftwm](https://aur.archlinux.org/packages/driftwm).
> (It ships a package‑managed `~/.config/…/driftwm.service` user service.)

## Install

```sh
git clone <your-url> ~/dotfiles
cd ~/dotfiles && bash install.sh
```

`install.sh` (idempotent — safe to re-run):
1. `pacman -S` the deps; builds/installs `driftwm` from the AUR if missing.
2. Copies `config/*` over `~/.config/` — the full waybar is laid into
   `~/.config/waybar/`, and your `~/.config/hypr/` scripts stay untouched
   (they're not part of this repo).
3. Retargets `~/.config/waybar/config → ~/.config/driftwm/waybar/config`
   (active bar) and `~/.config/waybar/style.css → …/Dusky‑07_minimal_h.css`.
4. Enables `driftwm.service` (starts on the next login).

Log in once to activate. (driftwm is your current session, so nothing changes visually.)

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

The bar shows `◈ N` only while a window has focus. While you're on the empty
canvas (no focused window) the module emits nothing and waybar hides it
(`hide-empty-text: true`). To save a bookmark, hover where you want a "home"
view and press `super+shift+N`.

## Switching the bar (driftwm ↔ hyprland)

The active bar is whatever `~/.config/waybar/config` points at:

```sh
# driftwm bar (shows the bookmark) — default
ln -sfn ~/.config/driftwm/waybar/config    ~/.config/waybar/config
# hypr bar (no bookmark)
ln -sfn ~/.config/hypr/waybar/config       ~/.config/waybar/config
pkill waybar        # restart the bar
```

## Notes

- This repo reuses the hyprland bar's module files so the look is identical.
  Several of those modules call `~/.config/hypr/scripts/*.sh` (brightness,
  volume, logout, wallpaper…). Those scripts are **not** in this repo; under
  driftwm the matching bar buttons do nothing (waybar degrades gracefully —
  no crash). To make them work, keep your existing `~/.config/hypr/` dotfiles
  alongside, or port the scripts to target driftwm.
- The built‑in `hyprland/window` and `hyprland/workspaces` waybar modules
  disable themselves automatically when hyprland isn't running — the bar never breaks.
- The full local waybar is committed (all modules + all ~70 themes from
  [LinuxBeginnings](https://github.com/LinuxBeginnings/waybar)), so a fresh
  install gets the complete bar — nothing extra to fetch.
