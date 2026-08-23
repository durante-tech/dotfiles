# MPD config

Canonical docs: `docs/mpd/README.md`. This file covers only what is specific to
the stowed package.

## Install

`brew install mpd`. The client here is **rmpc**, not `mpc` — `mpc` is in neither
the Brewfile nor install.sh and is not installed, so the old `mpc status` step
below only ever printed `command not found`.

## Manually run mpd
- run `mpd` — no config-path argument needed. MPD 0.24 searches
  `$XDG_CONFIG_HOME/mpd/mpd.conf` first and `~/.config/mpd` is the stow symlink
  into this package, so the bare command finds this config. (The `mpds` alias in
  `zsh/.zshrc` passes the path explicitly; both work.)

- Two ways to Check if mpd is running
    - `lsof -i TCP:6600` : where "6600" is the port specified in the mpd config
    - `pgrep -fl mpd` : where you'll see mpd running pointing to your mpd.conf path

## Restart mpd with
- run `mpd --kill` (works because `pid_file` is set), or `pkill mpd`
- run `mpd` again, or use the `mpds` alias


