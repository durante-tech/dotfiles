local M = {}

local js = { javascript = true, typescript = true, javascriptreact = true, typescriptreact = true }
local shared = { json = true, jsonc = true, css = true, graphql = true }
local prettier_only = {
    html = true, scss = true, less = true, vue = true, svelte = true, astro = true,
    json5 = true, yaml = true, xml = true, markdown = true, ["markdown.mdx"] = true, mdx = true,
}
local prettier_files = {
    ".prettierrc", ".prettierrc.json", ".prettierrc.yml", ".prettierrc.yaml", ".prettierrc.json5",
    ".prettierrc.js", ".prettierrc.cjs", ".prettierrc.mjs", ".prettierrc.ts", ".prettierrc.cts",
    ".prettierrc.mts", ".prettierrc.toml", "prettier.config.js", "prettier.config.cjs",
    "prettier.config.mjs", "prettier.config.ts", "prettier.config.cts", "prettier.config.mts",
}
local biome_files = { "biome.json", "biome.jsonc", ".biome.json", ".biome.jsonc" }

local function exists(path)
    local stat = vim.uv.fs_stat(path)
    return stat and stat.type == "file"
end

local function package_has_prettier(dir)
    local path = vim.fs.joinpath(dir, "package.json")
    if not exists(path) then return false end
    local ok, data = pcall(function() return vim.json.decode(table.concat(vim.fn.readfile(path), "\n")) end)
    return ok and type(data) == "table" and data.prettier ~= nil and data.prettier ~= vim.NIL
end

function M.find_config(dir, names, package_field)
    dir = vim.fs.normalize(dir)
    local distance = 0
    while dir and dir ~= "" do
        for _, name in ipairs(names) do
            local path = vim.fs.joinpath(dir, name)
            if exists(path) then return path, distance end
        end
        if package_field and package_has_prettier(dir) then
            return vim.fs.joinpath(dir, "package.json"), distance
        end
        local parent = vim.fs.dirname(dir)
        if parent == dir then break end
        dir, distance = parent, distance + 1
    end
end

function M.biome_config(dir)
    return M.find_config(dir, biome_files, false)
end

function M.is_web(ft)
    return js[ft] or shared[ft] or prettier_only[ft] or false
end

function M.select(bufnr)
    local ft = vim.bo[bufnr].filetype
    if not M.is_web(ft) then return nil end
    if prettier_only[ft] then return "prettier" end
    local filename = vim.api.nvim_buf_get_name(bufnr)
    local dir = vim.fs.dirname(filename)
    if not dir then return "prettier" end
    local prettier, pd = M.find_config(dir, prettier_files, true)
    local biome, bd = M.biome_config(dir)
    if biome and (not prettier or bd < pd or (bd == pd and js[ft])) then return "biome" end
    return "prettier"
end

-- Explicit ignore paths keep parent-project rules effective when a nested
-- formatter configuration changes Conform's working directory.
function M.prettier_ignore_args(_, ctx)
    local args = {}
    for _, name in ipairs({ ".gitignore", ".prettierignore" }) do
        local path = M.find_config(ctx.dirname, { name }, false)
        if path then vim.list_extend(args, { "--ignore-path", path }) end
    end
    return args
end

function M.options(bufnr, timeout)
    if vim.bo[bufnr].buftype ~= "" or vim.bo[bufnr].readonly or not vim.bo[bufnr].modifiable
        or vim.api.nvim_buf_get_name(bufnr) == "" then return nil end
    local ft = vim.bo[bufnr].filetype
    if ft == "zsh" then return nil end
    local formatter = M.select(bufnr)
    local opts = { bufnr = bufnr, async = false, timeout_ms = timeout, lsp_format = "fallback" }
    if formatter then
        opts.formatters = { formatter }
        opts.lsp_format = "never"
    end
    return opts
end

function M.format()
    local opts = M.options(0, 2000)
    if not opts then
        vim.notify("This buffer has no automatic formatting policy.", vim.log.levels.INFO)
        return
    end
    require("conform").format(opts)
end

function M.web_types()
    local out = {}
    for _, group in ipairs({ js, shared, prettier_only }) do
        for name in pairs(group) do out[#out + 1] = name end
    end
    return out
end

return M
