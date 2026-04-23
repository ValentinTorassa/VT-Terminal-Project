# VT Terminal Project

Personal dotfiles and terminal setup for macOS and Linux. One script to bootstrap a new machine with a fully configured terminal environment.

## What's included

- **Zsh** with Oh My Zsh + Powerlevel10k
- **Ghostty** terminal emulator config (catppuccin-mocha theme)
- **Modern CLI tools**: eza, bat, fzf, ripgrep, zoxide, delta, dust, thefuck, tldr
- **TUI tools**: lazygit, lazydocker
- **AI shell assistant**: command suggestions, output explanation, commit message generation (requires Anthropic API key)
- **Fuzzy cheatsheets**: searchable keyboard shortcut reference for terminal, git, docker, ghostty

## Quick start

```bash
git clone https://github.com/ValentinTorassa/vt-terminal-project.git ~/.dotfiles
cd ~/.dotfiles
./install.sh
```

## Structure

```
├── install.sh              # Entry point (detects OS)
├── install-linux.sh        # apt/dnf/pacman installer
├── install-macos.sh        # Homebrew installer
├── zsh/                    # Zsh config (modular)
│   ├── .zshrc
│   ├── .p10k.zsh
│   ├── aliases.zsh
│   ├── functions.zsh
│   ├── ai.zsh
│   └── keybindings.zsh
├── ghostty/config          # Ghostty terminal config
├── git/.gitconfig          # Git aliases and delta integration
├── cheatsheet/             # Fuzzy-searchable shortcut cheatsheets
└── scripts/
    ├── symlink.sh          # Links configs to $HOME
    └── uninstall.sh        # Reverts everything
```

## AI features

Set `ANTHROPIC_API_KEY` to enable:

- `ai "question"` — get a terminal command suggestion
- `cmd | aiexplain "question"` — explain piped output
- `aicommit` — generate commit message from staged changes
- `Ctrl+X Ctrl+A` — AI auto-complete current command
