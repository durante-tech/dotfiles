# Post-pull upgrade prompt

This file is the prompt template that `smart-pull.sh` injects into a Claude
Code session after a `git pull`. The wrapper substitutes the `__COMMIT_RANGE__`,
`__CHANGED_FILES__`, and `__DIFFSTAT__` placeholders with real values from the
pull.

If you're a human reading this — this isn't meant for you. Read `UPGRADE.md`
instead. This file is consumed by `smart-pull.sh`.

---

## PROMPT (everything below this line)

I just ran `git pull` in `~/dotfiles`. The commit range is `__COMMIT_RANGE__`.

Your job is to intelligently bring my dev environment back in sync with the
new state of this repo. The canonical playbook is at `docs/UPGRADE.md` — read
it once for the standard post-pull checklist.

**Changed files in this pull:**

```
__CHANGED_FILES__
```

**Diff stat:**

```
__DIFFSTAT__
```

---

### What I want you to do — in this order

1. **Read `docs/UPGRADE.md`** (the post-pull playbook) and `docs/PERSONALIZE.md`
   (the machine-specific values catalog). These tell you what reloads
   automatically vs needs a manual nudge, and what's user-specific.

2. **Read each commit message in the range above** (`git log --format=%B __COMMIT_RANGE__`)
   to understand intent — sometimes the commit body says "after this, run X".

3. **Classify the changes** into these buckets:
   - **Brewfile changed** → I need to run `./update.sh` (which now runs
     `brew bundle install` in §3.5 — picks up new brews like gptcommit/osv-scanner).
   - **Brews REMOVED from Brewfile** → check `UPGRADE.md` "Removing tools
     retired in recent commits". If something was removed (like fnm/pyenv),
     surface the `brew uninstall ...` command and ask me if I want to run it.
   - **Hardware-related files changed** (`bd-*.sh`, `aerospace.toml` monitor
     pinning, `personalize.sh`) → suggest `./personalize.sh --recheck` if my
     `~/.config/dotfiles/personal.env` is stale or missing.
   - **Config that auto-reloads** (`karabiner.json`, `sketchybar/*`) → note that
     they reload automatically; no action needed.
   - **Config that needs manual reload** (`aerospace.toml`, `.zshrc`/`.zprofile`,
     Tmux, LaunchAgent plists) → tell me the exact reload command per the
     UPGRADE.md table.
   - **New Neovim plugin** (new file in `nvim/.config/nvim/lua/sethy/plugins/`)
     → tell me to run `:Lazy sync` in Neovim; warn if it needs a build step
     (e.g. avante.nvim's `make`).
   - **New required env var** (API key, etc.) → check the diff for new
     references to `ANTHROPIC_API_KEY`, `OPENAI_API_KEY`, or similar. If a
     new one was added, tell me to set it in `~/.zshrc.local`.

4. **Run `./update.sh`** to do the safe deterministic work (Brewfile install,
   stow, mise install, plugin sync). Report any failures.

5. **Surface a Post-Pull Checklist** as a markdown table with these columns:
   - Action
   - Why (which commit triggered it)
   - Command to run
   - Whether you can run it for me (read-only / safe / destructive)

6. **Ask me** ONLY about decisions you can't make safely on your own:
   - Hardware-specific values (only if `personal.env` is missing or stale)
   - Destructive cleanup (uninstalling tools, removing data dirs)
   - New env vars that need real values (API keys)
   - Anything ambiguous in the commit messages

### What I do NOT want

- Don't run destructive commands (`brew uninstall`, `rm -rf`) without asking.
- Don't commit or push anything — this is a one-way sync from upstream.
- Don't lecture me about the playbook — execute it.
- Don't redo work that's already idempotent (e.g. re-stowing if stow says
  "already linked").
- Don't open files I don't need to read — work from the diff.

### When you're done

Summarize in 3-5 bullets:
- What you ran successfully
- What you asked me about
- What still needs my hands (manual reloads, GUI app permissions, etc.)
- What you intentionally skipped and why

If everything was a no-op (pull was empty or trivial), say so in one line.
