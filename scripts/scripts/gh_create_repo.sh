#!/usr/bin/env bash
# create git repo using gh
#
# The shebang used to sit on line 2, under this comment. The kernel only reads
# line 1, so `./gh_create_repo.sh` was executed by /bin/sh, not bash — it
# happened to work only because nothing below is bash-specific.

name=${1:-${PWD##*/}}
# The account the repo is created under: GH_USER, else whoever gh is logged in as.
owner="${GH_USER:-$(gh api user -q .login 2>/dev/null)}"
if [ -z "$owner" ]; then
    echo "Cannot determine the GitHub account: set GH_USER or run 'gh auth login'." >&2
    exit 1
fi

git init -b main
git branch -m main
gh repo create ${name} --public --license "MIT"
git remote add origin "git@github.com:${owner}/${name}.git"
git fetch
git add .
git commit -m "Initialize repo via gh"
git rebase origin/main
git push --set-upstream origin main

echo
echo "Added Repo at https://github.com/${owner}/${name}"
