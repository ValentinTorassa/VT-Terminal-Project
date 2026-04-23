#!/usr/bin/env bash
set -euo pipefail

echo "[*] Installing packages for macOS..."

# ---------- Homebrew ----------
if ! command -v brew &>/dev/null; then
  echo "[*] Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  if [[ -f "/opt/homebrew/bin/brew" ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ -f "/usr/local/bin/brew" ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi
fi

echo "[*] Updating Homebrew..."
brew update

# ---------- Oh My Zsh ----------
if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
  echo "[*] Installing Oh My Zsh..."
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi

# ---------- CLI tools via Homebrew ----------
BREW_PACKAGES=(
  # Core
  git
  curl
  wget
  jq

  # Modern replacements
  fzf
  fd
  ripgrep
  bat
  eza
  zoxide
  thefuck
  tldr

  # Git/Docker TUIs
  lazygit
  lazydocker

  # System tools
  dust
  glow
  delta
  yazi
)

echo "[*] Installing CLI tools..."
for pkg in "${BREW_PACKAGES[@]}"; do
  if ! brew list "$pkg" &>/dev/null; then
    echo "  -> $pkg"
    brew install "$pkg" || echo "  [!] Failed to install $pkg, continuing..."
  else
    echo "  -> $pkg (already installed)"
  fi
done

# ---------- Ghostty ----------
if ! brew list --cask ghostty &>/dev/null; then
  echo "[*] Installing Ghostty..."
  brew install --cask ghostty || echo "  [!] Failed to install Ghostty, install manually from https://ghostty.org"
fi

# ---------- Nerd Font ----------
echo "[*] Installing JetBrainsMono Nerd Font..."
brew install --cask font-jetbrains-mono-nerd-font 2>/dev/null || echo "  -> Already installed or failed"

# ---------- fzf key bindings ----------
if [[ -f "$(brew --prefix)/opt/fzf/install" ]]; then
  "$(brew --prefix)/opt/fzf/install" --key-bindings --completion --no-update-rc --no-bash --no-fish
fi

echo "[*] macOS package installation complete!"
