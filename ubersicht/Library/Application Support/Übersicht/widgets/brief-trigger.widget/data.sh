#!/usr/bin/env bash
# brief-trigger/data.sh — minimal state for the centerpiece run-brief button.
# Emits whether a brief was generated today + timestamp of the latest run.
exec python3 - <<'PY'
import json
from datetime import datetime, date
from pathlib import Path

WORK = Path.home() / "Durante" / "MEMORY" / "WORK"
candidates = sorted(WORK.glob("dailybrief-*.md"), reverse=True) if WORK.exists() else []

if candidates:
    latest = candidates[0]
    mtime = datetime.fromtimestamp(latest.stat().st_mtime)
    age_s = (datetime.now() - mtime).total_seconds()
    if   age_s < 60:    age = f"{int(age_s)}s ago"
    elif age_s < 3600:  age = f"{int(age_s/60)}m ago"
    elif age_s < 86400: age = f"{int(age_s/3600)}h ago"
    else:               age = f"{int(age_s/86400)}d ago"
    state = "fresh" if age_s < 86400 else "stale"
else:
    age = "never"
    state = "missing"

print(json.dumps({
    "state": state,
    "age":   age,
    "now":   datetime.now().strftime("%H:%M"),
}))
PY
