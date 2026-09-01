#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"

bash "$DOTFILES_DIR/scripts/vt-term"

OS="$(uname -s)"

case "$OS" in
  Linux)
    echo "[*] Detected Linux"
    bash "$DOTFILES_DIR/install-linux.sh"
    ;;
  Darwin)
    echo "[*] Detected macOS"
    bash "$DOTFILES_DIR/install-macos.sh"
    ;;
  *)
    echo "[!] Unsupported OS: $OS"
    exit 1
    ;;
esac

echo ""
echo "[*] Running symlink setup..."
bash "$DOTFILES_DIR/scripts/symlink.sh"

echo ""
echo "[*] Installing zsh plugins if missing..."

ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

if [[ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]]; then
  echo "  -> zsh-autosuggestions"
  git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
fi

if [[ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]]; then
  echo "  -> zsh-syntax-highlighting"
  git clone https://github.com/zsh-users/zsh-syntax-highlighting "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
fi

if [[ ! -d "$ZSH_CUSTOM/themes/powerlevel10k" ]]; then
  echo "  -> powerlevel10k"
  git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$ZSH_CUSTOM/themes/powerlevel10k"
fi

echo ""
echo "[*] Installing Ghostty theme..."
mkdir -p "$HOME/.config/ghostty/themes"
if [[ ! -f "$HOME/.config/ghostty/themes/catppuccin-mocha" ]]; then
  curl -sL "https://raw.githubusercontent.com/catppuccin/ghostty/main/themes/catppuccin-mocha.conf" \
    -o "$HOME/.config/ghostty/themes/catppuccin-mocha" &&
    echo "  -> catppuccin-mocha installed" ||
    echo "  [!] Theme download failed"
else
  echo "  -> catppuccin-mocha already installed"
fi

echo ""
echo "[*] Installing terminal commands..."
mkdir -p "$HOME/.local/bin"
ln -sf "$DOTFILES_DIR/scripts/vt-term" "$HOME/.local/bin/vt-term"
ln -sf "$DOTFILES_DIR/scripts/claude-resume" "$HOME/.local/bin/claude-resume"
echo "  -> ~/.local/bin/vt-term"
echo "  -> ~/.local/bin/claude-resume"

echo ""
echo "=================================="
echo "  Setup complete!"
echo "=================================="
echo ""
echo "Next steps:"
echo "  1. Restart your terminal or run: source ~/.zshrc"
echo "  2. Set your Anthropic API key for AI features (ai, aiexplain, aicommit):"
echo "     echo \"export VT_ANTHROPIC_KEY='your-key'\" >> ~/.zshrc.local"
echo "  3. Run 'cheat' to see the keyboard shortcuts cheatsheet"
echo "  4. Run 'vt-term' to print the VT Terminal banner"
echo ""
