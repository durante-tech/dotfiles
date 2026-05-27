# Personalizing your clone

This repo ships with the maintainer's (Lucas's) defaults. About 95% of it is
shareable as-is, but a handful of values are **machine-specific** — your monitors,
your BetterDisplay hardware IDs, your keyboard layout, your app preferences.

This doc catalogs every machine-specific value. Three ways to use it:

1. **Run `./personalize.sh`** — interactive prompt walks you through the
   common ones, writes `~/.config/dotfiles/personal.env`, regenerates affected
   configs. Recommended for new clones.

2. **Edit `~/.config/dotfiles/personal.env` directly** — if you know your
   values and skipped the prompt. The example template is at
   [`templates/personal.env.example`](../templates/personal.env.example).

3. **Read the catalog below + edit configs directly** — for the values that
   can't be externalized to env vars (AeroSpace `.toml`, Karabiner `.json`).

---

## Layer 1 — Hardware identifiers (load-bearing)

Wrong values silently break display + monitor automation.

### Monitor names

| Where | Lucas's value | What it is |
|-------|--------------|------------|
| `aerospace.toml:117-118` | `'Built-in Retina Display'` / `'^PORTRAIT-MONITOR$'` | macOS display names AeroSpace uses for `workspace-to-monitor-force-assignment` |
| `scripts/scripts/bd-apply.sh:22-23` (comments) | DEV-MAIN / PORTRAIT-MONITOR | Human labels for the two tagIDs below |

**Discover yours:**
```bash
aerospace list-monitors                       # exact names AeroSpace sees
betterdisplaycli get --identifiers            # BetterDisplay's per-display names
```

**Override:** AeroSpace TOML has no env-var substitution. Edit
`aerospace/.config/aerospace/aerospace.toml` lines 117-124 directly and
re-stow: `stow -R -t ~ aerospace && aerospace reload-config`.

### BetterDisplay tagIDs

| Where | Lucas's value | What it is |
|-------|--------------|------------|
| `scripts/scripts/bd-apply.sh:22` | `DEV_TAG=2` | tagID for the primary (built-in) display |
| `scripts/scripts/bd-apply.sh:23` | `PORT_TAG=60` | tagID for the external (portrait/secondary) display |
| `scripts/scripts/bd-lmu-watch.sh:27` | `PORT_TAG=60` | same — for ambient-light watch |
| `scripts/scripts/bd-build-slots.sh:17-18` | `DEV=2` / `PORT=60` | same — for slot-build (legacy) |

**Discover yours:**
```bash
betterdisplaycli get --identifiers | grep -E "tagID|name"
```

**Override:** add to `~/.config/dotfiles/personal.env`:
```bash
DOTFILES_BD_DEV_TAG=2          # your built-in display tagID
DOTFILES_BD_PORT_TAG=60        # your external display tagID
```
The bd-* scripts source this file at top.

---

## Layer 2 — User identifier (cosmetic, conflict-risk)

### LaunchAgent prefix

| Where | Lucas's value | What it is |
|-------|--------------|------------|
| `launchagents/Library/LaunchAgents/com.lucas.bd-*.plist.template` | `com.lucas.bd-*` | macOS launchd label prefix |

The `.plist.template` files use `__USER__` placeholder substitution at install
time via `setup.sh render_launchagents()`. **No manual edit needed** — the
running user's `$USER` is substituted automatically. Verify after install:
`ls ~/Library/LaunchAgents/`.

---

## Layer 3 — Keyboard layout

| Where | Lucas's value | What it is |
|-------|--------------|------------|
| `aerospace/.config/aerospace/aerospace.toml:199, 204, 222, 227, 238` | PT-BR (5 bindings commented out) | `alt-e`, `alt-n`, `alt-shift-e`, `alt-shift-n` are dead-keys for Portuguese accents (´ / ~) on the macOS PT-BR layout |

If you use US/UK/DE/etc. layout, **uncomment the `# COMMENTED OUT FOR
BRAZILIAN ACCENTS` lines** to recover those bindings. They're marked
explicitly so they're easy to find with `grep "BRAZILIAN ACCENTS"`.

---

## Layer 4 — Personal app preferences

### Karabiner Hyper sublayer app launches

| Sublayer | App launched | Where to edit |
|----------|--------------|---------------|
| `Hyper+O+D` | Discord | `~/.config/karabiner/karabiner.json` — search for `Discord.app` |
| `Hyper+O+C` | Google Chrome | search `Google Chrome.app` |
| `Hyper+O+M` | Message | search `Message.app` |
| `Hyper+O+N` / `O+P` | Notion / Obsidian | search those app names |
| Other Hyper rules | WezTerm, VSCode, Music | (varies) |

**Override:** edit `~/.config/karabiner/karabiner.json` directly. Karabiner
auto-reloads on file change. Backup first; the file is large.

### AeroSpace app workspace routing

| Where | Lucas's mapping |
|-------|-----------------|
| `aerospace.toml:290+` (`[[on-window-detected]]` blocks) | Claude + Codex → A · Chrome/Safari/Firefox/Zen/Arc → B · Dia → T · ChatGPT/Perplexity/Notion/Obsidian → N · iTerm/Alacritty → T |

**Override:** edit the `if.app-id` and `run = "move-node-to-workspace X"`
lines in `aerospace.toml`. Run `aerospace reload-config` after.

---

## Layer 5 — Private / maintainer paths

These reference DOS (Durante Operating System) infrastructure that lives in
`~/Durante/`. **They no-op gracefully on machines without DOS** — the configs
read but don't fail.

| Where | What it reads |
|-------|--------------|
| `ubersicht/.../dailybrief.widget/data.sh` | `~/Durante/MEMORY/WORK/dailybrief-YYYY-MM-DD.md` |
| `ubersicht/.../today-focus.widget/data.sh` | same as above |
| `scripts/scripts/dos-stream.ts` | `~/Durante/Overlays/*.html` |
| `scripts/scripts/obs-scene-build.ts` | `~/Durante/Overlays/` |
| `scripts/scripts/streamdeck-build.ts:27` | `~/Downloads/Durante Studio/theme.css` (maintainer-private) |

**If you don't run DOS:** these widgets show blank / scripts fail silently.
That's the intended degradation. Don't try to "fix" them — they're not
meant to ship beyond the maintainer.

---

## Pre-flight checklist (new clone)

After `git clone` + `./install.sh`:

- [ ] Run `./personalize.sh` (or set `~/.config/dotfiles/personal.env` manually)
- [ ] Edit `aerospace.toml` monitor names (lines 117-124) for your displays
- [ ] If non-PT-BR keyboard: uncomment the `BRAZILIAN ACCENTS` lines in `aerospace.toml`
- [ ] Edit Karabiner `Hyper+O+*` sublayer for apps you actually use (or strip the unused ones)
- [ ] Verify LaunchAgents loaded: `ls ~/Library/LaunchAgents/com.${USER}.*`
- [ ] If you don't have a portrait monitor: comment out the `T = '^PORTRAIT-MONITOR$'` line in `aerospace.toml` (or repoint to your single display)

After every `git pull`:

- See [`UPGRADE.md`](UPGRADE.md) — the standard post-pull checklist.
- Re-run `./personalize.sh --recheck` if hardware changed (new monitor, etc.).
