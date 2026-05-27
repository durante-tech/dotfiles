# Upgrading an existing clone

You already have `~/dotfiles` cloned and stowed. This walks the post-pull steps
so a `git pull` actually takes effect across all the tools that don't auto-reload.

## The one-shot upgrade

Two paths — pick the one that matches how you work.

### Path A — Deterministic (no AI required)

```bash
cd ~/dotfiles && git pull && ./update.sh
```

`update.sh` is a thin wrapper over `./install.sh --update`. It skips the slow
full reinstall, runs `brew bundle install` (idempotent), syncs Tmux + Neovim
plugins, and re-stows packages. Safe to run repeatedly. Extra flags are
forwarded — `./update.sh --dry-run` shows what would change.

This path is **complete and self-sufficient** — you don't need Claude Code or
any AI to upgrade. The rest of this doc tells you what manual reloads are
needed after `update.sh` finishes.

### Path B — DOS-orchestrated (Claude reads the diff and decides)

```bash
cd ~/dotfiles && ./smart-pull.sh
```

Does the pull, then opens an interactive Claude Code session with a prompt
that includes the commit range, changed files, and diff stat. Claude then
reads `UPGRADE.md` + `PERSONALIZE.md`, classifies the changes, runs
`./update.sh`, surfaces a post-pull checklist, and asks you only about
decisions it can't safely make on its own (hardware-specific values,
destructive cleanup, new API keys).

The prompt template is at [`docs/POSTPULL_PROMPT.md`](POSTPULL_PROMPT.md) —
edit it to tune what DOS focuses on. Useful flags:
- `./smart-pull.sh --print-prompt` — see what DOS would receive without opening a session
- `./smart-pull.sh --no-pull` — open DOS for the last 5 commits (e.g. re-process a pull you forgot to act on)

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
