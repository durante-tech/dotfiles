# Formatter Configuration Guide

Complete formatter setup for your Neovim configuration, based on real-world usage data.

## Quick Start

**1. Open Neovim and Mason will auto-install formatters:**
```bash
nvim
# Wait for Mason to install all formatters (bottom-right notification)
# Or manually: :Mason
```

**2. Format any file:**
```vim
<leader>mp          " Space + m + p
```

**3. Auto-format on save is ENABLED** ✅

## What's Configured

### Tier 1: Web Development (90%+ projects)

| Language | Formatter | Speed | Downloads/week |
|----------|-----------|-------|----------------|
| **JavaScript** | Biome | 35x faster | 1.5M |
| **TypeScript** | Biome | 35x faster | 1.5M |
| **HTML/CSS** | Prettier | Standard | 76M |
| **JSON** | Biome | Fast | Included |
| **YAML** | Prettier | Standard | Included |
| **Markdown** | Prettier | Standard | Included |

**Why Biome for JS/TS?**
- 35x faster than Prettier
- Written in Rust (performance)
- Built-in linter + formatter
- Growing ecosystem (Astro, Remix)

**Switch to Prettier?** Uncomment lines 46-49 in `formatting.lua`

### Tier 2: Backend Languages (50-70% usage)

| Language | Formatter | Why This One |
|----------|-----------|--------------|
| **Python** | Black + isort | 30M downloads/month, "opinionated" |
| **Go** | gofumpt + goimports | Go community standard |
| **Rust** | rustfmt | Rust official formatter |
| **Ruby** | rubocop | Ruby standard |
| **C/C++** | clang-format | LLVM standard |
| **Java** | google-java-format | Google style guide |
| **PHP** | php-cs-fixer | PSR standard |

### Tier 3: Scripts & Config

| Language | Formatter | Notes |
|----------|-----------|-------|
| **Lua** | stylua | Neovim ecosystem standard |
| **Shell** | shfmt | Bash/Zsh/Sh formatter |
| **TOML** | taplo | Rust config files |
| **SQL** | sql-formatter | Database queries |
| **GraphQL** | prettier | API schemas |
| **Terraform** | terraform_fmt | Infrastructure as code |

## Installation Status

### Auto-Installed (via Mason)

These install automatically when you open Neovim:

✅ **Installed by Mason:**
- prettier, prettierd (faster)
- biome
- stylua
- shfmt
- black, isort
- gofumpt, goimports
- taplo
- yamlfmt
- sql-formatter
- markdownlint

### Manual Installation (Language-specific)

**Some formatters require language toolchains:**

**Rust (rustfmt):**
```bash
# Comes with rustup
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
```

**Ruby (rubocop):**
```bash
gem install rubocop
```

**C/C++ (clang-format):**
```bash
# macOS (comes with Xcode)
xcode-select --install

# Or via Homebrew
brew install clang-format
```

**Java (google-java-format):**
```bash
brew install google-java-format
```

**PHP (php-cs-fixer):**
```bash
composer global require friendsofphp/php-cs-fixer
```

**Terraform (terraform):**
```bash
brew tap hashicorp/tap
brew install hashicorp/tap/terraform
```

## Usage

### Format Commands

**Manual format:**
```vim
<leader>mp          " Space + m + p (format file or selection)
<leader>f           " Space + f (LSP fallback)
```

**Auto-format on save:**
```vim
:w                  " Automatically formats before saving
```

**Format injected code:**
```vim
<leader>mf          " Format code in markdown, etc.
```

### Check Formatter Status

**See available formatters:**
```vim
:ConformInfo        " Shows formatters for current file
```

**Open Mason:**
```vim
:Mason              " See all installed formatters
```

**Check formatter installation:**
```bash
# From terminal:
which prettier      # Should show path
which biome         # Should show path
which stylua        # Should show path
```

## Configuration Details

### Formatter Settings

**All formatters use 4-space indentation (configurable):**

| Formatter | Config Location | Settings |
|-----------|----------------|----------|
| **Prettier** | `formatting.lua:145` | 4 spaces, no tabs, double quotes |
| **Biome** | `formatting.lua:195` | 4 spaces |
| **StyLua** | `formatting.lua:178` | 4 spaces, double quotes preferred |
| **Black** | `formatting.lua:190` | 88 char line length |
| **shfmt** | `formatting.lua:173` | 4 spaces |

**To change indent to 2 spaces:**

Edit `formatting.lua` and change all `"4"` to `"2"` in the formatter configs (lines 145-201).

### Format on Save Settings

**Current config** (`formatting.lua:133-137`):
```lua
format_on_save = {
    lsp_fallback = true,  -- Use LSP if no formatter
    async = false,        -- Wait for format
    timeout_ms = 2000,    -- 2 second timeout
},
```

**Disable auto-format:**
```lua
-- Comment out or set to nil:
format_on_save = nil,
```

**Async formatting (don't wait):**
```lua
format_on_save = {
    lsp_fallback = true,
    async = true,         -- Don't wait (faster saves)
    timeout_ms = 2000,
},
```

## Switching Formatters

### JavaScript/TypeScript: Biome → Prettier

**In `formatting.lua`, lines 40-49:**

```lua
-- Current (Biome):
javascript = { "biome" },
typescript = { "biome" },

-- Change to (Prettier):
javascript = { "prettierd", "prettier", stop_after_first = true },
typescript = { "prettierd", "prettier", stop_after_first = true },
```

### Python: Black → Ruff

**Ruff is newer and 10-100x faster than Black.**

**Install ruff via Mason:**
```vim
:Mason
# Search "ruff", press "i" to install
```

**In `formatting.lua`, line 85:**
```lua
-- Current:
python = { "isort", "black" },

-- Change to:
python = { "ruff_format", "ruff_organize_imports" },
```

### YAML: Prettier → yamlfmt

**In `formatting.lua`, line 68:**
```lua
-- Current:
yaml = { "prettierd", "prettier", stop_after_first = true },

-- Change to:
yaml = { "yamlfmt" },
```

## Adding New Formatters

### Step 1: Check Mason Availability

```vim
:Mason
# Search for formatter name
# If available, press "i" to install
```

### Step 2: Add to Mason Auto-Install

**Edit `mason.lua`, line 54:**
```lua
ensure_installed = {
    -- ... existing formatters ...
    "new-formatter-name",  -- Add here
},
```

### Step 3: Configure in formatting.lua

**Add to `formatters_by_ft` (around line 32):**
```lua
formatters_by_ft = {
    -- ... existing configs ...
    newlang = { "formatter-name" },
},
```

### Step 4: Test

```bash
# Open a file of that type
nvim test.newlang

# Try formatting
<leader>mp

# Check status
:ConformInfo
```

## Troubleshooting

### Formatter Not Working

**1. Check if formatter is installed:**
```vim
:Mason
# Find formatter, check if marked with ✓
```

**2. Check if available for file type:**
```vim
:ConformInfo
# Shows formatters configured for current buffer
```

**3. Check formatter output:**
```vim
:messages
# Shows formatter errors
```

**4. Try LSP fallback:**
```vim
<leader>f           " Use LSP formatter instead
```

### Format Too Slow

**Increase timeout:**

Edit `formatting.lua`, line 136:
```lua
timeout_ms = 5000,  -- 5 seconds instead of 2
```

**Use async formatting:**

Edit `formatting.lua`, line 135:
```lua
async = true,  -- Don't wait for format to complete
```

**Switch to faster formatter:**
- Prettier → Biome (JS/TS)
- Black → Ruff (Python)
- prettier → specific formatter

### Format on Save Not Working

**1. Check if enabled:**
```bash
# In formatting.lua, line 133-137, ensure not commented out
```

**2. Restart Neovim:**
```vim
:qa
nvim
```

**3. Check for errors:**
```vim
:messages
```

### Formatter Crashes

**Some formatters need valid syntax:**
- Biome: Requires valid JS/TS syntax
- Black: Requires valid Python syntax
- rustfmt: Requires valid Rust syntax

**If file has syntax errors, formatter may fail.**

**Workaround:**
1. Fix syntax errors first
2. Or use LSP formatter: `<leader>f`
3. Or disable format_on_save temporarily

## Formatter Comparison

### JS/TS: Prettier vs Biome

| Feature | Prettier | Biome |
|---------|----------|-------|
| **Speed** | Baseline | 35x faster |
| **Maturity** | Since 2017 | Since 2023 |
| **Plugins** | Many | Growing |
| **Adoption** | 76M/week | 1.5M/week |
| **Linter** | Separate (ESLint) | Built-in |
| **Config** | Many options | Opinionated |
| **Recommendation** | Mature projects | New projects, speed |

### Python: Black vs Ruff

| Feature | Black | Ruff |
|---------|-------|------|
| **Speed** | Baseline | 10-100x faster |
| **Maturity** | Since 2018 | Since 2022 |
| **Adoption** | 30M/month | 5M/month |
| **Features** | Format only | Format + lint |
| **Config** | Limited | More options |
| **Recommendation** | Conservative | Modern |

## Best Practices

### 1. Keep Formatters Updated

```vim
:Mason              # Open Mason
U                   # Update all (Shift+U)
```

### 2. Use Format on Save

Enabled by default. Ensures consistent style.

### 3. Use Project-Specific Config

**Prettier:** Create `.prettierrc` in project root
```json
{
  "tabWidth": 2,
  "semi": true,
  "singleQuote": true
}
```

**Biome:** Create `biome.json`
```json
{
  "formatter": {
    "indentStyle": "space",
    "indentWidth": 2
  }
}
```

**StyLua:** Create `stylua.toml`
```toml
indent_type = "Spaces"
indent_width = 2
```

### 4. Disable for Specific Files

**In Neovim, disable format on save for current buffer:**
```vim
:lua vim.b.disable_autoformat = true
```

**Re-enable:**
```vim
:lua vim.b.disable_autoformat = false
```

### 5. Format Before Commit

**Add to `.git/hooks/pre-commit`:**
```bash
#!/bin/sh
# Format staged files before commit
nvim -c "bufdo lua vim.lsp.buf.format()" -c "qa"
```

## Quick Reference

### Keybindings

| Keys | Action | Mode |
|------|--------|------|
| `<leader>mp` | Format file or selection | Normal/Visual |
| `<leader>mf` | Format injected code | Normal/Visual |
| `<leader>f` | LSP format (fallback) | Normal |
| `:w` | Auto-format on save | Normal |

### Commands

| Command | Action |
|---------|--------|
| `:ConformInfo` | Show formatters for current file |
| `:Mason` | Open formatter installer |
| `:MasonUpdate` | Update all formatters |
| `:messages` | Show formatter errors |

### Files

| File | Purpose |
|------|---------|
| `formatting.lua` | Formatter configuration |
| `mason.lua` | Auto-install list |
| `keymaps.lua` | LSP format keybinding |

---

## Stats & Sources

Formatter recommendations based on:
- **npm downloads:** npmtrends.com (weekly downloads)
- **PyPI downloads:** pypistats.org (monthly downloads)
- **GitHub stars:** github.com (community popularity)
- **State of JS 2024:** stateofjs.com (developer survey)
- **Stack Overflow 2024:** Developer Survey
- **Ecosystem standards:** Official language recommendations

**Last updated:** January 2025

---

**Need help?** Check `:help conform.nvim` or open an issue in the conform.nvim repo.
