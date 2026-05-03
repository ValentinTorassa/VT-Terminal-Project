#!/usr/bin/env bash
# VT IDE Project — Installer
# One-command setup for Zed + AI workflows
set -euo pipefail

YELLOW='\033[1;33m'
CYAN='\033[1;36m'
GREEN='\033[1;32m'
RED='\033[1;31m'
DIM='\033[2m'
BOLD='\033[1m'
RESET='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ZED_CONFIG_DIR="$HOME/.config/zed"
BIN_DIR="$HOME/.local/bin"

echo -e "${BOLD}${CYAN}"
echo "╔══════════════════════════════════════╗"
echo "║        VT IDE Project Setup          ║"
echo "║   Zed + Claude AI + Git Workflows    ║"
echo "╚══════════════════════════════════════╝"
echo -e "${RESET}"

# ── Helper functions ──────────────────────────────────────────

info()    { echo -e "${CYAN}[info]${RESET} $1"; }
success() { echo -e "${GREEN}[done]${RESET} $1"; }
warn()    { echo -e "${YELLOW}[warn]${RESET} $1"; }
fail()    { echo -e "${RED}[fail]${RESET} $1"; exit 1; }

backup_file() {
  local file="$1"
  if [[ -f "$file" && ! -L "$file" ]]; then
    local backup="${file}.backup.$(date +%Y%m%d%H%M%S)"
    cp "$file" "$backup"
    info "Backed up existing $(basename "$file") → $(basename "$backup")"
  fi
}

symlink() {
  local src="$1"
  local dst="$2"
  backup_file "$dst"
  ln -sf "$src" "$dst"
  success "Linked $(basename "$src") → $dst"
}

# ── Check platform ───────────────────────────────────────────

case "$(uname)" in
  Darwin|Linux) ;;
  *) warn "Untested platform: $(uname). Some features may not work." ;;
esac

# Per-OS install hint helper (e.g. Homebrew on macOS, apt on Debian/Ubuntu).
brew_or_apt() {
  if [[ "$(uname)" == "Darwin" ]]; then
    echo "brew install $1"
  else
    echo "sudo apt install $1  # or your distro's equivalent"
  fi
}

# ── Check dependencies ───────────────────────────────────────

echo -e "\n${BOLD}Checking dependencies...${RESET}\n"

MISSING=()

check_dep() {
  local cmd="$1"
  local name="${2:-$1}"
  local install_hint="${3:-}"
  if command -v "$cmd" &>/dev/null; then
    success "$name $(command -v "$cmd")"
  else
    warn "$name not found${install_hint:+ — $install_hint}"
    MISSING+=("$name")
  fi
}

check_dep "zed"  "Zed CLI" "Install from https://zed.dev or run: Zed → command palette → 'install cli'"
check_dep "gh"   "GitHub CLI" "$(brew_or_apt gh)"
check_dep "claude" "Claude Code" "npm install -g @anthropic-ai/claude-code"
check_dep "jq"   "jq" "$(brew_or_apt jq)"
check_dep "delta" "delta" "$(brew_or_apt git-delta)"
check_dep "git"  "git"

if [[ ${#MISSING[@]} -gt 0 ]]; then
  echo ""
  warn "Missing ${#MISSING[@]} dependency(ies). Install them for full functionality."
  echo -e "${DIM}The installer will continue, but some features won't work until dependencies are installed.${RESET}"
fi

# ── Install Zed config ──────────────────────────────────────

echo -e "\n${BOLD}Setting up Zed configuration...${RESET}\n"

mkdir -p "$ZED_CONFIG_DIR"

symlink "$SCRIPT_DIR/zed/settings.json" "$ZED_CONFIG_DIR/settings.json"
symlink "$SCRIPT_DIR/zed/keymap.json"   "$ZED_CONFIG_DIR/keymap.json"

# ── Install VT scripts to PATH ──────────────────────────────

echo -e "\n${BOLD}Installing VT workflow scripts...${RESET}\n"

mkdir -p "$BIN_DIR"

# Remove stale vt-* symlinks pointing to scripts no longer in this repo.
for link in "$BIN_DIR"/vt-*; do
  [[ -L "$link" ]] || continue
  target="$(readlink "$link")"
  if [[ "$target" == "$SCRIPT_DIR/scripts/"* && ! -e "$target" ]]; then
    rm "$link"
    info "Removed stale symlink $(basename "$link")"
  fi
done

for script in "$SCRIPT_DIR"/scripts/vt-*; do
  script_name="$(basename "$script")"
  symlink "$script" "$BIN_DIR/$script_name"
done

# Ensure ~/.local/bin is in PATH
if [[ ":$PATH:" != *":$BIN_DIR:"* ]]; then
  warn "$BIN_DIR is not in your PATH"

  SHELL_RC=""
  if [[ -f "$HOME/.zshrc" ]]; then
    SHELL_RC="$HOME/.zshrc"
  elif [[ -f "$HOME/.bashrc" ]]; then
    SHELL_RC="$HOME/.bashrc"
  fi

  if [[ -n "$SHELL_RC" ]]; then
    # Check if already added
    if ! grep -q 'VT IDE Project' "$SHELL_RC" 2>/dev/null; then
      echo '' >> "$SHELL_RC"
      echo '# VT IDE Project — workflow scripts' >> "$SHELL_RC"
      echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$SHELL_RC"
      success "Added $BIN_DIR to PATH in $(basename "$SHELL_RC")"
      info "Run 'source $SHELL_RC' or restart your terminal to apply"
    fi
  else
    warn "Add this to your shell config: export PATH=\"\$HOME/.local/bin:\$PATH\""
  fi
fi

# ── Zed extensions ──────────────────────────────────────────
# These are declared in zed/settings.json under auto_install_extensions and
# Zed picks them up on next launch — this section is informational only.

echo -e "\n${BOLD}Zed extensions (auto-installed on next Zed launch):${RESET}\n"

EXTENSIONS=(catppuccin catppuccin-icons discord-presence toml dockerfile dotenv basher github-actions)
for ext in "${EXTENSIONS[@]}"; do
  info "$ext"
done
info "If any are missing after launch, install via: Zed → command palette → 'zed: extensions'"

# ── Summary ─────────────────────────────────────────────────

echo -e "\n${BOLD}${GREEN}"
echo "╔══════════════════════════════════════╗"
echo "║          Setup Complete!             ║"
echo "╚══════════════════════════════════════╝"
echo -e "${RESET}"

echo -e "${BOLD}What was installed:${RESET}"
echo -e "  ${GREEN}✓${RESET} Zed settings and keybindings (panels docked right, AI suggestions on)"
echo -e "  ${GREEN}✓${RESET} VT workflow scripts (vt-diff, vt-review, vt-conflict)"
echo ""
echo -e "${BOLD}Quick start:${RESET}"
echo -e "  ${CYAN}vt-diff${RESET}       Explain your current changes"
echo -e "  ${CYAN}vt-review${RESET}     AI code review"
echo -e "  ${CYAN}vt-conflict${RESET}   Resolve merge conflicts"
echo -e "  ${DIM}(commit messages → Zed git panel · PR triage → GitHub MCP in agent panel)${RESET}"
echo ""
echo -e "${DIM}Cheatsheet: cat $(basename "$SCRIPT_DIR")/cheatsheet/zed-shortcuts.md${RESET}"
