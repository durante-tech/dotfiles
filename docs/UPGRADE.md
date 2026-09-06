# Upgrading an existing clone

Fetch and apply are separate operations. Preserve uncommitted work before
integrating new commits. Use a fast-forward pull or the existing launcher:

```bash
cd ~/dotfiles
git pull --ff-only
./update.sh
```

`./smart-pull.sh` performs the fast-forward fetch and retains its normal Claude
launcher behavior. `./smart-pull.sh --print-prompt` prints context without
fetching, applying configuration, or launching an agent. An already enabled
post-merge hook may print context; routine updates do not change hook settings.

## Apply configuration

`./update.sh` stows the manifest's packages, synchronizes Neovim and tmux plugins,
and checks deployment. It does not install tools, register services, or change
provider environments. Failures return nonzero; independent checks still run.

```bash
./update.sh --dry-run       # effect-free preview
./update.sh --with-tools    # explicitly add declared tool provisioning
./update.sh --with-tools --skip-casks
```

`--skip-brew` excludes formula installation/upgrades throughout the run;
`--skip-casks` excludes Homebrew casks and custom GUI installers. Both suppress
bundle installation. Flag order does not matter. See
[maintenance contracts](maintenance.md) for the full behavior table.

## Reloads

Updates report these commands without invoking additional restarts. Existing
native hot reload continues where an application already supports it.

| Tool | Manual action |
| --- | --- |
| Zsh | Open a new login terminal, or `exec zsh -l` when ready to replace this shell |
| tmux | `tmux source-file ~/.config/tmux/tmux.conf` (prefix is `Ctrl+b`; then `r` also reloads) |
| Neovim | Restart the editor after saving buffers |
| AeroSpace | `aerospace reload-config` after rendering a changed template |
| Sketchybar | `sketchybar --reload` |
| Kitty | `Cmd+B`, then `r` (the configured prefix binding) |
| LaunchAgents | Review rendered templates and run an explicit `./setup.sh --configure` only when intending service changes |

The updater preserves existing terminal sessions. Do not kill tmux just to load
configuration. Fresh terminal sessions will use the new canonical project naming;
existing compatible legacy sessions remain reusable.

## Ownership and retirement

No automatic package uninstall or runtime-state deletion is part of an update.
Legacy `.dos` / `.pi` links are preserved and reported when present. Helm,
DuranteOS lifecycle work, retired widgets, optional OBS tooling, and parked
terminal configurations require a separate ownership decision before removal or
migration. A file's presence alone does not establish that it owns the live tool.
