# Upgrading an existing clone

You already have `~/dotfiles` cloned and stowed. This walks the post-pull steps
so a `git pull` actually takes effect across all the tools that don't auto-reload.

## The one-shot upgrade

Two paths — pick the one that matches how you work. Both end up at the same place.

### Path A — Just pull (recommended)

```bash
cd ~/dotfiles && git pull
```

That's it. The `post-merge` hook (activated automatically by `install.sh`)
prints a copy-pasteable upgrade prompt to your terminal:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  DOS upgrade prompt for <commit-range>
  Copy everything between the two ┄┄┄ lines and paste into Claude/DOS.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
┄┄┄ PROMPT START ┄┄┄
I just ran `git pull` in `~/dotfiles`. The commit range is ...
... (full prompt with file list + diffstat) ...
┄┄┄ PROMPT END ┄┄┄
```

Select the text between the `┄┄┄` lines, paste into your **already-open
Claude / DOS session** (your choice of mode, agents, context). The prompt
instructs Claude to read this doc, classify the changes, run `./update.sh`
for you, surface a checklist, and ask only about decisions it can't safely
make on its own (hardware-specific values, destructive cleanup, API keys).

**Disable per-pull:** `git -c core.hooksPath=/dev/null pull`.
**Disable permanently:** `git -C ~/dotfiles config --unset core.hooksPath`.
**Customize the prompt:** edit [`docs/POSTPULL_PROMPT.md`](POSTPULL_PROMPT.md).

### Path B — Deterministic only (no AI)

```bash
cd ~/dotfiles && git pull && ./update.sh
```

Skip the AI entirely. `update.sh` does the deterministic work (brew bundle,
stow, plugin sync). Read the rest of this doc for the manual-reload table.
The hook still prints the prompt — just ignore it.

### Path C — Auto-open Claude (power user)

```bash
cd ~/dotfiles && ./smart-pull.sh
```

Pulls AND spawns a fresh Claude Code session with the prompt pre-filled.
Useful if you don't have a Claude session already open. Caveat: starts a
brand-new session (no carried-over context). Most of the time Path A is
nicer because you keep your context.

## What needs manual attention after a pull

Most tools watch their config file and reload automatically. The ones that do
not (and why):

| Tool | Auto-reloads? | If you need to force it |
|------|---------------|------------------------|
| Karabiner-Elements | ✅ Yes (watches `~/.config/karabiner/karabiner.json`) | — |
| Sketchybar | ✅ Yes on file change | `sketchybar --reload` |
| Stow symlinks | ✅ Idempotent | `stow -R -t ~ <package>` after a package adds new files |
| **Zsh** | ❌ Per-shell | `exec zsh` or open a new terminal — `~/.zshrc` is evaluated at shell start, not on file change |
| **AeroSpace** | ❌ | `aerospace reload-config` |
| **Neovim plugins** | ❌ (Lazy.nvim is lazy by design) | Inside nvim: `:Lazy sync` to install/update plugins; some (e.g. avante.nvim) compile native code on first sync |
| **Tmux** | ❌ Per-session | Inside tmux: `<prefix>r` to reload config; restart tmux for plugin changes |
| **Stream Deck profile** | ❌ | Re-run `bun ~/dotfiles/scripts/scripts/streamdeck-build.ts <src> <dst>` and `open <dst>` to re-import |
| **launchd plists** | ❌ Per-plist | `launchctl unload ~/Library/LaunchAgents/com.lucas.X.plist; launchctl load ~/Library/LaunchAgents/com.lucas.X.plist` |

## Watch-list per recent commit

When you pull and the changelog mentions one of these, do the matching step:

- **Brewfile changed** → already covered by `./update.sh`. Standalone: `brew bundle install --file=~/dotfiles/Brewfile --no-lock`.
- **`mise` version-manager changes** → `mise install` (per project) or `mise use -g <tool>@<version>` (global).
- **New Neovim plugin** → `:Lazy sync` inside nvim. For plugins with a `build` step (avante.nvim's `make`), wait for the build to complete.
- **AeroSpace binding or workspace map changed** → `aerospace reload-config`.
- **Karabiner Hyper rule added** → no action; Karabiner Elements watches the file and reloads on save.
- **Sketchybar plugin added or VIS map changed** → `sketchybar --reload`.
- **`bd-apply.sh` or BetterDisplay plist changed** → `launchctl unload && launchctl load` the affected plist. The wake handler (sleepwatcher) picks up changes automatically.
- **Stream Deck profile generator (`streamdeck-build.ts`) changed** → rebuild + re-import the profile (see table above).

## Removing tools retired in recent commits

`brew bundle` is **additive** — it installs what's in the Brewfile but never
uninstalls what was removed. After a pull that drops tools, clean them up
explicitly:

### Migration 2026-05-27: mise replaces fnm + pyenv

```bash
brew uninstall fnm pyenv
rm -rf ~/.fnm ~/.pyenv         # remove orphan data dirs (~150 MB)
```

mise already manages your node + python versions; nothing else to do.

### Nuclear option (use only if you trust the Brewfile as source of truth)

`brew bundle cleanup --force --file=~/dotfiles/Brewfile` will uninstall
**anything** on your system that's not in the Brewfile. This is destructive —
it will catch tools you installed manually outside the Brewfile (cli-foo,
experimental kegs, etc.). Always run without `--force` first to see the diff:

```bash
brew bundle cleanup --file=~/dotfiles/Brewfile      # dry-run, prints what would go
brew bundle cleanup --force --file=~/dotfiles/Brewfile   # actually removes
```

## API keys (only if you haven't already)

Export in `~/.zshrc.local` (not tracked in git):

```bash
export ANTHROPIC_API_KEY="sk-ant-..."   # avante.nvim
export OPENAI_API_KEY="sk-..."          # gptcommit + opencode
```

## Sanity check after upgrade

```bash
~/dotfiles/update.sh --dry-run             # see what would change
sketchybar --query bar | head              # confirm bar is responsive
aerospace list-workspaces --all            # confirm workspaces match aerospace.toml
zsh -i -c 'type bd-day bd-stream'          # confirm shell aliases load
```

## When something genuinely breaks

1. `git -C ~/dotfiles log --oneline -10` — what just changed
2. `git -C ~/dotfiles diff HEAD~1 -- <suspect-file>` — what specifically
3. `git -C ~/dotfiles checkout HEAD~1 -- <suspect-file>` then re-stow if needed — temporary rollback to the previous version
4. Open an issue or commit a fix; never `git push --force` to main
