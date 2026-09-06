# Maintenance command contract

Run these from a cloned checkout. The installer requires its shipped `lib/`
support files; a standalone downloaded `install.sh` is not an installation bundle.

| Command | Effects |
|---|---|
| `./update.sh` or `./install.sh --update` | Apply the selected checkout, sync editor/tmux plugins, check configuration; no repository pull or tool provisioning |
| `./update.sh --with-tools` | Also provision declared tools, pinned runtimes, global CLIs and the Neovim provider environment |
| `--skip-brew` | Exclude Homebrew formula installations/upgrades, including the bundle phase |
| `--skip-casks` | Exclude Homebrew casks and the pinned custom GUI installer |
| `--dry-run` | Print the plan without invoking package, network, deployment, service or agent commands |
| `./smart-pull.sh` | Fast-forward fetch, then the existing upgrade-prompt launcher |
| `./smart-pull.sh --print-prompt` | Print context for up to five available ancestors; no fetch, apply or agent |
| `./setup.sh --check` | Diagnostics; required missing dependencies/deployment failures return nonzero |
| `./setup.sh --provision` | Explicit provider-environment/native-helper provisioning |
| `./setup.sh --configure` | Explicit service/helper/integration setup; not part of routine updates |

Options are order-independent. The Brewfile is the package inventory; both
Homebrew skip flags suppress its installation phase. Updates do not run macOS
defaults, register services, or change Claude hooks. Plugin synchronization may
fetch plugin repositories and their own build dependencies; Mason tool provisioning
is disabled during configuration-only sync. TPM repositories are synchronized
without reloading the running tmux server. Missing prerequisites are reported.

Required failures produce a nonzero result and an incomplete summary. Independent
diagnostics still run. Optional unavailable components remain visible warnings.
The updater prints reload commands; it triggers no extra app/service restart.
Native file-watching behavior, such as Sketchybar hot reload, still applies.

Stow remains per package and reads `stow-packages.txt`. The tmux package excludes
agent runtime directories; existing legacy state links are preserved and reported.
No command performs broad cleanup or removes unlisted packages.

## Project navigation

Both pickers accept an optional directory argument. Otherwise they use the same
null-delimited fd/fzf discovery. Export `DOTFILES_SESSIONIZER_PATHS` as a newline-
delimited list to support spaces in roots; the old `TMUX_SESSIONIZER_PATHS` remains
whitespace-delimited. Unavailable roots are skipped; no available root is an error.

New tmux sessions use a readable basename plus a 12-character SHA-256 suffix of
the canonical directory. `@dotfiles_project_path` records the full owner. An old
basename-only session is reused only when its starting directory matches. Existing
sessions are never renamed or killed; a hash/owner mismatch is an error.

The shell preserves Kitty context supplied by the launching client and never
invents a PID/window or writes guessed values into tmux. The Kitty picker requires
`KITTY_LISTEN_ON` from the intended instance. Missing context is an explicit error.

## Formatting policy

The nearest explicit formatter configuration chooses the tool for JS/TS/JSX/TSX,
JSON/JSONC, CSS and GraphQL. At equal distance, JS/TS variants choose Biome and
other formats choose Prettier. Markdown/framework/other existing Prettier filetypes
stay on Prettier. Without configuration, Prettier's defaults apply. Project-local
binaries take precedence over installed fallbacks; formatting never installs tools.

Project configuration, EditorConfig, ignore rules and plugins remain authoritative.
No global Prettier/Prettierd style flags are supplied. A selected formatter's error,
missing binary/plugin or timeout is reported and leaves the original save intact;
web formats never silently switch to an LSP. Formatting runs once before save with
a 1,000 ms timeout. `<leader>f` and the non-Markdown `<leader>mp` alias share the
same policy with a 2,000 ms manual timeout; Markdown's preview mapping is retained.
Zsh is not sent to shfmt. Biome linting requires a project Biome configuration.
