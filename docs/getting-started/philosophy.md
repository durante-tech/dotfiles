# Philosophy & Design Decisions

Why this system exists and the principles behind every choice.

## The Core Idea

This dotfiles system is built around one principle: **the keyboard is faster than the mouse**. Every tool, every keybinding, every configuration choice serves that goal.

Instead of clicking through menus and GUIs, you work entirely from the terminal — editing code, managing files, navigating windows, controlling music, browsing the web — all without lifting your hands from the keyboard.

## Why Terminal-Based?

**Speed.** A terminal-based workflow eliminates context switching:

| GUI Workflow | Terminal Workflow |
|---|---|
| Cmd+Tab to Finder, click through folders | `z myproject` (instant jump) |
| Open VS Code, wait for Electron to load | `nvim` (instant) |
| Click File > Open, browse, click | `<leader>pf` → type 3 letters → Enter |
| Open browser for git, click buttons | `lg` (lazygit in terminal) |

**Composability.** Terminal tools pipe into each other. GUI apps don't.

**Reproducibility.** Every setting is a text file. Clone this repo on a new machine and you're productive in minutes, not hours.

**Portability.** SSH into any server and your muscle memory still works — same vim motions, same tmux prefix, same mental model.

## The Vi-Mode Everywhere Philosophy

Every tool in this system uses vi-style keybindings:

| Tool | Vi Mode |
|------|---------|
| Neovim | Native |
| Zsh | `set -o vi` |
| Tmux | `mode-keys vi` |
| Atuin | `keymap_mode = "vim-insert"` |
| Yazi | Built-in |
| w3m | Custom vi keymap |

**Why?** One set of muscle memory works everywhere. `hjkl` moves in your editor, your shell, your file manager, your terminal multiplexer. Learn it once, use it everywhere.

## Tool Selection Criteria

Every tool was chosen for specific reasons:

### Terminal Stack
| Tool | Why This One | Alternatives Considered |
|------|-------------|------------------------|
| **Ghostty** | GPU-accelerated, native macOS, fast | Kitty (backup), WezTerm (legacy), Alacritty (legacy) |
| **Tmux** | Session persistence, splits, scriptable | Zellij (too new), Ghostty splits (no persistence) |
| **Zsh** | Best plugin ecosystem, macOS default | Fish (not POSIX), Bash (limited) |

### Editor & Code
| Tool | Why This One | Alternatives Considered |
|------|-------------|------------------------|
| **Neovim** | Lua config, LSP native, blazing fast | VS Code (slow), Vim (no Lua), Zed (experimental) |
| **Lazy.nvim** | Lazy-loading, fast startup, declarative | Packer (deprecated), vim-plug (no lazy-load) |
| **Blink.cmp** | Rust-based, fastest completion engine | nvim-cmp (slower), coq (complex) |
| **Snacks.nvim** | Unified UI, picker, notifications, explorer | Telescope (heavier), multiple separate plugins |

### Navigation & Files
| Tool | Why This One | Alternatives Considered |
|------|-------------|------------------------|
| **Zoxide** | Learns your habits, instant jump | autojump (slower), z.lua (less maintained) |
| **FZF** | Universal fuzzy finder, pipes with everything | skim (less ecosystem) |
| **Yazi** | Async Rust, image preview, fast | ranger (Python, slow), lf (less features) |
| **Oil.nvim** | Edit filesystem like a buffer | NERDTree (tree view, less powerful) |

### Modern CLI Replacements
| Old | New | Why |
|-----|-----|-----|
| `ls` | `eza` | Git integration, icons, colors |
| `cat` | `bat` | Syntax highlighting, line numbers |
| `find` | `fd` | Simpler syntax, respects .gitignore |
| `grep` | `ripgrep` | Blazing fast, respects .gitignore |
| `ps` | `procs` | Color output, searchable |
| `top` | `bottom` | Graphs, mouse support |
| `curl` | `curlie` | Syntax-highlighted responses |
| `du` | `dust` | Visual tree, instant answers |

### Window Management
| Tool | Why This One | Alternatives Considered |
|------|-------------|------------------------|
| **AeroSpace** | i3-like, Alt keys, no SIP needed | yabai (needs SIP disabled), Rectangle (basic) |
| **Karabiner** | Hyperkey, deep remapping | Hammerspoon (Lua scripting, overkill) |
| **SketchyBar** | Fully scriptable macOS bar | Built-in menu bar (not customizable) |

## The Theme System

Consistency reduces cognitive load:

| Context | Theme | Why |
|---------|-------|-----|
| Terminal tools (tmux, starship, sketchybar) | **Catppuccin Mocha** | Warm, easy on eyes, great contrast |
| Editor (neovim, ghostty) | **Rose-pine** | Elegant, distinct from terminal chrome |

Two themes, not one, because the editor should feel visually distinct from the surrounding terminal — you always know where your cursor focus is.

## The Keybinding Strategy

### Layers of Control

```
Layer 1: AeroSpace (Alt+key)     → Which workspace/window
Layer 2: Tmux (Ctrl+Space)           → Which terminal pane/session
Layer 3: Neovim (<Space>+key)    → Which file/action in editor
Layer 4: Karabiner (Hyper+key)   → Global shortcuts from anywhere
```

No conflicts between layers because each uses a different modifier:
- **Alt** = Window management (AeroSpace)
- **Ctrl+Space** = Terminal management (Tmux)
- **Space** = Editor commands (Neovim leader)
- **CapsLock (Hyper)** = Global shortcuts (Karabiner)

### Mnemonic Keybindings

Keys are chosen to be memorable, not arbitrary:

| Key | Mnemonic | Example |
|-----|----------|---------|
| `p` | Project/Picker | `<leader>pf` = project find |
| `g` | Git/Go | `gd` = go to definition |
| `w` | Workspace | `<leader>ws` = workspace save |
| `v` | View/Visual | `<leader>vca` = view code actions |
| `r` | Rename/Restart | `<leader>rn` = rename |
| `d` | Diagnostic | `<leader>d` = diagnostic |
| `e` | Explorer | `<leader>ee` = explorer |

## GNU Stow: The Deployment System

See [GNU Stow Guide](gnu-stow.md) for details. The key insight: each directory in this repo mirrors `$HOME`. Stow creates symlinks, so editing `~/dotfiles/nvim/.config/nvim/init.lua` is the same as editing `~/.config/nvim/init.lua`.

**Why Stow over alternatives?**
- Simpler than Ansible/Chezmoi for personal dotfiles
- No templating engine to learn
- Git tracks everything naturally
- Selective stowing (only install what you want)

## Design Principles Summary

1. **Keyboard-first** — Every action has a keybinding
2. **Vi-mode everywhere** — One muscle memory for all tools
3. **Speed over features** — Fast startup, lazy loading, Rust tools
4. **Composable** — Tools pipe into each other
5. **Reproducible** — Clone and go on any Mac
6. **Consistent themes** — Catppuccin for terminal, Rose-pine for editor
7. **No conflicts** — Each layer uses a different modifier key
8. **Mnemonic keys** — Remember by meaning, not by rote
9. **Progressive disclosure** — Simple defaults, depth when needed
10. **Text files all the way down** — Every config is version-controlled

---

**Next:** [Installation Guide](installation.md)
