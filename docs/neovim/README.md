# Neovim Configuration

This Neovim configuration is built for modern development workflows with Lazy.nvim, LSP, and keyboard-driven productivity.

## Quick Reference

| Action | Keybinding |
|--------|------------|
| Find files | `<leader>ff` |
| Search in files | `<leader>fg` |
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
- **[Copy/Paste/Move](workflows/copy-paste-move.md)** - Clipboard and text manipulation
- **[LSP & Completion](workflows/lsp.md)** - Language server features

### Configuration
- **[Formatters](formatters.md)** - Code formatting setup (Conform.nvim)
- **[Formatter Troubleshooting](formatter-troubleshooting.md)** - Fixing formatter issues

### Reference
- **[Tips & Tricks](tips-and-tricks.md)** - Power user techniques
- **[Troubleshooting](troubleshooting.md)** - Common issues and solutions

## Key Plugins

| Plugin | Purpose | Key |
|--------|---------|-----|
| Snacks.nvim | Picker, notifications, UI | `<leader>p*` |
| Oil.nvim | File explorer | `-` |
| Blink.cmp | Fast completions | Auto |
| Conform.nvim | Formatting | `<leader>mp` |
| Mason | LSP installer | `:Mason` |
| Harpoon | Quick file marks | `<leader>a`, `<C-e>` |
| Auto-session | Workspace persistence | Auto |
| Lazygit | Git UI (via tmux) | `<C-g>` in tmux |

## File Structure

```
nvim/.config/nvim/
├── init.lua                 # Entry point
├── lua/sethy/
│   ├── core/               # Core settings, keymaps
│   ├── lazy.lua            # Plugin manager setup
│   └── plugins/            # Plugin configurations
│       ├── lsp/            # LSP, Mason, formatting
│       └── *.lua           # Individual plugins
```

## LSP Servers (via Mason)

Installed automatically: `lua_ls`, `ts_ls`, `html`, `cssls`, `tailwindcss`, `gopls`, `emmet_ls`, `marksman`

Run `:Mason` to install additional servers.
