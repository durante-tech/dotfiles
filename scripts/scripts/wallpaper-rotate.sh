#!/usr/bin/env bash
# wallpaper-rotate.sh — pick a Durante-themed wallpaper per monitor based on
# time-of-day band, then set it via wallpaper-cli. Designed to be fired
# hourly by ~/Library/LaunchAgents/com.lucas.wallpaper-rotate.plist.
#
# Banding (curates mood across the day):
#   06–12 morning      → calm: 01-telos, 02-voice, 03-skills
#   12–18 afternoon    → active: 04-algorithm, 05-studio, 06-hooks
#   18–22 evening      → contemplative: 07-mempalace, 08-sentinel
#   22–06 night        → deep: 09-council, 10-dos
#
# Per monitor: orientation-aware. Landscape monitors receive landscape
# wallpapers from the band; portrait monitors receive portrait wallpapers
# (falls back to any portrait if the band has none).
#
# Override: pass --all to ignore the band and pick from the full pool.

set -u

DIR="$HOME/Pictures/Wallpapers"
WALLPAPER="/opt/homebrew/bin/wallpaper"
[ -x "$WALLPAPER" ] || { echo "wallpaper-cli not found at $WALLPAPER" >&2; exit 1; }
[ -d "$DIR" ] || { echo "no wallpapers dir: $DIR" >&2; exit 1; }

MODE="${1:-band}"

current_band() {
  local h
  h=$(date +%H)
  h=$((10#$h))
  if   [ "$h" -ge 6  ] && [ "$h" -lt 12 ]; then echo morning
  elif [ "$h" -ge 12 ] && [ "$h" -lt 18 ]; then echo afternoon
  elif [ "$h" -ge 18 ] && [ "$h" -lt 22 ]; then echo evening
  else                                            echo night
  fi
}

band_files() {
  case "$1" in
    morning)   echo "01-telos.jpg 02-voice.jpg 03-skills.jpg" ;;
    afternoon) echo "04-algorithm.jpg 05-studio.jpg 06-hooks.jpg" ;;
    evening)   echo "07-mempalace.jpg 08-sentinel.jpg" ;;
    night)     echo "09-council.jpg 10-dos.jpg" ;;
  esac
}

is_portrait() {
  local f="$1"
  local w h
  w=$(sips -g pixelWidth  "$f" 2>/dev/null | awk '/pixelWidth:/  {print $2}')
  h=$(sips -g pixelHeight "$f" 2>/dev/null | awk '/pixelHeight:/ {print $2}')
  [ -n "$w" ] && [ -n "$h" ] && [ "$h" -gt "$w" ]
}

pick_random() {
  local arr=("$@")
  local n=${#arr[@]}
  [ "$n" -eq 0 ] && return 1
  echo "${arr[$((RANDOM % n))]}"
}

# Daily nano-banana wallpaper: the DailyBrief agent drops a fresh generated
# piece into $DIR/daily/ each evening (dailybrief-YYYY-MM-DD.png). If one
# exists and is <36h old, it joins every band's landscape pool for its day —
# so the day's generated art shows up in rotation alongside the gallery.
DAILY_DIR="$DIR/daily"
DAILY_PICK=""
if [ -d "$DAILY_DIR" ]; then
  newest="$(ls -t "$DAILY_DIR"/dailybrief-*.png "$DAILY_DIR"/dailybrief-*.jpg 2>/dev/null | head -1)"
  if [ -n "$newest" ]; then
    now_epoch="$(date +%s)"
    file_epoch="$(stat -f %m "$newest" 2>/dev/null || echo 0)"
    if [ $((now_epoch - file_epoch)) -lt 129600 ]; then  # 36h
      DAILY_PICK="$newest"
    fi
  fi
fi

# Build candidate pools.
band="$(current_band)"
if [ "$MODE" = "--all" ] || [ "$MODE" = "all" ]; then
  POOL=( "$DIR"/[0-9][0-9]-*.jpg )
else
  POOL=()
  for name in $(band_files "$band"); do
    [ -f "$DIR/$name" ] && POOL+=("$DIR/$name")
  done
  # Belt + suspenders: if band yielded nothing, fall back to full set.
  [ ${#POOL[@]} -eq 0 ] && POOL=( "$DIR"/[0-9][0-9]-*.jpg )
fi
# Fresh daily piece joins the pool (twice — gentle weighting toward today's art).
if [ -n "$DAILY_PICK" ]; then
  POOL+=("$DAILY_PICK" "$DAILY_PICK")
fi

# Split pool by orientation.
LAND=()
PORT=()
for f in "${POOL[@]}"; do
  if is_portrait "$f"; then PORT+=("$f"); else LAND+=("$f"); fi
done

# Full-set fallbacks for monitors when band+orientation has nothing.
LAND_ALL=()
PORT_ALL=()
for f in "$DIR"/[0-9][0-9]-*.jpg; do
  if is_portrait "$f"; then PORT_ALL+=("$f"); else LAND_ALL+=("$f"); fi
done

# Probe each screen, pick orientation-matched random, set it.
SCREENS_OUTPUT="$($WALLPAPER screens 2>/dev/null)"
[ -z "$SCREENS_OUTPUT" ] && { echo "could not list screens" >&2; exit 1; }

while read -r line; do
  idx="${line%% -*}"
  name="${line#*- }"
  [ -z "$idx" ] && continue
  # Determine screen orientation via system_profiler.
  res="$(system_profiler SPDisplaysDataType 2>/dev/null | grep -i "Resolution:" | sed -n "$((idx + 1))p")"
  if echo "$res" | grep -qE '\b([0-9]+) x ([0-9]+)\b'; then
    w="$(echo "$res" | sed -E 's/.* ([0-9]+) x ([0-9]+).*/\1/')"
    h="$(echo "$res" | sed -E 's/.* ([0-9]+) x ([0-9]+).*/\2/')"
    if [ "$h" -gt "$w" ]; then
      pick="$(pick_random "${PORT[@]:-${PORT_ALL[@]}}")"
    else
      pick="$(pick_random "${LAND[@]:-${LAND_ALL[@]}}")"
    fi
  else
    # Fall back to landscape pool when geometry probe fails.
    pick="$(pick_random "${LAND[@]:-${LAND_ALL[@]}}")"
  fi

  if [ -n "$pick" ]; then
    "$WALLPAPER" set "$pick" --screen "$idx" >/dev/null 2>&1
    echo "screen $idx ($name) → $(basename "$pick")  [band: $band]"
  fi
done <<< "$SCREENS_OUTPUT"
