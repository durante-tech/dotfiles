# OS Theme Auto-Switch for Dotfiles

## Context

Lucas wants all terminal tools to follow the macOS system appearance (dark/light mode). Currently, all tools are hardcoded to dark themes (Rose Pine for Neovim/Ghostty, Catppuccin Mocha for Tmux/Starship/Sketchybar). The goal is a fully automatic system: when macOS switches appearance, all tools switch instantly — plus a manual `theme` command as override.

## Architecture

**Single source of truth:** `~/.config/current-theme` file containing `dark` or `light`.

**Three layers:**
1. **`theme-switch` script** — reads OS appearance, writes to `~/.config/current-theme`, applies to each tool
2. **Swift daemon + LaunchAgent** — watches for macOS `AppleInterfaceThemeChangedNotification`, triggers `theme-switch auto`
3. **Per-tool integration** — each tool reads from the shared state file or gets updated by the script

## Files to Create (5 new files)

### 1. `scripts/scripts/theme-switch` (central switcher)
- Accepts: `auto` (detect OS), `dark`, `light`, `toggle`
- Writes mode to `~/.config/current-theme`
- Applies to each tool:
  - **Ghostty**: `sed` to swap `config-file`, `background`, `background-opacity` in config. Ghostty auto-reloads on file change.
  - **Neovim**: Already handled via `FocusGained` autocmd reading the file. No action needed from script.
  - **Tmux**: `tmux source-file ~/.config/tmux/tmux.conf` (config reads from current-theme file via `run-shell`)
  - **Starship**: `sed` to swap `palette = "catppuccin_mocha"` ↔ `"catppuccin_latte"`. Only affects new shells.
  - **Sketchybar**: `sketchybar --reload` (colors.sh reads from current-theme file)

### 2. `scripts/scripts/theme-watcher.swift` (daemon source)
- 10-line Swift program using `DistributedNotificationCenter`
- Observes `AppleInterfaceThemeChangedNotification`
- On change: runs `~/scripts/theme-switch auto`
- Compiled to `scripts/scripts/theme-watcher` binary

### 3. `launchagents/Library/LaunchAgents/com.dotfiles.theme-switch.plist`
- New stow package for LaunchAgents
- Starts `theme-watcher` on login, restarts on crash
- `KeepAlive: true`, `RunAtLoad: true`

### 4. `ghostty/.config/ghostty/themes/rosepine-dawn` (light theme)
- Rose Pine Dawn color palette for Ghostty (16 ANSI + foreground/background/cursor)

### 5. `sketchybar/.config/sketchybar/colors-light.sh` (Catppuccin Latte colors)
- Same structure as `colors.sh` but with Catppuccin Latte values

## Files to Modify (6 existing files)

### 1. `nvim/.config/nvim/lua/current-theme.lua`
**Current:** `vim.cmd("colorscheme rose-pine")`
**New:** Read `~/.config/current-theme`, set `vim.o.background` accordingly, apply `colorscheme rose-pine`. Add `FocusGained` autocmd to re-check on window focus.

### 2. `nvim/.config/nvim/lua/sethy/plugins/colorscheme.lua`
**Change:** Rose Pine `variant = "main"` → `variant = "auto"` (follows `vim.o.background`)

### 3. `starship/.config/starship/starship.toml`
**Add:** `[palettes.catppuccin_latte]` section with all Latte colors (rosewater through crust)

### 4. `tmux/.config/tmux/tmux.conf`
**Change:** Replace `set -g @catppuccin_flavor "mocha"` with `run-shell` that reads from `~/.config/current-theme`:
```
run-shell 'tmux set -g @catppuccin_flavor "$(if [ "$(cat ~/.config/current-theme 2>/dev/null)" = "light" ]; then echo latte; else echo mocha; fi)"'
```

### 5. `sketchybar/.config/sketchybar/colors.sh`
**Change:** Read from `~/.config/current-theme` and source either dark (current Mocha values) or light (Latte values from `colors-light.sh`)

### 6. `zsh/.zshrc`
**Add:** `alias theme="theme-switch"` for manual switching

## Theme Mappings

| Tool | Dark | Light |
|------|------|-------|
| Ghostty | Rose Pine (themes/rosepine) + #000000 bg + 0.75 opacity | Rose Pine Dawn (themes/rosepine-dawn) + #faf4ed bg + 1.0 opacity |
| Neovim | rose-pine (main variant, background=dark) | rose-pine (dawn variant, background=light) |
| Tmux | Catppuccin Mocha | Catppuccin Latte |
| Starship | catppuccin_mocha palette | catppuccin_latte palette |
| Sketchybar | Catppuccin Mocha colors | Catppuccin Latte colors |
| Lualine | Auto-follows rose-pine colorscheme | Auto-follows rose-pine colorscheme |

## Tool Update Behavior

| Tool | Live Update | Method |
|------|-------------|--------|
| Ghostty | Yes | Config file change triggers auto-reload |
| Neovim | Yes (on focus) | FocusGained autocmd re-reads current-theme |
| Tmux | Yes | Script runs `tmux source-file` |
| Starship | New shells only | sed edits palette line; existing prompts unchanged |
| Sketchybar | Yes | Script runs `sketchybar --reload` |

## Installation Steps (in install.sh or manual)

1. Compile Swift watcher: `swiftc -o ~/scripts/theme-watcher ~/scripts/theme-watcher.swift`
2. Stow new launchagents package: `stow -t ~ launchagents`
3. Load LaunchAgent: `launchctl load ~/Library/LaunchAgents/com.dotfiles.theme-switch.plist`
4. Re-stow ghostty for new theme file: `stow -R -t ~ ghostty`
5. Initial run: `theme-switch auto`

## Verification

1. Run `theme-switch light` — all tools switch to light themes
2. Run `theme-switch dark` — all tools revert to original dark themes (identical to before)
3. Toggle macOS appearance in System Settings — daemon auto-triggers switch
4. Open new Neovim — detects current theme on startup
5. Switch OS appearance while Neovim is open, click into Neovim — theme updates on FocusGained
