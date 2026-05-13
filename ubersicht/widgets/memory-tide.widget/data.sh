#!/usr/bin/env bash
# memory-tide/data.sh — counts git commits per day across hot repos, last 7 days.
# Multi-source signal: ~/Durante + ~/dotfiles + ~/.claude (MEMORY/WORK is gitignored, sessions added).
exec python3 - <<'PY'
import json, subprocess
from pathlib import Path
from datetime import datetime, date, timedelta

HOME = Path.home()
REPOS = [HOME / "Durante", HOME / "dotfiles", HOME / ".claude"]
WORK  = HOME / ".claude" / "MEMORY" / "STATE" / "work.json"

today    = date.today()
week_ago = today - timedelta(days=6)
buckets  = {(week_ago + timedelta(days=i)).isoformat(): 0 for i in range(7)}

# 1) git commits per day across repos (signal: "what shipped")
for r in REPOS:
    if not (r / ".git").exists():
        continue
    try:
        out = subprocess.run(
            ["git", "-C", str(r), "log", f"--since={week_ago.isoformat()}",
             "--format=%cI", "--all"],
            capture_output=True, text=True, timeout=3,
        )
        if out.returncode != 0:
            continue
        for ln in out.stdout.splitlines():
            day_iso = ln.strip()[:10]
            if day_iso in buckets:
                buckets[day_iso] += 1
    except Exception:
        continue

# 2) overlay sessions per day from work.json (signal: "what was attempted")
if WORK.exists():
    try:
        data = json.loads(WORK.read_text())
        for slug, s in (data.get("sessions") or {}).items():
            ts = (s.get("started") or s.get("updatedAt") or "")[:10]
            if ts in buckets:
                buckets[ts] += 1
    except Exception:
        pass

# oldest → today
days = []
for i in range(7):
    d = week_ago + timedelta(days=i)
    iso = d.isoformat()
    days.append({
        "date":  iso,
        "count": buckets.get(iso, 0),
        "label": d.strftime("%a"),
    })

print(json.dumps({
    "days": days,
    "max":  max(d["count"] for d in days) or 1,
    "now":  datetime.now().strftime("%H:%M"),
}))
PY
