#!/usr/bin/env python3
"""Produce the driftwm bookmark row cache for waybar's custom/bm0..9 modules.

Writes ~/.cache/driftwm-bookmarks.txt: one JSON line per bookmark 0..9, empty
when the bookmark is unset or driftwm is down. Each line is what one
custom/bm<N> module prints ({"text","tooltip","class"}); class "active" marks
the bookmark the camera is on, "empty" when no windows are there.

One producer per second keeps 10 waybar modules updated without 10 Python
processes: the modules read their line with sed.
"""
import json
import math
import os
import subprocess
import tempfile

RADIUS = 200.0  # canvas px: a bookmark "holds" the windows around its point
CACHE = os.path.join(
    os.environ.get("XDG_CACHE_HOME") or os.path.expanduser("~/.cache"),
    "driftwm-bookmarks.txt",
)


def run(cmd):
    try:
        p = subprocess.run(cmd, capture_output=True, text=True, timeout=1)
        if p.returncode != 0:
            return None
        return json.loads(p.stdout)
    except Exception:
        return None


def short(app):
    """Turn an app_id into a compact display name (org.foo.bar -> Foo)."""
    a = (app or "").strip().replace("-", "_")
    parts = [p for p in a.split(".") if p]
    suf = {"desktop", "app", "mobile", "applet", "android"}
    if len(parts) >= 2 and parts[-1].lower() in suf:
        n = parts[-2]
    elif len(parts) == 3:
        n = parts[-2]
    elif len(parts) >= 2:
        n = parts[-1]
    else:
        n = a.split("_")[0]
    return n[:1].upper() + n[1:] if n else "•"


def main():
    bks = (run(["driftwm", "msg", "bookmark", "--json"]) or {})
    bks = bks.get("Ok", {}).get("Bookmarks") or {}
    st = (run(["driftwm", "msg", "state", "--json"]) or {})
    st = st.get("Ok", {}).get("State") or {}

    wins = [w for w in st.get("windows") or [] if not w.get("is_widget")]
    active = st.get("active_bookmark")
    lines = []
    for i in range(10):
        key = str(i)
        if key not in bks:
            lines.append("")
            continue
        bx, by = bks[key]
        names = []
        for w in wins:
            px, py = w.get("position") or [0, 0]
            if math.hypot(px - bx, py - by) <= RADIUS:
                n = short(w.get("app_id") or "")
                if n not in names:
                    names.append(n)
        is_active = active is not None and str(active) == key
        cls = "active" if is_active else ("empty" if not names else "")
        text = key + (f": {' '.join(names)}" if names else "")
        lines.append(json.dumps({
            "text": text,
            "class": cls,
            "tooltip": f"Bookmark {key} — click or super+{key}",
        }))

    # atomic replace so the sed readers never see a half-written file
    d = os.path.dirname(CACHE)
    os.makedirs(d, exist_ok=True)
    fd, tmp = tempfile.mkstemp(dir=d)
    with os.fdopen(fd, "w") as f:
        f.write("\n".join(lines) + "\n")
    os.replace(tmp, CACHE)


if __name__ == "__main__":
    main()
