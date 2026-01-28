# Starship Configuration

Cross-shell prompt with Catppuccin Mocha theme.

## Prompt Format

```
 ~/projects/myapp  main [M!?]                    Node 20.0  3s
```

| Element | Description |
|---------|-------------|
| `` | Directory icon |
| Path | Truncated current directory |
| `` | Git branch icon |
| `main` | Current branch |
| `[M!?]` | Git status (Modified, Staged, Untracked) |
| Right side | Language versions, command duration |

## Git Status Indicators

| Symbol | Meaning |
|--------|---------|
| `M` | Modified files |
| `!` | Staged changes |
| `?` | Untracked files |
| `⇡` | Ahead of remote |
| `⇣` | Behind remote |
| `⇕` | Diverged |

## Theme: Catppuccin Mocha

11 custom colors defined:
- `rosewater`, `flamingo`, `pink`, `mauve`
- `red`, `maroon`, `peach`, `yellow`
- `green`, `teal`, `blue`

## Customization

Edit `~/.config/starship/starship.toml`:

```toml
# Change directory color
[directory]
style = "bold blue"

# Add language version
[nodejs]
disabled = false
```

## File Location

```
starship/.config/starship/starship.toml
```

## Features

- **3600s timeout**: Won't hang on slow git repos
- **Git URL display**: Custom module showing repo URL
- **Right prompt**: Time, languages, environment info
