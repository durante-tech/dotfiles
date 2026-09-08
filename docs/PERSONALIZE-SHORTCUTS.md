# Your personal shortcut reference

`./personalize.sh shortcuts` reads your effective preferences, renders the current
AeroSpace template in memory, and inspects the selected Karabiner source profile.
The resulting guide shows the bindings you configured and your preferred app and
workspace destinations. It does not query running apps or execute any binding.

```bash
./personalize.sh shortcuts
./personalize.sh shortcuts --json
```

Keep an exported personal guide outside the repository, because its application
choices and workspace destinations are personal. The maintained site should link
to this explanation; it must not publish a guide rendered with local preferences.

## Reading the keys

An ordered sequence contains successive steps. For example, an AeroSpace mode
entry chord is released before the next key selects an action. `Hold(CapsLock)`
means keep Caps Lock pressed during the later steps; `Hold(o)` keeps the sublayer
key pressed too. `Tap(CapsLock)` means press and release it alone. These sequences
are derived from the actual layer setters and key-up resets, not rule descriptions.

Case stays significant. `Shift+h` explicitly includes Shift, and left/right
modifier distinctions are retained. Karabiner optional modifiers and inactive
layer guards are available in the JSON record. Here, Hyper is a held variable
layer; it does not emit a Ctrl+Alt+Shift+Cmd chord.

The guide includes only bindings explicitly declared in the AeroSpace template
and the chosen Karabiner profile. It does not cover upstream default bindings,
arbitrary shell or tmux mappings, installed Raycast hotkeys, or running application
state. The source configuration may still need its documented reload.

## Source drift and uncertainty

Each export includes SHA-256 hashes for both source files and a deterministic
reference fingerprint. Re-export after preferences or bindings change. The same
source and effective choices produce the same result across checkout locations.

Rows marked `unsupported`, `ambiguous`, or `context-required` remain visible.
Unsupported conditional/timing forms retain their source and raw behavior instead
of receiving an invented sequence. A mode with no unique parsed entry path lists
its key as requiring that mode already active. Duplicate Karabiner inputs identify
first-match ambiguity. Disabled rules are omitted and reported separately.

Preferred destinations are resolved from the managed app/workspace helpers and
the rendered AeroSpace commands. A forwarded Karabiner key that resolves through
AeroSpace is marked as requiring AeroSpace's main mode. Earlier floating rules
may still prevent preferred workspace routing; the guide is a configuration
reference, not a live routing or app-installation check.

## Read-only structured reference

The JSON envelope has `version: 1`, `kind: "dotfiles-shortcut-reference"`, and
`reference_only: true`. Its `roles`, `records`, `diagnostics`, `sources`, and
`fingerprint` fields support local reference tooling. Each row contains an ordered
`sequence`, structured `steps` (including hold/tap semantics), literal `action`,
mode/context, source location, conditions (including earlier hold-step activation
guards), resolved destination, and support status.

A row's semantic ID changes when its key sequence, action, conditions, or resolved
destination changes. It is not a course drill ID and must not be used to transfer
mastery from an older shortcut. Exports contain no progress or scheduling state;
generation does not read or write browser storage. This format is deliberately
not a course progress import. Browser/OS interception is also a reason to keep
the guide beside the actual tool instead of treating every shortcut as a web drill.

Run `python3 -m unittest discover -s tests -p 'test_personal_shortcuts.py'` for
isolated coverage of personalized destinations, source drift, case/modifiers,
layer holds, ambiguous entries, profile selection, and read-only behavior.
