// aging-watch.widget — surfaces stuck work from the PRDSync registry.
// Catppuccin Mocha · right side · peach accent (semantic = warning / aging /
// stuck). Right-border mirrors deck.widget's right-yellow accent for symmetric
// portfolio. CSS uses standard CSS (semicolons + braces).

export const command = `bash "$HOME/Library/Application Support/Übersicht/widgets/aging-watch.widget/data.sh"`

export const refreshFrequency = 120 * 1000 // 2 min — work.json updates frequently

// ── DOS Widget Type Scale ────────────────────────────────────────────────────
// display 26px · lead 16px · body 13px · support 11px · label 10px · micro 9px

export const className = `
  box-sizing: border-box;
  top: 800px;
  left: 60px;
  width: 400px;
  font-family: 'JetBrainsMono Nerd Font', 'JetBrains Mono', 'Hack Nerd Font', monospace;
  background: rgba(17, 17, 27, 0.6);
  backdrop-filter: blur(28px) saturate(140%);
  -webkit-backdrop-filter: blur(28px) saturate(140%);
  padding: 22px 26px;
  border-radius: 16px;
  border: 1px solid rgba(250, 179, 135, 0.18);
  border-right: 4px solid #fab387;
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
    color: #fab387;
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
    letter-spacing: 0;
  }
  .header .count {
    color: #fab387;
    font-size: 10px; /* label */
    letter-spacing: 1px;
    font-weight: 600;
    opacity: 0.75;
  }

  .row {
    display: flex;
    align-items: center;
    gap: 8px;
    padding: 5px 0;
    font-size: 13px; /* body */
  }
  .row .pill {
    font-size: 9px; /* micro — pill chrome */
    letter-spacing: 1px;
    text-transform: uppercase;
    font-weight: 700;
    padding: 2px 6px;
    border-radius: 3px;
    flex-shrink: 0;
    min-width: 56px;
    text-align: center;
  }
  .row .pill.verify      { color: #1e1e2e; background: #fab387; }
  .row .pill.build-stuck { color: #1e1e2e; background: #f38ba8; }
  .row .pill.stale       { color: #cdd6f4; background: #45475a; }

  .row .name {
    color: #cdd6f4;
    font-size: 13px; /* body — primary content */
    flex: 1;
    overflow: hidden;
    text-overflow: ellipsis;
    white-space: nowrap;
  }
  .row .age {
    color: #a6adc8;
    font-size: 10px; /* label */
    flex-shrink: 0;
    text-align: right;
    width: 36px;
    font-weight: 500;
  }

  .empty {
    color: #6c7086;
    font-style: italic;
    padding: 12px 0;
    font-size: 13px; /* body */
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
    color: #fab387;
    opacity: 0.6;
    font-weight: 600;
  }

  .error {
    color: #f38ba8;
    font-size: 11px; /* support */
    padding: 4px 0;
  }
`

const Header = ({ count }) => (
  <div className="header">
    <span className="title">
      <span className="glyph">⏳</span>
      <span>Aging</span>
    </span>
    {typeof count === "number" && <span className="count">({count})</span>}
  </div>
)

const pillClass = (label) => {
  const l = (label || "").toLowerCase()
  if (l === "verify")      return "pill verify"
  if (l === "build-stuck") return "pill build-stuck"
  return "pill stale"
}

export const render = ({ output }) => {
  if (!output) {
    return (
      <div>
        <Header />
        <div className="empty">Loading…</div>
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

  if (data.state === "read-error") {
    return (
      <div>
        <Header />
        <div className="error">{(data.error || "unknown").slice(0, 120)}</div>
      </div>
    )
  }

  const items = data.items || []
  const total = data.total_count || 0

  if (data.state === "clean" || items.length === 0) {
    return (
      <div>
        <Header count={0} />
        <div className="empty">Nothing aging</div>
        <div className="footer">
          <span className="brand">Aging-Watch</span>
          <span>{data.now}</span>
        </div>
      </div>
    )
  }

  return (
    <div>
      <Header count={total} />

      {items.map((it, i) => (
        <div className="row" key={i}>
          <span className={pillClass(it.label)}>{it.label}</span>
          <span className="name">{it.title}</span>
          <span className="age">{it.age_human}</span>
        </div>
      ))}

      <div className="footer">
        <span className="brand">Aging-Watch</span>
        <span>refreshed {data.now}</span>
      </div>
    </div>
  )
}
