// golden-hour.widget — 24h sun ring with golden-hour bloom for São Paulo.
// Designer spec: 120×120 SVG, naked, top-left below moon. NOON at top of ring.
// Pure client-side computation — no shell call.

export const refreshFrequency = 60 * 1000

const LAT = -23.5505

// Approximate sun-time math (declination from day-of-year + hour-angle from latitude).
// Accurate to ~5 min — fine for ambient widget. Returns hours in local civil time.
function sunHours(now, lat) {
  const start = new Date(now.getFullYear(), 0, 0)
  const N = Math.floor((now - start) / 86400000)
  const decl = (-23.45 * Math.cos((360 / 365) * (N + 10) * Math.PI / 180)) * Math.PI / 180
  const phi  = lat * Math.PI / 180
  const cosH = -Math.tan(phi) * Math.tan(decl)
  const clamped = Math.max(-1, Math.min(1, cosH))
  const H = Math.acos(clamped) * 180 / Math.PI
  const noon = 12
  return {
    sunrise: noon - H / 15,
    sunset:  noon + H / 15,
    noon,
  }
}

// Golden hour ≈ 1 hour after sunrise / 1 hour before sunset
// Civil twilight ≈ 30 min before sunrise / 30 min after sunset
function buildSegments(now, lat) {
  const { sunrise, sunset, noon } = sunHours(now, lat)
  const ghMornEnd  = sunrise + 1
  const ghEvenStart = sunset  - 1
  const dawn = sunrise - 0.5
  const dusk = sunset  + 0.5

  const hToFrac = (h) => Math.max(0, Math.min(1, h / 24))

  return {
    segments: [
      { start: 0,                end: hToFrac(dawn),       kind: "night" },
      { start: hToFrac(dawn),    end: hToFrac(sunrise),    kind: "dawn" },
      { start: hToFrac(sunrise), end: hToFrac(ghMornEnd),  kind: "goldenHourMorning" },
      { start: hToFrac(ghMornEnd), end: hToFrac(ghEvenStart), kind: "day" },
      { start: hToFrac(ghEvenStart), end: hToFrac(sunset), kind: "goldenHourEvening" },
      { start: hToFrac(sunset),  end: hToFrac(dusk),       kind: "dusk" },
      { start: hToFrac(dusk),    end: 1,                   kind: "night" },
    ],
    sunrise, sunset, noon, ghMornEnd, ghEvenStart,
  }
}

const SEGMENT_STYLE = {
  night:               { color: "#181825", opacity: 0.9 },
  dawn:                { color: "#cba6f7", opacity: 0.5 },
  goldenHourMorning:   { color: "#f9e2af", opacity: 0.85 },
  day:                 { color: "#89dceb", opacity: 0.4 },
  goldenHourEvening:   { color: "#fab387", opacity: 0.85 },
  dusk:                { color: "#b4befe", opacity: 0.5 },
}

export const className = `
  top: 220px;
  left: 60px;
  width: 120px;
  height: 120px;
  user-select: none;
  -webkit-font-smoothing: antialiased;

  svg { display: block; overflow: visible; }

  .sun-dot {
    transition: cx 0.8s ease-out, cy 0.8s ease-out;
    filter: drop-shadow(0 0 8px rgba(249, 226, 175, 0.7));
  }

  .bloom-halo {
    animation: bloom 4s ease-in-out infinite;
  }

  @keyframes bloom {
    0%   { opacity: 0.15; }
    50%  { opacity: 0.35; }
    100% { opacity: 0.15; }
  }
`

// Convert 0..1 fraction to (x,y) on the ring. NOON (0.5) = top.
// Fraction 0 = bottom (midnight). 0.25 = right (6 AM). 0.5 = top (noon). 0.75 = left (6 PM).
function frac2xy(f, cx, cy, r) {
  // angle: 0 = bottom, increasing clockwise. Bottom = 90°(SVG y+ down) = 0.25π in math, 90° in svg.
  // SVG: 0° = 3 o'clock (right). Increasing clockwise.
  // Map fraction → angle in degrees: f=0→bottom→90°SVG; f=0.25→right→0°; f=0.5→top→-90°(or 270°); f=0.75→left→180°.
  const angDeg = 90 - f * 360
  const ang = angDeg * Math.PI / 180
  return {
    x: cx + r * Math.cos(ang),
    y: cy - r * Math.sin(ang),
  }
}

function arcPath(startFrac, endFrac, cx, cy, r) {
  const a = frac2xy(startFrac, cx, cy, r)
  const b = frac2xy(endFrac, cx, cy, r)
  const sweepLen = endFrac - startFrac
  const largeArc = sweepLen > 0.5 ? 1 : 0
  return `M ${a.x.toFixed(2)} ${a.y.toFixed(2)} A ${r} ${r} 0 ${largeArc} 1 ${b.x.toFixed(2)} ${b.y.toFixed(2)}`
}

export const render = () => {
  const now = new Date()
  const startOfDay = new Date(now.getFullYear(), now.getMonth(), now.getDate())
  const sunPositionFraction = (now - startOfDay) / 86400000

  const built = buildSegments(now, LAT)
  const { segments } = built
  const cx = 60, cy = 60, r = 48

  const isGoldenHour = segments.some((s) =>
    (s.kind === "goldenHourMorning" || s.kind === "goldenHourEvening") &&
    sunPositionFraction >= s.start && sunPositionFraction <= s.end
  )

  const sun = frac2xy(sunPositionFraction, cx, cy, r)

  // Three radial ticks at sunrise, noon, sunset
  const tickFracs = [
    built.sunrise / 24,
    0.5,
    built.sunset / 24,
  ]
  const ticks = tickFracs.map((f) => {
    const outer = frac2xy(f, cx, cy, r + 4)
    const inner = frac2xy(f, cx, cy, r - 2)
    return { x1: inner.x, y1: inner.y, x2: outer.x, y2: outer.y }
  })

  return (
    <div>
      <svg width="120" height="120" viewBox="0 0 120 120">
        {/* base ring (dim) for completeness */}
        <circle cx={cx} cy={cy} r={r} fill="none" stroke="#11111b" strokeWidth="6" opacity="0.3" />

        {/* segment arcs */}
        {segments.map((s, i) => {
          if (s.start >= s.end) return null
          const style = SEGMENT_STYLE[s.kind] || SEGMENT_STYLE.night
          return (
            <path
              key={i}
              d={arcPath(s.start, s.end, cx, cy, r)}
              fill="none"
              stroke={style.color}
              strokeWidth="6"
              strokeLinecap="round"
              opacity={style.opacity}
            />
          )
        })}

        {/* ticks at sunrise/noon/sunset */}
        {ticks.map((t, i) => (
          <line key={i} x1={t.x1} y1={t.y1} x2={t.x2} y2={t.y2} stroke="#6c7086" strokeWidth="1.5" opacity="0.7" />
        ))}

        {/* golden bloom halo */}
        {isGoldenHour && (
          <circle className="bloom-halo" cx={sun.x} cy={sun.y} r="14" fill="#fab387" opacity="0.25" />
        )}

        {/* sun dot */}
        <circle
          className="sun-dot"
          cx={sun.x}
          cy={sun.y}
          r={isGoldenHour ? 6 : 4}
          fill="#f9e2af"
        />
      </svg>
    </div>
  )
}
