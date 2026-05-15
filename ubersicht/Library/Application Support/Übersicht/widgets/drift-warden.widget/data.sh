#!/usr/bin/env bash
# drift-warden/data.sh — compares focus.intention.txt against current focused window.
# Persists tick state to ~/.claude/MEMORY/STATE/drift-warden-state.json
exec python3 - <<'PY'
import json, subprocess, re, sys
from pathlib import Path
from datetime import datetime

INTENTION = Path.home() / "Library" / "Application Support" / "Übersicht" / "widgets" / "focus.widget" / "intention.txt"
STATE     = Path.home() / ".claude" / "MEMORY" / "STATE" / "drift-warden-state.json"
THRESHOLD_TICKS    = 4
OVERLAP_THRESHOLD  = 0.3
PLACEHOLDERS = ["set your north star", "edit intention.txt", "north star", "…", "..."]

def fail(msg):
    print(json.dumps({"state": "aligned", "age_ticks": 0, "focus": "", "current": "", "error": msg, "now": datetime.now().strftime("%H:%M")}))
    sys.exit(0)

# read focus
focus = ""
if INTENTION.exists():
    try:
        text = INTENTION.read_text().strip()
        focus = text.splitlines()[0] if text else ""
    except Exception:
        pass

is_placeholder = (not focus) or any(m in focus.lower() for m in PLACEHOLDERS)

# read current focused window via aerospace
current = ""
try:
    out = subprocess.run(
        ["aerospace", "list-windows", "--focused", "--format", "%{app-name}|%{window-title}"],
        capture_output=True, text=True, timeout=2,
    )
    if out.returncode == 0:
        current = out.stdout.strip().replace("|", " · ")
except Exception:
    pass

if not current:
    # fallback: front app via osascript
    try:
        out = subprocess.run(
            ["osascript", "-e", 'tell application "System Events" to get name of first application process whose frontmost is true'],
            capture_output=True, text=True, timeout=2,
        )
        if out.returncode == 0:
            current = out.stdout.strip()
    except Exception:
        pass

# tokenize for overlap
def toks(s):
    return set(re.findall(r"[a-z0-9]{3,}", (s or "").lower()))

f_tok = toks(focus)
c_tok = toks(current)

if is_placeholder or not f_tok:
    overlap = 1.0
else:
    overlap = (len(f_tok & c_tok) / len(f_tok)) if f_tok else 1.0

# load prev state
prev = {"age_ticks": 0}
if STATE.exists():
    try:
        prev = json.loads(STATE.read_text())
    except Exception:
        pass

if is_placeholder or overlap >= OVERLAP_THRESHOLD:
    age_ticks = 0
else:
    age_ticks = int(prev.get("age_ticks", 0)) + 1

if age_ticks == 0:
    state = "aligned"
elif age_ticks < THRESHOLD_TICKS:
    state = "detour"
else:
    state = "drift"

# persist
try:
    STATE.parent.mkdir(parents=True, exist_ok=True)
    STATE.write_text(json.dumps({"age_ticks": age_ticks, "last_overlap": overlap}))
except Exception:
    pass

print(json.dumps({
    "state":     state,
    "age_ticks": age_ticks,
    "focus":     focus[:100],
    "current":   current[:140],
    "overlap":   round(overlap, 2),
    "now":       datetime.now().strftime("%H:%M"),
}))
PY
