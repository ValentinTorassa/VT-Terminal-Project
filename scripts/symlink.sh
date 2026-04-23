#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "$0")/.." && pwd)"

echo "[*] Creating symlinks..."

backup_and_link() {
  local src="$1"
  local dest="$2"

  if [[ -e "$dest" && ! -L "$dest" ]]; then
    echo "  [!] Backing up existing $dest -> ${dest}.backup"
    mv "$dest" "${dest}.backup"
  fi

  if [[ -L "$dest" ]]; then
    rm "$dest"
  fi

  ln -s "$src" "$dest"
  echo "  -> $src => $dest"
}

# Zsh
backup_and_link "$DOTFILES_DIR/zsh/.zshrc" "$HOME/.zshrc"

# P10k
if [[ -f "$DOTFILES_DIR/zsh/.p10k.zsh" ]]; then
  backup_and_link "$DOTFILES_DIR/zsh/.p10k.zsh" "$HOME/.p10k.zsh"
fi

# Git (only link if user doesn't have custom name/email set)
if [[ -f "$HOME/.gitconfig" ]]; then
  echo "  [!] ~/.gitconfig exists. Merging aliases only (preserving your name/email)..."
  git config --global include.path "$DOTFILES_DIR/git/.gitconfig"
  echo "  -> Added include.path for dotfiles gitconfig"
else
  backup_and_link "$DOTFILES_DIR/git/.gitconfig" "$HOME/.gitconfig"
fi

# Ghostty config
if [[ -f "$DOTFILES_DIR/ghostty/config" ]]; then
  if [[ "$(uname -s)" == "Darwin" ]]; then
    mkdir -p "$HOME/Library/Application Support/com.mitchellh.ghostty"
    backup_and_link "$DOTFILES_DIR/ghostty/config" "$HOME/Library/Application Support/com.mitchellh.ghostty/config"
  else
    mkdir -p "$HOME/.config/ghostty"
    backup_and_link "$DOTFILES_DIR/ghostty/config" "$HOME/.config/ghostty/config"
  fi
fi

# Export DOTFILES_DIR so cheatsheet and functions find it
echo "  -> Setting DOTFILES_DIR=$DOTFILES_DIR"
if ! grep -q "DOTFILES_DIR" "$DOTFILES_DIR/zsh/.zshrc"; then
  echo "export DOTFILES_DIR=\"$DOTFILES_DIR\"" >> "$DOTFILES_DIR/zsh/.zshrc"
fi

echo "[*] Symlinks created!"
