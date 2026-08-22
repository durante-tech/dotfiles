// clock.widget — large desktop time + uppercase date
// Catppuccin Mocha · JetBrainsMono Nerd Font

// No `command`: the clock renders from JS instead of shelling out. `date` was
// forked through bash once a second — 86,400 process spawns a day — to produce a
// string that only changes once a minute. worldclock.widget already computes its
// times in render with no command at all; same pattern here, and the 1s tick is
// kept so the minute still flips on time.
export const refreshFrequency = 1000

export const className = `
  top: 80px;
  left: 50%;
  transform: translateX(-50%);
  font-family: 'JetBrainsMono Nerd Font', 'JetBrains Mono', 'Hack Nerd Font', monospace;
  text-align: center;
  user-select: none;
  -webkit-font-smoothing: antialiased;

  .time {
    font-size: 96px;
    font-weight: 200;
    letter-spacing: -3px;
    line-height: 1;
    color: #cdd6f4;
    text-shadow: 0 2px 24px rgba(0, 0, 0, 0.6);
  }

  .date {
    font-size: 13px;
    margin-top: 12px;
    color: #cba6f7;
    letter-spacing: 6px;
    text-transform: uppercase;
    text-shadow: 0 1px 8px rgba(0, 0, 0, 0.6);
  }
`

export const render = () => {
  const now = new Date()
  const p = (n) => String(n).padStart(2, '0')
  const time = `${p(now.getHours())}:${p(now.getMinutes())}`
  // Byte-identical to the old `date '+%a · %b %-d'`, with the locale pinned to
  // en-US like worldclock.widget — Übersicht's env locale would otherwise decide.
  const date = `${now.toLocaleDateString('en-US', { weekday: 'short' })} · ${now.toLocaleDateString('en-US', { month: 'short', day: 'numeric' })}`
  return (
    <div>
      <div className="time">{time}</div>
      <div className="date">{date}</div>
    </div>
  )
}
