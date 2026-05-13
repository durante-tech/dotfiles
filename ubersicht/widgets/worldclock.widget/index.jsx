// worldclock.widget — 4-city world clock (SP primary in mauve)
// Catppuccin Mocha · bottom-right. 30s refresh.

export const refreshFrequency = 30 * 1000

const CITIES = [
  { name: 'SP', tz: 'America/Sao_Paulo',    primary: true  },
  { name: 'NY', tz: 'America/New_York',     primary: false },
  { name: 'SF', tz: 'America/Los_Angeles',  primary: false },
  { name: 'FR', tz: 'Europe/Paris',         primary: false },
]

export const className = `
  bottom: 60px;
  right: 60px;
  font-family: 'JetBrainsMono Nerd Font', 'JetBrains Mono', 'Hack Nerd Font', monospace;
  background: rgba(17, 17, 27, 0.55);
  backdrop-filter: blur(24px) saturate(140%);
  -webkit-backdrop-filter: blur(24px) saturate(140%);
  padding: 14px 20px;
  border-radius: 12px;
  border: 1px solid rgba(203, 166, 247, 0.15);
  color: #cdd6f4;
  user-select: none;
  -webkit-font-smoothing: antialiased;
  box-shadow: 0 12px 36px rgba(0, 0, 0, 0.35);

  .row {
    display: flex;
    justify-content: space-between;
    align-items: baseline;
    gap: 22px;
    padding: 4px 0;
    font-size: 13px;
  }

  .city {
    color: #6c7086;
    letter-spacing: 2px;
    text-transform: uppercase;
    font-size: 10px;
    font-weight: 700;
    min-width: 32px;
  }

  .city.primary { color: #cba6f7; }

  .time { color: #cdd6f4; font-variant-numeric: tabular-nums; }

  .time.primary { color: #cdd6f4; font-weight: 600; }
`

export const render = () => {
  const now = new Date()
  const fmt = (tz) =>
    now.toLocaleTimeString('en-US', {
      timeZone: tz,
      hour: '2-digit',
      minute: '2-digit',
      hour12: false,
    })
  return (
    <div>
      {CITIES.map((c) => (
        <div className="row" key={c.name}>
          <span className={c.primary ? 'city primary' : 'city'}>{c.name}</span>
          <span className={c.primary ? 'time primary' : 'time'}>{fmt(c.tz)}</span>
        </div>
      ))}
    </div>
  )
}
