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

Widget-own state/cache files live in `~/.claude/MEMORY/STATE/`
(`pipeline-widget-cache.json`, `attention-widget-cache.json`,
`drift-warden-state.json`) — widgets write nothing else.
