// today-focus.widget — surfaces today's 1-3 prioritized actions, large type
// designed to be readable from across the room. Catppuccin Mocha · left side ·
// green accent (semantic = forward / commit / next).
// CSS uses standard CSS (semicolons + braces) — Übersicht parser requires it.

export const command = `bash "$HOME/Library/Application Support/Übersicht/widgets/today-focus.widget/data.sh"`

export const refreshFrequency = 300 * 1000 // 5 min — brief updates daily

// ── DOS Widget Type Scale ────────────────────────────────────────────────────
// display 26px · lead 16px · body 13px · support 11px · label 10px · micro 9px
// today-focus is the north-star panel — rank uses display, title uses lead.

export const className = `
  box-sizing: border-box;
  /* Bottom-anchored north-star slot: grows upward from the corner, so a
     1-action day and a 3-action day both hug bottom-left without ever
     chasing attention.widget's variable height (was top:1075 → collisions). */
  bottom: 60px;
  left: 60px;
  width: 540px;
  font-family: 'JetBrainsMono Nerd Font', 'JetBrains Mono', 'Hack Nerd Font', monospace;
  background: rgba(17, 17, 27, 0.6);
  backdrop-filter: blur(28px) saturate(140%);
  -webkit-backdrop-filter: blur(28px) saturate(140%);
  padding: 22px 26px;
  border-radius: 16px;
  border: 1px solid rgba(166, 227, 161, 0.18);
  border-left: 4px solid #a6e3a1;
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
    color: #a6e3a1;
    font-size: 13px; /* body — panel identity */
    letter-spacing: 5px;
    text-transform: uppercase;
    font-weight: 700;
    margin-bottom: 16px;
  }
  .header .title {
    display: inline-flex;
    align-items: baseline;
    gap: 8px;
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

  .card {
    display: flex;
    align-items: flex-start;
    gap: 14px;
    margin-bottom: 14px;
  }
  .card:last-of-type { margin-bottom: 0; }
  .card .rank {
    color: rgba(166, 227, 161, 0.6);
    font-size: 26px; /* display — hero numeral */
    font-weight: 700;
    line-height: 1.05;
    width: 24px;
    flex-shrink: 0;
    font-family: 'JetBrainsMono Nerd Font', 'JetBrains Mono', monospace;
  }
  .card .body {
    flex: 1;
    min-width: 0;
  }
  .card .title {
    color: #cdd6f4;
    font-size: 16px; /* lead — primary readable content */
    font-weight: 600;
    line-height: 1.3;
    margin-bottom: 4px;
    overflow: hidden;
    text-overflow: ellipsis;
    display: -webkit-box;
    -webkit-line-clamp: 2;
    -webkit-box-orient: vertical;
  }
  .card .why {
    color: #a6adc8;
    font-size: 13px; /* body — readable subtitle */
    line-height: 1.45;
    overflow: hidden;
    text-overflow: ellipsis;
    display: -webkit-box;
    -webkit-line-clamp: 1;
    -webkit-box-orient: vertical;
    margin-bottom: 4px;
  }
  .card .tag {
    display: inline-block;
    color: #a6e3a1;
    background: rgba(166, 227, 161, 0.1);
    font-size: 10px; /* label */
    letter-spacing: 1.5px;
    text-transform: uppercase;
    font-weight: 700;
    padding: 2px 8px;
    border-radius: 4px;
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
    color: #a6e3a1;
    opacity: 0.6;
    font-weight: 600;
  }

  .error {
    color: #f38ba8;
    font-size: 11px; /* support */
    padding: 4px 0;
  }
`

const Header = ({ metaClass, metaText, withDot }) => (
  <div className="header">
    <span className="title">► Today's Focus</span>
    {metaText && (
      <span className={`meta ${metaClass || ""}`}>
        {withDot && <span className="dot" />}
        <span>{metaText}</span>
      </span>
    )}
  </div>
)

export const render = ({ output }) => {
  if (!output) {
    return (
      <div>
        <Header metaText="loading…" />
        <div className="empty">Fetching today's actions</div>
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
        <Header metaClass="very-stale" withDot metaText="read error" />
        <div className="error">{(data.error || "unknown").slice(0, 120)}</div>
      </div>
    )
  }

  if (data.state === "no-actions") {
    return (
      <div>
        <Header metaClass="stale" withDot metaText={data.date || data.now || ""} />
        <div className="empty">No focus section in today's brief</div>
        <div className="footer">
          <span className="brand">Today-Focus</span>
          <span>{data.now}</span>
        </div>
      </div>
    )
  }

  const stateClass =
    data.state === "very-stale" ? "very-stale" :
    data.state === "stale"      ? "stale"      :
    "fresh"

  const ageLabel =
    data.delta_days < 0       ? "fresh"  :
    data.delta_days === 0     ? "today"  :
    data.delta_days === 1     ? "1d old" :
    `${data.delta_days}d old`

  const actions = (data.actions || []).slice(0, 3)

  return (
    <div>
      <Header
        metaClass={stateClass}
        withDot
        metaText={`${data.date || ""} · ${ageLabel}`}
      />

      {actions.length === 0 && (
        <div className="empty">No actions parsed</div>
      )}

      {actions.map((a, i) => (
        <div className="card" key={i}>
          <span className="rank">{a.rank}</span>
          <span className="body">
            <div className="title">{a.title}</div>
            {a.why && <div className="why">{a.why}</div>}
            {a.tag && <span className="tag">{a.tag}</span>}
          </span>
        </div>
      ))}

      <div className="footer">
        <span className="brand">Today-Focus</span>
        <span>refreshed {data.now}</span>
      </div>
    </div>
  )
}
