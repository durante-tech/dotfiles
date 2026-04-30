#!/usr/bin/env bash
# Claude Code session indicator for SketchyBar.
#
# Shows current context window utilization + model. Reads the most recently
# modified .jsonl session file under ~/.claude/projects/, parses the last
# assistant message's `usage` block, and computes:
#   total_input = input_tokens + cache_creation_input_tokens + cache_read_input_tokens
# divided by the model's context budget.
#
# Color thresholds: green <70%, yellow 70–85%, red >85%.
# Click action: copies the session file path to the clipboard.

source "$CONFIG_DIR/colors.sh"

CLAUDE_PROJECTS="$HOME/.claude/projects"

# Pick most-recently-modified .jsonl across all projects (last 30 min only).
# Note: stat -f is hijacked by GNU coreutils on this machine, so we use ls -t.
LATEST=$(find "$CLAUDE_PROJECTS" -name "*.jsonl" -mmin -30 -print0 2>/dev/null \
         | xargs -0 ls -1t 2>/dev/null \
         | head -1)

if [ -z "$LATEST" ] || [ ! -f "$LATEST" ]; then
  sketchybar --set "$NAME" \
    icon="󰚩" \
    label="idle" \
    label.color="$GREY" \
    icon.color="$GREY"
  exit 0
fi

# Find last assistant message (has `message.usage`) and parse it.
STATE=$(tail -200 "$LATEST" | python3 -c '
import sys, json
last = None
for line in sys.stdin:
    try:
        d = json.loads(line)
        msg = d.get("message") or {}
        usage = msg.get("usage") or {}
        if usage and msg.get("model"):
            last = (msg.get("model"), usage)
    except Exception:
        continue
if not last:
    print("NONE")
    sys.exit(0)
model, u = last
in_tokens = (u.get("input_tokens") or 0) \
          + (u.get("cache_creation_input_tokens") or 0) \
          + (u.get("cache_read_input_tokens") or 0)
# Context budget heuristics by model family.
m = model.lower()
if "opus-4-7" in m or "[1m]" in m:
    budget = 1_000_000
elif "opus" in m or "sonnet" in m or "haiku" in m:
    budget = 200_000
else:
    budget = 200_000
pct = round(in_tokens * 100 / budget)
short = (
    "opus-4.7"  if "opus-4-7"  in m else
    "opus-4.6"  if "opus-4-6"  in m else
    "opus"      if "opus"      in m else
    "sonnet-4.6"if "sonnet-4-6"in m else
    "sonnet"    if "sonnet"    in m else
    "haiku-4.5" if "haiku-4-5" in m else
    "haiku"    if "haiku"     in m else
    m[:10]
)
print(f"{pct}|{short}|{in_tokens}|{budget}")
' 2>/dev/null)

if [ "$STATE" = "NONE" ] || [ -z "$STATE" ]; then
  sketchybar --set "$NAME" \
    icon="󰚩" \
    label="idle" \
    label.color="$GREY" \
    icon.color="$GREY"
  exit 0
fi

PCT=$(echo "$STATE" | cut -d'|' -f1)
MODEL=$(echo "$STATE" | cut -d'|' -f2)

# Color thresholds.
if   [ "$PCT" -ge 85 ]; then COLOR="$RED"
elif [ "$PCT" -ge 70 ]; then COLOR="$YELLOW"
else                          COLOR="$GREEN"
fi

sketchybar --set "$NAME" \
  icon="󰚩" \
  label="${PCT}% • ${MODEL}" \
  label.color="$COLOR" \
  icon.color="$COLOR"

# Stash session path for click handler.
echo "$LATEST" > "$HOME/.cache/sketchybar-claude-session.txt" 2>/dev/null
