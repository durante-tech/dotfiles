return {
    "ahmedkhalf/project.nvim",
    event = "VeryLazy",
    config = function()
        require("project_nvim").setup({
            -- Detection methods (order matters)
            detection_methods = { "lsp", "pattern" },

            -- Patterns to detect project root
            patterns = {
                ".git",
                "_darcs",
                ".hg",
                ".bzr",
                ".svn",
                "Makefile",
                "package.json",
                "Cargo.toml",
                "go.mod",
                "deno.json",
                "pyproject.toml",
            },

            -- Don't calculate root for these paths
            exclude_dirs = { "~/", "~/Downloads/*", "~/Documents/*" },

            -- Show hidden files in telescope
            show_hidden = false,

            -- Silent chdir (don't show "Changed directory" messages)
            silent_chdir = true,

            -- Scope of saved sessions (global or local)
            scope_chdir = "global",

            -- Path to store project history
            datapath = vim.fn.stdpath("data"),
        })

        -- Load telescope extension
        require("telescope").load_extension("projects")

        -- Set up keymap after extension is loaded
        vim.keymap.set("n", "<leader>pp", "<cmd>Telescope projects<CR>", { desc = "Switch project" })
    end,
}
