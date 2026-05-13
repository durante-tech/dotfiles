// memory-tide.widget — 7-day reflections sparkline with always-visible labels.
// Naked, bottom-center floating organic. Wider reeds, persistent header + day/count labels.

export const command = `bash "$HOME/Library/Application Support/Übersicht/widgets/memory-tide.widget/data.sh"`
export const refreshFrequency = 5 * 60 * 1000

const REED_COLORS = [
  "#6c7086", // overlay0   — oldest
  "#585b70", // surface2
  "#89dceb", // sky
  "#74c7ec", // sapphire
  "#89b4fa", // blue
  "#b4befe", // lavender
  "#94e2d5", // teal       — today
]

const W_TOTAL  = 360
const H_TOTAL  = 110
const REED_W   = 14
const REED_GAP = 32
const MAX_H    = 56
const MIN_H    = 12
const BASELINE_Y = 78

export const className = `
  bottom: 170px;
  left: 50%;
  transform: translateX(-50%);
  width: ${W_TOTAL}px;
  height: ${H_TOTAL}px;
  user-select: none;
  z-index: 0;
  font-family: 'JetBrainsMono Nerd Font', 'JetBrains Mono', monospace;

  svg { display: block; overflow: visible; }

  .reed {
    transform-origin: 50% 100%;
    animation: tide-sway 12s ease-in-out infinite;
  }

  @keyframes tide-sway {
    0%   { transform: rotate(-2deg); }
    50%  { transform: rotate(2deg); }
    100% { transform: rotate(-2deg); }
  }

  .header {
    fill: #a6adc8;
    font-size: 9px;
    letter-spacing: 0.32em;
    text-transform: uppercase;
    text-anchor: middle;
    font-weight: 700;
    opacity: 0.85;
  }

  .label {
    fill: #6c7086;
    font-size: 9px;
    letter-spacing: 0.05em;
    text-transform: uppercase;
    text-anchor: middle;
    font-weight: 600;
  }
  .label.today { fill: #94e2d5; }

  .count {
    fill: #a6adc8;
    font-size: 10px;
    text-anchor: middle;
    font-variant-numeric: tabular-nums;
  }
  .count.today { fill: #cdd6f4; font-weight: 600; }
  .count.zero  { fill: #45475a; }

  .baseline {
    stroke: #45475a;
    stroke-width: 1;
    opacity: 0.4;
  }

  .error {
    fill: #f38ba8;
    font-size: 10px;
    text-anchor: middle;
  }
`

export const render = ({ output }) => {
  let d = null
  try { d = JSON.parse((output || "").trim() || "{}") }
  catch (e) { return <div /> }
  if (d.error || !d.days) return <div />

  const days  = d.days
  const max   = d.max || 1
  const totalW = 7 * REED_W + 6 * REED_GAP
  const startX = (W_TOTAL - totalW) / 2

  return (
    <svg width={W_TOTAL} height={H_TOTAL} viewBox={`0 0 ${W_TOTAL} ${H_TOTAL}`}>
      <text className="header" x={W_TOTAL / 2} y={14}>✦ Activity · 7 days</text>

      {/* faint baseline so reeds have a horizon */}
      <line className="baseline" x1={startX - 4} y1={BASELINE_Y} x2={startX + totalW + 4} y2={BASELINE_Y} />

      {days.map((day, i) => {
        const isToday = i === 6
        const h = day.count > 0 ? MIN_H + (day.count / max) * (MAX_H - MIN_H) : MIN_H
        const x = startX + i * (REED_W + REED_GAP)
        const cx = x + REED_W / 2
        const reedColor = REED_COLORS[i] || "#6c7086"
        const reedOpacity = day.count === 0 ? 0.25 : (isToday ? 0.95 : 0.7)
        const delay = `${-i * 0.55}s`
        const dayLetter = day.label[0] // M T W T F S S
        return (
          <g key={day.date}>
            <text
              className={`count ${isToday ? "today" : ""} ${day.count === 0 ? "zero" : ""}`}
              x={cx}
              y={BASELINE_Y - h - 6}
            >
              {day.count}
            </text>
            <rect
              className="reed"
              x={x}
              y={BASELINE_Y - h}
              width={REED_W}
              height={h}
              rx={4}
              ry={4}
              fill={reedColor}
              opacity={reedOpacity}
              style={{ animationDelay: delay }}
            />
            <text
              className={`label ${isToday ? "today" : ""}`}
              x={cx}
              y={BASELINE_Y + 14}
            >
              {dayLetter}
            </text>
          </g>
        )
      })}
    </svg>
  )
}
