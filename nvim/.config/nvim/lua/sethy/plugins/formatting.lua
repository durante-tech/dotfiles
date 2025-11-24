return {
	"stevearc/conform.nvim",
	event = { "BufReadPre", "BufNewFile" },
	config = function()
		local conform = require("conform")

		conform.setup({
			formatters = {
				-- Markdown with TOC generation
				["markdown-toc"] = {
					condition = function(_, ctx)
						for _, line in ipairs(vim.api.nvim_buf_get_lines(ctx.buf, 0, -1, false)) do
							if line:find("<!%-%- toc %-%->") then
								return true
							end
						end
					end,
				},
				-- Markdownlint only if diagnostics present
				["markdownlint-cli2"] = {
					condition = function(_, ctx)
						local diag = vim.tbl_filter(function(d)
							return d.source == "markdownlint"
						end, vim.diagnostic.get(ctx.buf))
						return #diag > 0
					end,
				},
			},

			-- Formatter configurations by file type
			-- Based on: npm downloads, GitHub stars, community surveys (State of JS, Stack Overflow)
			formatters_by_ft = {
				-- ============================================================
				-- Web Development (Tier 1: 90%+ projects use these)
				-- ============================================================

				-- JavaScript/TypeScript (can use prettier OR biome)
				-- Biome: 35x faster, Rust-based, 1.5M npm downloads/week
				-- Prettier: More mature, 76M npm downloads/week, better plugins
				javascript = { "biome" }, -- Change to { "prettierd", "prettier" } for prettier
				typescript = { "biome" },
				javascriptreact = { "biome" },
				typescriptreact = { "biome" },

				-- Alternative: Use prettier for everything web (uncomment below)
				-- javascript = { "prettierd", "prettier", stop_after_first = true },
				-- typescript = { "prettierd", "prettier", stop_after_first = true },
				-- javascriptreact = { "prettierd", "prettier", stop_after_first = true },
				-- typescriptreact = { "prettierd", "prettier", stop_after_first = true },

				-- Web formats (prettier is industry standard)
				html = { "prettier" },
				css = { "prettier" },
				scss = { "prettier" },
				less = { "prettier" },

				-- Frameworks
				vue = { "prettier" },
				svelte = { "prettier" },
				astro = { "prettier" },

				-- ============================================================
				-- Data/Config Formats (Tier 1)
				-- ============================================================
				json = { "prettier" },
				jsonc = { "prettier" },
				json5 = { "prettier" },
				yaml = { "prettier" },
				toml = { "taplo" },
				xml = { "prettier" },

				-- ============================================================
				-- Documentation (Tier 1)
				-- ============================================================
				markdown = { "prettier" },
				["markdown.mdx"] = { "prettier" },

				-- ============================================================
				-- Backend Languages (Tier 2: 50-70% usage)
				-- ============================================================

				-- Python (Ruff is newer/faster, Black is traditional)
				-- Ruff: 5M PyPI downloads/month (modern, fast)
				-- Black: 30M PyPI downloads/month (mature, opinionated)
				python = { "isort", "black" }, -- Change to { "ruff_format" } for ruff

				-- Go (gofumpt is stricter version of gofmt)
				go = { "goimports", "gofumpt" }, -- or { "gofmt" }

				-- Rust (rustfmt is the standard)
				rust = { "rustfmt" },

				-- Ruby
				ruby = { "rubocop" },

				-- ============================================================
				-- Systems/Scripts (Tier 1 for dotfiles)
				-- ============================================================
				lua = { "stylua" },
				sh = { "shfmt" },
				bash = { "shfmt" },
				zsh = { "shfmt" },

				-- ============================================================
				-- Other Common Formats (Tier 2)
				-- ============================================================
				sql = { "sql-formatter" },
				graphql = { "prettier" },

				-- C/C++ (clang-format is standard)
				c = { "clang-format" },
				cpp = { "clang-format" },

				-- Java (uncomment when google-java-format is installed)
				-- java = { "google-java-format" },

				-- PHP (uncomment when php-cs-fixer is installed)
				-- php = { "php-cs-fixer" },

				-- Proto (uncomment when buf is installed)
				-- proto = { "buf" },

				-- Terraform/HCL (uncomment when terraform is installed)
				-- terraform = { "terraform_fmt" },
				-- tf = { "terraform_fmt" },
				-- hcl = { "terraform_fmt" },
			},

			-- Format on save configuration
			format_on_save = {
				lsp_fallback = true, -- Use LSP formatter if conform formatter not available
				async = false,       -- Synchronous (waits for format before saving)
				timeout_ms = 2000,   -- 2 second timeout (increased for slow formatters)
			},
		})

		-- ============================================================
		-- Individual Formatter Configurations
		-- ============================================================

		-- Prettier configuration (4 spaces, no tabs)
		conform.formatters.prettier = {
			prepend_args = {
				"--tab-width",
				"4",
				"--use-tabs",
				"false",
				"--single-quote",
				"false",
				"--trailing-comma",
				"es5",
			},
		}

		-- Prettierd (uses same config as prettier)
		conform.formatters.prettierd = {
			prepend_args = {
				"--tab-width",
				"4",
				"--use-tabs",
				"false",
				"--single-quote",
				"false",
				"--trailing-comma",
				"es5",
			},
		}

		-- Shell formatter (4 space indent)
		conform.formatters.shfmt = {
			prepend_args = { "-i", "4" },
		}

		-- StyLua configuration (matches Neovim style guide)
		conform.formatters.stylua = {
			prepend_args = {
				"--indent-type",
				"Spaces",
				"--indent-width",
				"4",
				"--quote-style",
				"AutoPreferDouble",
			},
		}

		-- Black (Python) - line length 88 (Black default)
		conform.formatters.black = {
			prepend_args = { "--line-length", "88" },
		}

		-- Biome configuration
		-- conform.nvim has built-in biome support, no need to configure
		-- Uncomment below to customize:
		-- conform.formatters.biome = {
		-- 	prepend_args = {
		-- 		"--indent-style=space",
		-- 		"--indent-width=4",
		-- 	},
		-- }

		-- ============================================================
		-- Keybindings
		-- ============================================================

		-- Format file or range (visual mode)
		vim.keymap.set({ "n", "v" }, "<leader>mp", function()
			conform.format({
				lsp_fallback = true,
				async = false,
				timeout_ms = 2000,
			})
		end, { desc = "Format file or range" })

		-- Format with specific formatter (choose from list)
		vim.keymap.set({ "n", "v" }, "<leader>mf", function()
			conform.format({
				formatters = { "injected" }, -- Format code injected into other formats (e.g., JS in Markdown)
				lsp_fallback = true,
				async = false,
				timeout_ms = 2000,
			})
		end, { desc = "Format injected languages" })
	end,
}
