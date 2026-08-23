return {
    "r-pletnev/pdfreader.nvim",
    lazy = false,
    dependencies = {
        "folke/snacks.nvim",
        "nvim-telescope/telescope.nvim",
    },
    -- <leader>P, not <leader>p: pr/ps/pt collided head-on with snacks.lua's
    -- picker keys (Recent files, Grep word, todo comments). Both specs declared
    -- them as unscoped global normal-mode keys, and lazy.nvim keeps whichever
    -- plugin its unordered pairs(Config.plugins) walk registers first — so which
    -- of the two actually fired was not decidable from the config, and one set
    -- was always dead. The whole PDF group moves rather than just the three
    -- offenders, to keep one prefix per plugin. (Inside a fugitive buffer
    -- <leader>P stays gitstuff.lua's buffer-local push; PDFs aren't read there.)
    keys = {
        { "<leader>Pb", "<cmd>PDFReader showBookmarks<cr>", desc = "PDF bookmarks" },
        { "<leader>Pr", "<cmd>PDFReader showRecentBooks<cr>", desc = "Recent PDFs" },
        { "<leader>Pt", "<cmd>PDFReader showToc<cr>", desc = "PDF table of contents" },
        { "<leader>Pd", "<cmd>PDFReader setViewMode dark<cr>", desc = "PDF dark mode" },
        { "<leader>Ps", "<cmd>PDFReader setViewMode standard<cr>", desc = "PDF standard mode" },
        { "<leader>Px", "<cmd>PDFReader setViewMode text<cr>", desc = "PDF text mode" },
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
