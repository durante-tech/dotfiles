#!/usr/bin/env bash
# aging-watch.widget/data.sh — surfaces stuck work from the PRDSync registry.
# Reads ~/.claude/MEMORY/STATE/work.json. For each session, computes age and
# classifies as VERIFY (>24h verify), BUILD-STUCK (>12h with 0 progress), or
# STALE (>7d non-complete). Sorts age-desc, returns top 5.
exec python3 - <<'PY'
import json, re
from pathlib import Path
from datetime import datetime, timezone

HOME = Path.home()
WORK_JSON = HOME / ".claude" / "MEMORY" / "STATE" / "work.json"

def now_utc():
    return datetime.now(timezone.utc)

def parse_ts(s):
    if not s: return None
    try:
        # work.json uses both "...Z" and "...+00:00" — normalize Z→+00:00
        return datetime.fromisoformat(str(s).replace("Z", "+00:00"))
    except Exception:
        return None

def age_human(seconds):
    if seconds is None: return "?"
    s = max(0, int(seconds))
    if s < 3600:        return f"{s // 60}m"
    if s < 86400:       return f"{s // 3600}h"
    return f"{s // 86400}d"

def parse_progress(p):
    """progress is "X/Y" string. Return (passed, total) or (None, None)."""
    if not isinstance(p, str): return (None, None)
    m = re.match(r"^\s*(\d+)\s*/\s*(\d+)\s*$", p)
    if not m: return (None, None)
    return (int(m.group(1)), int(m.group(2)))

def derive_title(sess):
    """Best-readable label: prefer task (truncated), fallback to sessionName."""
    t = (sess.get("task") or "").strip()
    if not t:
        t = (sess.get("sessionName") or "").strip()
    if not t:
        t = "(unnamed)"
    # Strip backticks and collapse whitespace
    t = re.sub(r"`([^`]+)`", r"\1", t)
    t = re.sub(r"\s+", " ", t).strip()
    return t

now = now_utc()
result_default = {
    "state": "clean",
    "items": [],
    "total_count": 0,
    "now": now.astimezone().strftime("%H:%M"),
}

if not WORK_JSON.exists():
    print(json.dumps(result_default))
    raise SystemExit(0)

try:
    raw = json.loads(WORK_JSON.read_text(encoding="utf-8", errors="ignore"))
except Exception as e:
    print(json.dumps({
        "state": "read-error",
        "error": str(e)[:200],
        "items": [],
        "total_count": 0,
        "now": now.astimezone().strftime("%H:%M"),
    }))
    raise SystemExit(0)

sessions = raw.get("sessions", {}) if isinstance(raw, dict) else {}

aged = []
for key, sess in sessions.items():
    if not isinstance(sess, dict): continue
    phase = (sess.get("phase") or "").lower()
    if phase == "complete": continue   # done is not aging

    updated = parse_ts(sess.get("updatedAt")) or parse_ts(sess.get("started"))
    if updated is None: continue
    age_sec = (now - updated).total_seconds()

    label = None
    passed, total = parse_progress(sess.get("progress"))

    # Classification rules (first match wins, ordered by specificity)
    if phase != "complete" and age_sec > 7 * 86400:
        label = "STALE"
    elif phase == "verify" and age_sec > 24 * 3600:
        label = "VERIFY"
    elif phase == "build" and (passed == 0 if passed is not None else False) and age_sec > 12 * 3600:
        label = "BUILD-STUCK"

    if label is None: continue

    aged.append({
        "label":     label,
        "title":     derive_title(sess)[:80],
        "age_sec":   age_sec,
        "age_human": age_human(age_sec),
    })

# Sort by age descending (oldest stuck work first)
aged.sort(key=lambda x: x["age_sec"], reverse=True)
total_count = len(aged)
top = aged[:5]

# Strip the internal age_sec before emitting
for item in top:
    item.pop("age_sec", None)

print(json.dumps({
    "state":       "clean" if total_count == 0 else "aging",
    "items":       top,
    "total_count": total_count,
    "now":         now.astimezone().strftime("%H:%M"),
}))
PY
