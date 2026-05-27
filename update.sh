#!/usr/bin/env bash
# update.sh — discoverable wrapper for `install.sh --update`.
# Delegates to install.sh so there's one canonical install pipeline.
# Forwards extra args (e.g. --dry-run) verbatim.
exec "$(dirname "$0")/install.sh" --update "$@"
