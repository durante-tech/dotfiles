-- Jupytext: Work with Jupyter notebooks as Python files
-- Automatically converts .ipynb files to editable .py format
-- This is NOT a Lazy plugin - it's pure Lua configuration

local M = {}

function M.setup()
        -- Create autocommand group for Jupyter notebooks
        local jupyter_group = vim.api.nvim_create_augroup("JupyterNotebook", { clear = true })

        -- Auto-convert .ipynb to .py when opening
        vim.api.nvim_create_autocmd("BufReadCmd", {
            group = jupyter_group,
            pattern = "*.ipynb",
            callback = function(args)
                local filename = args.file

                -- Read notebook as JSON to display properly
                vim.cmd('read ' .. vim.fn.fnameescape(filename))
                vim.cmd('0d_')  -- Delete empty first line

                -- Set filetype to enable syntax highlighting
                vim.bo.filetype = "jupyter"
                vim.bo.syntax = "json"

                -- Make buffer modifiable
                vim.bo.modifiable = true
                vim.bo.buftype = ""
            end,
        })

        -- Set specific options for Jupyter notebook buffers
        vim.api.nvim_create_autocmd("FileType", {
            group = jupyter_group,
            pattern = "jupyter",
            callback = function()
                -- Folding is left to nvim-ufo, which attaches to every buffer
                -- with provider_selector -> { "treesitter", "indent" }. What
                -- stood here set foldexpr = "nvim_treesitter#foldexpr()", a
                -- Vimscript autoload function that only existed on
                -- nvim-treesitter's `master` branch; treesitter.lua pins
                -- branch = "main", whose clone has no autoload/ directory at
                -- all, so every fold evaluation in a .ipynb buffer raised E117.
                -- v:lua.vim.treesitter.foldexpr() would silence the error but
                -- not help: there is no "jupyter" parser, so it returns "0" for
                -- every line and foldmethod=expr would then beat ufo's indent
                -- fallback. Dropping both lines gives ufo its indent folds back.
                vim.wo.foldlevel = 99  -- Start with all folds open

                -- Add cell markers for navigation
                vim.b.cell_markers = { '# %%', '# <codecell>', '#%%' }
            end,
        })

        -- Commands for Jupytext conversion
        vim.api.nvim_create_user_command('JupytextToPy', function()
            local current_file = vim.fn.expand('%:p')
            local py_file = vim.fn.fnamemodify(current_file, ':r') .. '.py'

            local cmd = string.format('jupytext --to py:percent "%s" -o "%s"', current_file, py_file)
            local result = vim.fn.system(cmd)

            if vim.v.shell_error == 0 then
                print('Converted to: ' .. py_file)
                vim.cmd('edit ' .. py_file)
            else
                print('Error: ' .. result)
            end
        end, { desc = "Convert .ipynb to .py with jupytext" })

        vim.api.nvim_create_user_command('JupytextToIpynb', function()
            local current_file = vim.fn.expand('%:p')
            local ipynb_file = vim.fn.fnamemodify(current_file, ':r') .. '.ipynb'

            local cmd = string.format('jupytext --to ipynb "%s" -o "%s"', current_file, ipynb_file)
            local result = vim.fn.system(cmd)

            if vim.v.shell_error == 0 then
                print('Converted to: ' .. ipynb_file)
                vim.cmd('edit ' .. ipynb_file)
            else
                print('Error: ' .. result)
            end
        end, { desc = "Convert .py to .ipynb with jupytext" })

        -- Auto-sync changes (optional - uncomment if you want automatic sync)
        -- vim.api.nvim_create_autocmd("BufWritePost", {
        --     group = jupyter_group,
        --     pattern = "*.py",
        --     callback = function()
        --         local ipynb_file = vim.fn.expand('%:r') .. '.ipynb'
        --         if vim.fn.filereadable(ipynb_file) == 1 then
        --             vim.fn.system('jupytext --to ipynb --update "' .. vim.fn.expand('%') .. '"')
        --         end
        --     end,
        -- })
end

return M
