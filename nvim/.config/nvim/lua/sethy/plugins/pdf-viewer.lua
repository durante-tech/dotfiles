return {
    "r-pletnev/pdfreader.nvim",
    lazy = false,
    dependencies = {
        "folke/snacks.nvim",
        "nvim-telescope/telescope.nvim",
    },
    keys = {
        { "<leader>pb", "<cmd>PDFReader showBookmarks<cr>", desc = "PDF bookmarks" },
        { "<leader>pr", "<cmd>PDFReader showRecentBooks<cr>", desc = "Recent PDFs" },
        { "<leader>pt", "<cmd>PDFReader showToc<cr>", desc = "PDF table of contents" },
        { "<leader>pd", "<cmd>PDFReader setViewMode dark<cr>", desc = "PDF dark mode" },
        { "<leader>ps", "<cmd>PDFReader setViewMode standard<cr>", desc = "PDF standard mode" },
        { "<leader>px", "<cmd>PDFReader setViewMode text<cr>", desc = "PDF text mode" },
    },
    config = function()
        require("pdfreader").setup({
            -- Rendering settings
            view_mode = "dark", -- "standard", "dark", or "text"
            autosave = true,    -- Save reading position

            -- Zoom settings
            default_zoom = 1.0,
            zoom_step = 0.1,
        })
    end,
}
