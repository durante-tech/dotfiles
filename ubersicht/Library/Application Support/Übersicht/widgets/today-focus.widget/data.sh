#!/usr/bin/env bash
# today-focus.widget/data.sh — emits JSON for the today-focus widget.
# Reads the SAME ~/Durante/MEMORY/WORK/dailybrief-YYYY-MM-DD.md files
# the dailybrief widget reads (newest by name). Parses ONLY the
# "Today's Focus" section and extracts numbered actions.
exec python3 - <<'PY'
import json, re
from pathlib import Path
from datetime import datetime, date

HOME = Path.home()
WORK = HOME / "Durante" / "MEMORY" / "WORK"

# Newest-by-name wins (same convention as dailybrief.widget)
target, target_date = None, None
candidates = sorted(WORK.glob("dailybrief-*.md"), reverse=True)
if candidates:
    target = candidates[0]
    m = re.search(r"dailybrief-(\d{4}-\d{2}-\d{2})", target.name)
    target_date = m.group(1) if m else "?"

if target is None:
    print(json.dumps({
        "state": "no-actions",
        "actions": [],
        "now": datetime.now().strftime("%H:%M"),
    }))
    raise SystemExit(0)

try:
    text = target.read_text(encoding="utf-8", errors="ignore")
except Exception as e:
    print(json.dumps({
        "state": "read-error",
        "error": str(e)[:200],
        "actions": [],
        "now": datetime.now().strftime("%H:%M"),
    }))
    raise SystemExit(0)

# strip yaml frontmatter
text = re.sub(r"^---\n.*?\n---\n", "", text, count=1, flags=re.DOTALL)

# Locate the "Today's Focus" section: heading match
# "## 6. Today's Focus" or "## Today's Focus" (case-insensitive)
heading_re = re.compile(r"^##\s*\d*\.?\s*today's\s+focus", re.IGNORECASE)

lines = text.splitlines()
section_start = None
for i, ln in enumerate(lines):
    if heading_re.match(ln.strip()):
        section_start = i + 1
        break

if section_start is None:
    print(json.dumps({
        "state": "no-actions",
        "date": target_date,
        "actions": [],
        "now": datetime.now().strftime("%H:%M"),
    }))
    raise SystemExit(0)

# Capture body until next H2 (## ) or end of file
body_lines = []
for ln in lines[section_start:]:
    if ln.startswith("## "):
        break
    body_lines.append(ln)

# ── Parse numbered actions ──────────────────────────────────────────────────
# Format produced by the brief generator (verified against
# dailybrief-2026-05-07.md):
#
#   **1. <Title sentence ending with period>**
#   <one paragraph of "why" prose>
#
#   **2. <Title sentence>**
#   <prose>
#
# Title = the bolded line (anything inside leading `**N. ... **`).
# Why = the contiguous non-blank prose paragraph immediately after.
def strip_md(s):
    s = re.sub(r"\*\*(.+?)\*\*", r"\1", s)
    s = re.sub(r"__(.+?)__",     r"\1", s)
    s = re.sub(r"`([^`]+)`",     r"\1", s)
    return s.strip()

# Primary: "**1. Title**". Fallbacks seen in real LLM output despite the
# prompt mandate: "**Priority 1 — Title**" (em/en dash or colon separator)
# and "1. **Title**". Try in order; first match wins per line.
action_header_res = [
    re.compile(r"^\s*\*\*\s*(?:priority\s*)?(\d+)\s*[.:—–-]\s*(.+?)\s*\*\*\s*$", re.IGNORECASE),
    re.compile(r"^\s*(\d+)\s*\.\s*\*\*\s*(.+?)\s*\*\*\s*$"),
]

def match_action_header(line):
    for rgx in action_header_res:
        m = rgx.match(line)
        if m:
            return m
    return None

actions = []
i = 0
while i < len(body_lines):
    ln = body_lines[i]
    m = match_action_header(ln)
    if not m:
        i += 1
        continue
    rank  = int(m.group(1))
    title = strip_md(m.group(2))
    # collect "why" — skip blanks until first non-blank, then take until next blank or next action header
    j = i + 1
    while j < len(body_lines) and not body_lines[j].strip():
        j += 1
    why_parts = []
    while j < len(body_lines):
        nxt = body_lines[j]
        if not nxt.strip(): break
        if match_action_header(nxt): break
        why_parts.append(strip_md(nxt))
        j += 1
    why = " ".join(why_parts).strip()
    actions.append({"rank": rank, "title": title, "why": why})
    i = j

# ── source_tag heuristic — first match wins ────────────────────────────────
# Scan title + why for known patterns and tag the action.
TAG_PATTERNS = [
    (re.compile(r"\bRFC[-\s]?(\d{3,4})\b", re.IGNORECASE),  lambda m: f"RFC-{m.group(1).zfill(4)}"),
    (re.compile(r"\bpost[-\s]?mortem\b", re.IGNORECASE),    lambda m: "POST-MORTEM"),
    (re.compile(r"\bVERIFY\b"),                             lambda m: "VERIFY-stuck"),
    (re.compile(r"\bkill\b", re.IGNORECASE),                lambda m: "KILL"),
    (re.compile(r"\bdefer(?:red|ral)?\b", re.IGNORECASE),   lambda m: "DEFER"),
    (re.compile(r"\bcleanup\b|\bclean[-\s]up\b", re.IGNORECASE), lambda m: "CLEANUP"),
    (re.compile(r"\bcorrection\b", re.IGNORECASE),          lambda m: "CORRECTION"),
    (re.compile(r"\bmemory\b", re.IGNORECASE),              lambda m: "MEMORY"),
    (re.compile(r"\bKG\b|\bknowledge\s+graph\b", re.IGNORECASE), lambda m: "KG"),
    (re.compile(r"\bsprint\b", re.IGNORECASE),              lambda m: "SPRINT"),
    (re.compile(r"\bhook\b", re.IGNORECASE),                lambda m: "HOOK"),
]

for a in actions:
    blob = f"{a['title']} {a['why']}"
    a["tag"] = None
    for rgx, fmt in TAG_PATTERNS:
        m = rgx.search(blob)
        if m:
            a["tag"] = fmt(m)
            break

# Take first 3 only
actions = actions[:3]

# Compute delta_days for header age display
try:
    delta_days = (date.today() - date.fromisoformat(target_date)).days
except Exception:
    delta_days = -1

state = "fresh" if delta_days <= 0 else ("stale" if delta_days <= 1 else "very-stale")
if not actions:
    state = "no-actions"

print(json.dumps({
    "state":      state,
    "date":       target_date,
    "delta_days": delta_days,
    "actions":    actions,
    "now":        datetime.now().strftime("%H:%M"),
}))
PY
