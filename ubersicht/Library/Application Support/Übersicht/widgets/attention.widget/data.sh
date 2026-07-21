#!/usr/bin/env bash
# attention.widget/data.sh — DuranteOS operator action queue ("what needs me now").
# Row builders: checks-failing (gh), decision-pending (fleet-decisions.jsonl),
# work-stuck (work.json, absorbs aging-watch thresholds), dlq (.pending/.quarantine),
# ci-green-queued (gh, informational — deploy line owns merges), corrections.
# Emits ONE JSON object on every path, exit 0 always. Each builder is isolated
# in try/except so one failure never kills the JSON.
exec python3 - <<'PY'
import json, os, re, subprocess, sys
from pathlib import Path
from datetime import datetime, timezone

HOME = Path.home()
GH = "/opt/homebrew/bin/gh"  # MUST be absolute — Übersicht PATH lacks homebrew
REPOS = [
    ("durante-tech/dos", "dos"),
    ("durante-tech/cc-durante-studio", "cc"),
    ("durante-tech/dos-studio", "studio"),
]
FAILING = {"FAILURE", "TIMED_OUT", "CANCELLED", "ACTION_REQUIRED", "ERROR", "STARTUP_FAILURE"}
CACHE = HOME / ".claude" / "MEMORY" / "STATE" / "attention-widget-cache.json"
FLEET_DECISIONS = HOME / "Durante" / "MEMORY" / "STATE" / "fleet-decisions.jsonl"
WORK_JSON = HOME / ".claude" / "MEMORY" / "STATE" / "work.json"
DLQ_ROOT = HOME / "Durante" / "MEMORY"
STATE_DIR = HOME / ".claude" / "MEMORY" / "STATE"

SEV_ORDER = {"crit": 0, "warn": 1, "info": 2}

now = datetime.now(timezone.utc)

def parse_ts(s):
    if not s:
        return None
    try:
        return datetime.fromisoformat(str(s).replace("Z", "+00:00"))
    except Exception:
        return None

def age_human(seconds):
    if seconds is None:
        return ""
    s = max(0, int(seconds))
    if s < 3600:
        return f"{s // 60}m"
    if s < 86400:
        return f"{s // 3600}h"
    return f"{s // 86400}d"

def clip(s, n):
    s = (s or "").strip()
    s = re.sub(r"\s+", " ", s)
    return s if len(s) <= n else s[: n - 1].rstrip() + "…"

rows = []  # each: dict + internal _age_sec for sorting

def add_row(rtype, severity, title, detail="", age="", source="", age_sec=0.0):
    rows.append({
        "type": rtype,
        "severity": severity,
        "title": clip(title, 70),
        "detail": clip(detail, 90) if detail else "",
        "age": age,
        "source": source,
        "_age_sec": age_sec or 0.0,
    })

# ── gh: fetch open PRs across the three repos ───────────────────────────────
gh_state = "ok"
gh_age = ""
prs = None  # normalized: [{repo, number, title, isDraft, checks:[CONCLUSION,...]}]

def normalize_pr(alias, pr):
    checks = []
    for c in (pr.get("statusCheckRollup") or []):
        if not isinstance(c, dict):
            continue
        concl = (c.get("conclusion") or c.get("state") or "").upper()
        checks.append(concl)
    return {
        "repo": alias,
        "number": pr.get("number"),
        "title": pr.get("title") or "",
        "isDraft": bool(pr.get("isDraft")),
        "checks": checks,
    }

try:
    if not os.path.exists(GH):
        gh_state = "gh-missing"
    else:
        fetched = []
        err_text = ""
        ok = True
        for full, alias in REPOS:
            try:
                p = subprocess.run(
                    [GH, "pr", "list", "--repo", full, "--state", "open",
                     "--json", "number,title,isDraft,statusCheckRollup", "--limit", "30"],
                    capture_output=True, text=True, timeout=15,
                )
                if p.returncode != 0:
                    ok = False
                    err_text += (p.stderr or "")
                    break
                for pr in json.loads(p.stdout or "[]"):
                    fetched.append(normalize_pr(alias, pr))
            except Exception as e:
                ok = False
                err_text += str(e)
                break
        if ok:
            prs = fetched
            try:
                CACHE.parent.mkdir(parents=True, exist_ok=True)
                CACHE.write_text(json.dumps({
                    "fetched_at": now.isoformat(),
                    "prs": prs,
                }))
            except Exception:
                pass
        else:
            low = err_text.lower()
            if "auth" in low or "401" in low or "credential" in low or "token" in low:
                gh_state = "gh-unauth"
            else:
                gh_state = "offline-cached"
            # fall back to cache on any failure class
            try:
                cached = json.loads(CACHE.read_text())
                prs = cached.get("prs")
                cts = parse_ts(cached.get("fetched_at"))
                if cts is not None:
                    gh_age = age_human((now - cts).total_seconds())
            except Exception:
                prs = None
except Exception:
    gh_state = "offline-cached"
    prs = None

# ── 1. checks-failing (crit) ────────────────────────────────────────────────
try:
    for pr in (prs or []):
        nfail = sum(1 for c in pr["checks"] if c in FAILING)
        if nfail == 0:
            continue
        plural = "check" if nfail == 1 else "checks"
        add_row(
            "checks-failing", "crit",
            f"{pr['repo']}#{pr['number']} — {nfail} {plural} failing",
            detail=pr["title"], age="", source="gh",
        )
except Exception:
    pass

# ── 2. decision-pending (crit) ──────────────────────────────────────────────
try:
    requested = {}
    resolved = set()
    with open(FLEET_DECISIONS, encoding="utf-8", errors="ignore") as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            try:
                r = json.loads(line)
            except Exception:
                continue
            t = r.get("type")
            if t == "decision_requested":
                requested[r.get("id")] = r
            elif t == "decision_resolved":
                resolved.add(r.get("id"))
    for rid, req in requested.items():
        if rid in resolved:
            continue
        ts = parse_ts(req.get("ts"))
        age_sec = (now - ts).total_seconds() if ts else 0.0
        add_row(
            "decision-pending", "crit",
            req.get("title") or req.get("body") or "(untitled decision)",
            detail=req.get("body") or "",
            age=age_human(age_sec), source="fleet", age_sec=age_sec,
        )
except Exception:
    pass

# ── 3. work-stuck (warn) — absorbs aging-watch classification ───────────────
JUNK_PREFIXES = (
    "You are summarizing",
    "You are a memory consolidation",
    "Apply maximum non-destructive compression",
)

def parse_progress(p):
    if not isinstance(p, str):
        return (None, None)
    m = re.match(r"^\s*(\d+)\s*/\s*(\d+)\s*$", p)
    if not m:
        return (None, None)
    return (int(m.group(1)), int(m.group(2)))

try:
    raw = json.loads(WORK_JSON.read_text(encoding="utf-8", errors="ignore"))
    sessions = raw.get("sessions", {}) if isinstance(raw, dict) else {}
    for key, sess in sessions.items():
        if not isinstance(sess, dict):
            continue
        task = (sess.get("task") or "").strip()
        mode = (sess.get("mode") or "").lower()
        phase = (sess.get("phase") or "").lower()
        # junk filter FIRST
        if mode == "native":
            continue
        if phase == "starting" and task.startswith(JUNK_PREFIXES):
            continue
        if phase == "complete":
            continue
        updated = parse_ts(sess.get("updatedAt")) or parse_ts(sess.get("started"))
        if updated is None:
            continue
        age_sec = (now - updated).total_seconds()
        passed, total = parse_progress(sess.get("progress"))
        label = None
        if phase == "verify" and age_sec > 24 * 3600:
            label = "verify-stuck"
        elif phase == "build" and passed == 0 and age_sec > 12 * 3600:
            label = "build-stuck"
        elif age_sec > 7 * 86400:
            label = "stale"
        if label is None:
            continue
        t = task or (sess.get("sessionName") or "").strip() or "(unnamed)"
        t = re.sub(r"`([^`]+)`", r"\1", t)
        add_row(
            "work-stuck", "warn",
            f"PRD {clip(t, 50)} — {label} {age_human(age_sec)}",
            detail="", age=age_human(age_sec), source="work.json", age_sec=age_sec,
        )
except Exception:
    pass

# ── 4. dlq (warn; crit if total > 1000) ─────────────────────────────────────
try:
    n_pending = 0
    n_quar = 0
    if DLQ_ROOT.is_dir():
        # Quarantine buckets NEST inside .pending (MEMORY/X/.pending/.quarantine/…)
        # as well as living at MEMORY/X/.quarantine/ — classify by whether the
        # file's path passes through a .quarantine dir, never double-count.
        for sub in DLQ_ROOT.iterdir():
            if not sub.is_dir():
                continue
            for name in (".pending", ".quarantine"):
                d = sub / name
                if not d.is_dir():
                    continue
                for _root, _dirs, files in os.walk(d):
                    in_quar = ".quarantine" in Path(_root).parts
                    if in_quar:
                        n_quar += len(files)
                    else:
                        n_pending += len(files)
    total_dlq = n_pending + n_quar
    if total_dlq > 0:
        add_row(
            "dlq", "crit" if total_dlq > 1000 else "warn",
            f"DLQ backlog — {n_pending} pending · {n_quar} quarantined",
            detail="drain: Docs/Playbook/dlq-recovery.md", age="", source="dlq",
        )
except Exception:
    pass

# ── 5. ci-green-queued (info) — ONE summary row, informational only ─────────
try:
    if prs:
        n_green = sum(
            1 for pr in prs
            if not pr["isDraft"] and not any(c in FAILING for c in pr["checks"])
        )
        if n_green > 0:
            plural = "PR" if n_green == 1 else "PRs"
            add_row(
                "ci-green-queued", "info",
                f"{n_green} {plural} CI-green · queued for deploy line",
                detail="", age="", source="gh",
            )
except Exception:
    pass

# ── 6. corrections (info) ───────────────────────────────────────────────────
try:
    n_corr = len(list(STATE_DIR.glob("correction-queue-*.json")))
    if n_corr > 0:
        plural = "correction" if n_corr == 1 else "corrections"
        add_row(
            "corrections", "info",
            f"{n_corr} {plural} queued",
            detail="", age="", source="state",
        )
except Exception:
    pass

# ── sort · cap · emit ───────────────────────────────────────────────────────
rows.sort(key=lambda r: (SEV_ORDER.get(r["severity"], 3), -r["_age_sec"]))
total_count = len(rows)
top = rows[:7]
for r in top:
    r.pop("_age_sec", None)

print(json.dumps({
    "state": "clear" if total_count == 0 else "attention",
    "rows": top,
    "total_count": total_count,
    "hidden": total_count - len(top),
    "gh_state": gh_state,
    "gh_age": gh_age,
    "now": now.astimezone().strftime("%H:%M"),
}))
PY
