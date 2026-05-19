# Troubleshooting Guide

Common issues and their solutions.

## General Issues

### "I'm stuck and don't know what mode I'm in!"

**Symptoms:** Keys aren't doing what you expect, screen looks weird

**Solution:**
```
1. Press Esc multiple times
2. Type :q!
3. Press Enter
4. Restart: nvim
```

### "Nothing happens when I type"

**Cause:** You're in NORMAL mode (for commands, not typing)

**Solution:** Press `i` to enter INSERT mode, then type normally

### "I pressed something and text is being selected"

**Cause:** You're in VISUAL mode

**Solution:** Press `Esc` to return to NORMAL mode

### "Everything I type appears as :something"

**Cause:** You're in COMMAND mode

**Solution:** Press `Esc` or `Ctrl-c` to cancel

### "Nvim opens but looks broken/no colors"

**Causes:**
- Terminal doesn't support true color
- Plugins not installed

**Solutions:**
```bash
# 1. Check Neovim version (need 0.11+)
nvim --version

# 2. Install plugins
nvim
:Lazy sync

# 3. Check terminal true color support
echo $TERM
# Should be: xterm-256color or similar

# 4. For Ghostty/WezTerm, already configured
```

### "Slow startup or lag"

**Causes:**
- Too many plugins loading at startup
- LSP server issues
- Large files

**Solutions:**
```vim
" 1. Check startup time
nvim --startuptime startup.log
" Review startup.log for slow plugins

" 2. Check plugin loading
:Lazy profile

" 3. Disable specific LSP if slow
:LspStop

" 4. Increase updatetime
:set updatetime=1000
```

## Plugin Issues

### "Plugins not loading"

**Check installation:**
```vim
:Lazy
" Should show all plugins installed
" If not, press 'I' to install
```

**Force reinstall:**
```vim
:Lazy clean
:Lazy sync
```

### "Lazy.nvim shows errors on startup"

**Common fixes:**
```vim
" 1. Check for syntax errors in plugin files
:checkhealth lazy

" 2. View error details
:messages

" 3. Clean and reinstall
:Lazy clean
:Lazy sync
```

### "Picker not finding files"

**Causes:**
- Not in a project directory
- Hidden files need toggle
- Gitignored files

**Solutions:**
```vim
" 1. Make sure you're in project root
:pwd

" 2. Use the picker with hidden files
" Snacks picker respects fd settings from FZF_DEFAULT_COMMAND
" which already includes --hidden --exclude .git

" 3. Check ripgrep is installed (used for grep)
:!rg --version

" 4. Check fd is installed (used for file finding)
:!fd --version
```

### "Oil file explorer not opening"

**Check keybinding:**
```vim
" Try manually
:Oil

" If works, keybinding issue
" Check: nvim/lua/sethy/plugins/oil.lua
```

### "Auto-session not restoring"

**Causes:**
- In suppressed directory (home, downloads, etc.)
- Session file corrupted

**Solutions:**
```vim
" 1. Check session dir
:echo g:auto_session_root_dir
" Or: ~/.local/share/nvim/sessions/

" 2. Manual restore
:SessionRestore

" 3. Check suppressed dirs (in auto-session.lua)
" Should avoid: ~/, ~/Downloads, ~/Documents, etc.

" 4. Delete corrupted session
:SessionDelete
```

## LSP Issues

### "LSP not starting"

**Diagnose:**
```vim
:LspInfo
" Should show attached servers

:checkhealth lsp
" Shows LSP configuration issues
```

**Solutions:**
```vim
" 1. Check server installed
:Mason
" Look for your language server

" 2. Install missing server
" In Mason, navigate to server, press 'i'

" 3. Restart LSP
:LspRestart

" 4. Check logs
:LspLog
```

### "Go to definition not working (gd)"

**Causes:**
- LSP not attached
- Not a symbol
- Project root not detected

**Solutions:**
```vim
" 1. Verify LSP attached
:LspInfo
" Should show server attached to buffer

" 2. Check it's a valid symbol
" Try on a function name or variable

" 3. Ensure in project with proper root markers
:lua print(vim.fn.getcwd())
" Should be in project root with .git, package.json, etc.

" 4. Manually attach LSP
:LspStart
```

### "Completions not appearing"

**Causes:**
- Blink.cmp not loaded
- LSP not providing completions
- Completion disabled

**Solutions:**
```vim
" 1. Check Blink.cmp loaded
:lua print(vim.inspect(require('blink.cmp')))

" 2. Check LSP capabilities
:lua print(vim.inspect(vim.lsp.get_clients()[1].server_capabilities))

" 3. Trigger manually
" In INSERT mode: Ctrl-n or Ctrl-space

" 4. Check Lazy for plugin status
:Lazy
" Look for blink.cmp in the list
```

### "Wrong LSP server attached"

**Scenario:** denols activating in Node project, or ts_ls in Deno project

**Solution:**
Check `lspconfig.lua` root detection:
```lua
-- ts_ls should exclude Deno projects
-- denols should only activate with deno.json/deno.jsonc

" Force correct server
:LspStop
:LspStart ts_ls
```

### "Diagnostics not showing"

**Check:**
```vim
" 1. Verify diagnostics enabled
:lua vim.diagnostic.enable()

" 2. Check diagnostic config
:lua print(vim.inspect(vim.diagnostic.config()))

" 3. View raw diagnostics
:lua vim.print(vim.diagnostic.get())

" 4. Check signs configured
" Should see icons in gutter:     󰠠
```

### "Too many false errors/warnings"

**Filter diagnostics:**
```lua
-- In lspconfig.lua, add to server config:
handlers = {
    ["textDocument/publishDiagnostics"] = function(_, result, ctx, config)
        -- Filter out hints and info
        result.diagnostics = vim.tbl_filter(function(d)
            return d.severity <= vim.diagnostic.severity.WARN
        end, result.diagnostics)
        vim.lsp.diagnostic.on_publish_diagnostics(_, result, ctx, config)
    end,
},
```

## Performance Issues

### "Neovim is slow/laggy"

**Diagnose:**
```vim
" 1. Profile startup
:Lazy profile

" 2. Check LSP performance
:LspInfo

" 3. Disable features to test
:LspStop
" If faster, LSP is the issue
```

**Solutions:**
```vim
" 1. Lazy load more plugins
" Edit plugin configs to use 'event = "VeryLazy"'

" 2. Disable unused LSP features
:lua vim.lsp.inlay_hint.enable(false)

" 3. Increase updatetime
:set updatetime=500

" 4. Disable virtual text
:lua vim.diagnostic.config({ virtual_text = false })
```

### "Slow syntax highlighting"

**For large files:**
```vim
:syntax off              " Disable syntax
:set syntax=off          " Permanently for buffer
```

**Or use TreeSitter:**
```vim
:TSDisable highlight     " Disable TreeSitter highlighting
```

### "High CPU usage"

**Check:**
```bash
# Outside nvim
top -p $(pgrep nvim)
```

**Common causes:**
- Infinite loop in plugin
- LSP server spinning
- Large file processing

**Solutions:**
```vim
:LspStop                 " Stop LSP
:Lazy reload {plugin}    " Reload problematic plugin
```

## File & Buffer Issues

### "Can't save file (:w fails)"

**Error: "E45: 'readonly' option is set"**
```vim
:w!                      " Force write
" or
:set noreadonly
:w
```

**Error: "Permission denied"**
```vim
:w !sudo tee %           " Write with sudo
```

### "Lost unsaved changes!"

**Recovery:**
```vim
" 1. Check swap file
:recover

" 2. List swap files
:swapname

" 3. Recover from swap
:e filename
:recover
```

### "Buffer shows [+] but I didn't change anything"

**Cause:** File changed externally (e.g., git checkout)

**Solution:**
```vim
:e!                      " Reload from disk (discards changes)
" or
:checktime               " Check if file changed
```

### "Can't close buffer (:bd fails)"

**Error: "No write since last change"**
```vim
:bd!                     " Force close without saving
" or
:w | bd                  " Save then close
```

## Search & Navigation Issues

### "Search highlighting won't go away"

**After searching with `/`:**
```vim
:noh                     " Clear highlight
" or
:set nohlsearch          " Disable forever
```

### "Can't find file with picker"

**Try:**
```vim
" 1. Search all files
<leader>pf

" 2. Make sure you're in project root
:pwd

" 3. Snacks picker respects fd settings from FZF_DEFAULT_COMMAND
" which already includes --hidden --exclude .git

" 4. Check fd is installed (used for file finding)
:!fd --version

" 5. Change directory if needed
:cd /path/to/project
```

### "Grep not finding text I can see"

**Causes:**
- Wrong directory
- File gitignored
- File not committed

**Solutions:**
```vim
" 1. Check current directory
:pwd

" 2. Use Snacks grep
<leader>ps

" 3. Check ripgrep is installed (used for grep)
:!rg --version

" 4. Use vimgrep as fallback
:vimgrep /pattern/ **/*
```

## Configuration Issues

### "Changes to config not taking effect"

**Solutions:**
```vim
" 1. Reload config
:source $MYVIMRC

" 2. Restart Neovim
:qa
nvim

" 3. For plugin changes
:Lazy reload {plugin}

" 4. For LSP changes
:LspRestart
```

### "Keybinding not working"

**Check:**
```vim
" 1. Check if key is mapped
:verbose map <leader>pf

" 2. Check leader key
:let mapleader
" Should output: <Space>

" 3. Check in correct mode
:verbose imap <C-h>      " INSERT mode
:verbose nmap <C-h>      " NORMAL mode
:verbose vmap <C-h>      " VISUAL mode
```

### "Plugin errors after update"

**Solutions:**
```vim
" 1. Check breaking changes
:Lazy log {plugin}

" 2. Rollback plugin
:Lazy
" Navigate to plugin, press 'r' for restore

" 3. Clean and reinstall
:Lazy clean
:Lazy sync
```

## Terminal & Shell Issues

### "Colors look wrong in terminal"

**Check terminal emulator:**
```bash
# Ghostty (recommended for this config)
echo $TERM
# Should output: xterm-256color

# Check true color support
echo -e "\033[38;2;255;100;0mTRUECOLOR\033[0m"
# Should show orange text
```

**Solutions:**
- Use Ghostty or WezTerm (configured for this setup)
- Set TERM variable: `export TERM=xterm-256color`
- Check colorscheme in Neovim: `:colorscheme`

### "Ghostty keybindings conflict with Neovim"

**Ghostty uses Cmd+B prefix (like tmux)**

If conflicts:
```toml
# Edit: ~/.config/ghostty/config
# Change prefix or disable specific keybindings
keybind = cmd+b>c=unbind
```

## Git Integration Issues

### "Git status not showing in statusline"

**Solutions:**
```vim
" 1. Check in git repo
:!git status

" 2. Check plugin loaded
:Lazy
" Look for git statusline plugin (lualine, etc.)

" 3. Reload
:e
```

### "Can't access lazygit"

**From tmux:**
```bash
# Check installed
lazygit --version

# From tmux:
# prefix + o (should open lazygit in floating window)
```

**From Neovim:**
```vim
:!lazygit
```

## Recovery & Emergency

### "Neovim crashed/frozen"

**Terminal frozen:**
```bash
Ctrl-z               # Suspend Neovim
fg                   # Bring back to foreground
# or
kill -9 $(pgrep nvim)  # Force kill (last resort)
```

**Neovim frozen:**
```vim
Ctrl-c               # Interrupt current operation
:qa!                 # Force quit all
```

### "Config is completely broken"

**Backup and reset:**
```bash
# 1. Backup current config
mv ~/.config/nvim ~/.config/nvim.backup

# 2. Re-stow from dotfiles
cd ~/dotfiles
stow -R -t ~ nvim

# 3. Reinstall plugins
nvim
:Lazy sync

# 4. If still broken, check health
:checkhealth
```

### "Lost work due to crash"

**Recover from swap:**
```vim
nvim filename
# Neovim prompts about swap file
# Choose (R)ecover
```

**Find all swap files:**
```bash
ls ~/.local/share/nvim/swap/
```

## Getting More Help

### Check Neovim Health

```vim
:checkhealth            " General health
:checkhealth lsp        " LSP specific
:checkhealth lazy       " Plugin manager
```

### View Messages

```vim
:messages               " See all messages
:messages clear         " Clear messages
```

### Enable Debug Logging

```lua
-- Add to init.lua temporarily
vim.lsp.set_log_level("debug")
```

Then check:
```vim
:LspLog
```

### Check Plugin Documentation

```vim
:help plugin-name
:help snacks
:help lspconfig
```

### Still Stuck?

1. **Check GitHub issues:**
   - Plugin-specific: github.com/{plugin}/issues
   - This config: github.com/durante-tech/dotfiles/issues

2. **Ask for help:**
   - Include: Neovim version (`:version`)
   - Include: Plugin versions (`:Lazy`)
   - Include: Error messages (`:messages`)
   - Include: Health check output (`:checkhealth`)

3. **Create minimal reproducer:**
```bash
# Minimal init.lua to test
nvim --clean -u minimal.lua
```

---

**Pro Tip:** When troubleshooting, use `:messages` to see what errors occurred, and `:checkhealth` to diagnose configuration issues.

**Most issues are solved by:** `:Lazy sync` + `:LspRestart` + Neovim restart!
