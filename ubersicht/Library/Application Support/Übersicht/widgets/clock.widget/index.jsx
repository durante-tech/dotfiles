// clock.widget — large desktop time + uppercase date
// Catppuccin Mocha · JetBrainsMono Nerd Font

export const command = "date '+%H:%M|%a · %b %-d'"
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

export const render = ({ output }) => {
  if (!output) return null
  const [time, date] = output.trim().split('|')
  return (
    <div>
      <div className="time">{time}</div>
      <div className="date">{date}</div>
    </div>
  )
}
