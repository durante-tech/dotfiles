# LSP & Completion Workflows

Master intelligent code features powered by Language Server Protocol.

## What is LSP?

Language Server Protocol provides IDE-like features:
- **Autocomplete** - Intelligent code completion
- **Go to Definition** - Jump to where things are defined
- **Find References** - See all usages
- **Diagnostics** - Real-time error checking
- **Code Actions** - Quick fixes and refactorings
- **Hover Documentation** - Inline docs
- **Rename** - Safe refactoring across files

## LSP Configuration

### Current Setup (Neovim 0.11+)

This config uses `vim.lsp.config` with these servers:

| Language | Server | Features |
|----------|--------|----------|
| Lua | `lua_ls` | Neovim API aware |
| JavaScript/TypeScript | `ts_ls` | Full TS support |
| Deno | `denols` | Deno projects only |
| HTML/CSS | `emmet_ls`, `emmet_language_server` | Emmet expansion |
| Go | `gopls` | Official Go server |

### Installing New LSP Servers

```vim
:Mason              " Open Mason
/search             " Search for server
i                   " Install selected
```

Or see [lspconfig.lua](../../nvim/.config/nvim/lua/sethy/plugins/lsp/lspconfig.lua) for manual configuration.

## Core LSP Features

### Go to Definition

| Keys | Action | Use Case |
|------|--------|----------|
| `gd` | Go to definition | Jump to where symbol is defined |
| `gD` | Go to declaration | Jump to declaration (C/C++) |
| `Ctrl-o` | Jump back | Return to previous location |

**Workflow:**
```javascript
// In app.js:
import { getUser } from './user';
             ^
// Cursor on getUser:
1. gd           // Jumps to user.js where getUser is defined
2. Read code
3. Ctrl-o       // Jump back to app.js
```

### Find References

| Keys | Action |
|------|--------|
| `gR` | Show all references in picker |
| `Ctrl-j`/`k` | Navigate results |
| `Enter` | Jump to reference |

**Workflow:**
```javascript
// Want to see everywhere getUser is called:
1. Cursor on getUser
2. gR                   // Picker shows all usages
3. Review list
4. Enter on one         // Jump to it
5. Ctrl-o               // Jump back to list
```

### Hover Documentation

| Keys | Action |
|------|--------|
| `K` | Show documentation |
| `K` (again) | Focus documentation window |
| `q` | Close documentation |

**When to use:**
- Understand function parameters
- Read type definitions
- See return types
- Quick API reference

```javascript
// Cursor on any standard library function:
Math.floor(x)
     ^
K       // Shows: "Returns the largest integer less than or equal to x"
```

### Type Information

| Keys | Action |
|------|--------|
| `gt` | Go to type definition |
| `gi` | Go to implementation |

**Workflow:**
```typescript
// Cursor on a variable:
const user: User = getUser();
            ^
1. gt           // Jump to User interface definition
2. K            // Read documentation
3. gi           // Jump to concrete implementation
```

### Signature Help

| Keys | Mode | Action |
|------|------|--------|
| `Ctrl-h` | INSERT | Show function signature |

**While typing:**
```javascript
console.log(
           ^
// Ctrl-h shows: console.log(message?: any, ...optionalParams: any[]): void
```

## Code Actions & Refactoring

### Code Actions

| Keys | Action | Use Case |
|------|--------|----------|
| `<leader>vca` | Show code actions | Quick fixes, imports, refactorings |

**Examples:**
```javascript
// Underlined error: unused variable
const user = getUser();

<leader>vca
// Shows:
// 1. Remove unused variable
// 2. Prefix with underscore
// 3. Disable ESLint for this line
```

```typescript
// Missing import:
const result: Result = {};
              ^
<leader>vca
// Shows:
// 1. Import Result from './types'
// 2. Add type definition
```

### Rename Symbol

| Keys | Action |
|------|--------|
| `<leader>rn` | Rename symbol across project |

**Workflow:**
```javascript
// Rename getUser → fetchUser everywhere:
1. Cursor on getUser (any usage)
2. <leader>rn
3. Type: fetchUser
4. Enter
// LSP renames in ALL files!
```

**Pro Tip:** LSP rename is safe - it understands scope and won't rename unrelated symbols with the same name.

## Diagnostics (Errors & Warnings)

### Viewing Diagnostics

| Keys | Action |
|------|--------|
| `<leader>d` | Show diagnostics for current line |
| `<leader>D` | Show all diagnostics for buffer |
| `<leader>xw` | Open trouble workspace diagnostics |

### Diagnostic Signs

This config shows diagnostics in the gutter:

| Icon | Severity |
|------|----------|
|  | Error |
|  | Warning |
| 󰠠 | Hint |
|  | Info |

### Navigating Diagnostics

```vim
:cnext      " Next diagnostic
:cprev      " Previous diagnostic
:copen      " Open quickfix list
```

**Workflow:**
```javascript
// File has 5 errors:
1. <leader>D        // See all errors in picker
2. Navigate list    // Review each
3. Enter            // Jump to error
4. <leader>vca      // See quick fixes
5. Select fix       // Apply
6. <leader>D        // Check remaining errors
```

## Autocomplete

### Using Blink.cmp

Blink.cmp is a Rust-based completion engine. Completion appears automatically as you type.

**In INSERT mode:**

| Keys | Action |
|------|--------|
| `Ctrl-j` / `Ctrl-k` | Navigate completions |
| `Ctrl-n` / `Ctrl-p` | Navigate completions (alt) |
| `Ctrl-y` / `Enter` | Confirm selection |
| `Ctrl-e` | Close completion |
| `Ctrl-space` | Toggle documentation |
| `Ctrl-b` / `Ctrl-f` | Scroll documentation |
| `Tab` / `Shift-Tab` | Navigate snippets / completions |

### Completion Sources

This config includes completions from:
- LSP (intelligent, context-aware)
- Buffer words (text in current buffer)
- Path (file paths)
- Snippets

**Completion Icons:**
```
 ƒ   - Function
 𝒗   - Variable
   - Class
   - Module
 󰜢  - Property
   - Field
   - Interface
   - Keyword
   - Snippet
```

### Snippets

Snippets expand common patterns:

```javascript
// Type "fn" and select snippet:
fn<Tab>
// Expands to:
function name(params) {
    |cursor here|
}

// Type, then Tab to next field
// Tab again to next field
// Esc to exit snippet mode
```

**Common Snippets:**
- `fn` - Function
- `if` - If statement
- `for` - For loop
- `cl` - console.log
- `try` - Try-catch

## LSP Workflows

### Workflow 1: Exploring New API

```javascript
// You see: import { useEffect } from 'react';

1. Cursor on useEffect
2. gd              // Jump to definition
3. K               // Read documentation
4. gR              // See example usages in project
5. Review examples
6. Ctrl-o Ctrl-o   // Jump back to your file
7. Start typing useEffect(
8. Ctrl-h          // See signature
```

### Workflow 2: Fixing Type Errors

```typescript
// TypeScript error: Type 'string' is not assignable to type 'number'
const age: number = "30";
                    ^^^^

1. <leader>d           // Read error details
2. <leader>vca         // See quick fixes
   - Convert to number
   - Change type to string
   - Disable type checking
3. Select "Convert to number"
4. Code becomes: const age: number = Number("30");
```

### Workflow 3: Refactoring

```javascript
// Rename getUserData → fetchUserData everywhere

1. /getUserData        // Find first usage
2. <leader>rn          // LSP rename
3. fetchUserData
4. Enter               // Renames in all files!

// Then verify:
5. <leader>ps          // Grep old name
   getUserData
6. No results!         // Success
```

### Workflow 4: Adding Imports

```javascript
// You type:
const data = axios.get('/api/users');
             ^^^^^

// Error: Cannot find name 'axios'
1. <leader>vca
   // Shows: "Import axios from 'axios'"
2. Select import
3. Auto-adds: import axios from 'axios';
```

### Workflow 5: Understanding Errors

```javascript
// 50 errors after dependency update
1. <leader>D           // Open diagnostics list
2. Review patterns     // See common errors
3. Sort by type        // Group similar errors
4. Fix most common     // Address root causes
5. <leader>D           // Recheck remaining
```

## LSP Configuration

### Check LSP Status

```vim
:LspInfo               " Show attached servers
:checkhealth lsp       " Check LSP health
```

### Restart LSP

| Keys | Action |
|------|--------|
| `<leader>rs` | Restart LSP for current buffer |

**When to restart:**
- After installing new dependencies
- After changing config files
- When LSP stops responding

### LSP Logs

```vim
:LspLog                " View LSP logs (debugging)
```

## Language-Specific Features

### JavaScript/TypeScript

**Organize Imports:**
```vim
:OrganizeImports       " Remove unused, sort imports
```

**Inlay Hints:**
```typescript
// Shows inline type hints:
const user = getUser();
      ^^^^ const user: User
```

### Go

**Gofumpt Formatting:**
Enabled automatically on save.

**Staticcheck:**
Integrated linting for Go best practices.

### Lua (Neovim Config)

**Vim API Completion:**
```lua
vim.api.nvim_
        ^^^^^ -- Shows all nvim_ functions
```

**Diagnostics for Config:**
Warns about:
- Undefined vim functions
- Typos in options
- Deprecated APIs

## Customizing LSP

### Adding New Server

See [LSP Configuration](../plugins/lsp.md) for details.

Quick example:
```lua
-- In lspconfig.lua:
vim.lsp.config.rust_analyzer = {
    capabilities = capabilities,
    settings = {
        ['rust-analyzer'] = {
            cargo = {
                allFeatures = true,
            },
        },
    },
}
vim.lsp.enable("rust_analyzer")
```

### Disabling LSP for File

```vim
:LspStop               " Stop LSP for current buffer
```

### Per-Project LSP Settings

Create `.vim/lsp.lua` in project root:
```lua
-- Project-specific LSP settings
return {
    settings = {
        typescript = {
            format = { enable = false },  -- Disable TS formatting
        },
    },
}
```

## Troubleshooting

### LSP Not Starting

```vim
:LspInfo               " Check if server attached
:checkhealth lsp       " Check for issues
```

**Common fixes:**
1. Install server: `:Mason`
2. Restart LSP: `<leader>rs`
3. Check logs: `:LspLog`

### Slow Completions

**Solutions:**
- Disable completion sources you don't use
- Increase `updatetime` in config
- Check `:LspInfo` for multiple servers

### Wrong Completions

**Causes:**
- Wrong LSP server attached (check `:LspInfo`)
- Conflicting servers (e.g., denols + ts_ls)
- Incorrect project root detection

**Fixes:**
- Ensure proper root markers (.git, package.json)
- Check server configuration in lspconfig.lua
- Use correct project structure

### Diagnostics Not Showing

```vim
:lua vim.diagnostic.enable()    " Enable diagnostics
```

Check signs in config:
```lua
-- Should show diagnostic icons in gutter
vim.diagnostic.config({
    signs = true,
    virtual_text = true,
})
```

## Pro Tips

### Quick Documentation Lookup
- `K` twice enters doc window (scrollable)
- `K` on doc window closes it

### Bulk Refactoring
1. `gR` - See all references
2. Review in picker
3. `<leader>rn` - Rename all at once

### Learning New APIs
Use `K` liberally! It's faster than switching to browser docs.

### Type-Driven Development
1. Write types first
2. Let LSP suggest implementations
3. Use code actions for scaffolding

### Diagnostic Filtering
```lua
-- In lspconfig.lua, per-server:
vim.lsp.config.ts_ls = {
    handlers = {
        ["textDocument/publishDiagnostics"] = function(_, result, ctx, config)
            -- Filter out certain diagnostics
            result.diagnostics = vim.tbl_filter(function(diagnostic)
                return diagnostic.severity ~= vim.diagnostic.severity.HINT
            end, result.diagnostics)
            vim.lsp.diagnostic.on_publish_diagnostics(_, result, ctx, config)
        end,
    },
}
```

---

**Practice Challenge:**
1. Open a project file
2. Use `gR` on 5 different symbols
3. Try `<leader>rn` to rename one
4. Use `K` on every function you don't recognize
5. Fix an error using `<leader>vca`

**Next:** [Search & Replace Workflows](search-replace.md)
