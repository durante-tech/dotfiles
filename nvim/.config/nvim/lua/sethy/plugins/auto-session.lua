return {
    "rmagatti/auto-session",
    lazy = false,
    config = function()
        local auto_session = require("auto-session")

        auto_session.setup({
            -- Auto restore session when opening nvim without arguments
            auto_restore_enabled = true,

            -- Auto save session on exit
            auto_save_enabled = true,

            -- Suppress auto-restore in these directories
            auto_session_suppress_dirs = {
                "~/",
                "~/Downloads",
                "~/Documents",
                "~/Desktop",
                "~/dotfiles",
                "/tmp",
            },

            -- Use git branch in session name for branch-specific sessions
            auto_session_use_git_branch = true,

            -- Session lens (Telescope integration)
            session_lens = {
                load_on_setup = true,
                theme_conf = { border = true },
                previewer = false,
            },
        })

        local keymap = vim.keymap
        -- Manual session management
        keymap.set("n", "<leader>wr", "<cmd>SessionRestore<CR>", { desc = "Restore session for cwd" })
        keymap.set("n", "<leader>ws", "<cmd>SessionSave<CR>", { desc = "Save session for cwd" })
        keymap.set("n", "<leader>wd", "<cmd>SessionDelete<CR>", { desc = "Delete session for cwd" })

        -- Session browsing (SessionSearch works without Telescope)
        keymap.set("n", "<leader>wf", "<cmd>SessionSearch<CR>", { desc = "Find and switch session" })
        keymap.set("n", "<leader>wl", "<cmd>SessionSearch<CR>", { desc = "List all sessions" })
    end,
}
