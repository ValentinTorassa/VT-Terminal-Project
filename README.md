# VT Terminal Project

Personal dotfiles and terminal setup for macOS and Linux. One script to bootstrap a new machine with a fully configured terminal environment.

Companion to [VT-IDE-Project](https://github.com/ValentinTorassa/VT-IDE-Project) - same philosophy, but for the editor layer.

## What's included

- **Zsh** with Oh My Zsh + Powerlevel10k
- **Ghostty** terminal emulator config (catppuccin-mocha theme)
- **Modern CLI tools**: eza, bat, fzf, ripgrep, zoxide, delta, dust, thefuck, tldr
- **TUI tools**: lazygit, lazydocker
- **AI shell assistant**: command suggestions, output explanation, commit message generation
- **Fuzzy cheatsheets**: searchable keyboard shortcut reference

## Quick start

```bash
git clone https://github.com/ValentinTorassa/vt-terminal-project.git ~/.dotfiles
cd ~/.dotfiles
./install.sh
```

## Keybindings

| Shortcut | Action |
|----------|--------|
| `Ctrl+F` | Fuzzy find file and open in editor |
| `Ctrl+G` | Launch lazygit |
| `Alt+D` | Launch lazydocker |
| `Alt+A` | AI auto-complete current command |
| `Ctrl+R` | Fuzzy search command history |
| `Ctrl+T` | Fuzzy find file |
| `Ctrl+Shift+O` | Ghostty: split horizontal |
| `Ctrl+Shift+E` | Ghostty: split vertical |

## Useful commands

| Command | Action |
|---------|--------|
| `lg` | lazygit |
| `dkl` | lazydocker |
| `dkcu` / `dkcd` | docker compose up / down |
| `dksh` | shell into container (fuzzy select) |
| `fkill` | fuzzy kill process |
| `mkcd` | create directory and cd into it |
| `serve` | quick HTTP server |
| `cheat` | browse shortcut cheatsheets |
| `z <dir>` | smart cd (zoxide) |
| `ll` | list files with icons and git status |
| `git diff` | see changes (side-by-side with delta) |

## AI features

Set `VT_ANTHROPIC_KEY` to enable:

| Command | Action |
|---------|--------|
| `ai "question"` | Get a terminal command suggestion |
| `aiexplain [question]` | Explain last output (or pipe: `cmd \| aiexplain "why"`) |
| `aicommit` | Generate commit message from staged changes |
| `Alt+A` | AI auto-complete current command |
