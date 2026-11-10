#!/bin/bash
# with_timeout LIMIT_SECONDS COMMAND... — run COMMAND, give up after LIMIT.
# Sourced by plugins (like colors.sh); defines a function, runs nothing.
#
# GNU timeout is not on sketchybar's PATH: coreutils puts it in a gnubin dir
# that only the interactive .zprofile adds, and Homebrew's bin has it only as
# `gtimeout`. A bare `timeout` therefore failed as "command not found", which
# `if ! timeout ... docker info` read as "Docker is off" — permanently.
# With neither binary present the limit is still enforced by a watchdog, so a
# hung daemon cannot block the bar.
TIMEOUT_BIN=""
for candidate in timeout gtimeout /opt/homebrew/bin/gtimeout /usr/local/bin/gtimeout; do
    if command -v "$candidate" >/dev/null 2>&1; then
        TIMEOUT_BIN="$candidate"
        break
    fi
done

with_timeout() {
    local limit="${1%s}"
    shift
    if [ -n "$TIMEOUT_BIN" ]; then
        "$TIMEOUT_BIN" "$limit" "$@"
        return
    fi
    "$@" &
    local pid=$! status
    ( sleep "$limit"; kill "$pid" 2>/dev/null ) >/dev/null 2>&1 &
    local watchdog=$!
    wait "$pid" 2>/dev/null
    status=$?
    kill "$watchdog" 2>/dev/null
    wait "$watchdog" 2>/dev/null
    return "$status"
}
