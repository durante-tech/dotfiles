// calendar.widget — month grid with today highlighted
// Catppuccin Mocha · JetBrainsMono Nerd Font

export const refreshFrequency = 60 * 1000

export const className = `
  top: 80px;
  right: 60px;
  font-family: 'JetBrainsMono Nerd Font', 'JetBrains Mono', 'Hack Nerd Font', monospace;
  background: rgba(17, 17, 27, 0.55);
  backdrop-filter: blur(24px) saturate(140%);
  -webkit-backdrop-filter: blur(24px) saturate(140%);
  padding: 18px 22px;
  border-radius: 14px;
  border: 1px solid rgba(203, 166, 247, 0.18);
  color: #cdd6f4;
  user-select: none;
  -webkit-font-smoothing: antialiased;
  box-shadow: 0 12px 36px rgba(0, 0, 0, 0.35);

  .header {
    color: #cba6f7;
    font-size: 12px;
    text-align: center;
    margin-bottom: 14px;
    letter-spacing: 3px;
    text-transform: uppercase;
    font-weight: 600;
  }

  table {
    border-collapse: separate;
    border-spacing: 2px;
    font-size: 12px;
  }

  th {
    color: #6c7086;
    font-weight: 500;
    padding: 4px 7px;
    text-transform: uppercase;
    font-size: 9px;
    letter-spacing: 1px;
  }

  td {
    padding: 5px 7px;
    text-align: center;
    color: #cdd6f4;
    border-radius: 5px;
    min-width: 18px;
  }

  td.dim { color: #45475a; }

  td.today {
    color: #1e1e2e;
    background: #cba6f7;
    font-weight: 700;
  }
`

export const render = () => {
  const now = new Date()
  const year = now.getFullYear()
  const month = now.getMonth()
  const today = now.getDate()
  const monthName = now.toLocaleString('en-US', { month: 'long', year: 'numeric' })

  const firstDay = new Date(year, month, 1).getDay()
  const daysInMonth = new Date(year, month + 1, 0).getDate()
  const daysInPrev = new Date(year, month, 0).getDate()

  const cells = []
  for (let i = firstDay - 1; i >= 0; i--) {
    cells.push({ day: daysInPrev - i, dim: true })
  }
  for (let d = 1; d <= daysInMonth; d++) {
    cells.push({ day: d, today: d === today })
  }
  let nextDay = 1
  while (cells.length % 7 !== 0) {
    cells.push({ day: nextDay++, dim: true })
  }

  const weeks = []
  for (let i = 0; i < cells.length; i += 7) {
    weeks.push(cells.slice(i, i + 7))
  }

  return (
    <div>
      <div className="header">{monthName}</div>
      <table>
        <thead>
          <tr>
            <th>S</th><th>M</th><th>T</th><th>W</th><th>T</th><th>F</th><th>S</th>
          </tr>
        </thead>
        <tbody>
          {weeks.map((week, i) => (
            <tr key={i}>
              {week.map((cell, j) => (
                <td key={j} className={cell.today ? 'today' : cell.dim ? 'dim' : ''}>
                  {cell.day}
                </td>
              ))}
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  )
}
