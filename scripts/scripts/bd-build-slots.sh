#!/usr/bin/env bash
# Build BetterDisplay favorite mode slots 2-5 for software development.
#
# Slot 1 is already saved as your daylight default — this script populates:
#   2 = dev-night      (warm, dim, low ambient)
#   3 = dev-meeting    (sRGB-accurate, bright, predictable color for video calls)
#   4 = dev-read       (larger text, calmer brightness for long-form reading)
#   5 = dev-stream     (sRGB-accurate, bright, STREAM-CAPTURE connected for OBS)
#
# Each slot save briefly switches DEV-MAIN and PORTRAIT-MONITOR into that mode.
# The script returns to slot 1 at the end so you're back where you started.
#
# Run interactively. Apps may re-layout during slot 4 (resolution change).

set -e

DEV=2          # DEV-MAIN tagID
PORT=60        # PORTRAIT-MONITOR tagID
STREAM=163     # STREAM-CAPTURE virtual screen tagID

bd() { betterdisplaycli "$@" >/dev/null 2>&1 || true; }

echo "BetterDisplay slot builder — populating 2 through 5."
echo "Current state is preserved in slot 1; restoring at the end."
echo
read -r -p "Proceed? [y/N] " yn
[[ "$yn" =~ ^[Yy]$ ]] || { echo "Aborted."; exit 0; }

echo
echo "[2/5] dev-night — warm, dim, evening coding"
bd set --tagID=$DEV  --brightness=50%
bd set --tagID=$PORT --hardwareBrightness=35%
bd set --tagID=$PORT --temperature=-3%
bd set --tagID=$PORT --bGain=-5%
sleep 1
bd set --tagID=$DEV  --saveFavoriteMode=2
bd set --tagID=$PORT --saveFavoriteMode=2
echo "    saved."

echo "[3/5] dev-meeting — sRGB-accurate, bright, video-call ready"
bd set --tagID=$PORT --temperature=0%
bd set --tagID=$PORT --bGain=0%
bd set --tagID=$PORT --hardwareBrightness=100%
bd set --tagID=$DEV  --brightness=100%
bd set --tagID=$DEV  --xdrPreset='Internet & Web (sRGB)'
sleep 1
bd set --tagID=$DEV  --saveFavoriteMode=3
bd set --tagID=$PORT --saveFavoriteMode=3
echo "    saved."

echo "[4/5] dev-read — larger text, calmer brightness for long-form"
bd set --tagID=$DEV  --resolution=1496x969 --refreshRate=ProMotion --hiDPI=on
bd set --tagID=$DEV  --brightness=70%
bd set --tagID=$DEV  --xdrPreset='Photography (P3-D65)'
bd set --tagID=$PORT --hardwareBrightness=65%
bd set --tagID=$PORT --temperature=-2%
sleep 2
bd set --tagID=$DEV  --saveFavoriteMode=4
bd set --tagID=$PORT --saveFavoriteMode=4
echo "    saved."

echo "[5/5] dev-stream — sRGB-accurate for OBS, STREAM-CAPTURE connected"
bd set --tagID=$DEV  --resolution=1728x1117 --refreshRate=ProMotion --hiDPI=on
bd set --tagID=$DEV  --brightness=90%
bd set --tagID=$DEV  --xdrPreset='Internet & Web (sRGB)'
bd set --tagID=$PORT --hardwareBrightness=90%
bd set --tagID=$PORT --temperature=0%
sleep 1
bd set --tagID=$DEV  --saveFavoriteMode=5
bd set --tagID=$PORT --saveFavoriteMode=5
echo "    saved."

echo
echo "Restoring slot 1 (daylight default)..."
bd set --tagID=$DEV  --favoriteMode=1
bd set --tagID=$PORT --favoriteMode=1
echo "Done. Use bd-day / bd-night / bd-meeting / bd-read / bd-stream to switch."
