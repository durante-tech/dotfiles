return {
	"coder/claudecode.nvim",
	dependencies = { "folke/snacks.nvim" },
	config = true,
	keys = {
		{ "<leader>ac", "<cmd>ClaudeCode<cr>", desc = "Toggle Claude" },
		{ "<leader>as", "<cmd>ClaudeCodeSend<cr>", desc = "Send to Claude", mode = "v" },
		{ "<leader>af", "<cmd>ClaudeCodeFocus<cr>", desc = "Focus Claude" },
		{ "<leader>aa", "<cmd>ClaudeCodeDiffAccept<cr>", desc = "Accept diff" },
		{ "<leader>ad", "<cmd>ClaudeCodeDiffDeny<cr>", desc = "Reject diff" },
	},
	opts = {
		-- Terminal settings
		terminal = {
			split_side = "left", -- Will be overridden by snacks_win_opts
			provider = "snacks",
			auto_close = true,
			snacks_win_opts = {
				position = "bottom",
				height = 0.30, -- 30% height
			},
		},
		-- Diff viewing options
		diff_opts = {
			auto_close_on_accept = true,
			vertical_split = true,
			open_in_current_tab = true,
		},
		-- Use git repo root as working directory
		git_repo_cwd = true,
	},
}
