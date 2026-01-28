# SketchyBar Configuration

Custom macOS status bar with system monitoring and AeroSpace integration.

## Layout

```
[Workspaces] [App] [Docker]          [CPU] [RAM] [Battery] [Network] [Weather] [Volume] [Spotify] [Time]
└─ Left ─────────────────┘           └─────────────────── Right ──────────────────────────────────────┘
```

## Sections

### Left Side
| Item | Description |
|------|-------------|
| Workspaces | AeroSpace workspace indicators |
| Active App | Currently focused application |
| Docker | Container status |

### Right Side
| Item | Description |
|------|-------------|
| CPU | Current usage percentage |
| Memory | RAM usage |
| Battery | Charge level and status |
| Network | Online/offline indicator |
| Weather | Current conditions |
| Volume | System volume |
| Spotify | Now playing |
| Time | Current time |

## AeroSpace Integration

Receives workspace change events:
```bash
sketchybar --trigger aerospace_workspace_change FOCUSED_WORKSPACE=$AEROSPACE_FOCUSED_WORKSPACE
```

## Toggle Visibility

`Alt+S` (in AeroSpace) toggles the bar.

## File Structure

```
sketchybar/.config/sketchybar/
├── sketchybarrc     # Main config
├── items/           # Individual item configs
│   ├── workspaces.sh
│   ├── cpu.sh
│   ├── battery.sh
│   └── ...
└── plugins/         # Plugin scripts
    ├── cpu.sh
    ├── battery.sh
    └── ...
```

## Customization

Each item is a separate shell script. Modify `items/*.sh` for appearance, `plugins/*.sh` for behavior.

## Dependencies

- `jq` for JSON parsing
- `switchaudio-osx` for volume control
- Custom plugins for weather, Spotify
