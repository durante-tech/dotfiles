-- avante.nvim — Cursor-style in-buffer AI editing with visual diff review.
-- Complements claudecode.nvim (which runs a terminal agent); avante edits buffers directly.
-- Uses <leader>v prefix so claudecode.nvim keeps the <leader>a namespace it owns.

return {
	"yetone/avante.nvim",
	event = "VeryLazy",
	version = false, -- always pull latest; avante moves fast
	-- Native rust build. First :Lazy sync after install runs `make` (~1 min).
	build = "make",
	dependencies = {
		"nvim-treesitter/nvim-treesitter",
		"stevearc/dressing.nvim",
		"nvim-lua/plenary.nvim",
		"MunifTanjim/nui.nvim",
		"MeanderingProgrammer/render-markdown.nvim", -- already in stack; reused
	},
	opts = {
		provider = "claude",
		claude = {
			endpoint = "https://api.anthropic.com",
			model = "claude-sonnet-4-5",
			timeout = 30000,
			temperature = 0,
			max_tokens = 4096,
		},
		mappings = {
			-- Disable defaults; remap under <leader>v to avoid clashing with claudecode.nvim
			ask = "<leader>vk",
			edit = "<leader>ve",
			refresh = "<leader>vr",
			focus = "<leader>vf",
			diff = {
				ours = "co",
				theirs = "ct",
				all_theirs = "ca",
				both = "cb",
				cursor = "cc",
				next = "]x",
				prev = "[x",
			},
			submit = {
				normal = "<CR>",
				insert = "<C-s>",
			},
			sidebar = {
				apply_all = "A",
				apply_cursor = "a",
				switch_windows = "<Tab>",
				reverse_switch_windows = "<S-Tab>",
			},
		},
		hints = { enabled = true },
		windows = {
			position = "right",
			width = 35,
			wrap = true,
		},
	},
	keys = {
		{ "<leader>vk", desc = "avante: ask" },
		{ "<leader>ve", desc = "avante: edit (visual selection)", mode = "v" },
		{ "<leader>vf", desc = "avante: focus sidebar" },
		{ "<leader>vr", desc = "avante: refresh" },
		{ "<leader>vt", "<cmd>AvanteToggle<cr>", desc = "avante: toggle sidebar" },
	},
}
