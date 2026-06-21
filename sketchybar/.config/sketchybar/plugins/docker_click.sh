#!/bin/bash

# Docker item click router:
#   left-click           → open Docker Desktop dashboard (original behavior)
#   right / shift-click  → (re)build a popup listing running containers
# Container rows are rebuilt on every open because the set is dynamic, exactly
# like the mic/volume device pickers.
source "$CONFIG_DIR/colors.sh"

DOCKER=$(command -v docker || echo "/usr/local/bin/docker")

open_dashboard() {
    open -a 'Docker Desktop' && sleep 0.3 && open docker-desktop://dashboard/containers
}

if [ "$BUTTON" != "right" ] && [ "$MODIFIER" != "shift" ]; then
    open_dashboard
    exit 0
fi

# Start fresh: drop any prior rows, then toggle the popup.
args=(--remove '/docker.row\.*/' --set docker popup.drawing=toggle)

if ! timeout 2s "$DOCKER" info >/dev/null 2>&1; then
    args+=(--add item docker.row.0 popup.docker
           --set docker.row.0 label="Docker not running" label.color="$GREY"
                 icon.drawing=off background.drawing=off
                 click_script="sketchybar --set docker popup.drawing=off")
else
    DATA=$(timeout 3s "$DOCKER" ps --format "{{.Names}}|{{.Status}}" 2>/dev/null)
    if [ -z "$DATA" ]; then
        args+=(--add item docker.row.0 popup.docker
               --set docker.row.0 label="No running containers" label.color="$GREY"
                     icon.drawing=off background.drawing=off
                     click_script="sketchybar --set docker popup.drawing=off")
    else
        COUNT=0
        while IFS='|' read -r name status; do
            [ -z "$name" ] && continue
            COLOR="$GREEN"
            case "$status" in
                *unhealthy*)        COLOR="$ORANGE" ;;
                *Exited*|*Created*) COLOR="$GREY" ;;
            esac
            args+=(--add item docker.row.$COUNT popup.docker
                   --set docker.row.$COUNT label="${name}  ·  ${status}" label.color="$COLOR"
                         icon.drawing=off background.color="$PURE_BLACK" background.drawing=on
                         click_script="sketchybar --set docker popup.drawing=off")
            COUNT=$((COUNT + 1))
        done <<< "$DATA"
    fi
fi

# Action row — always present.
args+=(--add item docker.row.dash popup.docker
       --set docker.row.dash label="Open Dashboard" label.color="$BLUE"
             icon.drawing=off background.color="$PURE_BLACK" background.drawing=on
             click_script="open -a 'Docker Desktop'; open docker-desktop://dashboard/containers; sketchybar --set docker popup.drawing=off")

sketchybar -m "${args[@]}" >/dev/null
