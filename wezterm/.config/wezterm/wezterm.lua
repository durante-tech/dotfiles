-- WezTerm Configuration - Rose Pine Theme (matching Ghostty)
local wezterm = require("wezterm")
local config = wezterm.config_builder()

-- Rose Pine color scheme
config.colors = {
	foreground = "#e0def4",
	background = "#000000",
	cursor_fg = "#000000",
	cursor_bg = "#ffff00",
	cursor_border = "#ffff00",
	selection_fg = "#e0def4",
	selection_bg = "#2a2837",
	ansi = {
		"#26233a", -- black
		"#eb6f92", -- red
		"#9ccfd8", -- green
		"#f6c177", -- yellow
		"#31748f", -- blue
		"#c4a7e7", -- magenta
		"#ebbcba", -- cyan
		"#e0def4", -- white
	},
	brights = {
		"#6e6a86", -- bright black
		"#eb6f92", -- bright red
		"#9ccfd8", -- bright green
		"#f6c177", -- bright yellow
		"#31748f", -- bright blue
		"#c4a7e7", -- bright magenta
		"#ebbcba", -- bright cyan
		"#e0def4", -- bright white
	},
}

-- Window appearance
config.window_background_opacity = 0.75
config.macos_window_background_blur = 23
config.window_decorations = "RESIZE"
config.window_padding = {
	left = 10,
	right = 10,
	top = 10,
	bottom = 10,
}

-- Font configuration
config.font = wezterm.font("JetBrainsMono Nerd Font")
config.font_size = 16.0
config.cell_width = 0.95 -- Slightly tighter spacing like Ghostty's -5%
config.harfbuzz_features = { "calt=1", "liga=1", "dlig=1" } -- Ligatures

-- Cursor
config.default_cursor_style = "SteadyBlock"
config.cursor_blink_rate = 0

-- Tab bar
config.enable_tab_bar = true
config.hide_tab_bar_if_only_one_tab = true
config.tab_bar_at_bottom = false
config.use_fancy_tab_bar = false

-- General behavior
config.automatically_reload_config = true
config.window_close_confirmation = "NeverPrompt"
config.hide_mouse_cursor_when_typing = true
config.native_macos_fullscreen_mode = true

-- macOS specific
config.send_composed_key_when_left_alt_is_pressed = false
config.send_composed_key_when_right_alt_is_pressed = false

-- Key bindings (tmux-style with Cmd+B leader)
config.leader = { key = "b", mods = "CMD", timeout_milliseconds = 1000 }
config.keys = {
	-- Reload config
	{ key = "r", mods = "LEADER", action = wezterm.action.ReloadConfiguration },

	-- Close pane
	{ key = "x", mods = "LEADER", action = wezterm.action.CloseCurrentPane({ confirm = false }) },

	-- New tab
	{ key = "c", mods = "LEADER", action = wezterm.action.SpawnTab("CurrentPaneDomain") },

	-- New window
	{ key = "n", mods = "LEADER", action = wezterm.action.SpawnWindow },

	-- Tab navigation
	{ key = "1", mods = "LEADER", action = wezterm.action.ActivateTab(0) },
	{ key = "2", mods = "LEADER", action = wezterm.action.ActivateTab(1) },
	{ key = "3", mods = "LEADER", action = wezterm.action.ActivateTab(2) },
	{ key = "4", mods = "LEADER", action = wezterm.action.ActivateTab(3) },
	{ key = "5", mods = "LEADER", action = wezterm.action.ActivateTab(4) },
	{ key = "6", mods = "LEADER", action = wezterm.action.ActivateTab(5) },
	{ key = "7", mods = "LEADER", action = wezterm.action.ActivateTab(6) },
	{ key = "8", mods = "LEADER", action = wezterm.action.ActivateTab(7) },
	{ key = "9", mods = "LEADER", action = wezterm.action.ActivateTab(8) },

	-- Splitting (like Ghostty)
	{ key = "\\", mods = "LEADER", action = wezterm.action.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
	{ key = "-", mods = "LEADER", action = wezterm.action.SplitVertical({ domain = "CurrentPaneDomain" }) },

	-- Pane navigation
	{ key = "h", mods = "LEADER", action = wezterm.action.ActivatePaneDirection("Left") },
	{ key = "j", mods = "LEADER", action = wezterm.action.ActivatePaneDirection("Down") },
	{ key = "k", mods = "LEADER", action = wezterm.action.ActivatePaneDirection("Up") },
	{ key = "l", mods = "LEADER", action = wezterm.action.ActivatePaneDirection("Right") },

	-- Equalize panes
	{ key = "e", mods = "LEADER", action = wezterm.action.PaneSelect({ mode = "SwapWithActive" }) },

	-- Quick terminal toggle (comma like Ghostty)
	{ key = ",", mods = "LEADER", action = wezterm.action.TogglePaneZoomState },
}

return config
