-- faster.nvim - Auto-disable features for big files and macros
-- https://github.com/pteroctopus/faster.nvim
return {
    "pteroctopus/faster.nvim",
    lazy = false,
    opts = {
        -- Behaviours define what happens when certain conditions are met
        behaviours = {
            -- Behaviour for big files (disable expensive features)
            bigfile = {
                -- File size in bytes above which to trigger (1MB default)
                filesize = 1000000,
                -- Features to disable for big files
                features_disabled = {
                    "illuminate",    -- vim-illuminate
                    "matchparen",    -- Match parentheses highlighting
                    "lsp",           -- Language server
                    "treesitter",    -- Treesitter highlighting
                    "indent_blankline", -- Indent guides
                    "vimopts",       -- Vim options like folds
                    "syntax",        -- Syntax highlighting
                    "filetype",      -- Filetype detection
                },
                -- Set these vim options for big files
                defer = false,
            },
            -- Behaviour during macro execution (make macros faster)
            fastmacro = {
                -- Enable fast macro mode
                enabled = true,
                -- Features to disable during macro execution
                features_disabled = {
                    "lsp",
                    "treesitter",
                    "syntax",
                },
            },
        },
        -- Features configuration
        features = {
            -- Treesitter highlighting
            treesitter = {
                enabled = true,
                -- Commands to disable/enable treesitter
                disable = function()
                    vim.cmd("TSBufDisable highlight")
                end,
                enable = function()
                    vim.cmd("TSBufEnable highlight")
                end,
            },
            -- Vim illuminate (highlight word under cursor)
            illuminate = {
                enabled = true,
                disable = function()
                    pcall(function()
                        require("illuminate").pause_buf()
                    end)
                end,
                enable = function()
                    pcall(function()
                        require("illuminate").resume_buf()
                    end)
                end,
            },
            -- Indent blankline
            indent_blankline = {
                enabled = true,
                disable = function()
                    pcall(function()
                        vim.cmd("IBLDisable")
                    end)
                end,
                enable = function()
                    pcall(function()
                        vim.cmd("IBLEnable")
                    end)
                end,
            },
            -- Matchparen (highlight matching parentheses)
            matchparen = {
                enabled = true,
                disable = function()
                    vim.cmd("NoMatchParen")
                end,
                enable = function()
                    vim.cmd("DoMatchParen")
                end,
            },
            -- LSP
            lsp = {
                enabled = true,
                disable = function()
                    vim.cmd("LspStop")
                end,
                enable = function()
                    vim.cmd("LspStart")
                end,
            },
            -- Syntax highlighting
            syntax = {
                enabled = true,
                disable = function()
                    vim.cmd("syntax off")
                end,
                enable = function()
                    vim.cmd("syntax on")
                end,
            },
            -- Filetype detection
            filetype = {
                enabled = true,
                disable = function()
                    vim.cmd("filetype off")
                end,
                enable = function()
                    vim.cmd("filetype on")
                end,
            },
            -- Vim options for big files
            vimopts = {
                enabled = true,
                disable = function()
                    vim.opt_local.swapfile = false
                    vim.opt_local.foldmethod = "manual"
                    vim.opt_local.undolevels = -1
                    vim.opt_local.undoreload = 0
                    vim.opt_local.list = false
                end,
                enable = function()
                    vim.opt_local.swapfile = true
                    vim.opt_local.undolevels = 1000
                    vim.opt_local.undoreload = 10000
                    vim.opt_local.list = true
                end,
            },
        },
    },
}
