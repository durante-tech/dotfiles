return {
    "roobert/tailwindcss-colorizer-cmp.nvim",
    {
        "NvChad/nvim-colorizer.lua",
        dependencies = { "nvim-treesitter/nvim-treesitter" },
        opts = {},
        config = function()
            if #vim.api.nvim_list_uis() == 0 or not vim.o.termguicolors then
                return
            end

            local nvchadcolorizer = require("colorizer")
            local tailwindcolorizer = require("tailwindcss-colorizer-cmp")

            nvchadcolorizer.setup({
                user_default_options = {
                    tailwind = true,
                },
                filetypes = { "html", "css", "javascript", "typescript", "jsx", "tsx", "vue", "svelte" },
            })

            tailwindcolorizer.setup({
                color_square_width = 2,
            })

            vim.api.nvim_create_autocmd({ "BufReadPost", "BufNewFile" }, {
                callback = function()
                    if #vim.api.nvim_list_uis() == 0 or not vim.o.termguicolors then
                        return
                    end

                    nvchadcolorizer.attach_to_buffer(0)
                end,
            })

        end,
    },
}
