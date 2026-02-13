# Shell Navigation Stack

How FZF, Zoxide, and Atuin work together to make shell navigation instant.

## The Three Tools

| Tool | What It Does | Trigger | Data Source |
|------|-------------|---------|-------------|
| **Zoxide** | Jump to directories by partial name | `z <partial>` | Tracks your `cd` history, ranks by frequency+recency |
| **FZF** | Fuzzy finder for files, directories, anything | `Ctrl+T`, `Alt+C`, piped input | Filesystem scan in real time |
| **Atuin** | Shell history search with context | `Ctrl+R` | Every command you've ever run, with timestamps |

## Zoxide: Smart Directory Jumping

Zoxide replaces `cd` with a learning system. Every time you visit a directory, it records it. Over time, it builds a ranked database of your most-used paths.

### Basic Usage

```bash
z dotfiles          # Jumps to ~/dotfiles (if you've been there before)
z nvim              # Jumps to ~/.config/nvim (most-visited match)
z proj api          # Jumps to ~/Projects/my-api (multiple keywords narrow it)
```

### How Ranking Works

Zoxide uses "frecency" (frequency + recency):
- Directories you visit often rank higher
- Recently visited directories get a boost
- Old, rarely-visited directories decay over time

```bash
zoxide query -ls     # See all tracked directories with scores
zoxide query dotfiles # See what 'z dotfiles' would resolve to
```

### Interactive Mode

```bash
zi                   # Opens FZF picker with all tracked directories
zi proj              # FZF picker pre-filtered to "proj" matches
```

### Zoxide + Neovim

```bash
nzo                  # Custom alias: zoxide pick → open in nvim
                     # Runs ~/scripts/zoxide_openfiles_nvim.sh
```

This opens an FZF picker of your zoxide database, then launches Neovim in the selected directory.

## FZF: Fuzzy Finding Everything

FZF is a general-purpose fuzzy finder. It reads lines from stdin (or scans the filesystem) and lets you interactively filter them.

### Built-in Shell Keybindings

These are activated by `eval "$(fzf --zsh)"` in `.zshrc`:

| Key | Action | Example |
|-----|--------|---------|
| `Ctrl+T` | Find files/dirs, insert path at cursor | `nvim ` then `Ctrl+T` to pick a file |
| `Alt+C` | Find directory, `cd` into it | Jump anywhere without typing the path |
| `Ctrl+R` | History search (overridden by Atuin) | See Atuin section below |

### FZF in the Shell

```bash
# Pipe anything into FZF:
ls | fzf                    # Pick a file from ls output
git branch | fzf            # Pick a git branch
ps aux | fzf                # Find a process

# Use FZF output in commands:
nvim $(fzf)                 # Pick a file, open in nvim
cd $(fd -t d | fzf)         # Pick a directory, cd into it
kill $(ps aux | fzf | awk '{print $2}')  # Pick a process, kill it
```

### Custom FZF Aliases

| Alias | What It Does | Script |
|-------|-------------|--------|
| `nlof` | Recent Neovim files via FZF → open in nvim | `~/scripts/fzf_listoldfiles.sh` |
| `nzo` | Zoxide directories via FZF → open in nvim | `~/scripts/zoxide_openfiles_nvim.sh` |
| `fman` | Browse all man pages via FZF → display | Inline in `.zshrc` |

### FZF Preview

FZF uses `bat` for file previews by default (configured via `FZF_DEFAULT_OPTS` in `.zprofile`). When browsing files with `Ctrl+T`, you see syntax-highlighted previews.

## FZF-Git: Git Operations with FZF

Junegunn's `fzf-git.sh` adds powerful git-aware FZF commands. All start with `Ctrl+G`:

| Keys | What It Shows | Use Case |
|------|--------------|----------|
| `Ctrl+G Ctrl+F` | Git **files** (tracked) | Find any file in the repo |
| `Ctrl+G Ctrl+B` | Git **branches** | Switch branches with preview |
| `Ctrl+G Ctrl+T` | Git **tags** | Browse release tags |
| `Ctrl+G Ctrl+H` | Git **hashes** (commits) | Browse commit history with diff preview |
| `Ctrl+G Ctrl+R` | Git **remotes** | See configured remotes |
| `Ctrl+G Ctrl+S` | Git **stashes** | Browse stashed changes |

### Example: Cherry-Pick a Commit

```bash
# Browse commits with diff preview, copy the hash:
Ctrl+G Ctrl+H     # Navigate commits, see diffs
                   # Select one → hash inserted at cursor
git cherry-pick <hash>
```

### Example: Switch Branch

```bash
gco $(git branch | fzf)    # Traditional way
# Or:
Ctrl+G Ctrl+B              # FZF-git way (with branch preview)
```

## Atuin: Better Shell History

Atuin replaces the default `Ctrl+R` history search with a full-featured history manager.

### Basic Usage

| Key | Action |
|-----|--------|
| `Ctrl+R` | Open Atuin search (vim-insert mode) |
| Type | Filter history in real time |
| `Enter` | Execute selected command |
| `Tab` | Insert command at cursor (edit before running) |
| `Esc` | Cancel |

### Atuin Configuration

Key settings (from `~/.config/atuin/config.toml`):

```toml
keymap_mode = "vim-insert"    # Vi-mode keybindings in search
filter_mode = "global"         # Search all history (not just current dir)
search_mode = "fuzzy"          # Fuzzy matching
secrets_filter = true          # Don't record commands with secrets
```

### What Makes Atuin Special

1. **Context-aware**: Records working directory, exit code, duration, hostname
2. **Secrets filtering**: Automatically skips commands containing tokens/keys
3. **Fuzzy search**: Matches anywhere in the command, not just prefix
4. **Vi-mode**: Navigate results with `j/k` in the search UI

## How They Chain Together

### Workflow 1: Jump to Project and Start Working

```bash
z myproject           # Zoxide: instant jump to project
tns                   # tmux-sessionizer: create/attach tmux session
# Inside tmux:
Ctrl+T                # FZF: find a file to open
nvim <selected>       # Edit it
```

### Workflow 2: Find That Command You Ran Last Week

```bash
Ctrl+R                # Atuin: search history
# Type partial command → fuzzy matches appear
# j/k to navigate, Enter to run
```

### Workflow 3: Navigate Git Repo

```bash
z myrepo              # Zoxide: jump to repo
Ctrl+G Ctrl+H         # FZF-git: browse commits
Ctrl+G Ctrl+B         # FZF-git: switch branch
Ctrl+G Ctrl+S         # FZF-git: apply stash
```

### Workflow 4: Open Recent File in Neovim

```bash
nlof                  # FZF: pick from Neovim's recent files
# or
nzo                   # Zoxide + FZF: pick directory, open in nvim
```

### Workflow 5: Quick Directory Exploration

```bash
Alt+C                 # FZF: interactive directory picker
# or
zi                    # Zoxide interactive: pick from frecent dirs
```

## Tips

### Make Zoxide Learn Faster

```bash
# Visit important directories once to seed the database:
cd ~/Projects/frontend && cd ~/Projects/backend && cd ~/dotfiles
# Now 'z front', 'z back', 'z dot' all work
```

### FZF Everywhere Pattern

Any list of things can be piped through FZF:

```bash
# Pick a docker container
docker ps | fzf | awk '{print $1}'

# Pick a brew package to uninstall
brew list | fzf | xargs brew uninstall

# Pick an npm script to run
jq -r '.scripts | keys[]' package.json | fzf | xargs bun run
```

### Combine Tools

```bash
# Zoxide jump + FZF file pick + nvim open:
cd $(zi) && nvim $(fzf)

# Atuin find command + modify + run:
Ctrl+R → find command → Tab (edit) → modify → Enter
```

## Quick Reference

| Task | Tool | Keys/Command |
|------|------|-------------|
| Jump to directory | Zoxide | `z <partial>` |
| Interactive dir jump | Zoxide + FZF | `zi` |
| Find file | FZF | `Ctrl+T` |
| Change directory | FZF | `Alt+C` |
| Search history | Atuin | `Ctrl+R` |
| Git files | FZF-git | `Ctrl+G Ctrl+F` |
| Git branches | FZF-git | `Ctrl+G Ctrl+B` |
| Git commits | FZF-git | `Ctrl+G Ctrl+H` |
| Recent nvim files | Custom | `nlof` |
| Zoxide + nvim | Custom | `nzo` |
| Man pages | Custom | `fman` |

---

**Next:** [Git Workflow](../git/workflow.md)
