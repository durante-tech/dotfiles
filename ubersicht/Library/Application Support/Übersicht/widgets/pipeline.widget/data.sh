#!/usr/bin/env bash
# pipeline.widget data source — DuranteOS SDLC spine panel.
# Emits EXACTLY one JSON object and exits 0 on every path.
# Stages: work (work.json) · prs (gh, cached) · sync (pull-hold.json)
#         deploy (fleet-board.md DEPLOY LINE row) · release (version.json)
exec python3 - <<'PY'
import json, os, re, subprocess, sys
from pathlib import Path
from datetime import datetime, timezone

HOME = Path.home()
GH = "/opt/homebrew/bin/gh"  # MUST be absolute — Übersicht LaunchAgent PATH is /usr/bin:/bin only
CACHE = HOME / ".claude" / "MEMORY" / "STATE" / "pipeline-widget-cache.json"
REPOS = [
    ("dos", "durante-tech/dos"),
    ("cc-studio", "durante-tech/cc-durante-studio"),
    ("dos-studio", "durante-tech/dos-studio"),
]
FAIL_CONCLUSIONS = {"FAILURE", "TIMED_OUT", "CANCELLED", "ACTION_REQUIRED", "ERROR", "STARTUP_FAILURE"}
SUMMARIZER_PREFIXES = (
    "You are summarizing",
    "You are a memory consolidation",
    "Apply maximum non-destructive compression",
)

NOW = datetime.now(timezone.utc)

def parse_iso(ts):
    try:
        dt = datetime.fromisoformat(str(ts).replace("Z", "+00:00"))
        if dt.tzinfo is None:
            dt = dt.replace(tzinfo=timezone.utc)
        return dt
    except Exception:
        return None

def age_str(ts):
    dt = parse_iso(ts) if not isinstance(ts, datetime) else ts
    if dt is None:
        return "?"
    secs = (NOW - dt).total_seconds()
    if secs < 0:
        secs = 0
    if secs < 60:
        return f"{int(secs)}s"
    if secs < 3600:
        return f"{int(secs // 60)}m"
    if secs < 86400:
        return f"{int(secs // 3600)}h"
    return f"{int(secs // 86400)}d"

def trunc(s, n=64):
    s = (s or "").strip().replace("\n", " ")
    return s if len(s) <= n else s[: n - 1] + "…"

# ── work ────────────────────────────────────────────────────────────────────
def stage_work():
    path = HOME / ".claude" / "MEMORY" / "STATE" / "work.json"
    sessions = json.loads(path.read_text()).get("sessions", {})
    kept, hidden = [], 0
    for s in sessions.values():
        task = (s.get("task") or "").strip()
        excluded = s.get("mode") == "native" or (
            s.get("phase") == "starting" and task.startswith(SUMMARIZER_PREFIXES)
        )
        if excluded:
            if s.get("phase") != "complete":
                hidden += 1
            continue
        if s.get("phase") == "complete":
            continue
        kept.append(s)
    kept.sort(key=lambda s: s.get("updatedAt") or s.get("started") or "", reverse=True)
    return {
        "items": [
            {
                "phase": s.get("phase", "?"),
                "progress": s.get("progress", "?"),
                "task": trunc(s.get("task")),
                "age": age_str(s.get("updatedAt") or s.get("started")),
            }
            for s in kept[:4]
        ],
        "total_active": len(kept),
        "hidden": hidden,
    }

# ── prs ─────────────────────────────────────────────────────────────────────
def read_pr_cache():
    try:
        cached = json.loads(CACHE.read_text())
        prs = cached.get("prs")
        if isinstance(prs, dict):
            prs["state"] = "offline-cached"
            prs["cache_age"] = age_str(cached.get("written_at"))
            return prs
    except Exception:
        pass
    return None

def stage_prs():
    if not os.access(GH, os.X_OK):
        return {"state": "gh-missing", "cache_age": None, "repos": []}
    repos_out, auth_hint = [], False
    for name, slug in REPOS:
        try:
            proc = subprocess.run(
                [GH, "pr", "list", "--repo", slug, "--state", "open",
                 "--json", "number,isDraft,statusCheckRollup", "--limit", "30"],
                capture_output=True, text=True, timeout=15,
            )
        except Exception:
            proc = None
        if proc is None or proc.returncode != 0:
            err = (proc.stderr if proc else "").lower()
            if any(t in err for t in ("auth", "401", "credential", "token")):
                auth_hint = True
            cached = read_pr_cache()
            if auth_hint:
                return {"state": "gh-unauth", "cache_age": None, "repos": []}
            if cached:
                return cached
            return {"state": "offline-cached", "cache_age": None, "repos": []}
        try:
            prs = json.loads(proc.stdout or "[]")
        except Exception:
            prs = []
        failing = green = draft = 0
        for pr in prs:
            rollup = pr.get("statusCheckRollup") or []
            is_fail = any(
                (item.get("conclusion") or item.get("state") or "").upper() in FAIL_CONCLUSIONS
                for item in rollup
            )
            is_draft = bool(pr.get("isDraft"))
            if is_fail:
                failing += 1
            if is_draft:
                draft += 1
            if not is_draft and not is_fail:
                green += 1
        repos_out.append({"name": name, "open": len(prs), "failing": failing,
                          "green": green, "draft": draft})
    result = {"state": "ok", "cache_age": None, "repos": repos_out}
    try:
        CACHE.parent.mkdir(parents=True, exist_ok=True)
        CACHE.write_text(json.dumps({"written_at": NOW.isoformat(), "prs": result}))
    except Exception:
        pass
    return result

# ── sync ────────────────────────────────────────────────────────────────────
def stage_sync():
    path = HOME / "Durante" / "MEMORY" / "STATE" / "pull-hold.json"
    data = json.loads(path.read_text())
    repos = data["repos"]
    parent, sub = repos["parent"], repos["submodule"]
    return {
        "state": "ok",
        "age": age_str(data.get("generated_at")),
        "parent": {"behind": parent.get("behind", 0), "status": parent.get("status", "?")},
        "submodule": {
            "behind": sub.get("behind", 0),
            "status": sub.get("status", "?"),
            "colliders": len(sub.get("colliders") or []),
        },
    }

# ── deploy ──────────────────────────────────────────────────────────────────
def stage_deploy():
    path = HOME / "Durante" / "MEMORY" / "STATE" / "fleet-board.md"
    line = None
    for ln in path.read_text().splitlines():
        if ln.startswith("| DEPLOY LINE"):
            line = ln
            break
    if line is None:
        return {"state": "unparseable", "age": None}
    # UNMANNED contains MANNED — check UNMANNED first, word-boundary only.
    if re.search(r"\bUNMANNED\b", line):
        state = "unmanned"
    elif re.search(r"\bMANNED\b", line):
        state = "manned"
    else:
        return {"state": "unparseable", "age": None}
    stamps = re.findall(r"\d{4}-\d{2}-\d{2}T\d{2}:\d{2}", line)
    return {"state": state, "age": age_str(stamps[-1]) if stamps else None}

# ── release ─────────────────────────────────────────────────────────────────
def stage_release():
    data = json.loads((HOME / ".claude" / "version.json").read_text())
    return {"dos": data.get("dos", "?"), "algorithm": data.get("algorithm", "?")}

# ── assemble — one failed source never kills the JSON ───────────────────────
out = {}
try:
    out["work"] = stage_work()
except Exception as e:
    out["work"] = {"items": [], "total_active": 0, "hidden": 0, "error": str(e)[:80]}
try:
    out["prs"] = stage_prs()
except Exception as e:
    out["prs"] = {"state": "offline-cached", "cache_age": None, "repos": [], "error": str(e)[:80]}
try:
    out["sync"] = stage_sync()
except Exception:
    out["sync"] = {"state": "absent", "age": "?",
                   "parent": {"behind": 0, "status": "?"},
                   "submodule": {"behind": 0, "status": "?", "colliders": 0}}
try:
    out["deploy"] = stage_deploy()
except Exception:
    out["deploy"] = {"state": "unparseable", "age": None}
try:
    out["release"] = stage_release()
except Exception:
    out["release"] = {"dos": "?", "algorithm": "?"}
out["now"] = NOW.astimezone().strftime("%H:%M")

print(json.dumps(out))
sys.exit(0)
PY
