# Custom Keybindings (defined in this dotfiles)

| Shortcut | Action |
|----------|--------|
| `Ctrl+F` | Fuzzy find file and open in editor |
| `Ctrl+G` | Launch lazygit |
| `Alt+D` | Launch lazydocker |
| `Alt+A` | AI command suggestion (complete/fix current input) |

## AI Commands

| Command | Action |
|---------|--------|
| `ai <question>` | Ask AI for a terminal command |
| `aiexplain [question]` | Explain last output (or pipe: `cmd \| aiexplain "why"`) |
| `aicommit` | Generate AI commit message from staged changes |
| `cr` | Choose a personal/team Claude conversation to resume |
| `cl` | Resume the newest Claude conversation across both accounts |

## Useful Functions

| Command | Action |
|---------|--------|
| `mkcd <dir>` | Create directory and cd into it |
| `fkill` | Fuzzy kill process |
| `serve [port]` | Quick HTTP server (default :8000) |
| `dksh` | Shell into a Docker container (fuzzy select) |
| `cheat [topic]` | View cheatsheet (fuzzy select if no topic) |
| `cheat-add <cat> <key> <desc>` | Add entry to a cheatsheet |
