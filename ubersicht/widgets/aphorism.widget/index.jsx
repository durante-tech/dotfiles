// aphorism.widget — rotating italic quote, refreshes every 30 minutes
// Reads from quotes.txt (one quote per line). Catppuccin Mocha · JetBrainsMono.

const QUOTES_PATH = "$HOME/Library/Application Support/Übersicht/widgets/aphorism.widget/quotes.txt"

export const command = `awk 'BEGIN{srand()} NF{a[++n]=$0} END{if(n) print a[int(rand()*n)+1]}' "${QUOTES_PATH}"`
export const refreshFrequency = 30 * 60 * 1000

export const className = `
  bottom: 60px;
  left: 50%;
  transform: translateX(-50%);
  max-width: 540px;
  font-family: 'JetBrainsMono Nerd Font', 'JetBrains Mono', 'Hack Nerd Font', monospace;
  background: rgba(17, 17, 27, 0.55);
  backdrop-filter: blur(24px) saturate(140%);
  -webkit-backdrop-filter: blur(24px) saturate(140%);
  padding: 16px 22px;
  border-radius: 12px;
  border: 1px solid rgba(203, 166, 247, 0.15);
  border-left: 3px solid #cba6f7;
  color: #cdd6f4;
  font-size: 13px;
  font-style: italic;
  line-height: 1.7;
  text-align: center;
  user-select: none;
  -webkit-font-smoothing: antialiased;
  box-shadow: 0 12px 36px rgba(0, 0, 0, 0.35);
`

export const render = ({ output }) => {
  const quote = output ? output.trim() : "..."
  return <div>{quote}</div>
}
