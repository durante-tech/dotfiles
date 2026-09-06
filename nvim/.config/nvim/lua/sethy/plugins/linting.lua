return {
	"mfussenegger/nvim-lint",
	event = { "BufReadPre", "BufNewFile" },
	config = function()
		local lint = require("lint")
		local lint_augroup = vim.api.nvim_create_augroup("lint", { clear = true })
		local eslint = lint.linters.eslint_d

		-- if Eslint error configuration not found : change MasonInstall eslint@version or npm i -g eslint at a specific version
		lint.linters_by_ft = {
			javascript = {"biomejs"},
			typescript = {"biomejs"},
			javascriptreact = {"biomejs"},
			typescriptreact = {"biomejs"},
			svelte = { "biomejs" },
			python = { "pylint" },
		}

		eslint.args = {
			"--no-warn-ignored",
			"--format",
			"json",
			"--stdin",
			"--stdin-filename",
			function()
                return vim.fn.expand("%:p")
			end,
		}

        local function try_project_lint()
            local ft = vim.bo.filetype
            if vim.tbl_contains({ "javascript", "typescript", "javascriptreact", "typescriptreact", "svelte" }, ft) then
                local dir = vim.fs.dirname(vim.api.nvim_buf_get_name(0))
                if dir and require("sethy.formatting-policy").biome_config(dir) then
                    lint.try_lint("biomejs")
                else
                    vim.diagnostic.reset(lint.get_namespace("biomejs"), 0)
                end
            else
                lint.try_lint()
            end
        end
        vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "InsertLeave" }, {
            group = lint_augroup,
            callback = try_project_lint,
        })

		vim.keymap.set("n", "<leader>l", function()
            try_project_lint()
        end, { desc = "Trigger linting for current file" })
	end,
}
