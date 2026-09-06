# Regression fixtures

Run `python3 -m unittest discover -s tests -p 'test_*.py'` from the repository.
Fixtures use temporary directories and intercepted terminal/package/service
commands. They never source a complete user shell profile, install packages,
or change a live terminal or display. Zsh and Stow are required.

Formatting and site tests have separate commands documented alongside their
fixtures. Keep negative source examples in temporary files so repository
linters do not mistake intentional invalid input for shipped code.
