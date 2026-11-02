# driftwm + waybar dotfiles

A dotfiles repo for a **driftwm** (trackpad-first *infinite canvas* Wayland
compositor) session with a **waybar** whose centre shows a live row of the
driftwm **bookmarks** — one clickable bubble per bookmark, styled exactly like
hyprland's workspaces.
Each WM owns its own *self-contained* full waybar dir, and a small launcher points
waybar at whichever WM is running — so driftwm and hyprland each get a complete,
independent bar. There is **no** shared `~/.config/waybar` dir.

## How it works
- Every WM has a complete waybar under `~/.config/<wm>/waybar/`
  (config + module bank + all styles + wallust palette + its own `bookmarks.py`).
- Waybar always reads the config via a launcher that picks the **running** WM:
  `~/.local/bin/start-waybar` runs `waybar --config ~/.config/<wm>/waybar/config
  --style ~/.config/<wm>/waybar/style/Dusky-07_minimal_h.css`.
- CSS `@import`s resolve relative to each theme file's own dir, so every dir is
  fully portable and self-contained (no cross-WM refs, no shared bank).
- Under driftwm the bar starts from driftwm itself:
  `autostart = ["start-waybar", "start-idle", "wl-paste ..."]` in
  `~/.config/driftwm/config.toml`. Not XDG autostart entries — those run before
  the Wayland socket exists, so waybar exits with `cannot open display: :0` and
  swayidle/wl-paste with `Failed to connect to a Wayland server`.

## Layout (repo)
```
config/
  driftwm/waybar/          # FULL waybar for driftwm
    config                 # includes ../driftwm/waybar/Modules*
    bookmarks.py           # writes the bookmark-row cache (one line per bookmark)
    bookmark-watch         # pushes driftwm changes to the bar (SIGRTMIN+12)
    Modules*  UserModules  # module bank (incl. custom/bm0..9 + group/bookmarks)
    configs/ dusky/ wallust/  style/   # all themes
  driftwm/config.toml      # driftwm keybindings (super+N bookmark toggle)
  driftwm/scripts/ClipManager.sh  # clipboard picker (super+alt+v)
  hypr/waybar/             # FULL waybar for hyprland (identical look)
start-waybar               # launcher: waybar -> the active WM's dir
driftwm-bookmark           # super+N jump / bounce-back helper
lock-screen                # lock now (hyprlock, blurred wallpaper behind)
start-idle                 # swayidle: lock on idle / before sleep
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
| `waybar-weather` (AUR) | `custom/weather2` |
| `cava` | audio visualizer |
| `playerctl` | media controls |
| `swaync` | `swaync-client` (notifications, `super+shift+n`) |
| `grim`, `slurp` | screenshots (`super+shift+s`) |
| `jq` | waybar-weather / scripts |
| `cliphist`, `wl-clipboard` | clipboard history for `super+alt+v` |
| `hyprlock`, `swayidle` | lockscreen + idle/lock daemon |

Optional: `hyprland` (for the alternate bar), `btop` (monitor window).

> `driftwm` is **not** in the official repos — install it from the AUR:
> `yay -S driftwm` ([aur.archlinux.org/packages/driftwm](https://aur.archlinux.org/packages/driftwm)).

## Install
```sh
git clone <your-url> ~/dotfiles
cd ~/dotfiles && bash install.sh
```
`install.sh` (idempotent):
1. `pacman -S` the deps; installs the AUR-only bits (`waybar-weather` and
   `driftwm`) with `yay`/`paru` if missing (not fatal if no AUR helper).
2. Copies the full waybar into `~/.config/driftwm/waybar/` and
   `~/.config/hypr/waybar/`, deploys `~/.local/bin/start-waybar` and
   `~/.local/bin/driftwm-bookmark`, `~/.local/bin/lock-screen` and
   `~/.local/bin/start-idle`, installs `~/.config/driftwm/config.toml`
   (bookmark + lock keybindings + autostart), and removes any stale
   shared `~/.config/waybar` (redundant now) and installs
   `~/.config/driftwm/scripts/ClipManager.sh` (the `super+alt+v` picker). Your
   `~/.config/hypr/scripts/*.sh` stay untouched (not in repo).
3. Enables `driftwm.service` (starts on login).

## Keybindings
| Key | Action |
|---|---|
| `super+1..0` | Jump to bookmark N — or bounce back if you're already on it |
| `super+shift+1..0` | Save the current view as bookmark N |
| `super+Return` | Terminal (kitty at 2× the default 640×400 = 1280×800) |
| `super+d` | rofi launcher |
| `super+shift+s` | Region screenshot (`grim` + `slurp`) |
| `super+alt+v` | Clipboard history (rofi + `cliphist`) |
| `super+shift+n` | Mark notification |
| `ctrl+alt+l` | Lock the screen |
| `ctrl+alt+Delete` | Log out: stop driftwm, back to the login screen |

`focus_follows_mouse = true` gives hover focus (sloppy) instead of click.

## Lock screen
One locker, via `ext-session-lock-v1` (driftwm supports it, so no Hyprland
session is needed):

- **`ctrl+alt+l`, idle auto-lock and the bar's lock button**
  (`loginctl lock-session`) all go through hyprlock, on its own config
  `~/.config/driftwm/hyprlock.conf`. Same look as the hyprland lock screen
  (blurred wallpaper, big clock, date, square password field) but deployed
  self-contained: the wallust colours are inlined and the background is
  driftwm's wallpaper, because `~/.config/hypr/hyprlock.conf` sources a palette
  file that does not exist. Blur comes from hyprlock's own screencopy, so a
  wallpaper change needs no rebuilding.

It covers every monitor and takes the same PAM password.

`lock-screen` is the wrapper swayidle and the bar call; it starts hyprlock with
driftwm's config and does nothing if hyprlock is already running. `start-idle`
runs `swayidle` for auto-lock, mirroring `hypridle.conf`: warn at 9 min, lock at
10 min, lock on `loginctl lock-session` and before sleep. hypridle's "screen
off" listener is not ported — `hyprctl dispatch dpms off` has no driftwm
equivalent.

## Bookmark behaviour
The bar centre is a row of **all 10 bookmarks**, styled 1:1 like the hyprland
workspaces bubbles: each bookmark is a rounded bubble showing its number and the
apps whose windows sit in that bookmark's canvas region (`bookmarks.py`,
`RADIUS=200` canvas px). The bookmark the camera is on is highlighted (`.active`);
empty bookmarks are dimmed (`.empty`).

- **Click** a bubble to move to that bookmark.
- **`super+N`** jumps to bookmark N; if you're already on N it bounces back to
  the bookmark you came from (`driftwm-bookmark` keeps the previous one in
  `~/.cache`).
- **`super+shift+N`** saves the current view as bookmark N.

The row updates **event-driven**: `bookmark-watch` (started by `start-waybar`)
streams `driftwm msg subscribe` and, when the row would actually change, sends
waybar `SIGRTMIN+12` — the `custom/bm0..9` modules' `"signal"` — so a jump shows
in ~0.1s instead of waiting for a poll. One `bookmarks.py` process rewrites the
cache (`~/.cache/driftwm-bookmarks.txt`, one line per bookmark) and the ten
modules just read their line. The modules also keep a 5s `interval` as a
fallback (e.g. a newly saved bookmark changes no state, so it appears within
5s). If driftwm isn't running the modules emit nothing and hide
(`hide-empty-text: true`). Under hyprland the bar uses hyprland's own
`hyprland/workspaces` instead, so nothing driftwm-specific runs there.

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
