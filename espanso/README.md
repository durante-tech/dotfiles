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
| `:sig`  | Email signature (`Lucas Gertel\nlgertel@altyaa.com`) |
| `:llm ` | (commented) shell pipe to local Ollama — uncomment + pick model after `ollama pull <model>` |

## The `:llm` trigger (Ollama)

Once you have Ollama running (`brew services start ollama`) and a model pulled (e.g. `ollama pull llama3.2:3b`), uncomment the `:llm` block in `match/base.yml`:

```yaml
- trigger: ":llm "
  replace: "{{output}}"
  vars:
    - name: output
      type: shell
      params:
        cmd: "echo '{{clipboard}}' | ollama run llama3.2:3b"
```

Workflow: copy a prompt to clipboard → type `:llm ` anywhere → Ollama processes it and pastes the response inline.

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
