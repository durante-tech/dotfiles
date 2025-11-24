-- Jupytext: Work with Jupyter notebooks as Python files
-- Automatically converts .ipynb files to editable .py format

return {
    -- Jupytext configuration via autocommands
    -- No plugin needed - uses jupytext CLI tool

    config = function()
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
                -- Enable folding
                vim.wo.foldmethod = "expr"
                vim.wo.foldexpr = "nvim_treesitter#foldexpr()"
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
    end,
}
