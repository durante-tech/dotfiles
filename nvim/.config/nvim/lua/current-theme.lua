-- Read OS theme from ~/.config/current-theme and apply colorscheme
local function apply_theme()
    local f = io.open(os.getenv("HOME") .. "/.config/current-theme", "r")
    if f then
        local mode = f:read("*l")
        f:close()
        if mode == "light" then
            vim.o.background = "light"
        else
            vim.o.background = "dark"
        end
    else
        vim.o.background = "dark"
    end
    vim.cmd("colorscheme everforest")
end

apply_theme()

vim.api.nvim_create_autocmd("FocusGained", {
    callback = apply_theme,
})
