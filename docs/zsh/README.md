# Zsh Configuration

Shell configuration with vi-mode, modern CLI tools, and extensive aliases.

## Quick Reference

| Alias | Command |
|-------|---------|
| `ls` | `eza` with icons and git status |
| `la` | `eza -la` all files |
| `lt` | `eza --tree` tree view |
| `cat` | `bat` with syntax highlighting |
| `z <dir>` | `zoxide` smart directory jump |
| `lg` | `lazygit` |
| `y` | `yazi` file manager |

## Git Aliases

| Alias | Command |
|-------|---------|
| `gs` | `git status -s` |
| `ga` | `git add .` |
| `gc` | `git commit -m` |
| `gco` | `git checkout` |
| `gcb` | `git checkout -b` |
| `gp` | `git push` |
| `gl` | `git pull` |
| `gd` | `git diff` |
| `gds` | `git diff --staged` |
| `glog` | `git log --oneline --graph --all` |

## Claude CLI Aliases

| Alias | Command |
|-------|---------|
| `cld` | `claude` |
| `cldo` | `claude --model opus` |
| `clds` | `claude --model sonnet` |
| `cldy` | `claude --dangerously-skip-permissions --model sonnet` |
| `cldyo` | `claude --dangerously-skip-permissions --model opus` |
| `lfg` | `claude --dangerously-skip-permissions --model opus` |
| `cldr` | `claude --resume` |

## FZF Integration

| Command | Description |
|---------|-------------|
| `Ctrl+R` | Atuin history search |
| `Ctrl+T` | FZF file finder |
| `Alt+C` | FZF directory jump |
| `nlof` | FZF recent files → nvim |
| `nzo` | Zoxide → nvim |
| `fman` | FZF man pages |

## Vi Mode

Enabled by default (`set -o vi`).

| Key | Mode | Action |
|-----|------|--------|
| `Esc` | Insert→Normal | Exit insert mode |
| `Ctrl+E` | Insert | Accept autosuggestion |
| `Ctrl+P/N` | Insert | History up/down |

## Fabric AI

Dynamic aliases auto-generated from `~/.config/fabric/patterns/`:

```bash
yt "https://youtube.com/..."      # Extract transcript
yt -t "https://youtube.com/..."   # With timestamps
fb --pattern summarize            # Use pattern
```

## File Structure

```
zsh/
├── .zprofile    # Login shell: PATH, env vars, Homebrew
└── .zshrc       # Interactive: aliases, plugins, prompt
```

## Plugins (via Homebrew)

- `zsh-autosuggestions` - Fish-like suggestions
- `zsh-syntax-highlighting` - Command highlighting
- `atuin` - Better shell history
- `starship` - Cross-shell prompt
- `zoxide` - Smart directory jumping

## Local Overrides

Machine-specific config (not tracked in git):
```bash
~/.zprofile.local
~/.zshrc.local
```
