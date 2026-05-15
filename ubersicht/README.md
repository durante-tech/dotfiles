# ubersicht — desktop widgets

Übersicht widget source lives at:
```
ubersicht/Library/Application Support/Übersicht/widgets/
```

The path mirrors `$HOME/Library/Application Support/Übersicht/widgets/` so
`stow -t ~ ubersicht` produces the symlink there.

## Stow caveat — absolute symlink required

GNU Stow creates **relative** symlinks (`../../../dotfiles/...`). Übersicht's
internal `server.js` does NOT follow relative symlinks correctly — it tries to
resolve the link target relative to its own application bundle directory, hits
a path that doesn't exist, and crashes with:

```
Error: could not find ../../../dotfiles/ubersicht/Library/Application Support/Übersicht/widgets
```

After `stow -t ~ ubersicht`, replace the relative symlink with an absolute one:

```bash
ln -sfn "$HOME/dotfiles/ubersicht/Library/Application Support/Übersicht/widgets" \
        "$HOME/Library/Application Support/Übersicht/widgets"
```

`setup.sh` should do this automatically as part of its stow pass — if you're
re-stowing manually, run the `ln -sfn` line above afterward.

## LaunchAgent

`launchagents/Library/LaunchAgents/com.lucas.ubersicht.plist.template` ensures
Übersicht starts at login so widgets survive reboots without manual app launch.
