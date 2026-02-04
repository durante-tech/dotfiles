-- vim.g.loaded_netrw = 0
-- vim.g.loaded_netrwPlugin = 0
-- vim.cmd("let g:netrw_liststyle = 3")
-- Disable netrw banner
vim.cmd("let g:netrw_banner = 0")

-- line numbers
vim.opt.nu = true
vim.opt.relativenumber = true

-- indentation
vim.opt.tabstop = 4
vim.opt.softtabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true
vim.opt.smartindent = true

-- wrapping (soft wrap - visual only, no line breaks)
vim.opt.wrap = true              -- Enable visual line wrapping
vim.opt.linebreak = true         -- Wrap at word boundaries (nicer)
vim.opt.breakindent = true       -- Maintain indentation on wrapped lines
vim.opt.showbreak = "↪ "         -- Symbol for wrapped lines (optional, can remove)
-- vim.opt.textwidth = 0         -- Don't insert actual line breaks (0 = disabled)

-- backup and undo
vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.undodir = os.getenv("HOME") .. "/.vim/undodir"
vim.opt.undofile = true

-- search
vim.opt.inccommand = "split"

-- UI
vim.opt.background = "dark"
vim.opt.scrolloff = 8
vim.opt.signcolumn = "yes"

-- folding (for nvim-ufo)
vim.o.foldenable = true
vim.o.foldmethod = "manual"
vim.o.foldlevel = 99
vim.o.foldcolumn = "0"

-- window splits
vim.opt.splitright = true
vim.opt.splitbelow = true

-- Auto-reload files changed outside of Neovim
vim.opt.autoread = true
vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter", "CursorHold", "CursorHoldI" }, {
    pattern = "*",
    callback = function()
        if vim.fn.mode() ~= "c" then  -- Don't check while in command-line mode
            vim.cmd("checktime")
        end
    end,
})
-- Notify when file is reloaded
vim.api.nvim_create_autocmd("FileChangedShellPost", {
    pattern = "*",
    callback = function()
        vim.notify("File changed on disk. Buffer reloaded.", vim.log.levels.WARN)
    end,
})

-- misc
vim.opt.isfname:append("@-@")
vim.opt.updatetime = 50
vim.opt.colorcolumn = "80"
vim.opt.clipboard:append("unnamedplus")
vim.opt.mouse = "a"

-- cursor customization (yellow cursor)
vim.opt.guicursor = "n-v-c:block-Cursor/lCursor,i-ci-ve:ver25-Cursor/lCursor,r-cr:hor20,o:hor50"
vim.opt.cursorline = true  -- Highlight the line where cursor is

-- Set cursor highlight colors (bright yellow with rose-pine compatibility)
vim.api.nvim_create_autocmd("ColorScheme", {
  pattern = "*",
  callback = function()
    -- Use rose-pine base for contrast with yellow cursor
    vim.api.nvim_set_hl(0, "Cursor", { fg = "#191724", bg = "#ffff00" })  -- Yellow cursor with rose-pine base
    vim.api.nvim_set_hl(0, "lCursor", { fg = "#191724", bg = "#ffff00" }) -- Yellow cursor (for language-specific)
    vim.api.nvim_set_hl(0, "CursorLineNr", { fg = "#ffff00", bold = true }) -- Yellow line number
    vim.api.nvim_set_hl(0, "CursorLine", { bg = "#1f1d2e" }) -- Subtle rose-pine surface for cursor line
  end,
})

-- Apply immediately for current session
vim.api.nvim_set_hl(0, "Cursor", { fg = "#191724", bg = "#ffff00" })
vim.api.nvim_set_hl(0, "lCursor", { fg = "#191724", bg = "#ffff00" })
vim.api.nvim_set_hl(0, "CursorLineNr", { fg = "#ffff00", bold = true })
vim.api.nvim_set_hl(0, "CursorLine", { bg = "#1f1d2e" })
