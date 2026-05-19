// @ts-check
import { defineConfig } from 'astro/config';
import starlight from '@astrojs/starlight';

import react from '@astrojs/react';

import sitemap from '@astrojs/sitemap';

// https://astro.build/config
export default defineConfig({
    site: 'https://dotfiles-mastery.vercel.app',
    integrations: [starlight({
        title: 'Dotfiles Mastery',
        description: 'A structured learning path from fresh macOS to keyboard-driven productivity.',
        social: [
            { icon: 'github', label: 'GitHub', href: 'https://github.com/durante-tech/dotfiles' },
        ],
        editLink: {
            baseUrl: 'https://github.com/durante-tech/dotfiles/edit/main/site/',
        },
        components: {
            Sidebar: './src/components/overrides/CustomSidebar.astro',
            Head: './src/components/overrides/CustomHead.astro',
        },
        customCss: [
                    './src/styles/custom.css',
                    './src/styles/vim-practice.css',
                    './src/styles/progress.css',
                    './src/styles/keybinding-trainer.css',
                    './src/styles/print.css',
                ],
        sidebar: [
            {
                label: 'Course Overview',
                items: [
                    { label: 'Welcome', slug: 'index' },
                    { label: 'Course Curriculum', slug: 'course' },
                    { label: 'Your Progress', slug: 'progress' },
                    { label: 'Keybinding Drills', slug: 'practice/drills' },
                ],
            },
            {
                label: 'Level 0: Foundation',
                collapsed: true,
                badge: { text: 'Day 1', variant: 'note' },
                items: [
                    { label: '0.1 Philosophy', slug: 'getting-started/philosophy' },
                    { label: '0.2 Installation', slug: 'getting-started/installation' },
                    { label: '0.3 GNU Stow', slug: 'getting-started/gnu-stow' },
                ],
            },
            {
                label: 'Level 1: Survival',
                collapsed: true,
                badge: { text: 'Week 1', variant: 'note' },
                items: [
                    { label: '1.1 Quick Start', slug: 'getting-started/quick-start' },
                    { label: '1.2 First Day', slug: 'getting-started/first-day' },
                    { label: '1.3 Neovim Cheatsheet', slug: 'neovim/daily-cheatsheet' },
                    { label: '1.4 Ghostty Terminal', slug: 'ghostty' },
                ],
            },
            {
                label: 'Level 2: Navigation',
                collapsed: true,
                badge: { text: 'Week 2', variant: 'note' },
                items: [
                    { label: '2.1 Navigation Workflows', slug: 'neovim/workflows/navigation' },
                    { label: '2.2 File Management (Oil)', slug: 'neovim/workflows/file-management' },
                    { label: '2.3 Tmux Quick Start', slug: 'tmux/quick-start' },
                    { label: '2.4 Sessions & Windows', slug: 'tmux/workflows/sessions' },
                    { label: '2.4b Windows', slug: 'tmux/workflows/windows' },
                    { label: '2.5 Shell Navigation', slug: 'zsh/navigation-stack' },
                ],
            },
            {
                label: 'Level 3: Efficient Editing',
                collapsed: true,
                badge: { text: 'Week 3', variant: 'note' },
                items: [
                    { label: '3.1 Editing Workflows', slug: 'neovim/workflows/editing' },
                    { label: '3.2 Copy, Paste, Move', slug: 'neovim/workflows/copy-paste-move' },
                    { label: '3.3 Search & Replace', slug: 'neovim/workflows/search-replace' },
                    { label: '3.4 Windows & Buffers', slug: 'neovim/workflows/windows-buffers' },
                    { label: '3.5 Tmux Panes', slug: 'tmux/workflows/panes' },
                    { label: '3.5b Tmux Copy Mode', slug: 'tmux/workflows/copy-mode' },
                ],
            },
            {
                label: 'Level 4: Code Intelligence',
                collapsed: true,
                badge: { text: 'Week 4', variant: 'note' },
                items: [
                    { label: '4.1 LSP Workflows', slug: 'neovim/workflows/lsp' },
                    { label: '4.2 Keybinding Reference', slug: 'neovim/keybindings' },
                    { label: '4.3 Tmux + Neovim', slug: 'tmux/integration/nvim' },
                    { label: '4.4 Atuin History', slug: 'atuin' },
                ],
            },
            {
                label: 'Level 5: Window Management',
                collapsed: true,
                badge: { text: 'Week 5', variant: 'note' },
                items: [
                    { label: '5.1 AeroSpace', slug: 'aerospace' },
                    { label: '5.2 Karabiner', slug: 'karabiner' },
                    { label: '5.3 SketchyBar', slug: 'sketchybar' },
                    { label: '5.4 Starship Prompt', slug: 'starship' },
                    { label: '5.5 Window Workflows', slug: 'window-management/workflow' },
                    { label: '5.6 Daily Workflow', slug: 'getting-started/daily-workflow' },
                ],
            },
            {
                label: 'Level 6: Power Tools',
                collapsed: true,
                badge: { text: 'Week 6', variant: 'note' },
                items: [
                    { label: '6.1 Yazi File Manager', slug: 'yazi' },
                    { label: '6.2 Modern CLI Tools', slug: 'getting-started/new-tools-guide' },
                    { label: '6.3 Aliases & Functions', slug: 'zsh/aliases-and-functions' },
                    { label: '6.4 Git Workflow', slug: 'git/workflow' },
                    { label: '6.5 Custom Scripts', slug: 'scripts' },
                    { label: '6.6 Tmux Keybindings', slug: 'tmux/keybindings' },
                    { label: '6.7 MPD Music', slug: 'mpd' },
                    { label: '6.7b rmpc Player', slug: 'rmpc' },
                    { label: '6.8 w3m Browser', slug: 'w3m' },
                ],
            },
            {
                label: 'Level 7: Mastery',
                collapsed: true,
                badge: { text: 'Ongoing', variant: 'success' },
                items: [
                    { label: '7.1 Development Stack', slug: 'integration/development-stack' },
                    { label: '7.2 Tips & Tricks', slug: 'neovim/tips-and-tricks' },
                    { label: '7.3 Troubleshooting', slug: 'neovim/troubleshooting' },
                    { label: '7.4 Tmux Reference', slug: 'tmux' },
                    { label: '7.5 Formatters', slug: 'neovim/formatters' },
                    { label: '7.5b Formatter Issues', slug: 'neovim/formatter-troubleshooting' },
                    { label: '7.6 Customizing', slug: 'getting-started/customizing' },
                ],
            },
            {
                label: 'Reference',
                collapsed: true,
                items: [
                    { label: 'Documentation Index', slug: 'docs-index' },
                    { label: 'Neovim Overview', slug: 'neovim' },
                    { label: 'Tmux Cheatsheet', slug: 'tmux/daily-cheatsheet' },
                    { label: 'Zsh Config', slug: 'zsh' },
                ],
            },
            {
                label: 'Legacy',
                collapsed: true,
                badge: { text: 'Archive', variant: 'caution' },
                items: [
                    { label: 'Alacritty', slug: 'legacy/alacritty' },
                    { label: 'Kitty', slug: 'legacy/kitty' },
                    { label: 'WezTerm', slug: 'legacy/wezterm' },
                    { label: 'Zed', slug: 'legacy/zed' },
                ],
            },
        ],
        }), react(), sitemap()],
});