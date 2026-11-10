# SketchyBar Configuration

Custom macOS status bar with system monitoring and AeroSpace integration.

## Layout

The bar is **quiet by default**: four things are always there, everything else
appears only while it has something to say. The macOS menu bar is set to
auto-hide, so this is the only bar on screen.

```
[occupied workspaces] [App] [docker?] [vpn?] [updates?]      [spotify?] [muted?] [github?] [net?] [mem?] [cpu?] [weather?] [☀] [Tue 10 · 14:33] [Battery]
└─ Left ───────────────────────────────────────────────┘      └─────────────────────────────────────── Right ─────────────────────────────────────────┘
```

## Sections

### Always shown
| Item | Description |
|------|-------------|
| Workspaces | Only workspaces that hold a window, plus the focused one (`plugins/spaces.sh`). Falls back to all of them if AeroSpace cannot be asked |
| Active App | Currently focused application |
| Clock | Weekday, day and time; click opens Calendar |
| Battery | Charge level and status |
| Brightness mode | Glyph only while Auto is healthy; the full label returns for Manual, HDR, pending and failed states |

### Shown only when relevant
| Item | Appears when |
|------|--------------|
| Docker | The daemon is up and at least one container runs |
| ClearVPN | The VPN is connected |
| MacUpdater | Updates are pending |
| GitHub | Unread notifications > 0 |
| CPU | Usage above 50% |
| Memory | Usage above 80% |
| Network | More than 1 MiB/s in either direction |
| Microphone | Input is muted or the device is unreadable (macOS shows its own indicator while the mic is live) |
| Volume | Output is muted (macOS draws its own OSD on change) |
| Spotify | Something is playing |
| AeroSpace mode | A non-main binding mode is active |
| Weather | On workspaces 1, 2 and N (`plugins/workspace_visibility.sh`) |

Each of those items sets its own `drawing` from its plugin and keeps
`updates=on`; without that a hidden item stops running its script and never
comes back. An item must have exactly one writer of `drawing`, so quiet items
are not listed in the workspace visibility table.

## Cost

A status bar must not spend the machine to describe it. Every poll is a shell
plus its commands, so the rule is: **events first, slow ticks second, nothing
faster than once a minute** unless the label itself needs it (the clock).

| Item | Refresh |
|------|---------|
| Workspaces | AeroSpace workspace change, app switch, the move bindings; 120 s safety net |
| Volume, brightness, front app, AeroSpace mode | Events only |
| Spotify | `com.spotify.client.PlaybackStateChanged`; 120 s safety net |
| CPU, memory, network, mic, VPN | 60 s |
| Docker, battery | 120 s |
| MacUpdater, GitHub, weather | 300 s, 600 s, 1800 s |
| Clock | 30 s |

Measured on this rig (user + system time per run × runs per day): about 2,750
CPU-seconds a day before, about 420 after. To re-measure, time each plugin with
`/usr/bin/time -l env NAME=<item> bash plugins/<item>.sh` and multiply by
`86400 / update_freq`.

## AeroSpace Integration

Receives workspace change events:
```bash
sketchybar --trigger aerospace_workspace_change FOCUSED_WORKSPACE=$AEROSPACE_FOCUSED_WORKSPACE
```

## Toggle Visibility

`Ctrl+Shift+\` (Karabiner) toggles the bar; so does tapping `B` while `Hyper+S` is still held.

## File Structure

```
sketchybar/.config/sketchybar/
├── sketchybarrc     # Main config
├── items/           # Individual item configs
│   ├── space.sh
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
