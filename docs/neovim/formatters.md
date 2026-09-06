# Formatter Configuration Guide

Formatting follows each project. `<leader>f` formats the buffer using the same
policy as save; `<leader>mp` keeps its non-Markdown formatting alias. In Markdown,
`<leader>mp` remains preview. `<leader>mf` formats injected code.

## How selection works

For JavaScript, TypeScript, JSX, TSX, JSON, JSONC, CSS, and GraphQL, configuration
is discovered outward from the file's directory. This includes supported Prettier
configuration files, the `prettier` field in `package.json`, and `biome.json` or
`biome.jsonc`. The closest configuration wins. At equal distance, JavaScript and
TypeScript use Biome; JSON, CSS, and GraphQL use Prettier.

HTML, Markdown, YAML, SCSS, Less, Vue, Svelte, Astro, JSON5, and XML keep their
Prettier route. Experimental Biome languages are not enabled by this policy.

Project-local executables take priority over installed fallback tools. Formatting
never downloads a tool. Install required formatter dependencies and plugins in
the project using its own package manager and lockfile.

With no formatter configuration, installed Prettier uses its standard defaults,
including two-space indentation. EditorConfig still applies. There is no global
Prettier configuration and no CLI style overrides. The previous options were
legal, but CLI overrides could defeat the project's intended style.

The policy preserves formatter ignore rules and disabled formatting. If the
selected formatter is unavailable, times out, or needs a missing plugin, Neovim
reports the error and saves the unformatted buffer. It does not try a different
formatter or a web LSP as a fallback.

## Save and manual formatting

- Save: synchronous formatting before the write, with a 1,000 ms limit.
- `<leader>f`: same selection with a 2,000 ms limit.
- `<leader>mp`: existing non-Markdown alias, also 2,000 ms.
- `:ConformInfo`: inspect the selected formatter, executable, and log.

There is no delayed after-save rewrite. Plain Prettier is the active route;
Prettierd is not selected. Read-only, unnamed, and special buffers are skipped.

## Other languages

| Language | Existing formatter route |
| --- | --- |
| Python | isort then Black |
| Go | goimports then gofumpt |
| Rust | rustfmt |
| Ruby | RuboCop |
| Lua | StyLua |
| Bash / POSIX shell | shfmt |
| TOML | Taplo |
| SQL | sql-formatter |
| C / C++ | clang-format |

Zsh is intentionally not mapped to shfmt: its syntax is not supported. Use
`zsh -n` for syntax validation. Other language tooling is preserved.

Biome linting runs for JavaScript and TypeScript only when the project has a
Biome configuration. Python's existing linting is unchanged.

## Configuration files

Selection lives in `nvim/.config/nvim/lua/sethy/formatting-policy.lua`;
Conform setup lives in `lua/sethy/plugins/formatting.lua`. Change project style
in that project's formatter configuration, not these routing files.

See [formatter troubleshooting](formatter-troubleshooting.md) and the
[maintenance command contracts](../maintenance.md). Prettier documents its
[configuration discovery](https://prettier.io/docs/configuration) and
[CLI precedence](https://prettier.io/docs/cli#--config-precedence).
