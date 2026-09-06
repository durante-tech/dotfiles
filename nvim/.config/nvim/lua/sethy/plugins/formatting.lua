return {
    "stevearc/conform.nvim",
    event = { "BufReadPre", "BufNewFile" },
    config = function()
        local conform = require("conform")
        local policy = require("sethy.formatting-policy")
        local by_ft = {
            python = { "isort", "black" },
            go = { "goimports", "gofumpt" },
            rust = { "rustfmt" },
            ruby = { "rubocop" },
            lua = { "stylua" },
            sh = { "shfmt" },
            bash = { "shfmt" },
            toml = { "taplo" },
            sql = { "sql-formatter" },
            c = { "clang-format" },
            cpp = { "clang-format" },
        }
        for _, ft in ipairs(policy.web_types()) do
            by_ft[ft] = function(bufnr) return { policy.select(bufnr) } end
        end
        conform.setup({
            formatters_by_ft = by_ft,
            notify_on_error = true,
            notify_no_formatters = true,
            formatters = {
                prettier = { append_args = policy.prettier_ignore_args },
                ["markdown-toc"] = {
                    condition = function(_, ctx)
                        for _, line in ipairs(vim.api.nvim_buf_get_lines(ctx.buf, 0, -1, false)) do
                            if line:find("<!%-%- toc %-%->") then return true end
                        end
                        return false
                    end,
                },
                ["markdownlint-cli2"] = {
                    condition = function(_, ctx)
                        return #vim.tbl_filter(function(d) return d.source == "markdownlint" end,
                            vim.diagnostic.get(ctx.buf)) > 0
                    end,
                },
                shfmt = { prepend_args = { "-i", "4" } },
                stylua = { prepend_args = { "--indent-type", "Spaces", "--indent-width", "4", "--quote-style", "AutoPreferDouble" } },
                black = { prepend_args = { "--line-length", "88" } },
            },
            -- One write. Failure/timeout leaves the original buffer available to save.
            format_on_save = function(bufnr) return policy.options(bufnr, 1000) end,
        })
        vim.keymap.set({ "n", "v" }, "<leader>f", policy.format, { desc = "Format with project policy" })
        vim.keymap.set({ "n", "v" }, "<leader>mp", policy.format, { desc = "Format file or range" })
        vim.keymap.set({ "n", "v" }, "<leader>mf", function()
            conform.format({ formatters = { "injected" }, lsp_format = "fallback", async = false, timeout_ms = 2000 })
        end, { desc = "Format injected languages" })
    end,
}
