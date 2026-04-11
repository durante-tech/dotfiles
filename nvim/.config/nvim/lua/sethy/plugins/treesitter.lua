return {
    {
        "nvim-treesitter/nvim-treesitter",
        branch = "main",
        lazy = false, -- new nvim-treesitter does NOT support lazy-loading
        build = ":TSUpdate",
        config = function()
            require("nvim-treesitter").setup({
                -- install_dir = vim.fn.stdpath('data') .. '/site' -- optional custom dir
            })

            -- Install parsers (async, no-op if already installed)
            require("nvim-treesitter").install({
                "json",
                "javascript",
                "typescript",
                "tsx",
                "go",
                "yaml",
                "html",
                "css",
                "python",
                "http",
                "prisma",
                "markdown",
                "markdown_inline",
                "svelte",
                "graphql",
                "bash",
                "lua",
                "vim",
                "dockerfile",
                "gitignore",
                "query",
                "vimdoc",
                "c",
                "java",
                "rust",
                "ron",
            })

            -- Highlighting and indentation are enabled by default via Neovim's built-in
            -- treesitter integration. No need to configure them here.

        end,
    },
    -- NOTE: js,ts,jsx,tsx Auto Close Tags
    {
        "windwp/nvim-ts-autotag",
        enabled = true,
        ft = { "html", "xml", "javascript", "typescript", "javascriptreact", "typescriptreact", "svelte" },
        config = function()
            require("nvim-ts-autotag").setup({
                opts = {
                    enable_close = true,
                    enable_rename = true,
                    enable_close_on_slash = false,
                },
                per_filetype = {
                    ["html"] = {
                        enable_close = true,
                    },
                    ["typescriptreact"] = {
                        enable_close = true,
                    },
                },
            })
        end,
    },
}
