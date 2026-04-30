# Dotfiles v2.0 — Verification Checks

**Run after installation. Each check has a pass condition + a "If this fails" repair note.**

Designed for AI agents to walk top-to-bottom. Every check is a single bash command with a deterministic exit/output the agent can parse.

---

## Critical CLI Tools (must all pass)

These are load-bearing — if any fail, basic shell features break.

```bash
for tool in zsh stow starship atuin zoxide fzf bat fd ripgrep eza nvim tmux git lazygit mise ghostty wallpaper espanso ollama gum glow ccusage gh; do
  if command -v "$tool" &>/dev/null; then
    echo "OK $tool"
  else
    echo "FAIL $tool not found"
  fi
done
```

**Pass condition:** every line starts with `OK`.

**If this fails:**
- `cd ~/dotfiles && ./install.sh` — re-runs full install (idempotent)
- `brew bundle --file=~/dotfiles/Brewfile` — re-installs from manifest
- `command -v <tool>` — confirm path resolution

---

## Shell Setup

```bash
# zsh is the active shell
[[ "$SHELL" == *zsh ]] && echo "OK zsh active" || echo "WARN default shell is $SHELL — run: chsh -s \$(which zsh)"

# Starship prompt is loaded
zsh -i -c 'echo $STARSHIP_CONFIG' 2>/dev/null | grep -q starship && echo "OK Starship loaded" || echo "FAIL Starship not initialized"

# mise activates and resolves Node + Python
zsh -i -c 'node --version && python --version' 2>&1 | grep -q "v" && echo "OK Node + Python via mise" || echo "FAIL mise not activating"

# direnv hook is wired
zsh -i -c 'type _direnv_hook' 2>&1 | grep -q "function" && echo "OK direnv hooked" || echo "FAIL direnv not hooked"

# Atuin is initialized
zsh -i -c 'type _atuin_search_widget' 2>&1 | grep -q "function" && echo "OK Atuin loaded" || echo "FAIL Atuin not loaded"
```

**If shell setup fails:**
- `source ~/.zprofile && source ~/.zshrc` — reload manually
- `cd ~/dotfiles && stow -R -t ~ zsh` — re-stow zsh package
- Open a new terminal — completion cache may need refresh

---

## Symlinks (Stow Verification)

```bash
declare -A EXPECTED_LINKS=(
  ["$HOME/.zshrc"]="zsh/.zshrc"
  ["$HOME/.zprofile"]="zsh/.zprofile"
  ["$HOME/.config/nvim"]="nvim/.config/nvim"
  ["$HOME/.config/tmux"]="tmux/.config/tmux"
  ["$HOME/.config/aerospace"]="aerospace/.config/aerospace"
  ["$HOME/.config/sketchybar"]="sketchybar/.config/sketchybar"
  ["$HOME/.config/starship"]="starship/.config/starship"
  ["$HOME/.config/mise"]="mise/.config/mise"
  ["$HOME/.config/ghostty"]="ghostty/.config/ghostty"
)

for target in "${!EXPECTED_LINKS[@]}"; do
  if [ -L "$target" ]; then
    echo "OK $target → $(readlink "$target")"
  elif [ -e "$target" ]; then
    echo "FAIL $target exists but is NOT a symlink"
  else
    echo "FAIL $target missing"
  fi
done
```

**If symlinks fail:**
- `cd ~/dotfiles && stow -R -t ~ <package>` — re-stow specific package
- `cd ~/dotfiles && ./install.sh --force-stow` — uses `--adopt` to absorb conflicts

---

## LaunchAgents (Wallpaper + Sketchybar)

```bash
# Plists were rendered (no __USER__ placeholders left)
for plist in ~/Library/LaunchAgents/com.lucas.wallpaper-rotate.plist \
             ~/Library/LaunchAgents/com.lucas.sketchybar-firstboot.plist; do
  if [ -f "$plist" ]; then
    if grep -q "__USER__" "$plist"; then
      echo "FAIL $plist still has __USER__ placeholder — setup.sh render failed"
    else
      echo "OK $plist rendered"
    fi
  else
    echo "FAIL $plist missing"
  fi
done

# Agents are loaded into launchd
launchctl list | grep -q "com.lucas.wallpaper-rotate" && \
  echo "OK wallpaper-rotate loaded" || echo "FAIL wallpaper-rotate not loaded"
launchctl list | grep -q "com.lucas.sketchybar-firstboot" && \
  echo "OK sketchybar-firstboot loaded" || echo "FAIL sketchybar-firstboot not loaded"
```

**If LaunchAgents fail:**
- `cd ~/dotfiles && ./setup.sh --configure` — re-renders + re-bootstraps both
- `launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/com.lucas.wallpaper-rotate.plist`

---

## Tmux Plugin Manager

```bash
[ -d "$HOME/.tmux/plugins/tpm" ] && \
  echo "OK TPM installed" || echo "FAIL TPM missing"

[ -d "$HOME/.tmux/plugins/vim-tmux-navigator" ] && \
  echo "OK tmux plugins installed" || echo "WARN no plugins yet — run prefix+I inside tmux"
```

**If TPM fails:**
- `git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm`
- Inside tmux: press `Ctrl+b` then `Shift+I` (capital i)

---

## Neovim

```bash
# Lazy.nvim is installed
[ -d "$HOME/.local/share/nvim/lazy/lazy.nvim" ] && \
  echo "OK Lazy.nvim installed" || echo "FAIL Lazy.nvim missing"

# Plugins are synced (count should be 60+)
PLUGIN_COUNT=$(ls "$HOME/.local/share/nvim/lazy/" 2>/dev/null | wc -l | tr -d ' ')
[ "$PLUGIN_COUNT" -gt 30 ] && \
  echo "OK $PLUGIN_COUNT Neovim plugins installed" || \
  echo "FAIL only $PLUGIN_COUNT plugins — run: nvim +Lazy! sync +qa"

# Headless start succeeds
nvim --headless +qa 2>&1 | grep -qE "error|Error" && \
  echo "FAIL Neovim has startup errors" || echo "OK Neovim starts clean"
```

**If Neovim fails:**
- `nvim +Lazy sync +qa` — full plugin sync
- `nvim +checkhealth +qa` — diagnose deeper issues
- `:Mason` inside Neovim — install missing LSP servers

---

## Espanso

```bash
espanso status 2>&1 | grep -q "is running" && \
  echo "OK Espanso running" || echo "WARN Espanso not running — needs Accessibility permission"

# Match file is symlinked from dotfiles
readlink "$HOME/Library/Application Support/espanso/match/base.yml" 2>/dev/null | \
  grep -q "dotfiles" && echo "OK base.yml symlinked from dotfiles" || \
  echo "FAIL base.yml not symlinked"

# All 5 triggers loaded (:dt :ts :sig :llm :llmf)
TRIGGER_COUNT=$(espanso match list 2>/dev/null | grep -c "^:")
[ "$TRIGGER_COUNT" -ge 5 ] && \
  echo "OK $TRIGGER_COUNT espanso triggers loaded" || \
  echo "FAIL only $TRIGGER_COUNT triggers"
```

**If Espanso fails:**
- System Settings → Privacy & Security → Accessibility → toggle on `Espanso`
- `espanso service register && espanso start`
- `cd ~/dotfiles && stow -R -t ~ espanso` — re-link config files
- `espanso restart` — pick up new match files

---

## Sketchybar

```bash
# Process running
pgrep -x sketchybar &>/dev/null && \
  echo "OK Sketchybar running" || echo "FAIL Sketchybar not running"

# Brew service registered
brew services list | grep sketchybar | grep -q "started\|none" && \
  echo "OK Sketchybar brew service registered" || echo "WARN Sketchybar service state unclear"

# Custom claude indicator item exists
sketchybar --query claude 2>&1 | grep -q '"name"' && \
  echo "OK claude bar item registered" || echo "FAIL claude item missing"

# ccusage cache populates (8s timeout — first run)
[ -x "$HOME/.bun/bin/ccusage" ] && \
  echo "OK ccusage installed" || echo "FAIL ccusage missing — run: bun install -g ccusage"
```

**If Sketchybar fails:**
- `brew services restart sketchybar` — full restart
- `sketchybar --reload` — partial reload (config only)
- `bun install -g ccusage` — install missing usage parser

---

## Wallpaper System

```bash
# wallpaper-cli responds
wallpaper get &>/dev/null && \
  echo "OK wallpaper-cli works: $(wallpaper get | head -1)" || \
  echo "FAIL wallpaper-cli broken"

# Rotation script is symlinked
readlink "$HOME/scripts/wallpaper-rotate.sh" | grep -q "dotfiles" && \
  echo "OK wallpaper-rotate.sh symlinked" || echo "FAIL not symlinked"

# Durante gallery present (10 images)
GALLERY_COUNT=$(ls "$HOME/Pictures/Wallpapers/"[0-9][0-9]-*.jpg 2>/dev/null | wc -l | tr -d ' ')
[ "$GALLERY_COUNT" -eq 10 ] && \
  echo "OK Durante gallery complete (10 images)" || \
  echo "WARN only $GALLERY_COUNT/10 gallery images present"

# Last rotation log entry
[ -f "$HOME/Library/Logs/wallpaper-rotate.log" ] && \
  echo "OK rotation log: $(tail -1 ~/Library/Logs/wallpaper-rotate.log)" || \
  echo "INFO no log yet (agent fires on next hour boundary)"
```

**If wallpaper system fails:**
- `~/scripts/wallpaper-rotate.sh` — manual run to test logic
- `cd ~/dotfiles && stow -R -t ~ scripts` — re-link scripts
- The Durante gallery is NOT in the repo (too large) — user must regenerate via Media skill or copy from another machine

---

## Ollama

```bash
[ -x "$(command -v ollama)" ] && \
  echo "OK ollama binary installed" || echo "FAIL ollama missing"

# Daemon (OK either way — it's session-only by design)
pgrep -x ollama &>/dev/null && \
  echo "OK ollama daemon running" || echo "INFO daemon not running — start with: ollama-up"

# At least one model pulled
MODEL_COUNT=$(ollama list 2>/dev/null | tail -n +2 | wc -l | tr -d ' ')
[ "$MODEL_COUNT" -gt 0 ] && \
  echo "OK $MODEL_COUNT model(s) installed: $(ollama list | tail -n +2 | awk '{print $1}' | tr '\n' ' ')" || \
  echo "WARN no models yet — for :llm trigger run: ollama-up && ollama pull qwen3-coder:30b"
```

**If Ollama fails:**
- `brew install ollama` — re-install
- `ollama-up` — start daemon (session-only, no boot persistence)
- `ollama pull qwen3-coder:30b` — fetch model for `:llm` espanso trigger

---

## Atuin Sync

```bash
atuin status 2>&1 | grep -q "Last sync" && \
  echo "OK Atuin synced: $(atuin status 2>&1 | grep 'Last sync')" || \
  echo "INFO Atuin not yet registered — run: atuin register -u USER -e EMAIL"
```

**If not registered (expected on fresh install):**
- `atuin register -u <username> -e <email>` (interactive password)
- `atuin sync` — push history
- `atuin key` — output encryption key, **save in 1Password** for cross-machine login

---

## Shell Startup Performance

```bash
echo "Measuring warm shell startup (3 runs)..."
for i in 1 2 3; do
  /usr/bin/time -p zsh -i -c exit 2>&1 | grep real
done
```

**Pass condition:** warm runs (#2 and #3) under 200ms.
**Cold run** (#1) may be 500ms+ due to compinit cache build — that's expected.

**If startup is slow (>250ms warm):**
- Check `~/.zshrc` for added plugins/integrations not present in repo
- `time zsh -i -c exit` repeatedly — identify variance
- Profile with `zprof`: prepend `zmodload zsh/zprof` to `.zshrc`, append `zprof` to find slow inits

---

## Final Summary

After running all checks, report to user:

```
"Verification complete:
  • Critical tools: <N>/24 OK
  • Shell setup: <X>/5 OK
  • Symlinks: <Y>/9 OK
  • LaunchAgents: <Z>/4 OK
  • Tmux: <A>/2 OK
  • Neovim: <B>/3 OK
  • Espanso: <C>/3 OK
  • Sketchybar: <D>/4 OK
  • Wallpaper: <E>/4 OK
  • Ollama: <F>/3 OK
  • Atuin: <G>/1 OK
  • Shell startup: <Nms>

Failures or warnings need attention:
  <list each FAIL/WARN line verbatim from output>

If all OK: 'Installation verified — your environment is ready.'
If any FAIL: walk through the 'If this fails' note for each."
```
