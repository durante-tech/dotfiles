return {
    "folke/flash.nvim",
    event = "VeryLazy",
    ---@type Flash.Config
    opts = {
        -- Labels to use for jump targets
        labels = "asdfghjklqwertyuiopzxcvbnm",

        -- Search configuration
        search = {
            -- Search mode: "exact", "search", "fuzzy"
            mode = "exact",
            -- Behave like `incsearch`
            incremental = false,
            -- When `false`, find only matches in the given direction
            forward = true,
            -- When `true`, search wraps around the buffer
            wrap = true,
            -- Each mode will take ignorecase and smartcase into account
            multi_window = true,
            -- Maximum number of matches to show
            max_length = false,
        },

        -- Jump configuration
        jump = {
            -- Save location in the jumplist
            jumplist = true,
            -- Jump position: "start", "end", "range"
            pos = "start",
            -- Add pattern to search history
            history = false,
            -- Jump to first match
            autojump = false,
            -- Clear highlight after jump
            nohlsearch = false,
        },

        -- Label configuration
        label = {
            -- Allow uppercase labels
            uppercase = true,
            -- Add a label for the first match in the current window
            current = true,
            -- Show labels after the match
            after = true,
            -- Show labels before the match
            before = false,
            -- Position: "overlay", "eol", "inline"
            style = "overlay",
            -- Minimum pattern length to show labels
            min_pattern_length = 0,
        },

        -- Highlight configuration
        highlight = {
            -- Show a backdrop with hl FlashBackdrop
            backdrop = true,
            -- Highlight matches
            matches = true,
            -- Extmark priority
            priority = 5000,
            -- Highlight groups
            groups = {
                match = "FlashMatch",
                current = "FlashCurrent",
                backdrop = "FlashBackdrop",
                label = "FlashLabel",
            },
        },

        -- Mode configurations
        modes = {
            -- Options for the default search mode
            search = {
                enabled = true,
                highlight = { backdrop = false },
                jump = { history = true, register = true, nohlsearch = true },
                search = {
                    mode = "search",
                    incremental = false,
                    max_length = false,
                },
            },

            -- Character mode (disabled by default to not override f/t/F/T)
            char = {
                enabled = false,
                -- Hide after jump when not using jump labels
                autohide = false,
                -- Show jump labels
                jump_labels = false,
                -- Set to `false` to use the current line only
                multi_line = true,
                -- When using jump labels, set to 'true' to use rainbow colors
                label = { exclude = "hjkliardc" },
                -- Keys used for motion
                keys = { "f", "F", "t", "T", ";", "," },
                -- Character mode configuration
                char_actions = function(motion)
                    return {
                        [";"] = "next",
                        [","] = "prev",
                        -- Set to `true` to automatically jump when there is only one match
                        [motion:lower()] = "next",
                        [motion:upper()] = "prev",
                    }
                end,
                search = { wrap = false },
                highlight = { backdrop = true },
                jump = { register = false },
            },

            -- Treesitter search
            treesitter = {
                labels = "abcdefghijklmnopqrstuvwxyz",
                jump = { pos = "range" },
                search = { incremental = false },
                label = { before = true, after = true, style = "inline" },
                highlight = {
                    backdrop = false,
                    matches = false,
                },
            },

            -- Treesitter search for selections
            treesitter_search = {
                jump = { pos = "range" },
                search = { multi_window = true, wrap = true, incremental = false },
                remote_op = { restore = true },
                label = { before = true, after = true, style = "inline" },
            },

            -- Remote flash
            remote = {
                remote_op = { restore = true, motion = true },
            },
        },

        -- Display a prompt to enter pattern
        prompt = {
            enabled = true,
            prefix = { { "⚡", "FlashPromptIcon" } },
            win_config = {
                relative = "editor",
                width = 1,
                height = 1,
                row = -1,
                col = 0,
                zindex = 1000,
            },
        },

        -- Action to perform when picking a label
        action = nil,

        -- Match pattern
        pattern = "",

        -- When `true`, flash will be triggered from a macro
        continue = false,
    },

    -- Keymaps
    keys = {
        -- Basic Flash jump (press 's' then 2 chars)
        {
            "s",
            mode = { "n", "x", "o" },
            function() require("flash").jump() end,
            desc = "Flash Jump"
        },

        -- Treesitter Flash (jump to code structures)
        {
            "S",
            mode = { "n", "x", "o" },
            function() require("flash").treesitter() end,
            desc = "Flash Treesitter"
        },

        -- Remote Flash (use in operator-pending mode)
        {
            "r",
            mode = "o",
            function() require("flash").remote() end,
            desc = "Remote Flash"
        },

        -- Treesitter Search
        {
            "R",
            mode = { "o", "x" },
            function() require("flash").treesitter_search() end,
            desc = "Treesitter Search"
        },

        -- Toggle Flash Search in command mode
        {
            "<c-s>",
            mode = { "c" },
            function() require("flash").toggle() end,
            desc = "Toggle Flash Search"
        },

        -- Additional useful mappings

        -- Jump to line
        {
            "<leader>fl",
            mode = { "n", "x", "o" },
            function()
                require("flash").jump({
                    search = { mode = "search", max_length = 0 },
                    label = { after = { 0, 0 } },
                    pattern = "^"
                })
            end,
            desc = "Flash Jump to Line"
        },

        -- Jump to word
        {
            "<leader>fw",
            mode = { "n", "x", "o" },
            function()
                require("flash").jump({
                    pattern = ".", -- any char
                    search = {
                        mode = function(str)
                            return "\\<" .. str
                        end,
                    },
                })
            end,
            desc = "Flash Jump to Word"
        },
    },

    -- Custom highlight groups (using rose-pine colors)
    config = function(_, opts)
        require("flash").setup(opts)

        -- Set custom highlight groups
        vim.api.nvim_set_hl(0, "FlashLabel", {
            fg = "#191724",
            bg = "#ffff00",
            bold = true
        })
        vim.api.nvim_set_hl(0, "FlashCurrent", {
            fg = "#191724",
            bg = "#eb6f92",
            bold = true
        })
        vim.api.nvim_set_hl(0, "FlashMatch", {
            fg = "#9ccfd8",
            bg = "NONE",
            bold = true
        })
        vim.api.nvim_set_hl(0, "FlashBackdrop", {
            fg = "#6e6a86",
            bg = "NONE"
        })
        vim.api.nvim_set_hl(0, "FlashPromptIcon", {
            fg = "#ffff00",
            bold = true
        })
    end,
}
