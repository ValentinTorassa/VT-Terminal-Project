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

# Downloads go to a private directory from mktemp, not to fixed /tmp paths
# that another local user could create first, and are removed on exit.
DL_DIR=$(mktemp -d "${TMPDIR:-/tmp}/vt-install.XXXXXX") || exit 1
trap 'rm -rf "$DL_DIR"' EXIT

# fetch_verified <url> <sha256> <dest>: downloads <url> and keeps it only if
# its SHA-256 matches. Without a checksum to compare against, it refuses.
fetch_verified() {
  local url="$1" sum="$2" dest="$3"
  if [[ ! "$sum" =~ ^[0-9a-f]{64}$ ]]; then
    echo "  [!] No SHA-256 to verify ${dest##*/} against, not installing it"
    return 1
  fi
  curl -fsSL -o "$dest" "$url" || return 1
  if ! printf '%s  %s\n' "$sum" "$dest" | sha256sum -c --status; then
    echo "  [!] SHA-256 mismatch for ${dest##*/}, not installing it"
    rm -f "$dest"
    return 1
  fi
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
  # dust publishes no checksum file, so the .deb is checked against the
  # SHA-256 GitHub records for the uploaded asset (the API's "digest").
  DUST_URL="" DUST_SUM=""
  read -r DUST_URL DUST_SUM < <(curl -fsSL "https://api.github.com/repos/bootandy/dust/releases/latest" 2>/dev/null |
    jq -r '[.assets[] | select(.name | endswith("_amd64.deb"))][0] // empty
      | "\(.browser_download_url) \((.digest // "") | ltrimstr("sha256:"))"' 2>/dev/null)
  if [[ "$DUST_URL" == https://* ]] &&
    fetch_verified "$DUST_URL" "$DUST_SUM" "$DL_DIR/dust.deb" &&
    sudo dpkg -i "$DL_DIR/dust.deb" 2>&1; then
    echo "  -> dust installed"
  else
    echo "  [!] dust install failed"
  fi
fi

# ---------- Tools that need manual install ----------

# lazygit (not in most repos)
if ! command -v lazygit &>/dev/null; then
  echo "  -> lazygit (from GitHub release)"
  LAZYGIT_TAG=$(curl -fsSL "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" 2>/dev/null | jq -r '.tag_name // empty' 2>/dev/null)
  if [[ -n "$LAZYGIT_TAG" ]]; then
    LAZYGIT_BASE="https://github.com/jesseduffield/lazygit/releases/download/${LAZYGIT_TAG}"
    # The release's checksums.txt gives both the SHA-256 and the asset's
    # exact name (it has been both _Linux_ and _linux_ over the years).
    LAZYGIT_SUM="" LAZYGIT_TGZ=""
    read -r LAZYGIT_SUM LAZYGIT_TGZ < <(curl -fsSL "$LAZYGIT_BASE/checksums.txt" 2>/dev/null |
      awk '!found && tolower($2) ~ /_linux_x86_64\.tar\.gz$/ { print $1, $2; found = 1 }')
    if [[ -n "$LAZYGIT_TGZ" ]] &&
      fetch_verified "$LAZYGIT_BASE/$LAZYGIT_TGZ" "$LAZYGIT_SUM" "$DL_DIR/lazygit.tar.gz" &&
      tar xzf "$DL_DIR/lazygit.tar.gz" -C "$DL_DIR" lazygit &&
      sudo install "$DL_DIR/lazygit" /usr/local/bin/; then
      echo "  -> lazygit installed"
    else
      echo "  [!] lazygit install failed"
    fi
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
      # Ghostty publishes no .deb: ghostty-org/ghostty has no GitHub "latest"
      # release, only tags and a macOS/source "tip" prerelease. Ubuntu 26.04+
      # has it in apt; elsewhere the snap is the prebuilt option that
      # https://ghostty.org/docs/install/binary lists.
      if apt-cache show ghostty &>/dev/null; then
        install_pkg ghostty || echo "  [!] ghostty install failed"
      elif command -v snap &>/dev/null; then
        sudo snap install ghostty --classic || echo "  [!] ghostty snap install failed"
      else
        echo "  [!] Ghostty is not in your apt sources and snap is not installed"
        echo "  [!] Install manually: https://ghostty.org/docs/install/binary"
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
  FONT_BASE="https://github.com/ryanoasis/nerd-fonts/releases/latest/download"
  FONT_SUM=$(curl -fsSL "$FONT_BASE/SHA-256.txt" 2>/dev/null | awk '$2 == "JetBrainsMono.zip" { print $1 }')
  if fetch_verified "$FONT_BASE/JetBrainsMono.zip" "$FONT_SUM" "$DL_DIR/JetBrainsMono.zip"; then
    unzip -o "$DL_DIR/JetBrainsMono.zip" -d "$HOME/.local/share/fonts/JetBrainsMono" > /dev/null
    fc-cache -f
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
