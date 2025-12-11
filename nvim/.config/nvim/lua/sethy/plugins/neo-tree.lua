return {
	"nvim-neo-tree/neo-tree.nvim",
	branch = "v3.x",
	dependencies = {
		"nvim-lua/plenary.nvim",
		"nvim-tree/nvim-web-devicons",
		"MunifTanjim/nui.nvim",
	},
	keys = {
		{ "<leader>ee", "<cmd>Neotree toggle<cr>", desc = "Toggle Neo-tree" },
		{ "<leader>ef", "<cmd>Neotree reveal<cr>", desc = "Reveal current file in Neo-tree" },
		{ "<leader>eg", "<cmd>Neotree git_status<cr>", desc = "Git status in Neo-tree" },
		{ "<leader>eb", "<cmd>Neotree buffers<cr>", desc = "Open buffers in Neo-tree" },
	},
	opts = {
		close_if_last_window = true,
		popup_border_style = "rounded",
		enable_git_status = true,
		enable_diagnostics = true,
		sort_case_insensitive = true,

		-- Sources available
		sources = { "filesystem", "buffers", "git_status" },

		-- Default component configs
		default_component_configs = {
			indent = {
				indent_size = 2,
				padding = 1,
				with_markers = true,
				indent_marker = "│",
				last_indent_marker = "└",
				with_expanders = true,
				expander_collapsed = "",
				expander_expanded = "",
			},
			icon = {
				folder_closed = "",
				folder_open = "",
				folder_empty = "",
			},
			modified = {
				symbol = "●",
			},
			git_status = {
				symbols = {
					added = "",
					modified = "",
					deleted = "✖",
					renamed = "󰁕",
					untracked = "",
					ignored = "",
					unstaged = "󰄱",
					staged = "",
					conflict = "",
				},
			},
		},

		-- Window settings (left sidebar)
		window = {
			position = "left",
			width = 35,
			mapping_options = {
				noremap = true,
				nowait = true,
			},
			mappings = {
				["<space>"] = "none", -- Disable space (it's leader)
				["<cr>"] = "open",
				["l"] = "open",
				["h"] = "close_node",
				["<esc>"] = "cancel",
				["P"] = { "toggle_preview", config = { use_float = true } },
				["S"] = "open_split",
				["s"] = "open_vsplit",
				["t"] = "open_tabnew",
				["w"] = "open_with_window_picker",
				["C"] = "close_node",
				["z"] = "close_all_nodes",
				["Z"] = "expand_all_nodes",
				["a"] = { "add", config = { show_path = "relative" } },
				["A"] = "add_directory",
				["d"] = "delete",
				["r"] = "rename",
				["y"] = "copy_to_clipboard",
				["x"] = "cut_to_clipboard",
				["p"] = "paste_from_clipboard",
				["c"] = "copy",
				["m"] = "move",
				["q"] = "close_window",
				["R"] = "refresh",
				["?"] = "show_help",
				["<"] = "prev_source",
				[">"] = "next_source",
			},
		},

		-- Filesystem specific settings
		filesystem = {
			filtered_items = {
				visible = false,
				hide_dotfiles = false,
				hide_gitignored = false,
				hide_by_name = {
					".DS_Store",
					"thumbs.db",
					"node_modules",
				},
				never_show = {
					".DS_Store",
				},
			},
			follow_current_file = {
				enabled = true,
				leave_dirs_open = true,
			},
			group_empty_dirs = true,
			hijack_netrw_behavior = "open_current",
			use_libuv_file_watcher = true,
		},

		-- Buffers specific settings
		buffers = {
			follow_current_file = {
				enabled = true,
				leave_dirs_open = true,
			},
			group_empty_dirs = true,
			show_unloaded = true,
		},

		-- Git status specific settings
		git_status = {
			window = {
				position = "float",
			},
		},
	},
}
