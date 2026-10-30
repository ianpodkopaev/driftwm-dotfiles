#!/usr/bin/env python3
"""waybar custom/bookmark module.

Prints the active driftwm bookmark when a window is focused, e.g. "◈ 2".
Emits nothing (and waybar hides the module via hide-empty) when:
  - no driftwm is running (hyprland/sway -> inert, never crashes), or
  - no window is focused (empty canvas), or
  - no active bookmark yet.
"""
import json
import subprocess
import sys


def driftwm_state():
    """Return the state dict from `driftwm msg state --json`, or None."""
    try:
        proc = subprocess.run(
            ["driftwm", "msg", "state", "--json"],
            capture_output=True, text=True, timeout=1,
        )
        if proc.returncode != 0:
            return None
        data = json.loads(proc.stdout)
    except Exception:
        return None
    return data.get("Ok", {}).get("State")


def main():
    state = driftwm_state()
    if not state:
        return  # not driftwm (or IPC unavailable) -> show nothing

    windows = state.get("windows") or []
    focused = [w for w in windows if w.get("is_focused")]
    bookmark = state.get("active_bookmark")

    if focused and bookmark:
        print(f"◈ {bookmark}")
    # else: emit nothing -> hide-empty hides the module
    return


if __name__ == "__main__":
    main()
