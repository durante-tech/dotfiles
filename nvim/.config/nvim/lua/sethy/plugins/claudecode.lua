return {
	"coder/claudecode.nvim",
	dependencies = { "folke/snacks.nvim" },
	config = true,
	keys = {
		-- Basic toggle/focus
		{ "<leader>ac", "<cmd>ClaudeCode<cr>", desc = "Toggle PAI" },
		{ "<leader>af", "<cmd>ClaudeCodeFocus<cr>", desc = "Focus PAI" },
		-- PAI with options
		{ "<leader>al", "<cmd>ClaudeCode -l<cr>", desc = "PAI (local)" },
		{ "<leader>am", "<cmd>ClaudeCode -l -m full<cr>", desc = "PAI (full MCPs)" },
		{ "<leader>aw", "<cmd>ClaudeCode -l -m dev-work<cr>", desc = "PAI (dev-work)" },
		{ "<leader>ar", "<cmd>ClaudeCode --resume<cr>", desc = "PAI (resume)" },
		{ "<leader>aM", "<cmd>ClaudeCode -l -m full --resume<cr>", desc = "PAI (full + resume)" },
		{ "<leader>aW", "<cmd>ClaudeCode -l -m dev-work --resume<cr>", desc = "PAI (dev-work + resume)" },
		-- Selection/diff
		{ "<leader>as", "<cmd>ClaudeCodeSend<cr>", desc = "Send to PAI", mode = "v" },
		{ "<leader>aa", "<cmd>ClaudeCodeDiffAccept<cr>", desc = "Accept diff" },
		{ "<leader>ad", "<cmd>ClaudeCodeDiffDeny<cr>", desc = "Reject diff" },
	},
	opts = {
		-- Use PAI instead of claude (full paths since alias/PATH not available in nvim terminal)
		terminal_cmd = vim.fn.expand("~") .. "/.bun/bin/bun " .. vim.fn.expand("~") .. "/.claude/skills/CORE/Tools/pai.ts",
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
