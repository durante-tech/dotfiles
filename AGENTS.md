# Repository guidance

Read [CLAUDE.md](CLAUDE.md) before making changes. It is the single source of
truth for architecture, conventions, commands, and deployment boundaries.

Run the isolated regression fixtures described in `tests/README.md` and the
relevant checks in [VERIFY.md](VERIFY.md). Deploy per package using
[stow-packages.txt](stow-packages.txt); never treat the repository root as a
Stow package.
