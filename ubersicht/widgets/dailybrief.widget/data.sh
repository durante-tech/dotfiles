#!/usr/bin/env bash
# dailybrief/data.sh — emits JSON for the dailybrief.widget.
# Reads today's brief from ~/Durante/MEMORY/WORK/dailybrief-YYYY-MM-DD.md
# (falls back to most-recent if today's hasn't been generated yet).
exec python3 - <<'PY'
import json, re
from pathlib import Path
from datetime import datetime, date

HOME = Path.home()
WORK = HOME / "Durante" / "MEMORY" / "WORK"

# Always pick the most recent dailybrief-*.md by filename date.
# Agent stamps the file using UTC; widget reads local day. End-of-day edge
# case (BRT ~21:00 UTC midnight rollover) means today's filename can be
# tomorrow's UTC date — newest-by-name wins regardless.
target = None
target_date = None
candidates = sorted(WORK.glob("dailybrief-*.md"), reverse=True)
if candidates:
    target = candidates[0]
    m = re.search(r"dailybrief-(\d{4}-\d{2}-\d{2})", target.name)
    target_date = m.group(1) if m else "?"

if target is None:
    print(json.dumps({
        "state": "no-brief",
        "now": datetime.now().strftime("%H:%M"),
    }))
    raise SystemExit(0)

# 2) parse brief markdown into sections
text = ""
try:
    text = target.read_text(encoding="utf-8", errors="ignore")
except Exception as e:
    print(json.dumps({"state": "read-error", "error": str(e)[:200]}))
    raise SystemExit(0)

# strip yaml frontmatter
text = re.sub(r"^---\n.*?\n---\n", "", text, count=1, flags=re.DOTALL)

# split on H2/H3 (## or ###); keep first ~3 sections previewed
sections = []
current = None
for ln in text.splitlines():
    if ln.startswith("### ") or ln.startswith("## "):
        if current:
            sections.append(current)
        current = {"heading": ln.lstrip("#").strip(), "body": []}
    elif current is not None:
        current["body"].append(ln)
    # ignore preamble before first heading
if current:
    sections.append(current)

def is_table_row(s):
    # "| col | col |" or "|---|---|" or "| :--- | ---: |"
    if not (s.startswith("|") and s.endswith("|")): return False
    inner = s[1:-1].strip()
    return True

def strip_md(s):
    # remove **bold** and __bold__, *italic*, `code`, leading/trailing whitespace
    import re as _re
    s = _re.sub(r"\*\*(.+?)\*\*", r"\1", s)
    s = _re.sub(r"__(.+?)__",     r"\1", s)
    s = _re.sub(r"`([^`]+)`",     r"\1", s)
    return s.strip()

def trim(body, max_lines=3):
    out = []
    for ln in body:
        s = strip_md(ln)
        if not s: continue
        if s.startswith("---"): continue       # horizontal rules
        if is_table_row(s): continue           # table headers + separators
        if s.startswith("###") or s.startswith("##"): continue  # leftover sub-headings
        out.append(s)
        if len(out) >= max_lines: break
    return out

preview_sections = []
for s in sections[:5]:
    body = trim(s["body"])
    if not body: continue
    preview_sections.append({
        "heading": strip_md(s["heading"])[:60],
        "lines":   [l[:200] for l in body],
    })

# 3) freshness — staleness in days vs today
state = "fresh"
try:
    delta_days = (date.today() - date.fromisoformat(target_date)).days
except Exception:
    delta_days = -1

if delta_days < 0:
    state = "fresh"        # brief is dated tomorrow (UTC rollover at end of day BRT)
elif delta_days == 0:
    state = "fresh"
elif delta_days <= 1:
    state = "stale"
else:
    state = "very-stale"

print(json.dumps({
    "state":      state,
    "date":       target_date,
    "delta_days": delta_days,
    "path":       str(target),
    "sections":   preview_sections,
    "now":        datetime.now().strftime("%H:%M"),
}))
PY
