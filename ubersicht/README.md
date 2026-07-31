# ubersicht — desktop widgets

Übersicht widget source lives at:
```
ubersicht/Library/Application Support/Übersicht/widgets/
```

The path mirrors `$HOME/Library/Application Support/Übersicht/widgets/` so
`stow -t ~ ubersicht` produces the symlink there.

## Stow caveat — absolute symlink required

GNU Stow creates **relative** symlinks (`../../../dotfiles/...`). Übersicht's
internal `server.js` does NOT follow relative symlinks correctly — it tries to
resolve the link target relative to its own application bundle directory, hits
a path that doesn't exist, and crashes with:

```
Error: could not find ../../../dotfiles/ubersicht/Library/Application Support/Übersicht/widgets
```

After `stow -t ~ ubersicht`, replace the relative symlink with an absolute one:

```bash
ln -sfn "$HOME/dotfiles/ubersicht/Library/Application Support/Übersicht/widgets" \
        "$HOME/Library/Application Support/Übersicht/widgets"
```

`setup.sh` should do this automatically as part of its stow pass — if you're
re-stowing manually, run the `ln -sfn` line above afterward.

## LaunchAgent

`launchagents/Library/LaunchAgents/com.lucas.ubersicht.plist.template` ensures
Übersicht starts at login so widgets survive reboots without manual app launch.

## SDLC panels (2026-07 redesign)

The Durante panels follow one trust contract: **every `data.sh` always emits
exactly one valid JSON object and exits 0** — sources degrade to explicit
states (`offline-cached`, `gh-unauth`, `absent`, `unparseable`), never to a
crash or a silently-wrong number. Homebrew binaries are invoked by absolute
path (`/opt/homebrew/bin/gh`) because Übersicht's LaunchAgent environment has
only the system PATH.

- **pipeline.widget** — the SDLC spine: real active PRDs (junk-filtered from
  `~/.claude/MEMORY/STATE/work.json`, with a visible `hidden` count) → open
  PRs + CI rollup across durante-tech/{dos, cc-durante-studio, dos-studio} →
  sync/deploy state (`~/Durante/MEMORY/STATE/pull-hold.json` + the fleet-board
  DEPLOY LINE row, minimal MANNED/UNMANNED + timestamp parse only) → release
  train (`~/.claude/version.json`).
- **attention.widget** — the prioritized action queue: failing CI checks,
  pending fleet decisions (`fleet-decisions.jsonl` requested-without-resolved),
  stuck PRDs (verify >24h, build 0-progress >12h, stale >7d), DLQ backlog
  (`MEMORY/*/.pending` + `.quarantine`), CI-green PRs *queued for the deploy
  line* (informational — merges belong to the deploy-line session, never to a
  widget prompt), corrections queue. Empty state renders an explicit CLEAR.
- **dailybrief.widget / today-focus.widget** — daily ops narrative + top-3
  actions (healthy, unchanged).
- **deck.widget** — working set: hot files + repo status; repo list comes from
  the canonical `~/Durante/Tools/.dos-projects.json` registry (deprecated
  entries skipped) instead of a hardcoded list.
- **q3-thread.widget** — one reflection lesson, weighted to low-sentiment
  runs; reads both reflection schemas (doctrine-12 `reflection_q3` and
  runtime-8 `reflection`).

Retired (absorbed by pipeline/attention): `mempalace.widget` (session counts),
`aging-watch.widget` (stuck-work rows), `decisions.widget` (recent decisions —
covered by the daily brief). Future absorption candidates: today-focus (into
dailybrief), drift-warden (as an attention row).

## Layout lanes (2026-07 UX pass, 2560×1440 logical)

Every panel owns a lane; variable-height panels are capped or bottom-anchored
so they can never grow into a neighbor:

| Lane | Widget | Anchor |
|---|---|---|
| Left 1 | pipeline | `top:70 left:60 w:540` |
| Left 2 | memory-tide (sparkline) | `top:560 left:60` |
| Left 3 | attention (max 4 rows, detail on top 2) | `top:720 left:60 w:540` |
| Left 4 | today-focus | `bottom:60 left:60 w:540` (grows upward) |
| Top-center-left | focus (intention mantra) | `top:80 left:640` |
| Center | brief-trigger ring | `top:42% left:50%` (42% keeps it clear of deck) |
| Center-bottom | dailybrief | `bottom:60 left:640 w:460` |
| Center-right-bottom | deck | `bottom:60 left:1160 w:540` |
| Right-bottom | q3-thread (mirror) | `bottom:60 left:1760 w:540` |

The old layout stacked focus + dailybrief + today-focus on the same
`bottom:60 left:60` anchor (three-way collision) and let attention run into
today-focus.

## Daily nano-banana wallpaper

The DailyBrief agent (`~/Durante/Packs/Agents/DailyBrief`) generates one
wallpaper per evening via Nano Banana Pro (Gemini, through the Studio media
gateway) into `~/Pictures/Wallpapers/daily/dailybrief-YYYY-MM-DD.png` and sets
it immediately. The prompt is grounded in the brief's **Visual Metaphor**
section — the synthesizer's one-sentence translation of the day's operational
reality (load, failures, pipeline health, commitments) into abstract visual
language. `--force-wallpaper` mints extra versioned variants on demand.

Visibility is owned by `wallpaper-workspace.sh` (AeroSpace
exec-on-workspace-change): its lookup chain now prefers a fresh (<36h) daily
piece for every workspace except `WALLPAPER_DAILY_EXCLUDE` (default `T`, the
portrait monitor — daily art is 16:9). Without that step the per-workspace
files stomped every wallpaper change on the next workspace switch, which is
why the hourly rotation was invisible. `wallpaper-rotate.sh` also folds the
daily piece into its band pools for the no-fresh-daily fallback path.

Widget-own state/cache files live in `~/.claude/MEMORY/STATE/`
(`pipeline-widget-cache.json`, `attention-widget-cache.json`,
`drift-warden-state.json`) — widgets write nothing else.
