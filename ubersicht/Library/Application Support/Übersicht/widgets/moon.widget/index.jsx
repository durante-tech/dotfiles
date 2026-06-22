// moon.widget — current lunar phase + illumination %
// Pure JS (no network), hourly refresh. Catppuccin Mocha · top-left.

export const refreshFrequency = 60 * 60 * 1000

const SYNODIC = 29.530588853
const REF_NEW_MOON = new Date('2000-01-06T18:14:00Z')

const PHASES = [
  { glyph: '🌑', name: 'New' },
  { glyph: '🌒', name: 'Waxing Crescent' },
  { glyph: '🌓', name: 'First Quarter' },
  { glyph: '🌔', name: 'Waxing Gibbous' },
  { glyph: '🌕', name: 'Full' },
  { glyph: '🌖', name: 'Waning Gibbous' },
  { glyph: '🌗', name: 'Last Quarter' },
  { glyph: '🌘', name: 'Waning Crescent' },
]

export const className = `
  top: 70px;
  right: 60px;
  font-family: 'JetBrainsMono Nerd Font', 'JetBrains Mono', 'Hack Nerd Font', monospace;
  text-align: center;
  color: #cdd6f4;
  user-select: none;
  -webkit-font-smoothing: antialiased;

  .glyph {
    font-size: 64px;
    line-height: 1;
    text-shadow: 0 2px 28px rgba(203, 166, 247, 0.4);
  }

  .name {
    font-size: 11px;
    margin-top: 12px;
    color: #cba6f7;
    letter-spacing: 4px;
    text-transform: uppercase;
    font-weight: 600;
    text-shadow: 0 1px 8px rgba(0, 0, 0, 0.6);
  }

  .illum {
    font-size: 10px;
    margin-top: 4px;
    color: #6c7086;
    letter-spacing: 2px;
    text-shadow: 0 1px 6px rgba(0, 0, 0, 0.6);
  }
`

export const render = () => {
  const days = (Date.now() - REF_NEW_MOON.getTime()) / 86400000
  const phase = (((days % SYNODIC) + SYNODIC) % SYNODIC) / SYNODIC
  const idx = Math.floor(phase * 8 + 0.5) % 8
  const illum = Math.round(((1 - Math.cos(phase * 2 * Math.PI)) / 2) * 100)
  const { glyph, name } = PHASES[idx]
  return (
    <div>
      <div className="glyph">{glyph}</div>
      <div className="name">{name}</div>
      <div className="illum">{illum}% lit</div>
    </div>
  )
}
