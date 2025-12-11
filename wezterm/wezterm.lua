local wezterm = require("wezterm")
-- local sessionizer = require("lua.sessionizer")
local config = wezterm.config_builder()

-- appearance
config.font = wezterm.font("Codelia Ligatures")
config.font_size = 16
config.cell_width = 0.9  -- Reduce character spacing (1.0 = default)
config.color_scheme = "rose-pine"
config.colors = {
    background = "#000",
    cursor_bg = "#ffff00",
    cursor_fg = "#191724",
    cursor_border = "#ffff00",
}
config.window_padding = {
    left = 18,
    right = 15,
    top = 20,
    bottom = 5,
}

config.max_fps = 120
config.animation_fps = 120
config.front_end = "WebGpu"
config.prefer_egl = true


config.enable_tab_bar = false
config.window_decorations = "RESIZE"
config.window_close_confirmation = "NeverPrompt"
config.automatically_reload_config = true
config.audible_bell = "Disabled"
config.adjust_window_size_when_changing_font_size = false
config.harfbuzz_features = { "calt=1", "liga=1", "dlig=1" }  -- Enable ligatures

-- mapping ctrl a to leader similar to tmux prefix
config.leader = { key = "a" , mods = "CTRL" , timeout_milliseconds = 1000 }
config.keys = {
    -- {
    --     key = "f",
    --     mods = "CTRL",
    --     action = wezterm.action_callback(sessionizer.toggle)
    -- },
    -- Key bindings delete word
    {
        key = "LeftArrow",
        mods = "OPT",
        action = wezterm.action({ SendString = "\x1bb" }),
    },
    {
        key = "RightArrow",
        mods = "OPT",
        action = wezterm.action({ SendString = "\x1bf" }),
    },
    -- Example: programming workspace with leader v
    -- Customize with your own project path
    -- {
    --     key = "v",
    --     mods = "LEADER",
    --     action = wezterm.action.SwitchToWorkspace {
    --         name = "coding",
    --         spawn = {
    --             cwd = wezterm.home_dir .. "/Projects",
    --             args = { "nvim" },
    --         },
    --     },
    -- },
}


return config
