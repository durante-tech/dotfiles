return {
    "benlubas/molten-nvim",
    version = "^1.0.0", -- use version <2.0.0 to avoid breaking changes
    dependencies = { "3rd/image.nvim" },
    build = ":UpdateRemotePlugins",
    ft = { "python", "jupyter" },
    init = function()
        -- Molten Configuration
        vim.g.molten_image_provider = "image.nvim"
        vim.g.molten_output_win_max_height = 20
        vim.g.molten_auto_open_output = true  -- Auto-show output after execution
        vim.g.molten_wrap_output = true
        vim.g.molten_virt_text_output = true
        vim.g.molten_virt_lines_off_by_1 = true

        -- Output window styling
        vim.g.molten_output_win_border = { "╭", "─", "╮", "│", "╯", "─", "╰", "│" }
        vim.g.molten_output_win_cover_gutter = true
        vim.g.molten_output_show_more = true

        -- Virtual text configuration
        vim.g.molten_enter_output_behavior = "open_then_enter"
        vim.g.molten_use_border_highlights = true
    end,
    config = function()
        -- Highlight groups for Molten
        vim.api.nvim_set_hl(0, "MoltenOutputBorder", { fg = "#ffff00", bg = "NONE" })  -- Yellow border
        vim.api.nvim_set_hl(0, "MoltenOutputWin", { bg = "#1f1d2e" })  -- Rose-pine surface
        vim.api.nvim_set_hl(0, "MoltenCell", { bg = "#26233a" })  -- Slightly lighter for cells

        -- Note: Auto-initialization removed to prevent errors
        -- Manually initialize Molten with:
        --   :MoltenInit python3
        -- Or use keybinding: <leader>mI
    end,
    keys = {
        -- Initialize/Kernel Management
        { "<leader>mi", ":MoltenInit<CR>", desc = "Initialize Molten kernel" },
        { "<leader>mI", ":MoltenInit python3<CR>", desc = "Initialize Python3 kernel" },
        { "<leader>mD", ":MoltenDeinit<CR>", desc = "Deinitialize Molten kernel" },
        { "<leader>mR", ":MoltenRestart!<CR>", desc = "Restart kernel" },

        -- Execution
        { "<leader>me", ":MoltenEvaluateOperator<CR>", desc = "Evaluate operator", mode = "n" },
        { "<leader>ml", ":MoltenEvaluateLine<CR>", desc = "Evaluate line", mode = "n" },
        { "<leader>mr", ":MoltenReevaluateCell<CR>", desc = "Re-evaluate cell" },
        { "<leader>mv", ":<C-u>MoltenEvaluateVisual<CR>gv", desc = "Evaluate visual selection", mode = "v" },
        { "<leader>mc", ":MoltenEvaluateCell<CR>", desc = "Evaluate current cell" },

        -- Cell Management
        { "<leader>md", ":MoltenDelete<CR>", desc = "Delete Molten cell" },
        { "[m", ":MoltenPrev<CR>", desc = "Previous cell" },
        { "]m", ":MoltenNext<CR>", desc = "Next cell" },

        -- Output Management
        { "<leader>mo", ":MoltenShowOutput<CR>", desc = "Show output" },
        { "<leader>mh", ":MoltenHideOutput<CR>", desc = "Hide output" },
        { "<leader>mO", ":MoltenEnterOutput<CR>", desc = "Enter output window" },

        -- Quick Run
        { "<leader>rr", ":MoltenEvaluateCell<CR>", desc = "Run cell", ft = { "python", "jupyter" } },
        { "<leader>ra", ":MoltenEvaluateAll<CR>", desc = "Run all cells", ft = { "python", "jupyter" } },
    },
}
