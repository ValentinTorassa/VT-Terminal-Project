#!/usr/bin/env bash
# One-line install for VT Terminal Project:
#
#   curl -fsSL https://raw.githubusercontent.com/ValentinTorassa/VT-Terminal-Project/v1.0.0/bootstrap.sh | bash
#
# Clones the repository (or updates an existing clone) at a fixed release and runs install.sh.
# Read it before piping it into a shell: it is short.
#
#   VT_TERMINAL_DIR=~/.dotfiles   where the clone lives (default: ~/.dotfiles)
#   VT_TERMINAL_REF=v1.0.0        release tag, branch or commit to check out (default: this release)
#   VT_TERMINAL_NO_INSTALL=1      clone or update only, without running install.sh
#
# Everything runs inside a function called on the last line, so a download cut halfway runs nothing.
set -euo pipefail

vt_bootstrap() {
  local repo="https://github.com/ValentinTorassa/VT-Terminal-Project.git"
  local dir="${VT_TERMINAL_DIR:-$HOME/.dotfiles}"
  local ref="${VT_TERMINAL_REF:-v1.0.0}"

  if ! command -v git >/dev/null 2>&1; then
    echo "[!] git is required" >&2
    exit 1
  fi

  if [[ -d "$dir/.git" ]]; then
    if [[ -n "$(git -C "$dir" status --porcelain)" ]]; then
      echo "[!] $dir has local changes: commit or stash them, then run this again." >&2
      exit 1
    fi
    echo "[*] Updating $dir to $ref"
    git -C "$dir" fetch --quiet --tags origin
  elif [[ -e "$dir" ]]; then
    echo "[!] $dir exists and is not a git clone: set VT_TERMINAL_DIR to another folder." >&2
    exit 1
  else
    echo "[*] Cloning into $dir"
    git clone --quiet "$repo" "$dir"
  fi

  if git -C "$dir" show-ref --verify --quiet "refs/remotes/origin/$ref"; then
    # A branch: follow it, without discarding local commits on it.
    git -C "$dir" checkout --quiet "$ref"
    git -C "$dir" merge --ff-only --quiet "origin/$ref"
  else
    # A release tag or a commit: a fixed version.
    git -C "$dir" checkout --quiet "$ref"
  fi
  echo "[*] $dir is at $(git -C "$dir" describe --tags --always)"

  if [[ "${VT_TERMINAL_NO_INSTALL:-0}" == "1" ]]; then
    echo "[*] Done (install.sh skipped)"
    return
  fi
  bash "$dir/install.sh"
}

vt_bootstrap "$@"
