return {
    "iamcco/markdown-preview.nvim",
    enabled = true,
    cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
    build = "cd app && npm install",
    ft = { "markdown" },
    keys = {
        -- ft-scoped: globally this collided with conform's <leader>mp (format)
        { "<leader>mp", "<cmd>MarkdownPreviewToggle<cr>", desc = "Markdown Preview Toggle", ft = "markdown" },
    },
    config = function()
        vim.g.mkdp_auto_start = 0  -- Don't auto-open preview
        vim.g.mkdp_auto_close = 1  -- Auto-close when switching buffers
        vim.g.mkdp_refresh_slow = 0  -- Auto-refresh on save
        vim.g.mkdp_command_for_global = 0  -- Only work in markdown files
        vim.g.mkdp_open_to_the_world = 0  -- Don't open to network
        vim.g.mkdp_browser = ""  -- Use default browser
        vim.g.mkdp_echo_preview_url = 1  -- Echo preview URL
        vim.g.mkdp_page_title = "${name}"  -- Use filename as page title

        -- Enable Mermaid diagrams (this is enabled by default)
        vim.g.mkdp_preview_options = {
            mkit = {},
            katex = {},
            uml = {},
            maid = {
                theme = "dark",  -- Mermaid theme: default, dark, forest, neutral
            },
            disable_sync_scroll = 0,
            sync_scroll_type = "middle",
            hide_yaml_meta = 1,
            sequence_diagrams = {},
            flowchart_diagrams = {},
            content_editable = false,
            disable_filename = 0,
            toc = {}
        }

        -- Rose Pine themed Mermaid (custom CSS)
        vim.g.mkdp_markdown_css = ""
        vim.g.mkdp_highlight_css = ""
    end,
}
