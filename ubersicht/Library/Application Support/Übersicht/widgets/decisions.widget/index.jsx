// decisions.widget — surfaces recent strategic decisions captured to MemPalace
// in the last 7 days, scanned from PRD ## Decisions sections.
// Catppuccin Mocha · left side · mauve accent (semantic = decided / intelligence).
// CSS uses standard CSS (semicolons + braces) — Übersicht parser requires it.

export const command = `bash "$HOME/Library/Application Support/Übersicht/widgets/decisions.widget/data.sh"`

export const refreshFrequency = 600 * 1000 // 10 min — decisions accrue slowly

// ── DOS Widget Type Scale ────────────────────────────────────────────────────
// display 26px · lead 16px · body 13px · support 11px · label 10px · micro 9px

export const className = `
  box-sizing: border-box;
  bottom: 60px;
  left: 560px;
  width: 540px;
  font-family: 'JetBrainsMono Nerd Font', 'JetBrains Mono', 'Hack Nerd Font', monospace;
  background: rgba(17, 17, 27, 0.6);
  backdrop-filter: blur(28px) saturate(140%);
  -webkit-backdrop-filter: blur(28px) saturate(140%);
  padding: 16px 22px;
  border-radius: 16px;
  border: 1px solid rgba(203, 166, 247, 0.18);
  border-right: 4px solid #cba6f7;
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
    color: #cba6f7;
    font-size: 13px; /* body — panel identity */
    letter-spacing: 5px;
    text-transform: uppercase;
    font-weight: 700;
    margin-bottom: 8px;
  }
  .header .count {
    color: #cba6f7;
    font-size: 10px; /* label */
    letter-spacing: 1px;
    font-weight: 600;
    opacity: 0.75;
  }

  .row {
    display: flex;
    flex-direction: column;
    gap: 4px;
    padding: 10px 0;
    border-bottom: 1px solid rgba(205, 214, 244, 0.05);
  }
  .row:last-child {
    border-bottom: none;
  }
  .row .head {
    display: flex;
    align-items: baseline;
    gap: 10px;
  }
  .row .title {
    flex: 1;
    color: #cdd6f4;
    font-size: 13px; /* body — primary content */
    font-weight: 600;
    overflow: hidden;
    text-overflow: ellipsis;
    white-space: nowrap;
  }
  .row .source {
    flex-shrink: 0;
    color: #cba6f7;
    font-size: 9px; /* micro — badge chrome */
    letter-spacing: 1px;
    text-transform: uppercase;
    font-weight: 600;
    opacity: 0.85;
    background: rgba(203, 166, 247, 0.1);
    padding: 2px 8px;
    border-radius: 4px;
  }
  .row .why {
    color: #a6adc8;
    font-size: 11px; /* support */
    overflow: hidden;
    text-overflow: ellipsis;
    white-space: nowrap;
    opacity: 0.9;
  }

  .empty {
    color: #6c7086;
    font-style: italic;
    padding: 8px 0;
    font-size: 11px; /* support */
  }

  .footer {
    margin-top: 6px;
    font-size: 9px; /* micro */
    color: #6c7086;
    display: flex;
    justify-content: space-between;
    letter-spacing: 1px;
    text-transform: uppercase;
  }
  .footer .brand {
    color: #cba6f7;
    opacity: 0.7;
    font-weight: 600;
  }
`

export const render = ({ output }) => {
  if (!output) {
    return (
      <div>
        <div className="header"><span>► Decisions</span></div>
        <div className="empty">Loading…</div>
      </div>
    )
  }

  let data
  try {
    data = JSON.parse(output)
  } catch {
    return (
      <div>
        <div className="header"><span>► Decisions</span></div>
        <div className="empty">Parse error</div>
      </div>
    )
  }

  if (data.state === "empty" || !data.decisions || data.decisions.length === 0) {
    return (
      <div>
        <div className="header">
          <span>► Decisions</span>
          <span className="count">{data.lookback}d window</span>
        </div>
        <div className="empty">No recent decisions captured</div>
        <div className="footer">
          <span className="brand">Decisions</span>
          <span>{data.now}</span>
        </div>
      </div>
    )
  }

  return (
    <div>
      <div className="header">
        <span>► Decisions</span>
        <span className="count">{data.count} · last {data.lookback}d</span>
      </div>

      {data.decisions.slice(0, 1).map((d, i) => (
        <div className="row" key={i}>
          <div className="head">
            <span className="title">{d.title}</span>
            <span className="source">{d.source}</span>
          </div>
          {d.why ? <div className="why">{d.why}</div> : null}
        </div>
      ))}

      <div className="footer">
        <span className="brand">Decisions</span>
        <span>{data.now}</span>
      </div>
    </div>
  )
}
