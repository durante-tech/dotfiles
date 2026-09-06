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
