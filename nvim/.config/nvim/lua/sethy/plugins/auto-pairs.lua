return {
    "windwp/nvim-autopairs",
    event = { "InsertEnter" },
    config = function()
        local autopairs = require("nvim-autopairs")

        autopairs.setup({
            check_ts = true, -- treesitter enabled
            ts_config = {
                lua = { "string" }, -- dont add pairs in lua string treesitter nodes
                java = false, -- dont check treesitter on java
            },
        })

        -- NOTE: nvim-cmp integration removed since we're using blink.cmp
        -- Autopairs still works for basic pair completion
        -- blink.cmp handles completion confirmation separately
    end,
}
