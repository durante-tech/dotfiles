return {
    "williamboman/mason.nvim",
    lazy = false,
    dependencies = {
        "williamboman/mason-lspconfig.nvim",
        "WhoIsSethDaniel/mason-tool-installer.nvim",
        "neovim/nvim-lspconfig",
    },
    config = function()
        -- import mason and mason_lspconfig
        local mason = require("mason")
        local mason_lspconfig = require("mason-lspconfig")
        local mason_tool_installer = require("mason-tool-installer")

        -- NOTE: LSP configuration moved to lspconfig.lua
        -- Using blink.cmp for capabilities (see lspconfig.lua)

        -- enable mason and configure icons
        mason.setup({
            ui = {
                icons = {
                    package_installed = "✓",
                    package_pending = "➜",
                    package_uninstalled = "✗",
                },
            },
        })

        mason_lspconfig.setup({
            automatic_enable = false,
            -- servers for mason to install
            ensure_installed = {
                "lua_ls",
                "ts_ls", -- currently using a ts plugin
                "html",
                "cssls",
                "tailwindcss",
                "gopls",
                "angularls",
                "emmet_language_server",
                -- "eslint",
                "marksman",
            },
        })

        mason_tool_installer.setup({
            ensure_installed = {
                -- Formatters (most common, based on npm downloads & usage)
                "prettier",      -- JS/TS/HTML/CSS/JSON/YAML/Markdown (76M downloads/week)
                "prettierd",     -- Prettier daemon (faster)
                "stylua",        -- Lua formatter (Neovim ecosystem standard)
                "shfmt",         -- Shell script formatter
                "black",         -- Python formatter (traditional, 30M downloads/month)
                "isort",         -- Python import sorter
                "gofumpt",       -- Go formatter (stricter than gofmt)
                "goimports",     -- Go imports organizer
                "taplo",         -- TOML formatter
                "yamlfmt",       -- YAML formatter (alternative to prettier)
                "sql-formatter", -- SQL formatter
                "markdownlint",  -- Markdown linter
                "biome",         -- JS/TS/JSON formatter & linter (fast, Rust-based)

                -- Linters
                "pylint",
                "eslint_d",      -- ESLint daemon (faster)
                "shellcheck",    -- Shell script linter

                -- LSP servers
                "clangd",
                "denols",
            },

            -- NOTE: mason BREAKING Change! Removed setup_handlers
            -- moved lsp configuration settings back into lspconfig.lua file
        })
    end,
}
