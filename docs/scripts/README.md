# Custom Scripts

Utility scripts automatically available in PATH via `~/scripts/`.

## Available Scripts

### tmux-sessionizer

Fuzzy-find projects and create/switch tmux sessions.

```bash
tns                    # Alias
# or
tmux-sessionizer       # Direct call
```

**How it works:**
1. FZF lists project directories
2. Select a project
3. Creates or attaches to tmux session named after project

**Keybinding:** `Ctrl+B > F` in tmux

### fzf-git.sh

Git operations with FZF preview (by Junegunn).

| Keybinding | Action |
|------------|--------|
| `Ctrl+G Ctrl+F` | Files |
| `Ctrl+G Ctrl+B` | Branches |
| `Ctrl+G Ctrl+T` | Tags |
| `Ctrl+G Ctrl+H` | Hashes (commits) |
| `Ctrl+G Ctrl+R` | Remotes |
| `Ctrl+G Ctrl+S` | Stashes |

### fzf_listoldfiles.sh

FZF interface for Neovim's recent files.

```bash
nlof                   # Alias
```

Opens FZF with recent files, selection opens in Neovim.

### zoxide_openfiles_nvim.sh

Zoxide integration with Neovim.

```bash
nzo                    # Alias
```

Jump to directory with zoxide, then open in Neovim.

## Adding New Scripts

1. Create script in `scripts/scripts/`
2. Make executable: `chmod +x scripts/scripts/myscript`
3. Available immediately (directory is in PATH)

## File Location

```
scripts/scripts/
├── tmux-sessionizer
├── fzf-git.sh
├── fzf_listoldfiles.sh
└── zoxide_openfiles_nvim.sh
```
