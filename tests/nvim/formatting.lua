local repo = assert(vim.env.DOTFILES_TEST_REPO)
local root = assert(vim.env.DOTFILES_TEST_WORK)
local conform_dir = assert(vim.env.DOTFILES_TEST_CONFORM_DIR)
vim.opt.rtp:prepend(repo .. "/nvim/.config/nvim")
vim.opt.rtp:prepend(conform_dir)
local policy = require("sethy.formatting-policy")
local notices = {}
vim.notify = function(message) notices[#notices + 1] = tostring(message) end
local function check(value, message) assert(value, message) end
local function put(path, text)
    vim.fn.mkdir(vim.fs.dirname(path), "p")
    vim.fn.writefile(vim.split(text, "\n", { plain = true }), path)
end
local function buffer(path, ft, text)
    vim.cmd("enew!")
    vim.api.nvim_buf_set_name(0, path)
    vim.bo.filetype = ft
    vim.api.nvim_buf_set_lines(0, 0, -1, false, vim.split(text or '{"a":1}', "\n", { plain = true }))
    return vim.api.nvim_get_current_buf()
end
local function content() return table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), "\n") end
local count = 0
local function test(name, fn)
    fn()
    count = count + 1
    print("PASS " .. name)
end

local function main()
    test("nearest config and deterministic ties", function()
        local dir = root .. "/selection"
        vim.fn.mkdir(dir, "p")
        buffer(dir .. "/file.ts", "typescript")
        check(policy.select(0) == "prettier", "unconfigured default")
        put(dir .. "/biome.json", "{}")
        check(policy.select(0) == "biome", "Biome-only project")
        put(dir .. "/.prettierrc", "{}")
        check(policy.select(0) == "biome", "JS/TS tie")
        vim.bo.filetype = "json"
        check(policy.select(0) == "prettier", "JSON tie")
        put(dir .. "/nested/package.json", '{"prettier":{"tabWidth":3}}')
        buffer(dir .. "/nested/file.ts", "typescript")
        check(policy.select(0) == "prettier", "nearest package configuration")
        put(dir .. "/nested/deeper/biome.jsonc", "{}")
        buffer(dir .. "/nested/deeper/file.css", "css")
        check(policy.select(0) == "biome", "nearest Biome for shared types")
        vim.bo.filetype = "astro"
        check(policy.select(0) == "prettier", "no experimental Biome routing")
    end)

    local spec = dofile(repo .. "/nvim/.config/nvim/lua/sethy/plugins/formatting.lua")
    spec.config()
    local conform = require("conform")

    test("project-local executable precedence", function()
        local dir = root .. "/local"
        local exe = dir .. "/node_modules/.bin/prettier"
        put(exe, "#!/bin/sh\ncat")
        vim.fn.setfperm(exe, "rwxr-xr-x")
        buffer(dir .. "/file.json", "json")
        local info = conform.get_formatter_info("prettier", 0)
        check(info.available and info.command == exe, vim.inspect(info))
    end)

    test("project indentation and a single pre-save write", function()
        local dir = root .. "/prettier"
        put(dir .. "/.prettierrc.json", '{"tabWidth":2}')
        buffer(dir .. "/file.json", "json", '{\n"outer":{"answer":42}\n}')
        local writes = 0
        vim.api.nvim_create_autocmd("BufWritePost", { buffer = 0, callback = function() writes = writes + 1 end })
        vim.cmd("write")
        check(content():find('\n  "outer"', 1, true), content())
        check(writes == 1 and not vim.bo.modified, "expected exactly one formatted write")
        vim.wait(100)
        check(writes == 1, "late after-save write")
        check(policy.options(0, 1000).lsp_format == "never", "web LSP fallback")
        check(policy.options(0, 2000).timeout_ms == 2000, "manual timeout")
    end)

    test("standard defaults without project configuration", function()
        local dir = root .. "/defaults"
        vim.fn.mkdir(dir, "p")
        buffer(dir .. "/file.json", "json", '{\n"outer":{"answer":42}\n}')
        vim.cmd("write")
        check(content():find('\n  "outer"', 1, true), content())
    end)

    test("EditorConfig without a formatter configuration", function()
        local dir = root .. "/editorconfig"
        put(dir .. "/.editorconfig", "root = true\n[*]\nindent_style = space\nindent_size = 3")
        buffer(dir .. "/file.json", "json", '{\n"outer":{"answer":42}\n}')
        vim.cmd("write")
        check(content():find('\n   "outer"', 1, true), content())
    end)

    test("parent ignore file with a nested formatter config", function()
        local dir = root .. "/ignore"
        put(dir .. "/.prettierignore", "nested/ignored.json")
        put(dir .. "/nested/.prettierrc", "{}")
        buffer(dir .. "/nested/ignored.json", "json", '{ "messy" : 1 }')
        local original = content()
        vim.cmd("write")
        check(content() == original, "ignored file changed")
    end)

    test("Biome configuration and disabled formatting", function()
        local dir = root .. "/biome"
        put(dir .. "/biome.json", '{"formatter":{"indentStyle":"space","indentWidth":3}}')
        buffer(dir .. "/file.json", "json", '{\n"outer":{"answer":42}\n}')
        vim.cmd("write")
        check(content():find('\n   "outer"', 1, true), content())
        put(dir .. "/biome.json", '{"formatter":{"enabled":false}}')
        buffer(dir .. "/disabled.json", "json", '{ "messy" : 1 }')
        local original = content()
        vim.cmd("write")
        check(content() == original, "disabled formatter changed the file")
    end)

    test("missing plugin reports failure and preserves the save", function()
        local dir = root .. "/missing-plugin"
        put(dir .. "/.prettierrc.json", '{"plugins":["not-a-real-dotfiles-test-plugin"]}')
        buffer(dir .. "/file.json", "json", '{ "messy" : 1 }')
        local original, before = content(), #notices
        vim.cmd("write")
        vim.wait(100)
        check(content() == original, "error changed content")
        check(#notices > before, "formatter error was hidden")
    end)

    test("missing executable never falls through to another formatter", function()
        local old = conform.formatters.prettier
        conform.formatters.prettier = { command = root .. "/absent-executable" }
        local dir = root .. "/missing-executable"
        vim.fn.mkdir(dir, "p")
        buffer(dir .. "/file.json", "json", '{ "messy" : 1 }')
        local original, before = content(), #notices
        vim.cmd("write")
        vim.wait(100)
        check(content() == original and #notices > before, "missing formatter was hidden or replaced")
        conform.formatters.prettier = old
    end)

    test("timeout keeps the original save and has no late rewrite", function()
        local old = conform.formatters.prettier
        conform.formatters.prettier = { inherit = false, command = "python3",
            args = { "-c", "import time; time.sleep(2); print('late rewrite')" }, stdin = true }
        local dir = root .. "/timeout"
        vim.fn.mkdir(dir, "p")
        buffer(dir .. "/file.json", "json", '{ "messy" : 1 }')
        local original, before = content(), #notices
        vim.cmd("write")
        vim.wait(1500)
        check(content() == original, "late formatter result changed the buffer")
        check(table.concat(vim.fn.readfile(dir .. "/file.json"), "\n") == original, "saved bytes changed")
        check(#notices > before, "timeout was hidden")
        conform.formatters.prettier = old
    end)

    test("readonly, special, unnamed and Zsh buffers are skipped", function()
        buffer(root .. "/skip.zsh", "zsh")
        check(policy.options(0, 1000) == nil, "Zsh sent to a Bash formatter")
        vim.bo.filetype = "json"; vim.bo.readonly = true
        check(policy.options(0, 1000) == nil, "readonly buffer")
        vim.bo.readonly = false; vim.bo.buftype = "nofile"
        check(policy.options(0, 1000) == nil, "special buffer")
        vim.cmd("enew!")
        check(policy.options(0, 1000) == nil, "unnamed buffer")
    end)
    print(string.format("%d formatting scenarios passed", count))
end

local ok, err = xpcall(main, debug.traceback)
if not ok then
    io.stderr:write(tostring(err) .. "\n")
    vim.cmd("cquit 1")
else
    vim.cmd("qa!")
end
