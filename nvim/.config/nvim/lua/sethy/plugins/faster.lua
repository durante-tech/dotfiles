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
                -- Threshold in MiB, NOT bytes. bigfile.lua computes
                -- `stats.size / (1024 * 1024)` and compares `filesize < for_size`;
                -- the README says "Value is in MB." and ships `filesize = 2`.
                -- The old `1000000` therefore meant a ~1 TB file, so the whole
                -- bigfile behaviour could never once fire. 2 sits just above
                -- snacks.nvim's own bigfile handler (snacks.lua: 1.5 MiB) so the
                -- two don't both pounce on the same buffer.
                filesize = 2,
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
                -- (no `defer` here: `defer` is a *feature* key, read by
                -- utils.run_on_features; init.lua only ever reads `on`,
                -- `features_disabled`, `init` and `stop` off a behaviour.)
            },
            -- Behaviour during macro execution (make macros faster)
            fastmacro = {
                -- Enable fast macro mode. The key is `on`; init.lua does
                -- `if b.on == nil then b.on = false end` and never reads
                -- `enabled` (which only worked before because tbl_deep_extend
                -- merged upstream's own `on = true` back in).
                on = true,
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
                on = true,
                -- Use the built-in vim.treesitter API, not :TSBufDisable /
                -- :TSBufEnable. Those were nvim-treesitter `master` commands;
                -- treesitter.lua pins branch = "main", whose plugin/ registers
                -- only TSInstall/TSInstallFromGrammar/TSUpdate/TSUninstall/TSLog.
                -- vim.cmd() on a missing command raises E492, and nothing in
                -- faster.nvim pcalls it (utils.run_on_features calls func(f)
                -- bare) -- so every `@` replay aborted in macro.lua before it
                -- could feed the macro keys, and every long-line file errored
                -- out of longline.lua's disable pass.
                disable = function()
                    pcall(vim.treesitter.stop, 0)
                end,
                enable = function()
                    pcall(vim.treesitter.start, 0)
                end,
            },
            -- Vim illuminate (highlight word under cursor)
            illuminate = {
                on = true,
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
                on = true,
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
                on = true,
                disable = function()
                    vim.cmd("NoMatchParen")
                end,
                enable = function()
                    vim.cmd("DoMatchParen")
                end,
            },
            -- LSP
            lsp = {
                on = true,
                disable = function()
                    vim.cmd("LspStop")
                end,
                enable = function()
                    vim.cmd("LspStart")
                end,
            },
            -- syntax / filetype / vimopts are deliberately NOT overridden.
            -- The overrides that stood here ran `:syntax off` and
            -- `:filetype off`, which are GLOBAL, and "restored" vimopts to
            -- hardcoded values instead of the buffer's own (losing foldmethod
            -- entirely). bigfile and longline only ever re-enable features from
            -- stop(), never per buffer -- so one minified file would have left
            -- the whole session with no syntax and no filetype detection.
            -- faster.nvim's shipped versions (lua/faster/features.lua) set
            -- vim.opt_local and keep a per-bufnr backup table, so they restore
            -- exactly what was there; setup() merges them in via tbl_deep_extend.
        },
    },
}
