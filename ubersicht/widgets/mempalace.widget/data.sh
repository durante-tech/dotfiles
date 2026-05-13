#!/usr/bin/env bash
# Emits JSON for mempalace.widget. Read-only, no MCP calls — just work.json.
exec python3 - <<'PY'
import json, sys
from pathlib import Path
from datetime import datetime, timezone
from collections import Counter

WORK = Path.home() / ".claude" / "MEMORY" / "STATE" / "work.json"

def fail(msg):
    print(json.dumps({"error": msg, "now": datetime.now().strftime("%H:%M")}))
    sys.exit(0)

if not WORK.exists():
    fail("work.json missing")

try:
    data = json.loads(WORK.read_text())
except Exception as e:
    fail(f"parse error: {e}")

sessions = data.get("sessions", {})
items = list(sessions.values())
now = datetime.now(timezone.utc)

def age(s):
    ts = s.get("updatedAt") or s.get("started")
    if not ts:
        return "?"
    try:
        dt = datetime.fromisoformat(ts.replace("Z", "+00:00"))
    except Exception:
        return "?"
    secs = (now - dt).total_seconds()
    if secs < 60:    return f"{int(secs)}s"
    if secs < 3600:  return f"{int(secs/60)}m"
    if secs < 86400: return f"{int(secs/3600)}h"
    return f"{int(secs/86400)}d"

def trunc(s, n=50):
    s = (s or "").strip().replace("\n", " ")
    return s if len(s) <= n else s[:n-1] + "…"

strategic = [s for s in items if s.get("mode") not in ("native", None)]
strategic.sort(key=lambda s: s.get("updatedAt", ""), reverse=True)

native = [s for s in items if s.get("mode") == "native"]
native.sort(key=lambda s: s.get("updatedAt", ""), reverse=True)

today = now.strftime("%Y-%m-%d")
native_today = [s for s in native if (s.get("updatedAt") or "").startswith(today)]

phases = Counter(s.get("phase", "?") for s in items)

out = {
    "total": len(items),
    "phases": dict(phases.most_common()),
    "strategic": [{
        "phase":    s.get("phase", "?"),
        "progress": s.get("progress", "?"),
        "task":     trunc(s.get("task")),
        "age":      age(s),
    } for s in strategic[:4]],
    "native_today": len(native_today),
    "native_total": len(native),
    "native_last":  trunc(native[0].get("task")) if native else "",
    "now": now.astimezone().strftime("%H:%M"),
}
print(json.dumps(out))
PY
