#!/bin/bash

source "$CONFIG_DIR/colors.sh"

# Left-click opens notifications; right-click / shift-click opens a quick-links
# popup (plugins/github_click.sh) with a live unread-count header.
github=(
  script="$PLUGIN_DIR/github.sh"
  icon=""
  label=""
  background.color="$PURE_BLACK"
  padding_right=5
  padding_left=5
  update_freq=300
  updates=on
  click_script="$PLUGIN_DIR/github_click.sh"
  popup.background.color="$POPUP_BACKGROUND_COLOR"
  popup.background.border_color="$POPUP_BORDER_COLOR"
  popup.background.border_width=2
  popup.background.corner_radius=6
  popup.horizontal=off
  popup.align=left
  popup.y_offset=5
)

sketchybar --add item github right \
           --set github "${github[@]}"

##### Popup quick-link rows (header refreshed on open by github_click.sh) #####
sketchybar --add item github.count popup.github \
           --set github.count label="…" label.color="$WHITE" \
                 icon.drawing=off background.drawing=off \
                 click_script="sketchybar --set github popup.drawing=off"

sketchybar --add item github.notifs popup.github \
           --set github.notifs label="Notifications" label.color="$WHITE" \
                 icon.drawing=off background.color="$PURE_BLACK" background.drawing=on \
                 click_script="open https://github.com/notifications; sketchybar --set github popup.drawing=off"

sketchybar --add item github.prs popup.github \
           --set github.prs label="Pull Requests" label.color="$WHITE" \
                 icon.drawing=off background.color="$PURE_BLACK" background.drawing=on \
                 click_script="open https://github.com/pulls; sketchybar --set github popup.drawing=off"

sketchybar --add item github.issues popup.github \
           --set github.issues label="Issues" label.color="$WHITE" \
                 icon.drawing=off background.color="$PURE_BLACK" background.drawing=on \
                 click_script="open https://github.com/issues; sketchybar --set github popup.drawing=off"

sketchybar --add item github.open popup.github \
           --set github.open label="Open GitHub" label.color="$BLUE" \
                 icon.drawing=off background.color="$PURE_BLACK" background.drawing=on \
                 click_script="open https://github.com; sketchybar --set github popup.drawing=off"
