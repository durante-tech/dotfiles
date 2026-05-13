// drift-warden.widget — 10px sentinel dot at top-right corner of focus widget.
// Designer spec: aligned=invisible, detour=quiet, drift=peach pulse, hover=tooltip.

export const command = `bash "$HOME/Library/Application Support/Übersicht/widgets/drift-warden.widget/data.sh"`
export const refreshFrequency = 30 * 1000

// Position calibrated to focus.widget at bottom:60 left:60 width:380.
// Top-right corner of focus card sits ~at left:440, bottom:130.
export const className = `
  bottom: 125px;
  left: 435px;
  width: 10px;
  height: 10px;
  user-select: none;
  -webkit-font-smoothing: antialiased;

  .dot {
    width: 10px;
    height: 10px;
    border-radius: 50%;
    transition: background-color 600ms ease, opacity 600ms ease, box-shadow 600ms ease;
  }
  .dot.aligned { background: #6c7086; opacity: 0.15; }
  .dot.detour  { background: #6c7086; opacity: 0.45; }
  .dot.drift   {
    background: #fab387;
    opacity: 0.85;
    box-shadow: 0 0 8px rgba(250, 179, 135, 0.5);
    animation: warden-pulse 3.2s ease-in-out infinite;
  }

  @keyframes warden-pulse {
    0%   { opacity: 0.85; box-shadow: 0 0 8px  rgba(250,179,135,0.5); }
    50%  { opacity: 1.0;  box-shadow: 0 0 14px rgba(250,179,135,0.7); }
    100% { opacity: 0.85; box-shadow: 0 0 8px  rgba(250,179,135,0.5); }
  }

  .tooltip {
    position: absolute;
    top: 18px;
    right: -4px;
    width: max-content;
    max-width: 280px;
    padding: 6px 10px;
    background: rgba(17, 17, 27, 0.85);
    border: 1px solid rgba(203, 166, 247, 0.18);
    border-radius: 6px;
    color: #a6adc8;
    font-family: 'JetBrainsMono Nerd Font', 'JetBrains Mono', monospace;
    font-size: 10px;
    white-space: nowrap;
    overflow: hidden;
    text-overflow: ellipsis;
    pointer-events: none;
    opacity: 0;
    transition: opacity 200ms ease;
  }
  &:hover .tooltip { opacity: 1; }
`

export const render = ({ output }) => {
  let d = null
  try { d = JSON.parse((output || "").trim() || "{}") }
  catch (e) { return <div /> }

  const state = d.state || "aligned"
  const tooltip = d.current
    ? `${state.toUpperCase()} · ${d.current}`
    : state.toUpperCase()

  return (
    <div>
      <div className={`dot ${state}`} />
      <div className="tooltip">{tooltip}</div>
    </div>
  )
}
