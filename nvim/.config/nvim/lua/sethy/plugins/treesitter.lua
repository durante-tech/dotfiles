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

            -- nvim-treesitter `main` does NOT turn highlighting on. Its README
            -- says of everything it ships: "These are not automatically
            -- enabled", and Neovim itself calls vim.treesitter.start() from
            -- exactly four runtime ftplugins (lua, markdown, help, query). So
            -- without this autocmd the parsers installed above were dead weight
            -- for the other 22 languages, which silently fell back to regex
            -- :syntax. pcall: start() asserts when the filetype has no parser
            -- (conf, text, gitcommit, the "jupyter" ft set in jupyter-config).
            vim.api.nvim_create_autocmd("FileType", {
                group = vim.api.nvim_create_augroup("sethy_treesitter_start", { clear = true }),
                callback = function(ev)
                    -- Skip buffers a runtime ftplugin already started: calling
                    -- highlighter.new() twice orphans the first highlighter,
                    -- leaving its on_changedtree callback registered on the tree.
                    if vim.treesitter.highlighter.active[ev.buf] then
                        return
                    end
                    pcall(vim.treesitter.start, ev.buf)
                end,
            })

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
