# Formatter Troubleshooting

Start with `:ConformInfo` in the affected buffer. It shows the selected formatter,
resolved executable, and log. Restart Neovim after changing its formatter policy.

## Unexpected style

Inspect configuration from the buffer's directory outward, including
`package.json`, `.editorconfig`, `.prettierrc*`, `prettier.config.*`, and
`biome.json` / `biome.jsonc`. The nearest formatter configuration wins;
JavaScript/TypeScript ties favor Biome and JSON/CSS/GraphQL ties favor Prettier.

Unconfigured projects use Prettier defaults, with EditorConfig respected. There
are no global indentation, quote, semicolon, line-width, or trailing-comma overrides.

## File stays unchanged

Check `.prettierignore`, `.gitignore`, and the selected formatter's ignore or
disabled-formatting settings. An ignored file staying unchanged is expected.

If a notification reports a missing executable or plugin, use the project's
package manager to install its declared dependencies. Formatting never installs
packages. Local binaries win over fallback tools on PATH.

A formatter error preserves the unformatted save. Web formats never silently
switch to an LSP or another formatter. Check the selected tool's diagnostic
before retrying.

## Large or slow files

Before-save formatting stops after one second. Manual `<leader>f` allows two
seconds. A timeout must not cause a later file rewrite. If both time out, run the
project's formatter command explicitly and investigate its plugin/configuration
cost; no larger automatic timeout is assumed.

`<leader>mp` previews Markdown and formats non-Markdown buffers. Use `<leader>f`
when you want to format Markdown. Zsh has no shfmt mapping; run `zsh -n` to check
its syntax.

See the [formatter guide](formatters.md) for the full selection policy.
