# Regression fixtures

Run `python3 -m unittest discover -s tests -p 'test_*.py'` from the repository.
Fixtures use temporary directories and intercepted terminal/package/service
commands. They never source a complete user shell profile, install packages,
or change a live terminal or display. Zsh and Stow are required.

Formatting and site tests have separate commands documented alongside their
fixtures. Keep negative source examples in temporary files so repository
linters do not mistake intentional invalid input for shipped code.

## Formatting

Run `python3 tests/run_formatting.py` with Neovim >=0.11, Prettier and Biome
already installed. `DOTFILES_TEST_CONFORM_DIR` selects the Conform checkout;
the local default is the installed lazy.nvim directory. CI fetches the exact
`lazy-lock.json` revision. The runner uses disposable XDG roots, no startup config,
no Lazy/Mason setup, and only fixture files. It performs no dependency installation.

## Display control

`test_display_control.py` covers Manual/Auto ownership, calibrated presets,
HDR round trips, per-display failures, identifier ambiguity, malformed state,
lock contention, and fresh wake intent. `test_display_layout.py` covers layout
preview precedence, failed writes/readback, atomic profile persistence, and
ambient retries. Hardware is fake; no real brightness changes occur in fixtures.

## Personalization

`test_personalization.py` covers literal multiline preservation, typed preferences,
preview precedence, app/workspace routing, shell/TOML quoting, concurrent edits,
write rollback, and guarded undo. App bundles and launch commands are fixtures;
no applications, hardware controls, or services are started. `test_shell.py` also
checks the final local-override ordering before the profiling report.

`test_readability.py`, `test_preference_profiles.py`, and `test_personal_shortcuts.py`
cover terminal rendering, explicit profile ownership, and source-derived key
sequences. `test_customization_integration.py` exercises shared rollback/undo,
old backups, late symlink changes, non-executing entry points, and Raycast argument
boundaries. Optional native font/parser checks use temporary configurations and
never open terminal windows. See `docs/CUSTOMIZATION-ROADMAP.md` for real-use checks.
