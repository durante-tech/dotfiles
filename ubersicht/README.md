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


- **attention.widget** — the prioritized action queue: failing CI checks,
  pending fleet decisions (`fleet-decisions.jsonl` requested-without-resolved),
  stuck PRDs (verify >24h, build 0-progress >12h, stale >7d), DLQ backlog
  (`MEMORY/*/.pending` + `.quarantine`), CI-green PRs *queued for the deploy
  line* (informational — merges belong to the deploy-line session, never to a
  widget prompt), corrections queue. Empty state renders an explicit CLEAR.
- **deck.widget** — working set: hot files + repo status; repo list comes from
  the canonical `~/Durante/Tools/.dos-projects.json` registry (deprecated
  entries skipped) instead of a hardcoded list.

Retired (absorbed by attention): `mempalace.widget` (session counts),
`aging-watch.widget` (stuck-work rows), `decisions.widget` (recent decisions).

Removed 2026-08-22 when DuranteOS was retired — all four read data directories
that no longer exist, so each rendered a permanent empty or error tile:
`dailybrief.widget` and `today-focus.widget` (read `~/Durante/MEMORY/WORK/`),
`brief-trigger.widget` (clicked a launchd service that is gone), and
`q3-thread.widget` (read the removed reflections journal). `pipeline.widget`
followed for the same reason — it read `~/.claude/MEMORY/STATE/work.json`, which
went with the DOS removal, so it rendered its error branch permanently.

## Layout lanes (2026-07 UX pass, 2560×1440 logical)

Every panel owns a lane; variable-height panels are capped or bottom-anchored
so they can never grow into a neighbor:

| Lane | Widget | Anchor |
|---|---|---|
| Left 2 | memory-tide (sparkline) | `top:560 left:60` |
| Left 3 | attention (max 4 rows, detail on top 2) | `top:720 left:60 w:540` |
| Center-right-bottom | deck | `bottom:60 left:1160 w:540` |

The Left 4, Center, Center-bottom and Right-bottom lanes were freed by the
2026-08-22 widget removal above; the lanes that remain are unchanged.

### Built-in-display widgets (NOT dashboard lanes)

`scripts/scripts/ubersicht-screen-sync.sh` pins these three to the built-in
Retina panel with `showOnMainScreen` — its `BUILTIN_WIDGETS` list is the source
of truth, and the live `WidgetSettings.json` agrees. Their CSS coordinates are
therefore against the 1728-wide built-in display, **not** the 2560px dashboard
above. `focus` used to be listed in the lane table, which sent anyone
re-anchoring it to the wrong screen width:

| Widget | Anchor |
|---|---|
| clock | `top:80 left:50%` (centered) |
| focus (intention mantra) | `top:80 left:640 max-w:380` |
| drift-warden (10px dot) | `top:76 left:1015` |

## Daily nano-banana wallpaper

> **Retired 2026-08-22.** `~/Durante/Packs/Agents/DailyBrief` no longer exists,
> so nothing below runs. Kept as a record of what the wallpaper hook did.

The DailyBrief agent (`~/Durante/Packs/Agents/DailyBrief`) generated one
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
why wallpaper rotation was invisible. `wallpaper-rotate.sh` also folds the
daily piece into its band pools for the no-fresh-daily fallback path.

Widget-own state/cache files live in `~/.claude/MEMORY/STATE/`
(`attention-widget-cache.json`,
`drift-warden-state.json`) — widgets write nothing else.
