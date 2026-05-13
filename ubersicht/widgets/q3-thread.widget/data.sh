#!/usr/bin/env bash
# q3-thread/data.sh — picks one Q3 reflection, weighted toward low-sentiment runs.
exec python3 - <<'PY'
import json, random, sys
from pathlib import Path
from datetime import datetime

REFL = Path.home() / ".claude" / "MEMORY" / "LEARNING" / "REFLECTIONS" / "algorithm-reflections.jsonl"

def fail(msg):
    print(json.dumps({"error": msg, "now": datetime.now().strftime("%H:%M")}))
    sys.exit(0)

if not REFL.exists():
    fail("no reflections")

try:
    with REFL.open() as f:
        lines = f.readlines()[-200:]
except Exception as e:
    fail(f"read error: {e}")

entries = []
for ln in lines:
    ln = ln.strip()
    if not ln or not ln.startswith("{"):
        continue
    try:
        j = json.loads(ln)
        q3 = (j.get("reflection_q3") or "").strip()
        if not q3 or len(q3) < 12:
            continue
        entries.append({
            "task":       (j.get("task_description") or "").strip(),
            "task_date":  (j.get("timestamp") or "")[:10],
            "q3":         q3,
            "sentiment":  int(j.get("implied_sentiment") or 7),
        })
    except Exception:
        continue

if not entries:
    fail("no q3 entries")

# Weight low-sentiment more (sharper lessons): sentiment 1 → weight 10, 10 → 1
weights = [max(1, 11 - e["sentiment"]) for e in entries]
pick = random.choices(entries, weights=weights, k=1)[0]

# Truncate q3 if absurdly long
q3 = pick["q3"]
if len(q3) > 320:
    q3 = q3[:317] + "…"

print(json.dumps({
    "task":      pick["task"][:80],
    "task_date": pick["task_date"],
    "q3":        q3,
    "sentiment": pick["sentiment"],
    "now":       datetime.now().strftime("%H:%M"),
}))
PY
