# espanso/

System-wide text expander config, stowed into `~/Library/Application Support/espanso/`.

## Layout

```
espanso/Library/Application Support/espanso/
├── config/default.yml   # backend + global settings
└── match/base.yml       # snippet definitions
```

`stow -t ~ espanso` symlinks both files into espanso's macOS config dir.

## First-time setup

Espanso needs **macOS Accessibility** permission to function. After installing:

1. **Grant accessibility permission**
   - Open `System Settings → Privacy & Security → Accessibility`
   - Toggle on `Espanso` (path: `/Applications/Espanso.app`)
2. **Register the LaunchAgent and start**
   ```bash
   espanso service register
   espanso start
   ```
3. **Verify** — type `:dt` anywhere; it should expand to today's ISO date.

## Built-in snippets

| Trigger | Expansion |
|---------|-----------|
| `:dt`   | Today's ISO date — `2026-04-30` |
| `:ts`   | ISO timestamp — `2026-04-30T14:32:01` |
| `:sig`  | Email signature (`Lucas Gertel\nlucas.gertel@durante.tech`) |
| `:llm` | Pipe clipboard to qwen3-coder:30b → reply pastes inline (copy prompt first, then type `:llm`) |
| `:llmf` | Form popup → type prompt directly → reply pastes inline (no clipboard needed) |

## The `:llm` and `:llmf` triggers (Ollama)

Two patterns ship enabled:

- **`:llm` (clipboard-based)** — copy any text (Cmd+C), type `:llm` anywhere, qwen3-coder:30b processes the clipboard contents and pastes the reply inline. Best for "explain this", "rewrite this", "summarize this" workflows where the prompt is whatever you just selected.

- **`:llmf` (form-based)** — type `:llmf` anywhere, espanso opens a multiline form, you type the prompt, Enter submits, reply pastes inline. Best for spontaneous "what's the regex for X" questions where there's no source text.

Prereqs:
1. `ollama-up` to start the daemon (or it's already running)
2. `ollama pull qwen3-coder:30b` (~19 GB; needed once)
3. Espanso's Accessibility permission granted in System Settings

To swap to a different model (e.g. qwen3.6:35b for general reasoning):
- Edit `match/base.yml`, change `qwen3-coder:30b` to your tag
- `espanso restart`

Add a third trigger like `:llmg` if you want both models reachable without editing.

## Adding more snippets

Drop new `.yml` files into `match/` (stow picks them up after `stow -R -t ~ espanso`). Espanso reloads automatically when files change.

Common additions:
- `:em` → email address
- `:addr` → mailing address
- `:gpg` → GPG fingerprint
- `:pr` → PR template scaffold
- `:rfc` → RFC template scaffold

## Reload after edits

```bash
espanso restart
```

## Troubleshooting

- `unable to start service: launchctl exited with non-zero code 3` — accessibility permission missing or not yet granted. Grant in System Settings, then `espanso service register && espanso start`.
- `unable to load config` — check `match/base.yml` YAML syntax with `espanso edit` or `yq eval`.
