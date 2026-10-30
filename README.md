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
- Under driftwm the bar autostarts via an XDG `.desktop` file
  (`~/.config/autostart/waybar.desktop`); driftwm runs `xdg-desktop-autostart`.

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
  hypr/waybar/             # FULL waybar for hyprland (identical look)
  gtklock/                 # lockscreen theme (config.ini + style.css)
start-waybar               # launcher: waybar -> the active WM's dir
driftwm-bookmark           # super+N jump / bounce-back helper
lock-screen                # lock now (gtklock, blurred wallpaper behind)
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
| `waybar-weather` | `custom/weather2` |
| `cava` | audio visualizer |
| `playerctl` | media controls |
| `swaync` | `swaync-client` (notifications, `super+shift+n`) |
| `grim`, `slurp` | screenshots (`super+shift+s`) |
| `jq` | waybar-weather / scripts |
| `cliphist`, `wl-clipboard` | clipboard history for `super+alt+v` |
| `gtklock`, `swayidle` | lockscreen + idle/lock daemon |
| `imagemagick` | blurs the wallpaper for the lock background |

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
   `~/.config/hypr/waybar/`, deploys `~/.local/bin/start-waybar` and
   `~/.local/bin/driftwm-bookmark`, `~/.local/bin/lock-screen` and
   `~/.local/bin/start-idle`, installs `~/.config/driftwm/config.toml`
   (bookmark + lock keybindings), the gtklock theme, and removes any stale
   shared `~/.config/waybar` (redundant now). Your `~/.config/hypr/scripts/*.sh`
   stay untouched (not in repo).
3. Enables `driftwm.service` (starts on login).

## Keybindings
| Key | Action |
|---|---|
| `super+1..0` | Jump to bookmark N — or bounce back if you're already on it |
| `super+shift+1..0` | Save the current view as bookmark N |
| `super+Return` | Terminal |
| `super+d` | rofi launcher |
| `super+shift+s` | Region screenshot (`grim` + `slurp`) |
| `super+alt+v` | Clipboard history (rofi + `cliphist`) |
| `super+shift+n` | Mark notification |
| `super+l`, `ctrl+alt+l` | Lock the screen |
| `ctrl+alt+Delete` | Log out: stop driftwm, back to the login screen |

`focus_follows_mouse = true` gives hover focus (sloppy) instead of click.

## Lock screen
`super+l` (or the bar's lock button, which runs `loginctl lock-session`) locks
with **gtklock** — driftwm supports `ext-session-lock-v1`, so no Hyprland
locker is needed. The look is a port of `~/.config/hypr/hyprlock.conf`: the
driftwm wallpaper, blurred, behind a large clock, the date, and a square
outlined password field. Colours come from the same wallust palette the bar
uses (`config/gtklock/style.css` imports it), so the lock screen matches the
desktop. `lock-screen` regenerates `~/.config/gtklock/background.jpg` with
`magick` when the wallpaper changes (first lock takes ~1s).

gtklock shows the password form on the first monitor it enumerates, which is
not necessarily the one you're looking at, so `lock-screen` passes
`-M <active output>` (read from `driftwm msg state`). With more than one
monitor, both are covered but the form follows the active output. The pointer
blanks itself after 5 s idle (`idle-hide`), and any key or motion brings the
form and the pointer back.

`start-idle` runs `swayidle` for auto-lock, mirroring `hypridle.conf`: warn at
9 min, lock at 10 min, lock on `loginctl lock-session` and before sleep.
hypridle's "screen off" listener is not ported — `hyprctl dispatch dpms off`
has no driftwm equivalent. Test the theme without locking yourself out with
`gtklock --preview` (any password unlocks).

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
