#!/usr/bin/env bash
# decisions.widget/data.sh — surfaces recent strategic decisions captured to MemPalace.
# Reads ## Decisions sections from MEMORY/WORK/*/PRD.md files modified in last 7 days,
# extracts first decision bullet per PRD, returns 3-5 most recent.
exec python3 - <<'PY'
import json, os, re, sys
from pathlib import Path
from datetime import datetime, timedelta

HOME = Path.home()
WORK_DIRS = [
    HOME / ".claude" / "MEMORY" / "WORK",
    HOME / "Durante" / "MEMORY" / "WORK",
]
LOOKBACK_DAYS = 7
MAX_DECISIONS = 4

now_ts = datetime.now().timestamp()
cutoff = now_ts - (LOOKBACK_DAYS * 86400)

# Collect PRDs modified in lookback window
prds = []
for root in WORK_DIRS:
    if not root.exists(): continue
    for prd in root.rglob("PRD.md"):
        try:
            mt = prd.stat().st_mtime
        except OSError:
            continue
        if mt < cutoff: continue
        prds.append((mt, prd))

prds.sort(reverse=True)

def parse_decisions(path):
    """Extract bullets under ## Decisions section. Returns list of (text, source_slug)."""
    try:
        text = path.read_text(encoding="utf-8", errors="ignore")
    except Exception:
        return []
    # locate ## Decisions section
    m = re.search(r"^##\s+Decisions\s*$([\s\S]*?)(?=^##\s+|\Z)", text, re.MULTILINE)
    if not m:
        return []
    body = m.group(1)
    # extract bullets — `- ` or `* ` or numbered
    bullets = []
    for ln in body.splitlines():
        s = ln.strip()
        if not s: continue
        if s.startswith("- "):
            bullets.append(s[2:].strip())
        elif s.startswith("* "):
            bullets.append(s[2:].strip())
        elif re.match(r"^\d+\.\s", s):
            bullets.append(re.sub(r"^\d+\.\s+", "", s).strip())
        elif s.startswith("(populated"):
            return []  # unfilled placeholder
    return bullets

def strip_md(s):
    s = re.sub(r"\*\*(.+?)\*\*", r"\1", s)
    s = re.sub(r"`([^`]+)`",     r"\1", s)
    s = re.sub(r"\*(.+?)\*",     r"\1", s)
    return s.strip()

def split_decision(text):
    """A decision often has a 'X — why' shape. Split for visual hierarchy."""
    # em-dash or " - " or ": "
    for sep in [" — ", " – ", " - ", ": "]:
        if sep in text:
            head, rest = text.split(sep, 1)
            return head.strip(), rest.strip()
    return text, ""

def slug_short(prd_path):
    """Convert /path/to/20260506-203702_wire-daily-brief/PRD.md → 'wire-daily-brief'."""
    parent = prd_path.parent.name
    # strip leading timestamp-like prefix
    cleaned = re.sub(r"^\d{8}-\d{6}_", "", parent)
    cleaned = re.sub(r"^\d{4}-\d{2}-\d{2}T?\d*_?", "", cleaned)
    # cap length
    if len(cleaned) > 28:
        cleaned = cleaned[:26] + "…"
    return cleaned

decisions = []
seen_titles = set()
for mt, prd in prds:
    bullets = parse_decisions(prd)
    if not bullets: continue
    # take top 1 bullet from this PRD (most important)
    raw = bullets[0]
    cleaned = strip_md(raw)
    if not cleaned: continue
    head, why = split_decision(cleaned)
    # dedupe by title
    if head in seen_titles: continue
    seen_titles.add(head)
    decisions.append({
        "title":  head[:90],
        "why":    why[:160],
        "source": slug_short(prd),
        "ts":     mt,
    })
    if len(decisions) >= MAX_DECISIONS: break

state = "fresh" if decisions else "empty"

print(json.dumps({
    "state":     state,
    "decisions": decisions,
    "count":     len(decisions),
    "lookback":  LOOKBACK_DAYS,
    "now":       datetime.now().strftime("%H:%M"),
}))
PY
