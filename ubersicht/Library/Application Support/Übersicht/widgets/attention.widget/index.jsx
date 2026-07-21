// attention.widget — DuranteOS operator action queue ("what needs me now").
// Data source: data.sh emits JSON (state, rows[], total_count, hidden, gh_state, gh_age, now).
// Visual language: matches dailybrief.widget. Catppuccin Mocha · red accent (attention).
// CSS in className uses standard CSS (semicolons + braces) — Übersicht parser
// requires this, NOT Stylus indented syntax.

export const command = `bash "$HOME/Library/Application Support/Übersicht/widgets/attention.widget/data.sh"`

export const refreshFrequency = 300 * 1000 // 5 min

// ── Severity tokens ─────────────────────────────────────────────────────────
const SEV_COLOR = {
  crit: "#f38ba8",
  warn: "#f9e2af",
  info: "#89b4fa",
}

// ── DOS Widget Type Scale ────────────────────────────────────────────────────
// display 26px · lead 16px · body 13px · support 11px · label 10px · micro 9px

export const className = `
  box-sizing: border-box;
  /* Left-column lane 3: pipeline (70) → memory-tide (560) → attention (720)
     → today-focus (bottom:60). At top:800 with 7 rows this panel ran into
     today-focus; 720 + a 6-row cap keeps it clear. */
  top: 720px;
  left: 60px;
  width: 540px;
  font-family: 'JetBrainsMono Nerd Font', 'JetBrains Mono', 'Hack Nerd Font', monospace;
  background: rgba(17, 17, 27, 0.6);
  backdrop-filter: blur(28px) saturate(140%);
  -webkit-backdrop-filter: blur(28px) saturate(140%);
  padding: 22px 26px;
  border-radius: 16px;
  border: 1px solid rgba(243, 139, 168, 0.18);
  border-left: 4px solid #f38ba8;
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
    color: #f38ba8;
    font-size: 13px; /* body — panel identity */
    letter-spacing: 5px;
    text-transform: uppercase;
    font-weight: 700;
    margin-bottom: 12px;
  }
  .header .title {
    display: inline-flex;
    align-items: baseline;
    gap: 8px;
  }
  .header .title .glyph {
    font-size: 13px; /* body — match header */
    color: #f38ba8;
    opacity: 0.95;
    letter-spacing: 0;
  }
  .header .right {
    display: inline-flex;
    align-items: center;
    gap: 10px;
  }
  .header .badge {
    display: inline-flex;
    align-items: center;
    justify-content: center;
    min-width: 22px;
    height: 20px;
    padding: 0 7px;
    border-radius: 10px;
    font-size: 11px; /* support */
    font-weight: 700;
    letter-spacing: 0;
  }
  .header .badge.crit {
    color: #f38ba8;
    background: rgba(243, 139, 168, 0.14);
    border: 1px solid rgba(243, 139, 168, 0.4);
  }
  .header .badge.warn {
    color: #f9e2af;
    background: rgba(249, 226, 175, 0.12);
    border: 1px solid rgba(249, 226, 175, 0.4);
  }
  .header .badge.clear {
    color: #a6e3a1;
    background: rgba(166, 227, 161, 0.12);
    border: 1px solid rgba(166, 227, 161, 0.4);
  }
  .header .gh-note {
    color: #6c7086;
    font-size: 9px; /* micro */
    letter-spacing: 1px;
    text-transform: none;
    font-weight: 500;
  }

  .row {
    display: flex;
    align-items: baseline;
    gap: 9px;
    margin-top: 7px;
  }
  .row:first-of-type {
    margin-top: 2px;
  }
  .row .dot {
    flex: 0 0 auto;
    display: inline-block;
    width: 7px;
    height: 7px;
    border-radius: 50%;
    position: relative;
    top: -1px;
  }
  .row .row-title {
    flex: 1 1 auto;
    color: #cdd6f4;
    font-size: 11px; /* support */
    overflow: hidden;
    text-overflow: ellipsis;
    white-space: nowrap;
  }
  .row .age {
    flex: 0 0 auto;
    color: #a6adc8;
    font-size: 10px; /* label */
    letter-spacing: 1px;
    text-align: right;
  }
  .detail {
    color: #6c7086;
    font-size: 11px; /* support */
    margin: 1px 0 0 16px;
    overflow: hidden;
    text-overflow: ellipsis;
    white-space: nowrap;
  }

  .clear-line {
    color: #a6e3a1;
    font-size: 11px; /* support */
    letter-spacing: 2px;
    padding: 8px 0;
  }

  .error {
    color: #f38ba8;
    font-size: 11px; /* support */
    padding: 4px 0;
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
    color: #f38ba8;
    opacity: 0.7;
    font-weight: 600;
  }
`

// ── Render helpers ──────────────────────────────────────────────────────────

const ghNoteText = (data) => {
  if (!data || data.gh_state === "ok") return null
  if (data.gh_state === "offline-cached")
    return data.gh_age ? `gh: cached ${data.gh_age}` : "gh: cached"
  if (data.gh_state === "gh-unauth") return "gh: unauth"
  if (data.gh_state === "gh-missing") return "gh: missing"
  return null
}

const Header = ({ data, badgeClass, badgeText }) => (
  <div className="header">
    <span className="title">
      <span className="glyph">◆</span>
      <span>Attention</span>
    </span>
    <span className="right">
      {ghNoteText(data) && <span className="gh-note">{ghNoteText(data)}</span>}
      {badgeText != null && (
        <span className={`badge ${badgeClass}`}>{badgeText}</span>
      )}
    </span>
  </div>
)

// withDetail: only the top of the queue earns a context line — rows 3-4 are
// title-only. Keeps the panel inside its lane (attention must end above
// today-focus's tallest reach) while the top items keep their "why".
const Row = ({ row, withDetail }) => (
  <div>
    <div className="row">
      <span
        className="dot"
        style={{
          background: SEV_COLOR[row.severity] || "#6c7086",
          boxShadow: `0 0 6px ${SEV_COLOR[row.severity] || "#6c7086"}66`,
        }}
      />
      <span className="row-title">{row.title}</span>
      {row.age ? <span className="age">{row.age}</span> : null}
    </div>
    {withDetail && row.detail ? <div className="detail">{row.detail}</div> : null}
  </div>
)

export const render = ({ output }) => {
  if (!output) {
    return (
      <div>
        <Header badgeClass="clear" badgeText="…" />
        <div className="clear-line">loading…</div>
      </div>
    )
  }

  let data
  try {
    data = JSON.parse(output)
  } catch (e) {
    return (
      <div>
        <Header badgeClass="crit" badgeText="!" />
        <div className="error">parse: {String(e).slice(0, 80)}</div>
      </div>
    )
  }

  const rows = data.rows || []
  const critCount = rows.filter((r) => r.severity === "crit").length
  const warnCount = rows.filter((r) => r.severity === "warn").length

  const badgeClass = critCount > 0 ? "crit" : warnCount > 0 ? "warn" : "clear"
  const badgeText = data.total_count || 0

  if (data.state === "clear" || rows.length === 0) {
    return (
      <div>
        <Header data={data} badgeClass="clear" badgeText={0} />
        <div className="clear-line">— CLEAR — nothing needs you</div>
        <div className="footer">
          <span className="brand">DOS · ATTENTION</span>
          <span>refreshed {data.now}</span>
        </div>
      </div>
    )
  }

  return (
    <div>
      <Header data={data} badgeClass={badgeClass} badgeText={badgeText} />

      {rows.map((row, i) => (
        <Row row={row} withDetail={i < 2} key={i} />
      ))}

      {/* No "+N more" line — the header badge already carries total queue
          depth, and the extra line pushed the panel into today-focus. */}

      <div className="footer">
        <span className="brand">DOS · ATTENTION</span>
        <span>refreshed {data.now}</span>
      </div>
    </div>
  )
}
