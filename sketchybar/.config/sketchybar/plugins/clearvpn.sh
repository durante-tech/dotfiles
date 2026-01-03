#!/bin/bash

source "$CONFIG_DIR/colors.sh"

# Check if ClearVPN is running
if ! pgrep -f "ClearVPN" > /dev/null 2>&1; then
    sketchybar --set "$NAME" icon="󰦝" label="Off" icon.color="$GREY"
    exit 0
fi

# Check if default route goes through VPN (utun interface)
# When VPN is connected, traffic routes through utun* instead of en0/en1
DEFAULT_IFACE=$(route -n get default 2>/dev/null | grep "interface:" | awk '{print $2}')

if [[ "$DEFAULT_IFACE" == utun* ]]; then
    # VPN is connected - traffic routed through tunnel
    sketchybar --set "$NAME" icon="󰌆" label="VPN" icon.color="$GREEN"
else
    # ClearVPN running but not connected
    sketchybar --set "$NAME" icon="󰦝" label="Off" icon.color="$YELLOW"
fi
