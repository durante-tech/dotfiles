// mempalace.widget — desktop dashboard for active work
// Reads ~/.claude/MEMORY/STATE/work.json via data.sh helper. Catppuccin Mocha · middle-left.

export const command = `bash "$HOME/Library/Application Support/Übersicht/widgets/mempalace.widget/data.sh"`
export const refreshFrequency = 60 * 1000

export const className = `
  top: 70px;
  left: 60px;
  width: 540px;
  font-family: 'JetBrainsMono Nerd Font', 'JetBrains Mono', 'Hack Nerd Font', monospace;
  background: rgba(17, 17, 27, 0.6);
  backdrop-filter: blur(28px) saturate(140%);
  -webkit-backdrop-filter: blur(28px) saturate(140%);
  padding: 26px 30px;
  border-radius: 16px;
  border: 1px solid rgba(203, 166, 247, 0.2);
  border-left: 4px solid #cba6f7;
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
    color: #cba6f7;
    font-size: 15px;
    letter-spacing: 5px;
    text-transform: uppercase;
    font-weight: 700;
    margin-bottom: 20px;
  }
  .header .count {
    color: #a6adc8;
    font-size: 11px;
    letter-spacing: 1px;
    font-weight: 500;
  }

  .section {
    margin-top: 18px;
  }
  .section-title {
    color: #f9e2af;
    font-size: 11px;
    letter-spacing: 4px;
    text-transform: uppercase;
    font-weight: 700;
    margin-bottom: 10px;
    opacity: 0.9;
  }

  .row {
    display: flex;
    align-items: baseline;
    gap: 10px;
    padding: 4px 0;
    color: #cdd6f4;
  }
  .row .phase {
    flex-shrink: 0;
    color: #94e2d5;
    width: 84px;
    font-size: 11px;
    letter-spacing: 1.5px;
    text-transform: uppercase;
    font-weight: 600;
  }
  .row .progress {
    flex-shrink: 0;
    color: #a6adc8;
    width: 56px;
    font-size: 13px;
    text-align: right;
    font-variant-numeric: tabular-nums;
  }
  .row .task {
    flex: 1;
    color: #cdd6f4;
    font-size: 13px;
    overflow: hidden;
    text-overflow: ellipsis;
    white-space: nowrap;
  }
  .row .age {
    flex-shrink: 0;
    color: #6c7086;
    font-size: 11px;
    width: 44px;
    text-align: right;
  }

  .native {
    color: #cdd6f4;
    font-size: 14px;
  }
  .native .last {
    color: #a6adc8;
    font-size: 12px;
    margin-top: 6px;
    overflow: hidden;
    text-overflow: ellipsis;
    white-space: nowrap;
  }

  .phases-row {
    display: flex;
    flex-wrap: wrap;
    gap: 10px 18px;
    color: #a6adc8;
    font-size: 12px;
  }
  .phases-row .ph {
    display: inline-flex;
    gap: 5px;
    align-items: baseline;
  }
  .phases-row .ph .name { color: #6c7086; text-transform: uppercase; font-size: 10px; letter-spacing: 1.5px; }
  .phases-row .ph .n    { color: #cdd6f4; font-weight: 700; font-size: 13px; }

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
  let data = null
  try {
    data = JSON.parse((output || "").trim() || "{}")
  } catch (e) {
    return <div className="error">parse: {String(e)}</div>
  }

  if (data.error) {
    return (
      <div>
        <div className="header"><span>✦ DuranteOS</span></div>
        <div className="error">{data.error}</div>
      </div>
    )
  }

  return (
    <div>
      <div className="header">
        <span>✦ DuranteOS</span>
        <span className="count">{data.total} sessions</span>
      </div>

      <div className="section">
        <div className="section-title">► Strategic</div>
        {(data.strategic || []).length === 0 && (
          <div className="row"><span className="task" style={{color:'#6c7086'}}>no active strategic work</span></div>
        )}
        {(data.strategic || []).map((s, i) => (
          <div className="row" key={i}>
            <span className="phase">{s.phase}</span>
            <span className="progress">{s.progress}</span>
            <span className="task">{s.task}</span>
            <span className="age">{s.age}</span>
          </div>
        ))}
      </div>

      <div className="section">
        <div className="section-title">► Native today</div>
        <div className="native">
          {data.native_today} today · {data.native_total} total
          {data.native_last && <div className="last">last: {data.native_last}</div>}
        </div>
      </div>

      <div className="section">
        <div className="section-title">► Phases</div>
        <div className="phases-row">
          {Object.entries(data.phases || {}).map(([name, n]) => (
            <span className="ph" key={name}>
              <span className="name">{name}</span>
              <span className="n">{n}</span>
            </span>
          ))}
        </div>
      </div>

      <div className="footer">refreshed {data.now}</div>
    </div>
  )
}
