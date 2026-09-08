# Customization roadmap

The customization work builds on the completed reliability and display-control
changes. Shared configuration stays in Git; personal choices stay outside it.
The sequence below records the implemented capabilities and their activation
boundaries.

| Order | Capability | Current behavior |
| --- | --- | --- |
| 1 | Safe personalization | Preserves multiline/unknown settings; validates, previews, backs up, and supports guarded undo |
| 2 | Consistent preferences | Preferred apps, project roots, monitor patterns, and optional terminal readability controls share the catalog |
| 3 | App/workspace roles | AeroSpace and Karabiner consume the selected destinations and launchers |
| 4 | Explicit profiles | Laptop/Desk/Presentation start unconfigured; capture named owned keys and apply them explicitly |
| 5 | Raycast preferences | Existing Script Commands expose settings, profile capture/use, backups, undo, and the reference |
| 6 | Personal shortcut reference | Markdown/JSON is derived from effective AeroSpace and selected Karabiner source bindings |

Readability, profile planning, and shortcut derivation were implemented in isolated
parallel branches. Shared transaction and Raycast integration followed, with
independent review and cross-feature fixtures. The same tests run in CI.

Configuration consistency and source-derived references are verified separately
from human acceptance. The tools report reload guidance without claiming that
running applications already loaded it. Choose and compare your own font/size
settings, save meaningful profiles, and inspect familiar shortcuts during normal
use. Installation preserves the current appearance and selects no profile.

The personal reference is a course companion, not a progress import. It never
transfers mastery to changed bindings or writes learning history. Automated
profile switching, a course trainer that imports personal reference data, broad
package cleanup, and ownership/retirement decisions remain separate work.

Start with [personalization](PERSONALIZE.md), then [readability](PERSONALIZE-READABILITY.md),
[profiles](PERSONALIZE-PROFILES.md), [Raycast](PERSONALIZE-RAYCAST.md), and
[personal shortcuts](PERSONALIZE-SHORTCUTS.md).
