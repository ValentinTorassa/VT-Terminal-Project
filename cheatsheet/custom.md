# Custom Keybindings (defined in this dotfiles)

| Shortcut | Action |
|----------|--------|
| `Ctrl+F` | Fuzzy find file and open in editor |
| `Ctrl+G` | Launch lazygit |
| `Ctrl+X Ctrl+D` | Launch lazydocker |
| `Ctrl+X Ctrl+A` | AI command suggestion (complete/fix current input) |

## AI Commands

| Command | Action |
|---------|--------|
| `ai <question>` | Ask AI for a terminal command |
| `aiexplain <question>` | Pipe output to AI: `cmd \| aiexplain "why"` |
| `aicommit` | Generate AI commit message from staged changes |

## Useful Functions

| Command | Action |
|---------|--------|
| `mkcd <dir>` | Create directory and cd into it |
| `fkill` | Fuzzy kill process |
| `serve [port]` | Quick HTTP server (default :8000) |
| `dksh` | Shell into a Docker container (fuzzy select) |
| `cheat [topic]` | View cheatsheet (fuzzy select if no topic) |
| `cheat-add <cat> <key> <desc>` | Add entry to a cheatsheet |
