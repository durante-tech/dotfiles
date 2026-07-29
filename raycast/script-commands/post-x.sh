#!/usr/bin/env bash
# @raycast.schemaVersion 1
# @raycast.title DOS Post to X
# @raycast.mode silent
# @raycast.icon 𝕏
# @raycast.packageName DOS · Stream
# @raycast.description Open Typefully draft (or X compose if Typefully not installed)

# Try Typefully first (https://typefully.com — best for thread drafting)
if open -gj "typefully://compose" 2>/dev/null; then
  :
else
  # Fallback: open X compose with optional pre-filled text from clipboard
  TEXT=$(pbpaste | head -c 280 | python3 -c "import sys, urllib.parse; print(urllib.parse.quote(sys.stdin.read()))")
  open "https://twitter.com/intent/tweet?text=${TEXT}"
fi
