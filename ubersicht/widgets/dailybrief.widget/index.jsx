// dailybrief.widget — renders today's daily operations brief as an ambient panel.
// Data source: data.sh emits JSON (state, date, sections[], delta_days).
// Visual language: matches deck.widget. Catppuccin Mocha · left side · blue accent.
// CSS in className uses standard CSS (semicolons + braces) — Übersicht parser
// requires this, NOT Stylus indented syntax.

export const command = `bash "$HOME/Library/Application Support/Übersicht/widgets/dailybrief.widget/data.sh"`

export const refreshFrequency = 300 * 1000 // 5 min — brief regenerates daily, no need to thrash

// ── "Today's Focus" filter ──────────────────────────────────────────────────
// That section now lives in today-focus.widget. Filter it out of the brief
// render so the two surfaces don't duplicate each other.
const isTodayFocusSection = (heading) => {
  const h = (heading || "").toLowerCase().trim()
  // strip leading enumeration like "1. ", "2) ", "## "
  const stripped = h.replace(/^[\d]+[.)]\s+/, "").replace(/^#+\s+/, "").trim()
  if (stripped.startsWith("today's focus")) return true
  if (stripped.startsWith("today")) return true
  if (stripped.startsWith("focus")) return true
  if (/^\d+\.\s*today/i.test(h)) return true
  return false
}

// ── Critical-finding prefix detection ───────────────────────────────────────
// When a line starts with one of these tokens, render the prefix in an accent
// colour. Order matters — longest first so "quality problem:" wins over "quality".
const CRITICAL_PREFIXES = [
  { token: "Quality problem:",  className: "tag-critical" },
  { token: "Staleness alert:",  className: "tag-warn" },
  { token: "Critical:",         className: "tag-critical" },
  { token: "Pattern:",          className: "tag-warn" },
  { token: "Warning:",          className: "tag-warn" },
  { token: "Alert:",            className: "tag-critical" },
  { token: "Watch it.",         className: "tag-warn" },
]

const splitCritical = (text) => {
  for (const { token, className } of CRITICAL_PREFIXES) {
    if (text.startsWith(token)) {
      return { tag: token, rest: text.slice(token.length), className }
    }
  }
  return null
}

// ── Word-boundary truncation ────────────────────────────────────────────────
// Trim at the last whitespace before `max` chars, append a single ellipsis.
// Avoids the ugly "mid-word…" cut that the previous version produced.
const wordTruncate = (s, max) => {
  if (!s || s.length <= max) return s
  const slice = s.slice(0, max)
  const lastSpace = slice.lastIndexOf(" ")
  const cut = lastSpace > max * 0.6 ? slice.slice(0, lastSpace) : slice
  return cut.replace(/[.,;:\-—\s]+$/, "") + "…"
}

// ── Layout knobs ────────────────────────────────────────────────────────────
const MAX_SECTIONS          = 5    // data.sh already caps at 5
const MAX_LINES_PER_SECTION = 2    // visible lines before "+N more"
const LINE_CHAR_BUDGET      = 96   // word-truncate target

// ── DOS Widget Type Scale ────────────────────────────────────────────────────
// display 26px · lead 16px · body 13px · support 11px · label 10px · micro 9px
// Applied throughout: every font-size below maps to one of these tokens.

export const className = `
  box-sizing: border-box;
  top: 220px;
  left: 60px;
  width: 380px;
  font-family: 'JetBrainsMono Nerd Font', 'JetBrains Mono', 'Hack Nerd Font', monospace;
  background: rgba(17, 17, 27, 0.6);
  backdrop-filter: blur(28px) saturate(140%);
  -webkit-backdrop-filter: blur(28px) saturate(140%);
  padding: 22px 26px;
  border-radius: 16px;
  border: 1px solid rgba(137, 180, 250, 0.18);
  border-left: 4px solid #89b4fa;
  color: #cdd6f4;
  user-select: none;
  -webkit-font-smoothing: antialiased;
  box-shadow: 0 16px 48px rgba(0, 0, 0, 0.4);
  font-size: 13px; /* body */
  line-height: 1.55;
  overflow-x: hidden;
  overflow-y: auto;

  .header {
    display: flex;
    justify-content: space-between;
    align-items: baseline;
    color: #89b4fa;
    font-size: 13px; /* body — panel identity */
    letter-spacing: 5px;
    text-transform: uppercase;
    font-weight: 700;
    margin-bottom: 14px;
  }
  .header .title {
    display: inline-flex;
    align-items: baseline;
    gap: 8px;
  }
  .header .title .glyph {
    font-size: 13px; /* body — match header */
    color: #89b4fa;
    opacity: 0.95;
    letter-spacing: 0;
  }
  .header .right {
    display: inline-flex;
    align-items: center;
    gap: 10px;
  }
  .header .run-btn {
    display: inline-flex;
    align-items: center;
    justify-content: center;
    width: 22px;
    height: 22px;
    border-radius: 50%;
    background: rgba(137, 180, 250, 0.12);
    border: 1px solid rgba(137, 180, 250, 0.35);
    color: #89b4fa;
    font-size: 12px;
    font-weight: 700;
    cursor: pointer;
    user-select: none;
    transition: background 180ms ease, transform 180ms ease, color 180ms ease;
    letter-spacing: 0;
  }
  .header .run-btn:hover {
    background: rgba(137, 180, 250, 0.25);
    transform: scale(1.08);
  }
  .header .run-btn.running {
    color: #f9e2af;
    border-color: rgba(249, 226, 175, 0.45);
    background: rgba(249, 226, 175, 0.12);
    animation: spin 1.2s linear infinite;
  }
  @keyframes spin {
    from { transform: rotate(0deg); }
    to   { transform: rotate(360deg); }
  }
  .header .meta {
    display: inline-flex;
    align-items: center;
    gap: 6px;
    color: #a6adc8;
    font-size: 10px; /* label */
    letter-spacing: 1px;
    font-weight: 500;
  }
  .header .meta .dot {
    display: inline-block;
    width: 6px;
    height: 6px;
    border-radius: 50%;
    background: #a6e3a1;
    box-shadow: 0 0 6px rgba(166, 227, 161, 0.6);
  }
  .header .meta.fresh      .dot { background: #a6e3a1; box-shadow: 0 0 6px rgba(166, 227, 161, 0.6); }
  .header .meta.stale      .dot { background: #f9e2af; box-shadow: 0 0 6px rgba(249, 226, 175, 0.6); }
  .header .meta.very-stale .dot { background: #f38ba8; box-shadow: 0 0 6px rgba(243, 139, 168, 0.6); }
  .header .meta.fresh      { color: #a6e3a1; }
  .header .meta.stale      { color: #f9e2af; }
  .header .meta.very-stale { color: #f38ba8; }

  .section {
    margin-top: 10px;
  }
  .section:first-of-type {
    margin-top: 4px;
  }
  .section-title {
    color: #cba6f7;
    font-size: 10px; /* label */
    letter-spacing: 3px;
    text-transform: uppercase;
    font-weight: 700;
    margin-bottom: 5px;
    opacity: 0.9;
    overflow: hidden;
    text-overflow: ellipsis;
    white-space: nowrap;
  }

  .line {
    color: #cdd6f4;
    font-size: 11px; /* support */
    margin: 2px 0 2px 20px;
    opacity: 0.88;
    overflow: hidden;
    text-overflow: ellipsis;
    white-space: nowrap;
  }
  .line .tag-critical {
    color: #f38ba8;
    font-weight: 700;
    margin-right: 4px;
  }
  .line .tag-warn {
    color: #f9e2af;
    font-weight: 700;
    margin-right: 4px;
  }
  .more {
    color: #6c7086;
    font-size: 10px; /* label */
    margin: 2px 0 2px 20px;
    font-style: italic;
    letter-spacing: 0.5px;
  }

  .empty {
    color: #6c7086;
    font-style: italic;
    padding: 8px 0;
    font-size: 11px; /* support */
  }

  .footer {
    margin-top: 14px;
    font-size: 9px; /* micro */
    color: #6c7086;
    display: flex;
    justify-content: space-between;
    letter-spacing: 1px;
    text-transform: uppercase;
  }
  .footer .brand {
    color: #89b4fa;
    opacity: 0.7;
    font-weight: 600;
  }

  .error {
    color: #f38ba8;
    font-size: 11px; /* support */
    padding: 4px 0;
  }
`

// ── Render helpers ──────────────────────────────────────────────────────────

// Module-scoped flag — survives re-renders triggered by widget refresh.
// Tracks "user clicked Run" so the spinner stays for ~60s while the agent runs.
let __briefRunningUntil = 0

const fireBrief = () => {
  // POST /run/ with raw bash as body — Übersicht spawns bash and pipes the body to stdin.
  const cmd = "launchctl kickstart -k gui/$(id -u)/tech.durante.dos.daily-brief"
  fetch("/run/", { method: "POST", body: cmd }).catch(() => {})
  __briefRunningUntil = Date.now() + 60_000
}

const isBriefRunning = () => Date.now() < __briefRunningUntil

const Header = ({ metaClass, metaText, withDot }) => (
  <div className="header">
    <span className="title">
      <span className="glyph">✦</span>
      <span>Daily Brief</span>
    </span>
    <span className="right">
      <span
        className={`run-btn ${isBriefRunning() ? "running" : ""}`}
        title={isBriefRunning() ? "Brief running — refreshes when ready" : "Run brief now"}
        onClick={fireBrief}
      >
        ↻
      </span>
      {metaText && (
        <span className={`meta ${metaClass || ""}`}>
          {withDot && <span className="dot" />}
          <span>{metaText}</span>
        </span>
      )}
    </span>
  </div>
)

const Line = ({ text, idx }) => {
  const trimmed = wordTruncate(text, LINE_CHAR_BUDGET)
  const tagged = splitCritical(trimmed)
  if (tagged) {
    return (
      <div className="line" key={idx}>
        <span className={tagged.className}>{tagged.tag}</span>
        {tagged.rest}
      </div>
    )
  }
  return <div className="line" key={idx}>{trimmed}</div>
}

export const render = ({ output }) => {
  if (!output) {
    return (
      <div>
        <Header metaText="loading…" />
        <div className="empty">Fetching today's brief</div>
      </div>
    )
  }

  let data
  try {
    data = JSON.parse(output)
  } catch (e) {
    return (
      <div>
        <Header />
        <div className="error">parse: {String(e).slice(0, 80)}</div>
      </div>
    )
  }

  if (data.state === "no-brief") {
    return (
      <div>
        <Header metaClass="stale" withDot metaText={data.now || ""} />
        <div className="empty">No brief yet — fires daily 21:00 BRT</div>
        <div className="footer">
          <span className="brand">DailyBrief</span>
          <span>{data.now}</span>
        </div>
      </div>
    )
  }

  if (data.state === "read-error") {
    return (
      <div>
        <Header metaClass="very-stale" withDot metaText="read error" />
        <div className="error">{(data.error || "unknown").slice(0, 120)}</div>
      </div>
    )
  }

  // ── normal render ─────────────────────────────────────────────────────────
  const stateClass =
    data.state === "very-stale" ? "very-stale" :
    data.state === "stale"      ? "stale"      :
    "fresh"

  const ageLabel =
    data.delta_days < 0       ? "fresh"  :
    data.delta_days === 0     ? "today"  :
    data.delta_days === 1     ? "1d old" :
    `${data.delta_days}d old`

  const sections = (data.sections || [])
    .filter((s) => !isTodayFocusSection(s.heading))
    .slice(0, MAX_SECTIONS)

  return (
    <div>
      <Header
        metaClass={stateClass}
        withDot
        metaText={`${data.date || ""} · ${ageLabel}`}
      />

      {sections.length === 0 && (
        <div className="empty">Brief is empty — no sections parsed</div>
      )}

      {sections.map((s, i) => {
        const lines = s.lines || []
        const visible = lines.slice(0, MAX_LINES_PER_SECTION)
        const hidden = lines.length - visible.length
        return (
          <div className="section" key={i}>
            <div className="section-title">► {s.heading}</div>
            {visible.map((ln, j) => <Line text={ln} idx={j} key={j} />)}
            {hidden > 0 && <div className="more">+{hidden} more</div>}
          </div>
        )
      })}

      <div className="footer">
        <span className="brand">DailyBrief</span>
        <span>refreshed {data.now}</span>
      </div>
    </div>
  )
}
