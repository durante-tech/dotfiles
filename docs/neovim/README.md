# Neovim Configuration

This Neovim configuration is built for modern development workflows with Lazy.nvim, LSP, and keyboard-driven productivity.

## Quick Reference

| Action | Keybinding |
|--------|------------|
| Find files | `<leader>pf` |
| Search in files | `<leader>ps` |
| Switch project | `<leader>pp` |
| File explorer | `-` (Oil) or `<leader>ee` (Snacks explorer) |
| Go to definition | `gd` |
| Show references | `gR` |
| Code actions | `<leader>vca` |
| Rename symbol | `<leader>rn` |
| Format file | `<leader>mp` |
| Git worktrees | `<leader>gt` |
| List sessions | `<leader>wl` |

## Documentation

### Getting Started
- **[Keybindings](keybindings.md)** - Complete keybinding reference
- **[Daily Cheatsheet](daily-cheatsheet.md)** - Most common operations

### Workflows
- **[Editing](workflows/editing.md)** - Writing and manipulating code
- **[Navigation](workflows/navigation.md)** - Moving through files and code
- **[File Management](workflows/file-management.md)** - Finding and managing files
- **[Search & Replace](workflows/search-replace.md)** - Finding and transforming text
- **[Copy/Paste/Move](workflows/copy-paste-move.md)** - Clipboard and text manipulation
- **[Windows & Buffers](workflows/windows-buffers.md)** - Splits, buffers, and tabs
- **[LSP & Completion](workflows/lsp.md)** - Language server features

### Configuration
- **[Formatters](formatters.md)** - Code formatting setup (Conform.nvim)
- **[Formatter Troubleshooting](formatter-troubleshooting.md)** - Fixing formatter issues

### Reference
- **[Tips & Tricks](tips-and-tricks.md)** - Power user techniques
- **[Troubleshooting](troubleshooting.md)** - Common issues and solutions

## Key Plugins

### Core

| Plugin | Purpose | Key |
|--------|---------|-----|
| Snacks.nvim | Picker, notifications, explorer, UI | `<leader>pf`, `<leader>ee` |
| Oil.nvim | Buffer-based file explorer | `-` |
| Blink.cmp | Fast completions | Auto |
| Conform.nvim | Formatting | `<leader>mp` |
| Mason | LSP installer | `:Mason` |
| Harpoon | Quick file marks | `<leader>a`, `<C-e>` |
| Auto-session | Workspace persistence | Auto |
| Project.nvim | Project detection/switching | `<leader>pp` |

### Navigation & Motion

| Plugin | Purpose | Key |
|--------|---------|-----|
| Flash.nvim | Jump/motion with labels | `s` (search), `S` (treesitter) |
| MiniFiles | Miller-column file explorer | `<leader>em` |
| Vim-maximizer | Maximize/restore split | `<leader>sm` |

### Editor Enhancement

| Plugin | Purpose | Key |
|--------|---------|-----|
| Auto-pairs | Auto-close brackets/quotes | Auto |
| Treesitter | Syntax highlighting/textobjects | Auto |
| Todo-comments | Highlight TODO/FIXME/NOTE | `<leader>xt` |
| Trouble | Diagnostics list | `<leader>xw` |
| Undotree | Undo history visualizer | `<leader>u` |
| Noice.nvim | UI for messages/cmdline | Auto |
| Wilder | Command-line fuzzy completion | Auto |
| Showkeys | Display pressed keys | Auto |
| nvim-ufo | Code folding | `zc`, `zo`, `zR`, `zM` |
| Faster.nvim | Accelerated j/k scrolling | Auto |

### Git

| Plugin | Purpose | Key |
|--------|---------|-----|
| Git integration | Signs, blame, diff | `<leader>gs` |
| Git worktree | Worktree management | `<leader>gt` |

### Language & Development

| Plugin | Purpose | Key |
|--------|---------|-----|
| Claude Code | AI assistant integration | `<leader>ac` toggle, `<leader>as` send selection |
| Tailwind Tools | Tailwind CSS support | Auto |
| Emmet | HTML/CSS expansion | `<leader>xe` (wrap) |
| Render-markdown | Markdown rendering in buffer | Auto |
| Markdown-preview | Browser markdown preview | `:MarkdownPreview` |
| Molten | Jupyter notebook support | `:MoltenInit` |
| Debugging (DAP) | Debug adapter protocol | `:DapToggleBreakpoint` |

### UI & Visual

| Plugin | Purpose | Key |
|--------|---------|-----|
| Rose-pine | Color scheme | Auto |
| Lualine | Status line | Auto |
| Incline | Floating filename labels | Auto |
| Image support | Inline image rendering | Auto |
| PDF viewer | PDF rendering in Neovim | Auto |

## File Structure

```
nvim/.config/nvim/
├── init.lua                 # Entry point
├── lua/sethy/
│   ├── core/               # Core settings, keymaps
│   ├── lazy.lua            # Plugin manager (Lazy.nvim)
│   ├── jupyter-config.lua  # Jupyter/Molten configuration
│   ├── terminalpop.lua     # Terminal popup utility
│   └── plugins/            # Plugin configurations (38 files)
│       ├── lsp/            # LSP, Mason
│       │   ├── lspconfig.lua
│       │   └── mason.lua
│       └── *.lua           # Individual plugins
```

## LSP Servers (via Mason)

Installed automatically: `lua_ls`, `ts_ls`, `html`, `cssls`, `tailwindcss`, `gopls`, `emmet_ls`, `marksman`

Run `:Mason` to install additional servers.
