// q3-thread.widget — replaces aphorism with Lucas's own Q3 reflections.
// Designer spec: bottom-center, mauve border-left (sister to aphorism), peach border on low-sentiment.

export const command = `bash "$HOME/Library/Application Support/Übersicht/widgets/q3-thread.widget/data.sh"`
export const refreshFrequency = 30 * 60 * 1000

export const className = `
  bottom: 60px;
  left: 1760px;
  width: 540px;
  font-family: 'JetBrainsMono Nerd Font', 'JetBrains Mono', 'Hack Nerd Font', monospace;
  background: rgba(17, 17, 27, 0.55);
  backdrop-filter: blur(28px) saturate(140%);
  -webkit-backdrop-filter: blur(28px) saturate(140%);
  padding: 18px 22px;
  border-radius: 14px;
  border: 1px solid rgba(203, 166, 247, 0.18);
  border-left: 3px solid #cba6f7;
  color: #cdd6f4;
  user-select: none;
  -webkit-font-smoothing: antialiased;
  box-shadow: 0 12px 36px rgba(0, 0, 0, 0.35);
  animation: q3-fadein 600ms ease-out;

  @keyframes q3-fadein {
    from { opacity: 0; }
    to   { opacity: 1; }
  }

  &.low-sentiment {
    border-left: 3px solid rgba(250, 179, 135, 0.6);
  }

  .header {
    color: #a6adc8;
    font-size: 9px;
    letter-spacing: 4px;
    text-transform: uppercase;
    margin-bottom: 10px;
    font-weight: 600;
  }

  .q3 {
    font-size: 13.5px;
    line-height: 1.55;
    color: #cdd6f4;
    font-weight: 400;
  }

  .task {
    margin-top: 10px;
    font-size: 10px;
    color: #6c7086;
    text-transform: uppercase;
    letter-spacing: 1.5px;
  }

  .error {
    color: #f38ba8;
    font-size: 12px;
  }
`

const formatDate = (iso) => {
  if (!iso || iso.length < 10) return ""
  const d = new Date(iso)
  if (isNaN(d.getTime())) return iso
  return d.toLocaleDateString("en-US", { day: "2-digit", month: "short" }).toUpperCase()
}

export const render = ({ output }) => {
  let d = null
  try { d = JSON.parse((output || "").trim() || "{}") }
  catch (e) { return <div className="error">parse: {String(e)}</div> }

  if (d.error) {
    return (
      <div>
        <div className="header">✦ Mirror</div>
        <div className="error">{d.error}</div>
      </div>
    )
  }

  const isLow = (d.sentiment || 7) <= 4
  const taskLine = d.task && d.task_date
    ? `${d.task.replace(/[—–]/g, "-")} · ${formatDate(d.task_date)}`
    : (d.task || formatDate(d.task_date) || "")

  return (
    <div className={isLow ? "low-sentiment" : ""}>
      <div className="header">✦ Mirror</div>
      <div className="q3">{d.q3}</div>
      {taskLine && <div className="task">{taskLine}</div>}
    </div>
  )
}
