#!/bin/sh

# bd_mode — current BetterDisplay mode indicator + click-to-cycle.
# Listens for bd_mode_changed events (emitted by bd-apply.sh).

bd_mode=(
    background.color="$PURE_BLACK"
    icon=󰖙
    icon.font="$FONT:Bold:15.0"
    label=""
    label.font="$FONT:Bold:12.0"
    update_freq=0
    script="$PLUGIN_DIR/bd_mode.sh"
    click_script="if [ \"\$BUTTON\" = right ]; then $HOME/dotfiles/scripts/scripts/bd-cycle.sh prev; else $HOME/dotfiles/scripts/scripts/bd-cycle.sh next; fi"
)

sketchybar --add event bd_mode_changed
sketchybar --add item bd_mode right \
           --set bd_mode "${bd_mode[@]}" \
           --subscribe bd_mode bd_mode_changed system_woke
