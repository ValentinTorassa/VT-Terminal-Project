#!/usr/bin/env bash
set -uo pipefail

echo "[*] Installing packages for Linux..."

# Detect package manager
if command -v apt &>/dev/null; then
  PM="apt"
elif command -v dnf &>/dev/null; then
  PM="dnf"
elif command -v pacman &>/dev/null; then
  PM="pacman"
else
  echo "[!] No supported package manager found (apt, dnf, pacman)"
  exit 1
fi

install_pkg() {
  case "$PM" in
    apt)    sudo apt install -y "$@" ;;
    dnf)    sudo dnf install -y "$@" ;;
    pacman) sudo pacman -S --noconfirm "$@" ;;
  esac
}

try_install() {
  local name="$1"
  shift
  echo "  -> $name"
  if ! "$@"; then
    echo "  [!] $name install failed (non-fatal, continuing)"
  fi
}

echo "[*] Updating package lists..."
case "$PM" in
  apt)    sudo apt update 2>&1 || echo "  [!] apt update had warnings (non-fatal)" ;;
  dnf)    sudo dnf check-update || true ;;
  pacman) sudo pacman -Sy || true ;;
esac

# ---------- Core tools ----------
echo "[*] Installing core tools..."
install_pkg git curl wget jq unzip zsh || true

# ---------- Oh My Zsh ----------
if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
  echo "[*] Installing Oh My Zsh..."
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended || true
fi

# ---------- Modern CLI tools ----------
echo "[*] Installing modern CLI tools..."

# Install packages one by one so a missing package doesn't block the rest
APT_PACKAGES=(fzf fd-find ripgrep bat eza zoxide xclip thefuck tldr-py git-delta)
DNF_PACKAGES=(fzf fd-find ripgrep bat eza zoxide xclip thefuck tldr glow git-delta)
PACMAN_PACKAGES=(fzf fd ripgrep bat eza zoxide xclip thefuck tldr glow git-delta dust)

case "$PM" in
  apt)
    echo "[*] Installing from apt repos (one by one)..."
    for pkg in "${APT_PACKAGES[@]}"; do
      if dpkg -s "$pkg" &>/dev/null; then
        echo "  -> $pkg (already installed)"
      else
        echo "  -> $pkg"
        sudo apt install -y "$pkg" 2>&1 || echo "  [!] $pkg not available, skipping"
      fi
    done

    # bat is 'batcat' on Debian, create symlink
    if command -v batcat &>/dev/null && ! command -v bat &>/dev/null; then
      mkdir -p "$HOME/.local/bin"
      ln -sf "$(which batcat)" "$HOME/.local/bin/bat"
      echo "  -> Created bat symlink for batcat"
    fi
    ;;
  dnf)
    echo "[*] Installing from dnf repos..."
    for pkg in "${DNF_PACKAGES[@]}"; do
      echo "  -> $pkg"
      sudo dnf install -y "$pkg" 2>&1 || echo "  [!] $pkg not available, skipping"
    done
    ;;
  pacman)
    echo "[*] Installing from pacman repos..."
    for pkg in "${PACMAN_PACKAGES[@]}"; do
      echo "  -> $pkg"
      sudo pacman -S --noconfirm "$pkg" 2>&1 || echo "  [!] $pkg not available, skipping"
    done
    ;;
esac

# ---------- Tools not in standard repos, install manually ----------

# glow (markdown renderer - charm.sh repo for apt)
if ! command -v glow &>/dev/null; then
  echo "  -> glow (from charm.sh repo)"
  case "$PM" in
    apt)
      sudo mkdir -p /etc/apt/keyrings
      curl -fsSL https://repo.charm.sh/apt/gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/charm.gpg 2>/dev/null || true
      echo "deb [signed-by=/etc/apt/keyrings/charm.gpg] https://repo.charm.sh/apt/ * *" | sudo tee /etc/apt/sources.list.d/charm.list > /dev/null
      sudo apt update 2>&1 || true
      sudo apt install -y glow 2>&1 || echo "  [!] glow install failed"
      ;;
  esac
fi

# dust (directory size)
if ! command -v dust &>/dev/null; then
  echo "  -> dust (from GitHub release)"
  DUST_VERSION=$(curl -s "https://api.github.com/repos/bootandy/dust/releases/latest" | jq -r '.tag_name' 2>/dev/null)
  if [[ -n "$DUST_VERSION" && "$DUST_VERSION" != "null" ]]; then
    curl -Lo /tmp/dust.deb "https://github.com/bootandy/dust/releases/download/${DUST_VERSION}/du-dust_${DUST_VERSION#v}-1_amd64.deb" 2>&1 &&
    sudo dpkg -i /tmp/dust.deb 2>&1 &&
    rm -f /tmp/dust.deb &&
    echo "  -> dust installed" ||
    echo "  [!] dust install failed"
  fi
fi

# ---------- Tools that need manual install ----------

# lazygit (not in most repos)
if ! command -v lazygit &>/dev/null; then
  echo "  -> lazygit (from GitHub release)"
  LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | jq -r '.tag_name' | sed 's/^v//')
  if [[ -n "$LAZYGIT_VERSION" && "$LAZYGIT_VERSION" != "null" ]]; then
    curl -Lo /tmp/lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz" &&
    tar xf /tmp/lazygit.tar.gz -C /tmp lazygit &&
    sudo install /tmp/lazygit /usr/local/bin/ &&
    rm -f /tmp/lazygit /tmp/lazygit.tar.gz &&
    echo "  -> lazygit installed" ||
    echo "  [!] lazygit install failed"
  fi
fi

# zed editor
if ! command -v zed &>/dev/null; then
  echo "  -> zed"
  curl -fsS https://zed.dev/install.sh | sh 2>&1 || echo "  [!] zed install failed"
fi

# lazydocker (not in most repos)
if ! command -v lazydocker &>/dev/null; then
  echo "  -> lazydocker (from GitHub release)"
  curl -s https://raw.githubusercontent.com/jesseduffield/lazydocker/master/scripts/install_update_linux.sh | bash 2>&1 || echo "  [!] lazydocker install failed"
fi

# Ghostty terminal emulator
if ! command -v ghostty &>/dev/null; then
  echo "  -> ghostty"
  case "$PM" in
    apt)
      GHOSTTY_DEB_URL=$(curl -s "https://api.github.com/repos/ghostty-org/ghostty/releases/latest" | jq -r '.assets[] | select(.name | endswith("_amd64.deb")) | .browser_download_url // empty' 2>/dev/null)
      if [[ -n "$GHOSTTY_DEB_URL" ]]; then
        curl -Lo /tmp/ghostty.deb "$GHOSTTY_DEB_URL" &&
        sudo dpkg -i /tmp/ghostty.deb || sudo apt install -f -y
        rm -f /tmp/ghostty.deb
      else
        echo "  [!] Ghostty .deb not found in latest release"
        echo "  [!] Install manually: https://ghostty.org/docs/install"
      fi
      ;;
    dnf)
      sudo dnf copr enable -y pgdev/ghostty 2>/dev/null && install_pkg ghostty || echo "  [!] Install Ghostty manually: https://ghostty.org/docs/install"
      ;;
    pacman)
      install_pkg ghostty 2>/dev/null || echo "  [!] Install Ghostty from AUR: yay -S ghostty"
      ;;
  esac
fi

# JetBrainsMono Nerd Font (needed for Ghostty + Powerlevel10k)
if ! fc-list 2>/dev/null | grep -qi "JetBrainsMono Nerd"; then
  echo "  -> JetBrainsMono Nerd Font"
  mkdir -p "$HOME/.local/share/fonts"
  if curl -Lo /tmp/JetBrainsMono.zip "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip"; then
    unzip -o /tmp/JetBrainsMono.zip -d "$HOME/.local/share/fonts/JetBrainsMono" > /dev/null
    fc-cache -f
    rm -f /tmp/JetBrainsMono.zip
    echo "  -> Font installed"
  else
    echo "  [!] Font download failed"
  fi
fi

# yazi (optional)
if ! command -v yazi &>/dev/null; then
  echo "  -> yazi (optional, install manually: https://yazi-rs.github.io/docs/installation)"
fi

echo "[*] Linux package installation complete!"
