#!/usr/bin/env bash
# Emits JSON for deck.widget. Read-only operator deck — files, repos, inbox, insights.
exec python3 - <<'PY'
import json, os, subprocess, time
from pathlib import Path
from datetime import datetime, timezone

HOME = Path.home()
HOT_DIRS = [HOME / "Durante", HOME / "dotfiles", HOME / ".claude"]

# Repo list comes from the canonical DOS project registry (.dos-projects.json)
# instead of a hardcoded list that drifts. Deprecated projects are skipped;
# the three always-relevant roots stay as the fallback when the registry is
# missing or unparseable.
BASE_REPOS = [HOME / "Durante", HOME / "dotfiles", HOME / ".claude"]

def registry_repos():
    reg_candidates = [
        HOME / "Durante" / "Tools" / ".dos-projects.json",
        HOME / "Durante" / ".dos-projects.json",
    ]
    out = []
    for reg in reg_candidates:
        if not reg.exists():
            continue
        try:
            data = json.loads(reg.read_text())
        except Exception:
            return []
        for p in data.get("projects", []):
            if p.get("deprecated"):
                continue
            root = p.get("root_path", "")
            if not root:
                continue
            out.append(Path(root.replace("~", str(HOME), 1)))
        break
    return out

REPO_PATHS = list(dict.fromkeys(BASE_REPOS + registry_repos()))
EXTS = {".md", ".ts", ".tsx", ".jsx", ".lua", ".py", ".sh", ".toml", ".yaml", ".yml"}
EXCLUDE_PARTS = {"node_modules", ".git", ".venv", "dist", "build", ".next", "target",
                 "shell-snapshots", "STATE", "todos", "intel-context-cache",
                 "intel-context-fired", "transcripts", "ack-state"}
EXCLUDE_NAMES = {"session-name-cache.sh"}

now = time.time()

def age_str(ts):
    d = now - ts
    if d < 60:    return f"{int(d)}s"
    if d < 3600:  return f"{int(d/60)}m"
    if d < 86400: return f"{int(d/3600)}h"
    return f"{int(d/86400)}d"

def short(p: Path):
    s = str(p)
    h = str(HOME)
    if s.startswith(h):
        s = "~" + s[len(h):]
    return s

# ── HOT FILES ──────────────────────────────────────────────
hits = []
cutoff = now - 86400  # 24h window
for root in HOT_DIRS:
    if not root.exists(): continue
    for path, dirs, files in os.walk(root):
        dirs[:] = [d for d in dirs if d not in EXCLUDE_PARTS and not d.startswith(".") or d == ".claude"]
        for f in files:
            if f in EXCLUDE_NAMES: continue
            if not any(f.endswith(e) for e in EXTS): continue
            fp = Path(path) / f
            try:
                mt = fp.stat().st_mtime
            except OSError:
                continue
            if mt < cutoff: continue
            hits.append((mt, fp))

hits.sort(reverse=True)
hot_files = []
for mt, fp in hits[:6]:
    hot_files.append({
        "path": short(fp),
        "name": fp.name,
        "age":  age_str(mt),
    })

# ── REPOS ──────────────────────────────────────────────────
def gx(repo, *args, timeout=2):
    try:
        out = subprocess.run(
            ["git", "-C", str(repo), *args],
            capture_output=True, text=True, timeout=timeout
        )
        return out.stdout.strip() if out.returncode == 0 else ""
    except Exception:
        return ""

repos = []
for r in REPO_PATHS:
    if not (r / ".git").exists(): continue
    branch = gx(r, "symbolic-ref", "--short", "HEAD") or "(detached)"
    porcelain = gx(r, "status", "--porcelain")
    dirty = len([ln for ln in porcelain.splitlines() if ln.strip()])
    last_ct = gx(r, "log", "-1", "--format=%ct")
    try:
        last = int(last_ct) if last_ct else 0
    except ValueError:
        last = 0
    repos.append({
        "name":   r.name,
        "branch": branch,
        "dirty":  dirty,
        "age":    age_str(last) if last else "?",
        "last":   last,
    })

repos.sort(key=lambda x: x["last"], reverse=True)
repos = repos[:4]

# ── INBOX ──────────────────────────────────────────────────
state = HOME / ".claude" / "MEMORY" / "STATE"
corrections = len(list(state.glob("correction-queue-*.json"))) if state.exists() else 0

today = datetime.now().strftime("%Y-%m-%d")
fail_root = HOME / ".claude" / "MEMORY" / "LEARNING" / "FAILURES"
failures_today = 0
if fail_root.exists():
    for d in fail_root.rglob(f"{today}*"):
        if d.is_dir():
            failures_today += 1

# ── LAST INSIGHT ───────────────────────────────────────────
refl = HOME / ".claude" / "MEMORY" / "LEARNING" / "REFLECTIONS" / "algorithm-reflections.jsonl"
last_q1 = ""
last_task = ""
if refl.exists():
    try:
        with refl.open("rb") as fh:
            fh.seek(0, 2)
            size = fh.tell()
            chunk = 4096
            while size > 0:
                step = min(chunk, size)
                size -= step
                fh.seek(size)
                buf = fh.read(step)
                if b"\n" in buf and size > 0:
                    pass
            fh.seek(max(0, fh.tell() - 8192))
            tail = fh.read().decode("utf-8", "ignore")
        lines = [ln for ln in tail.strip().splitlines() if ln.startswith("{")]
        if lines:
            j = json.loads(lines[-1])
            last_q1 = (j.get("reflection_q1") or "").strip()
            last_task = (j.get("task_description") or "").strip()
    except Exception:
        pass

def trunc(s, n):
    s = (s or "").replace("\n", " ").strip()
    return s if len(s) <= n else s[:n-1] + "…"

print(json.dumps({
    "hot_files":      hot_files,
    "repos":          repos,
    "inbox": {
        "corrections":     corrections,
        "failures_today":  failures_today,
    },
    "last_insight": {
        "task": trunc(last_task, 60),
        "q1":   trunc(last_q1, 110),
    },
    "now": datetime.now().strftime("%H:%M"),
}))
PY
