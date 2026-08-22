return {
	"coder/claudecode.nvim",
	dependencies = { "folke/snacks.nvim" },
	config = true,
	keys = {
		-- Basic toggle/focus
		{ "<leader>ac", "<cmd>ClaudeCode<cr>", desc = "Toggle Claude Code" },
		{ "<leader>af", "<cmd>ClaudeCodeFocus<cr>", desc = "Focus Claude Code" },
		{ "<leader>ar", "<cmd>ClaudeCode --resume<cr>", desc = "Claude Code (resume)" },
		-- Selection/diff
		{ "<leader>as", "<cmd>ClaudeCodeSend<cr>", desc = "Send to Claude Code", mode = "v" },
		{ "<leader>aa", "<cmd>ClaudeCodeDiffAccept<cr>", desc = "Accept diff" },
		{ "<leader>ad", "<cmd>ClaudeCodeDiffDeny<cr>", desc = "Reject diff" },
	},
	opts = {
		-- Absolute path: the `claude` alias and ~/.local/bin are not on PATH inside
		-- the nvim terminal. This pointed at ~/.claude/skills/CORE/Tools/pai.ts,
		-- which does not exist, so every mapping here failed with exit 127.
		terminal_cmd = vim.fn.expand("~") .. "/.local/bin/claude",
		-- Terminal settings
		terminal = {
			split_side = "left", -- Will be overridden by snacks_win_opts
			provider = "snacks",
			auto_close = true,
			snacks_win_opts = {
				position = "right",
				width = 0.40, -- 40% width
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
