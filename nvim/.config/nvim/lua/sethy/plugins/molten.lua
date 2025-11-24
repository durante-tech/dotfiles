return {
    "benlubas/molten-nvim",
    version = "^1.0.0", -- use version <2.0.0 to avoid breaking changes
    dependencies = { "3rd/image.nvim" },
    build = ":UpdateRemotePlugins",
    init = function()
        -- Configuration
        vim.g.molten_image_provider = "image.nvim"
        vim.g.molten_output_win_max_height = 20
        vim.g.molten_auto_open_output = false
        vim.g.molten_wrap_output = true
        vim.g.molten_virt_text_output = true
        vim.g.molten_virt_lines_off_by_1 = true
    end,
    keys = {
        { "<leader>mi", ":MoltenInit<CR>", desc = "Initialize Molten" },
        { "<leader>me", ":MoltenEvaluateOperator<CR>", desc = "Evaluate operator", mode = "n" },
        { "<leader>ml", ":MoltenEvaluateLine<CR>", desc = "Evaluate line", mode = "n" },
        { "<leader>mr", ":MoltenReevaluateCell<CR>", desc = "Re-evaluate cell" },
        { "<leader>mv", ":<C-u>MoltenEvaluateVisual<CR>gv", desc = "Evaluate visual selection", mode = "v" },
        { "<leader>md", ":MoltenDelete<CR>", desc = "Delete Molten cell" },
        { "<leader>mo", ":MoltenShowOutput<CR>", desc = "Show output" },
        { "<leader>mh", ":MoltenHideOutput<CR>", desc = "Hide output" },
        { "[m", ":MoltenPrev<CR>", desc = "Previous cell" },
        { "]m", ":MoltenNext<CR>", desc = "Next cell" },
    },
}
