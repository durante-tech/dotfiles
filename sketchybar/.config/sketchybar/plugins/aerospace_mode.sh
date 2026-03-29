#!/usr/bin/env bash

MODE="${MODE:-main}"

case "$MODE" in
    main)
        sketchybar --set "$NAME" drawing=off
        ;;
    resize)
        sketchybar --set "$NAME" drawing=on \
            label="RESIZE" \
            label.color=0xfff9e2af \
            icon.color=0xfff9e2af \
            background.color=0x40f9e2af
        ;;
    service)
        sketchybar --set "$NAME" drawing=on \
            label="SERVICE" \
            label.color=0xfff38ba8 \
            icon.color=0xfff38ba8 \
            background.color=0x40f38ba8
        ;;
    *)
        sketchybar --set "$NAME" drawing=on \
            label="$MODE" \
            label.color=0xffcdd6f4 \
            icon.color=0xffcdd6f4 \
            background.color=0x40cdd6f4
        ;;
esac
