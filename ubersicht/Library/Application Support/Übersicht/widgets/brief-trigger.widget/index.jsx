// brief-trigger.widget — center-screen circular trigger for the daily brief agent.
// Sits at orbital sphere center; click fires launchctl kickstart on the daily-brief LaunchAgent.
// Catppuccin Mocha · blue accent · large glyph readable from across the room.

export const command = `bash "$HOME/Library/Application Support/Übersicht/widgets/brief-trigger.widget/data.sh"`

export const refreshFrequency = 30 * 1000 // 30s — light, just for age display

let __runningUntil = 0
const fireBrief = () => {
  // Übersicht's server.js spawns bash and writes the POST body to its stdin.
  // POST /run/ with raw command text as body — same-origin guard satisfied
  // because we're running inside Übersicht's webkit context.
  const cmd = "launchctl kickstart -k gui/$(id -u)/tech.durante.dos.daily-brief"
  fetch("/run/", { method: "POST", body: cmd }).catch(() => {})
  __runningUntil = Date.now() + 60_000
}
const isRunning = () => Date.now() < __runningUntil

export const className = `
  box-sizing: border-box;
  /* 42% (not 50%): keeps the ring + labels clear of deck.widget's variable-height
     panel growing up from bottom:60 — at 50% the deck overlapped the labels. */
  top: 42%;
  left: 50%;
  transform: translate(-50%, -50%);
  width: 180px;
  height: 180px;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  font-family: 'JetBrainsMono Nerd Font', 'JetBrains Mono', 'Hack Nerd Font', monospace;
  user-select: none;
  -webkit-font-smoothing: antialiased;
  z-index: 50;

  .ring {
    width: 140px;
    height: 140px;
    border-radius: 50%;
    background: rgba(17, 17, 27, 0.55);
    backdrop-filter: blur(28px) saturate(160%);
    -webkit-backdrop-filter: blur(28px) saturate(160%);
    border: 2px solid rgba(137, 180, 250, 0.45);
    box-shadow:
      0 0 0 6px rgba(137, 180, 250, 0.06),
      0 0 32px rgba(137, 180, 250, 0.18),
      0 16px 48px rgba(0, 0, 0, 0.5);
    display: flex;
    align-items: center;
    justify-content: center;
    color: #89b4fa;
    font-size: 56px;
    font-weight: 400;
    cursor: pointer;
    transition:
      transform 220ms cubic-bezier(0.2, 0.7, 0.3, 1.4),
      border-color 220ms ease,
      box-shadow 220ms ease,
      color 220ms ease;
  }
  .ring:hover {
    transform: scale(1.06);
    border-color: rgba(137, 180, 250, 0.85);
    box-shadow:
      0 0 0 10px rgba(137, 180, 250, 0.10),
      0 0 56px rgba(137, 180, 250, 0.35),
      0 16px 48px rgba(0, 0, 0, 0.55);
  }
  .ring.running {
    color: #f9e2af;
    border-color: rgba(249, 226, 175, 0.7);
    box-shadow:
      0 0 0 10px rgba(249, 226, 175, 0.08),
      0 0 56px rgba(249, 226, 175, 0.30),
      0 16px 48px rgba(0, 0, 0, 0.55);
    animation: spin 1.4s linear infinite;
  }
  .ring:active {
    transform: scale(0.96);
  }
  @keyframes spin {
    from { transform: rotate(0deg); }
    to   { transform: rotate(360deg); }
  }

  .label {
    margin-top: 14px;
    color: #cdd6f4;
    font-size: 11px; /* support */
    letter-spacing: 4px;
    text-transform: uppercase;
    font-weight: 600;
    opacity: 0.85;
    text-shadow: 0 2px 8px rgba(0, 0, 0, 0.8);
  }
  .age {
    margin-top: 4px;
    color: #a6adc8;
    font-size: 9px; /* micro */
    letter-spacing: 2px;
    text-transform: uppercase;
    font-weight: 500;
    opacity: 0.65;
    text-shadow: 0 2px 8px rgba(0, 0, 0, 0.8);
  }
  .age.missing { color: #f38ba8; opacity: 0.85; }
  .age.stale   { color: #f9e2af; opacity: 0.85; }
`

export const render = ({ output }) => {
  let data = { state: "fresh", age: "loading…" }
  if (output) {
    try { data = JSON.parse(output) } catch { /* keep defaults */ }
  }

  const running = isRunning()
  const ageClass = data.state === "missing" ? "missing"
                 : data.state === "stale"   ? "stale"
                 : ""

  return (
    <div>
      <div
        className={`ring ${running ? "running" : ""}`}
        title={running ? "Brief running — refreshes when ready" : "Run daily brief now"}
        onClick={fireBrief}
      >
        ↻
      </div>
      <div className="label">{running ? "Running" : "Run Brief"}</div>
      <div className={`age ${ageClass}`}>last: {data.age}</div>
    </div>
  )
}
