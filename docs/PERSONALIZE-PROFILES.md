# Explicit preference profiles

Profiles save a named selection of supported preferences. You choose their values
and the keys they own, then preview a profile before applying it. Laptop, Desk,
and Presentation start **unconfigured**. Installing or updating dotfiles does not
invent a desk arrangement, select a profile, or change your current visual settings.

## Capture and use

```bash
cd ~/dotfiles
./personalize.sh profile list
./personalize.sh profile save laptop apps.terminal workspaces.terminal
./personalize.sh profile save laptop apps.terminal workspaces.terminal --apply
./personalize.sh profile show laptop
./personalize.sh profile use laptop
./personalize.sh profile use laptop --apply
```

`save` captures the current effective values of the named keys. It only saves the
profile; it does not apply preferences or render tool configuration. The first
command without `--apply` previews those captured values. Enter the same command
with `--apply` to save them. Capturing an existing name requires `--replace`, so
an accidental save cannot replace a tuned profile.

Use `desk` and `presentation` the same way after configuring the values you want
to keep. They are names for your choices, with no assumed brightness or font
sizes. Custom names use lowercase letters, digits, and dashes, start with a
letter, and contain at most 48 characters.

`use` applies only the profile's owned keys through the normal preference
transaction. An unrelated app choice or project root remains unchanged. Profiles
may intentionally own the same keys; the most recent explicit application sets
those keys. `--dry-run` wins over `--apply` in either order.

## Reading status

`profile list` and `profile show NAME` compare saved values with current effective
preferences. They report:

| State | Meaning |
| --- | --- |
| `unconfigured` | The starter name has no saved values; it cannot be applied. |
| `matches` | Every owned value currently matches its saved value or reset rule. |
| `different` | At least one owned value differs; the output identifies the keys. |

Several profiles can match simultaneously. Status is derived each time, so a
manual preference change cannot leave behind a misleading “active profile” flag.
Unknown custom names fail visibly instead of becoming implicit profiles.

## Ownership and storage

Profiles are private machine data in `~/.config/dotfiles/profiles.json`, alongside
`preferences.json` and `personal.env`. `DOTFILES_USER_CONFIG_DIR` selects another
directory for all three. They are not stored in Git.

Every supported catalog key can be owned except `display.*`. Profile switching
does not own the display controller's serial identities, calibration, brightness,
HDR, or Manual/Auto intent. It performs no monitor detection, hardware writes,
service changes, app launches, or automatic switching. Monitor matching patterns
remain ordinary AeroSpace preferences; they do not invoke the brightness controller.

The version-1 file has an explicit ownership partition:

```json
{
  "version": 1,
  "profiles": [
    {
      "name": "presentation",
      "owns": ["apps.editor", "workspaces.browser"],
      "values": {"apps.editor": null},
      "reset": ["workspaces.browser"]
    }
  ]
}
```

Each owned key occurs exactly once in `values` or `reset`. A saved `null` remains
an explicit value, such as an unconfigured optional editor. A reset removes the
managed override when the profile is used, allowing the then-current legacy or
repository default to apply. The CLI's `save` command captures values; advanced
manual recipes can use the `reset` list and are validated by `profile show` and
`profile use` before writes.

Malformed JSON, duplicate names or ownership, unsupported keys, invalid catalog
values, and future schema versions are rejected without replacing saved data.
Application routing conflicts are checked against current preferences before
use, and the normal apply checks validate selected installed applications.

## Backups and activation

Saving or using a profile uses the personalizer's backups and guarded undo. The
profile file and preference inputs are included in the transaction's change
checks. If they change after preview or apply, retry from a fresh preview or
preserve the newer edits before undo. The profile backend never writes a separate
“last active” record.

Saving a profile needs no reload. Using one prints the relevant reload commands;
it does not run them or restart sessions. App launchers read their preferences on
the next invocation. AeroSpace routing changes take effect after:

```bash
aerospace reload-config
```

Projected environment settings apply in new shells. Other affected tools follow
the reload guidance printed by the personalizer. See [personalization](PERSONALIZE.md)
for preview, validation, and undo details.
