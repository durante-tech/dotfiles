#!/bin/bash
# with_timeout LIMIT_SECONDS COMMAND... — run COMMAND, give up after LIMIT.
# Sourced by plugins (like colors.sh); defines a function, runs nothing.
#
# GNU timeout is not on sketchybar's PATH: coreutils puts it in a gnubin dir
# that only the interactive .zprofile adds, and Homebrew's bin has it only as
# `gtimeout`. A bare `timeout` therefore failed as "command not found", which
# `if ! timeout ... docker info` read as "Docker is off" — permanently.
# Exit status 124 means the limit was hit, with or without the binary.
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
    local status
    if [ -n "$TIMEOUT_BIN" ]; then
        # -k 1: KILL one second after the TERM. Without it GNU timeout waits
        # forever on a command that ignores TERM, the very hang this bounds.
        "$TIMEOUT_BIN" -k 1 "$limit" "$@"
        status=$?
        # timeout exits 137 when it had to KILL; one code for "timed out".
        [ "$status" -eq 137 ] && status=124
        return "$status"
    fi
    "$@" &
    local pid=$!
    # TERM first; a command that ignores it gets KILL one second later, so the
    # `wait` below is bounded by limit + 1 whatever the command does.
    ( sleep "$limit"; kill "$pid" 2>/dev/null; sleep 1; kill -9 "$pid" 2>/dev/null ) >/dev/null 2>&1 &
    local watchdog=$!
    wait "$pid" 2>/dev/null
    status=$?
    kill "$watchdog" 2>/dev/null
    wait "$watchdog" 2>/dev/null
    # 143 = TERM, 137 = KILL: report both as 124, GNU timeout's own code.
    case "$status" in 137|143) status=124 ;; esac
    return "$status"
}

# True when STATUS means "gave up waiting", as opposed to "ran and failed".
timed_out() {
    [ "$1" -eq 124 ] || [ "$1" -eq 137 ]
}
