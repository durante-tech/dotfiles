# Tier 5 — manual setup steps

Three tools installed in commit ahead. Each needs a one-time manual
step the dotfiles repo can't automate (accessibility prompts, password
entry, etc.).

## 1. Maccy — clipboard manager

Already installed at `/Applications/Maccy.app`. To activate:

1. **Launch Maccy once** — `open -a Maccy`
2. **Grant Accessibility permission** — System Settings → Privacy & Security → Accessibility → toggle on `Maccy`
3. **Optional: change default hotkey** — Maccy preferences. Default is `Cmd+Shift+C` (popup), `Cmd+Shift+V` to paste last item.
4. **Optional: launch at login** — Maccy preferences → Launch at login

Storage: Maccy stores up to 200 items by default in `~/Library/Application Support/Maccy/`.

## 2. gh-dash — terminal PR/issue dashboard

Already installed as a `gh` extension. To use:

```bash
ghd                    # alias for `gh dash` — opens interactive dashboard
gh dash                # same, full form
```

**Default config:** lives at `~/.config/gh-dash/config.yml`. To customize sections (PRs you authored, PRs awaiting your review, issues, etc.):

```bash
gh dash --help         # see all options
mkdir -p ~/.config/gh-dash
gh dash --gen-config > ~/.config/gh-dash/config.yml  # write default to file
```

A common config pinning your most-used filters:

```yaml
prSections:
  - title: My PRs
    filters: is:open author:@me
  - title: Needs my review
    filters: is:open review-requested:@me
  - title: Involved
    filters: is:open involves:@me -author:@me
```

## 3. Atuin sync — encrypted shell history sync

Atuin already installed and active locally. To sync history across
machines via the free hosted server at `api.atuin.sh` (or self-host):

```bash
# 1. Register a new account (will prompt for password)
atuin register -u <username> -e <email>

# 2. Sync history up to the server
atuin sync

# 3. Auto-sync from now on (already configured by atuin init zsh)
#    Subsequent terminals will sync automatically.
```

**On a second machine**, after `brew install atuin`:

```bash
# Login with the same credentials
atuin login -u <username>

# Pull existing history
atuin sync
```

**Encryption note:** Atuin uses end-to-end encryption with a key derived from your password + a per-user secret. The server only sees ciphertext. Save the key shown after register — you need it to decrypt history on new machines:

```bash
atuin key                           # show your encryption key
# Save this somewhere safe (1Password, etc.)
```

**Self-host option:** If you'd rather not depend on api.atuin.sh, run the server yourself:
```bash
# On a server with Docker:
docker run -d --name atuin -e ATUIN_DB_URI=postgres://... ghcr.io/atuinsh/atuin:latest server start
# Then point local atuin at it:
atuin config set sync_address https://your-server.example.com
```

## Status checks

```bash
# Maccy
ps aux | grep -i maccy             # running?

# gh-dash
gh extension list                  # should include dlvhdr/gh-dash

# Atuin
atuin status                       # shows sync state
atuin info                         # detailed account info
```
