// focus.widget — north-star intention from intention.txt
// Edit intention.txt to set today's focus. Catppuccin Mocha · top center-left · yellow accent.
// Moved out of bottom-left (was bottom:60 left:60) — that corner is
// today-focus.widget's anchor now; three panels were stacking there.

export const command = `cat "$HOME/Library/Application Support/Übersicht/widgets/focus.widget/intention.txt" 2>/dev/null | head -1`
export const refreshFrequency = 5 * 60 * 1000

export const className = `
  top: 80px;
  left: 640px;
  max-width: 380px;
  font-family: 'JetBrainsMono Nerd Font', 'JetBrains Mono', 'Hack Nerd Font', monospace;
  background: rgba(17, 17, 27, 0.55);
  backdrop-filter: blur(24px) saturate(140%);
  -webkit-backdrop-filter: blur(24px) saturate(140%);
  padding: 16px 20px;
  border-radius: 12px;
  border: 1px solid rgba(203, 166, 247, 0.15);
  border-left: 3px solid #f9e2af;
  color: #cdd6f4;
  user-select: none;
  -webkit-font-smoothing: antialiased;
  box-shadow: 0 12px 36px rgba(0, 0, 0, 0.35);

  .header {
    color: #f9e2af;
    font-size: 9px;
    letter-spacing: 4px;
    text-transform: uppercase;
    margin-bottom: 8px;
    font-weight: 700;
  }

  .text {
    font-size: 13px;
    line-height: 1.5;
    color: #cdd6f4;
  }
`

export const render = ({ output }) => {
  const text = (output || '').trim() || 'Set your north star: edit intention.txt'
  return (
    <div>
      <div className="header">✦ Today</div>
      <div className="text">{text}</div>
    </div>
  )
}
