#!/bin/sh
# Tests for git/hooks: fixture repos in a temp dir, hooks wired through core.hooksPath.
#   sh tests/git-guard-test.sh
set -eu

hooks="$(cd "$(dirname "$0")/../git/hooks" && pwd)"
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
fails=0

ok() { printf 'ok   %s\n' "$1"; }
ko() { printf 'FAIL %s\n' "$1"; fails=$((fails + 1)); }

export GIT_CONFIG_GLOBAL="$tmp/gitconfig"
export GIT_CONFIG_NOSYSTEM=1
git config --global init.defaultBranch main
git config --global core.hooksPath "$hooks"
git config --global user.name Tester
git config --global user.email me@personal.example
git config --global guard.denyEmail '@work\.example$'

git init -q --bare "$tmp/remote.git"
git init -q "$tmp/repo"
cd "$tmp/repo"
git remote add origin "$tmp/remote.git"

# commit-msg strips Claude attribution
printf 'one\n' >a
git add a
git commit -q -m "first

Co-Authored-By: Claude <noreply@anthropic.com>
Claude-Session: https://example.com/s/1"
if git log -1 --format=%B | grep -qi claude; then ko "commit-msg strips trailers"; else ok "commit-msg strips trailers"; fi

# pre-commit refuses a denied author email, allows a good one
printf 'two\n' >>a
git add a
if git -c user.email=me@work.example commit -q -m second 2>/dev/null; then
  ko "pre-commit refuses a denied author email"
else
  ok "pre-commit refuses a denied author email"
fi
if GIT_AUTHOR_EMAIL=Me@WORK.example git commit -q -m second 2>/dev/null; then
  ko "pre-commit match is case-insensitive"
else
  ok "pre-commit match is case-insensitive"
fi
git commit -q -m second
ok "pre-commit allows a good email"

if git push -q origin main 2>/dev/null; then ok "clean push goes through"; else ko "clean push goes through"; fi

# pre-push refuses a denied email that skipped pre-commit
printf 'three\n' >>a
git add a
git -c user.email=me@work.example commit -q --no-verify -m third
if git push -q origin main 2>/dev/null; then ko "pre-push refuses a denied email"; else ok "pre-push refuses a denied email"; fi
git reset -q --hard origin/main

# pre-push refuses a trailer that skipped commit-msg, on a new branch too
git checkout -q -b topic
printf 'four\n' >>a
git add a
git commit -q --no-verify -m "fourth

Co-Authored-By: Claude <noreply@anthropic.com>"
if git push -q origin topic 2>/dev/null; then ko "pre-push refuses a trailer on a new branch"; else ok "pre-push refuses a trailer on a new branch"; fi

# without guard.denyEmail the email check is off
git checkout -q main
git config --global --unset guard.denyEmail
printf 'five\n' >>a
git add a
if git -c user.email=me@work.example commit -q -m fifth 2>/dev/null; then
  ok "no guard.denyEmail, no email check"
else
  ko "no guard.denyEmail, no email check"
fi

[ "$fails" -eq 0 ] || { echo "$fails failed"; exit 1; }
echo "all passed"
