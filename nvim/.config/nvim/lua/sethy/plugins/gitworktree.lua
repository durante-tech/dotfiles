return {
	"ThePrimeagen/git-worktree.nvim",
	-- NOTE: Disabled — requires Telescope which is no longer installed (migrated to Snacks picker)
	-- TODO: Re-enable when a Snacks-compatible worktree picker is available
	enabled = false,
	dependencies = {
		"nvim-lua/plenary.nvim",
	},

	config = function()
		local gitworktree = require("git-worktree")

		gitworktree.setup()

		-- Safely load telescope extension (may not be available at config time)
		local ok, telescope = pcall(require, "telescope")
		if ok then
			telescope.load_extension("git_worktree")
		end

		-- HACK: by default
		-- <Enter> - switches to that worktree
		-- <c-d> - deletes that worktree
		-- <c-f> - toggles forcing of the next deletion

		-- Create new worktree
		vim.keymap.set("n", "<leader>gt", function()
			require("telescope").extensions.git_worktree.git_worktrees()
		end, { desc = "Git worktree list" })

		-- Switch/list worktrees
		vim.keymap.set("n", "<leader>wc", function()
			require("telescope").extensions.git_worktree.create_git_worktree()
		end, { desc = "Create Git Worktree Branches" })
	end,
}
