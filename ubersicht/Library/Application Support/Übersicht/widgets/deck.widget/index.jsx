// deck.widget — Operator Deck
// Surfaces hot files, active repos, inbox, last insight. Catppuccin Mocha · middle-right · yellow accent.

export const command = `bash "$HOME/Library/Application Support/Übersicht/widgets/deck.widget/data.sh"`
export const refreshFrequency = 60 * 1000

export const className = `
  top: 50%;
  right: 60px;
  transform: translateY(-50%);
  width: 540px;
  font-family: 'JetBrainsMono Nerd Font', 'JetBrains Mono', 'Hack Nerd Font', monospace;
  background: rgba(17, 17, 27, 0.6);
  backdrop-filter: blur(28px) saturate(140%);
  -webkit-backdrop-filter: blur(28px) saturate(140%);
  padding: 26px 30px;
  border-radius: 16px;
  border: 1px solid rgba(249, 226, 175, 0.18);
  border-right: 4px solid #f9e2af;
  color: #cdd6f4;
  user-select: none;
  -webkit-font-smoothing: antialiased;
  box-shadow: 0 16px 48px rgba(0, 0, 0, 0.4);
  font-size: 14px;
  line-height: 1.55;

  .header {
    display: flex;
    justify-content: space-between;
    align-items: baseline;
    color: #f9e2af;
    font-size: 15px;
    letter-spacing: 5px;
    text-transform: uppercase;
    font-weight: 700;
    margin-bottom: 20px;
  }
  .header .clock {
    color: #a6adc8;
    font-size: 11px;
    letter-spacing: 1px;
    font-weight: 500;
  }

  .section {
    margin-top: 18px;
  }
  .section-title {
    color: #cba6f7;
    font-size: 11px;
    letter-spacing: 4px;
    text-transform: uppercase;
    font-weight: 700;
    margin-bottom: 10px;
    opacity: 0.9;
  }

  .file-row {
    display: flex;
    align-items: baseline;
    gap: 10px;
    padding: 3px 0;
    font-size: 13px;
  }
  .file-row .name { color: #cdd6f4; flex: 1; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
  .file-row .dir  { color: #6c7086; font-size: 11px; }
  .file-row .age  { color: #6c7086; font-size: 11px; width: 44px; text-align: right; flex-shrink: 0; }

  .repo-row {
    display: flex;
    align-items: baseline;
    gap: 10px;
    padding: 3px 0;
    font-size: 13px;
  }
  .repo-row .name   { color: #cdd6f4; width: 168px; flex-shrink: 0; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
  .repo-row .branch { color: #94e2d5; flex: 1; font-size: 11px; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
  .repo-row .dirty.clean { color: #45475a; }
  .repo-row .dirty.dirty { color: #f38ba8; font-weight: 600; }
  .repo-row .age    { color: #6c7086; font-size: 11px; width: 44px; text-align: right; flex-shrink: 0; }

  .inbox {
    display: flex;
    gap: 22px;
    align-items: baseline;
  }
  .inbox .pill {
    display: inline-flex;
    align-items: baseline;
    gap: 6px;
    font-size: 13px;
  }
  .inbox .pill .label { color: #6c7086; text-transform: uppercase; font-size: 10px; letter-spacing: 1.5px; }
  .inbox .pill .n     { color: #cdd6f4; font-weight: 700; }
  .inbox .pill.warn .n { color: #fab387; }
  .inbox .pill.alarm .n { color: #f38ba8; }
  .inbox .empty { color: #45475a; font-size: 11px; font-style: italic; }

  .insight {
    color: #a6adc8;
    font-size: 12px;
    line-height: 1.55;
    font-style: italic;
  }
  .insight .task {
    display: block;
    color: #6c7086;
    font-size: 10px;
    letter-spacing: 1px;
    text-transform: uppercase;
    margin-bottom: 4px;
    font-style: normal;
  }

  .footer {
    margin-top: 18px;
    color: #45475a;
    font-size: 10px;
    text-align: right;
    letter-spacing: 1px;
  }

  .error {
    color: #f38ba8;
    font-size: 13px;
  }
`

export const render = ({ output }) => {
  let d = null
  try { d = JSON.parse((output || '').trim() || '{}') }
  catch (e) { return <div className="error">parse: {String(e)}</div> }

  if (d.error) return <div className="error">{d.error}</div>

  const inbox = d.inbox || { corrections: 0, failures_today: 0 }
  const insight = d.last_insight || {}
  const corrPill = inbox.corrections >= 5 ? 'pill alarm' : inbox.corrections > 0 ? 'pill warn' : 'pill'
  const failPill = inbox.failures_today >= 3 ? 'pill alarm' : inbox.failures_today > 0 ? 'pill warn' : 'pill'
  const inboxEmpty = !inbox.corrections && !inbox.failures_today

  return (
    <div>
      <div className="header">
        <span>✦ Operator Deck</span>
        <span className="clock">{d.now || ''}</span>
      </div>

      <div className="section">
        <div className="section-title">► Hot Files</div>
        {(d.hot_files || []).length === 0 && <div className="insight">no recent edits in last 24h</div>}
        {(d.hot_files || []).map((f, i) => {
          const slash = f.path.lastIndexOf('/')
          const dir = slash > 0 ? f.path.slice(0, slash + 1) : ''
          const name = slash > 0 ? f.path.slice(slash + 1) : f.path
          return (
            <div className="file-row" key={i}>
              <span className="name"><span className="dir">{dir}</span>{name}</span>
              <span className="age">{f.age}</span>
            </div>
          )
        })}
      </div>

      <div className="section">
        <div className="section-title">► Repos</div>
        {(d.repos || []).map((r, i) => (
          <div className="repo-row" key={i}>
            <span className="name">{r.name}</span>
            <span className="branch">{r.branch}</span>
            <span className={r.dirty > 0 ? 'dirty dirty' : 'dirty clean'}>
              {r.dirty > 0 ? `●${r.dirty}` : '○'}
            </span>
            <span className="age">{r.age}</span>
          </div>
        ))}
      </div>

      <div className="section">
        <div className="section-title">► Inbox</div>
        <div className="inbox">
          {inboxEmpty && <span className="empty">all clear</span>}
          {!inboxEmpty && (
            <span className={corrPill}>
              <span className="label">Corrections</span>
              <span className="n">{inbox.corrections}</span>
            </span>
          )}
          {!inboxEmpty && (
            <span className={failPill}>
              <span className="label">Failures</span>
              <span className="n">{inbox.failures_today}</span>
            </span>
          )}
        </div>
      </div>

      {insight.q1 && (
        <div className="section">
          <div className="section-title">► Last Insight</div>
          <div className="insight">
            {insight.task && <span className="task">{insight.task}</span>}
            {insight.q1}
          </div>
        </div>
      )}

      <div className="footer">refreshed {d.now}</div>
    </div>
  )
}
