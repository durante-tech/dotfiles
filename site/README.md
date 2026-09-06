# Dotfiles learning site

Markdown under `../docs/` owns reference prose. `scripts/reference-pages.json`
explicitly lists its site mirrors; add a mapping when intentionally publishing
another reference. Course wrappers and navigation use `src/data/levels.json`.
Existing MDX frontmatter is retained as metadata. The landing page, progress page,
and other authored course pages remain separate from generated reference bodies.

```sh
bun install --frozen-lockfile
bun run docs:generate
bun run docs:check
bun test
bun run typecheck
bun run build
bun run links:check
```

`docs:generate` runs migration then lesson embedding. Both stages are idempotent.
`docs:check` regenerates in a temporary directory and reports drift without
rewriting tracked files. Edit generated reference prose in its Markdown source.
The link check reads built HTML without fetching external sites.

Drills have readable `keys` labels and ordered, case-sensitive `sequence` arrays.
Modifier chords are single entries, such as `Ctrl+b`; sequential letters are
separate entries. If a shortcut changes, update its label too: progress IDs use
`set-id:keys`, so the historical shortcut keeps its own statistics.

The trainer offers typed notation for browser/OS-reserved shortcuts. Key repeat
events do not count as attempts. Exact prefixes wait for the next key; an exact
sequence or invalid prefix records one result. Try Again resets the attempt.

Progress schema 2 persists SM-2 `repetitions`. Version 1 is backed up verbatim in
`dotfiles-mastery-progress-backup-v1` before migration. Lessons, streaks, and
historical counts survive; unknown consecutive repetitions become zero and cards
are scheduled for review. Obsolete shortcuts retain their history without giving
mastery to changed bindings. Imports also preserve a pre-import backup.

Malformed or unsupported future data cannot overwrite saved progress. Unreadable
saved data remains exportable, automatic saving pauses, and the progress page
shows a recovery notice. Explicit Reset clears active data, leaving backups.

Tests use disposable DOM and localStorage fixtures. They do not read real browser
progress, call accounts, or publish the site.
