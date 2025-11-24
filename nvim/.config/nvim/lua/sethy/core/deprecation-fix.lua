-- Fix for deprecated vim.lsp.buf_get_clients()
-- This must load VERY early, before any plugins
-- Used by: project.nvim, nvim-dap-go

-- The function is already deprecated by Neovim, but we can provide a clean implementation
-- that plugins can use without triggering deprecation warnings

-- Store reference to the new API
local get_clients = vim.lsp.get_clients

-- Create a clean wrapper function (not marked as deprecated)
local function buf_get_clients_impl(bufnr)
    return get_clients({ bufnr = bufnr or 0 })
end

-- Directly set the function in the vim.lsp table, bypassing deprecation
-- Use rawset to avoid triggering metatable checks
rawset(vim.lsp, 'buf_get_clients', buf_get_clients_impl)
