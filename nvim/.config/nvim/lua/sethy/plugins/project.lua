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

        -- Keymap using Snacks picker (Telescope is disabled)
        vim.keymap.set("n", "<leader>pp", function()
            local projects = require("project_nvim").get_recent_projects()
            require("snacks").picker.select(projects, {
                prompt = "Projects",
                format = function(item) return vim.fn.fnamemodify(item, ":~") end,
            }, function(selected)
                if selected then vim.cmd("cd " .. selected) end
            end)
        end, { desc = "Switch project" })
    end,
}
