#!/usr/bin/env bash
# create git repo using gh
#
# The shebang used to sit on line 2, under this comment. The kernel only reads
# line 1, so `./gh_create_repo.sh` was executed by /bin/sh, not bash — it
# happened to work only because nothing below is bash-specific.

name=${1:-${PWD##*/}}

git init -b main
git branch -m main
gh repo create ${name} --public --license "MIT"
git remote add origin "git@github.com:${GH_USER:-durante-tech}/${name}.git"
git fetch
git add .
git commit -m "Initialize repo via gh"
git rebase origin/main
git push --set-upstream origin main

echo
echo "Added Repo at https://github.com/${GH_USER:-durante-tech}/${name}"
