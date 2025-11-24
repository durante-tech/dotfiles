# Neovim Configuration Documentation

Welcome to the complete guide for this Neovim configuration. This documentation is organized around real developer workflows and daily tasks.

## 📚 Documentation Structure

### Getting Started
- **[Quick Start](quick-start.md)** - Get up and running in 5 minutes
- **[First Day Guide](first-day.md)** - Your first day with this Neovim config

### Daily Reference
- **[Daily Cheatsheet](daily-cheatsheet.md)** - Most common operations at a glance
- **[Keybindings Reference](keybindings.md)** - Complete keybinding list organized by category

### Workflows
Learn how to accomplish real development tasks:

- **[Editing Workflows](workflows/editing.md)** - Writing, changing, and manipulating code
- **[Navigation](workflows/navigation.md)** - Moving through files, projects, and code
- **[File Management](workflows/file-management.md)** - Finding, opening, and managing files
- **[Git Integration](workflows/git.md)** - Version control workflows with lazygit and fugitive
- **[LSP & Completion](workflows/lsp.md)** - Language server features, autocomplete, diagnostics
- **[Debugging](workflows/debugging.md)** - Debugging workflows and tools
- **[Search & Replace](workflows/search-replace.md)** - Finding and replacing text across files
- **[Window & Buffer Management](workflows/windows-buffers.md)** - Managing your workspace layout

### Plugin Guides
Deep dives into key plugins:

- **[Telescope](plugins/telescope.md)** - Fuzzy finder for everything
- **[LSP Configuration](plugins/lsp.md)** - Language server setup and usage
- **[Auto-session & Projects](plugins/sessions.md)** - Workspace and session management
- **[Oil](plugins/oil.md)** - File explorer and manipulation
- **[Tmux Integration](plugins/tmux.md)** - Terminal multiplexer workflows

### Advanced Topics
- **[Customization Guide](advanced/customization.md)** - How to customize this config
- **[Plugin Development](advanced/plugin-dev.md)** - Adding new plugins
- **[Troubleshooting](troubleshooting.md)** - Common issues and solutions
- **[Tips & Tricks](tips-and-tricks.md)** - Pro tips for power users

## 🎯 Learning Path

### Beginner (Week 1)
1. Start with [Quick Start](quick-start.md)
2. Review [Daily Cheatsheet](daily-cheatsheet.md) - keep it open!
3. Focus on [Editing Workflows](workflows/editing.md) and [Navigation](workflows/navigation.md)
4. Practice [File Management](workflows/file-management.md)

### Intermediate (Week 2-4)
1. Master [Telescope](plugins/telescope.md) for fuzzy finding
2. Learn [LSP features](workflows/lsp.md) for your languages
3. Integrate [Git workflows](workflows/git.md) into your daily routine
4. Explore [Window Management](workflows/windows-buffers.md)

### Advanced (Month 2+)
1. Customize your config following [Customization Guide](advanced/customization.md)
2. Set up [Debugging](workflows/debugging.md) for your stack
3. Master [Search & Replace](workflows/search-replace.md) across projects
4. Dive into [Tips & Tricks](tips-and-tricks.md) for efficiency

## 🔥 Most Used Features

Here are the features developers use most in their daily work:

### File Operations
- `<leader>ff` - Find files (Telescope)
- `<leader>fg` - Search in files (grep)
- `<leader>pp` - Switch projects
- `-` - Open file explorer (Oil)

### Code Navigation
- `gd` - Go to definition
- `gr` - Show references
- `<C-o>` / `<C-i>` - Jump backward/forward
- `<leader>pWs` - Search word under cursor

### Editing
- `gcc` - Toggle comment line
- `gc` (visual) - Comment selection
- `<leader>vca` - Code actions
- `<leader>rn` - Rename symbol

### Git
- `<leader>lg` - Open lazygit (in tmux)
- Git integration available in status line

### Sessions & Projects
- `<leader>pp` - Switch project
- `<leader>wf` - Find session
- Auto-saves workspace on exit

## 💡 Philosophy

This configuration is built around:

1. **Modal Editing** - Master vim motions for efficient editing
2. **Keyboard-First** - Everything accessible via keybindings
3. **Project-Aware** - Smart detection and context switching
4. **LSP-Powered** - Modern IDE features via Language Servers
5. **Composable** - Tools work together (Tmux + Neovim + Lazygit)

## 🆘 Need Help?

- Check [Troubleshooting](troubleshooting.md) for common issues
- Review [Keybindings Reference](keybindings.md) if you forgot a key
- Consult [Daily Cheatsheet](daily-cheatsheet.md) for quick reference

## 📖 External Resources

- [Neovim Documentation](https://neovim.io/doc/)
- [Vim Motions Practice](https://www.vimgenius.com/)
- [Learn Vim Progressively](https://yannesposito.com/Scratch/en/blog/Learn-Vim-Progressively/)
- [Effective Neovim](https://www.youtube.com/watch?v=stqUbv-5u2s)

---

**Remember**: Learning Neovim is a journey. Focus on one workflow at a time, practice daily, and gradually build your muscle memory. You'll be faster than ever in a few weeks!
