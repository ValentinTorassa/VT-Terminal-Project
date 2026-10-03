# VT IDE Project

```
 ██╗   ██╗████████╗    ██╗██████╗ ███████╗
 ██║   ██║╚══██╔══╝    ██║██╔══██╗██╔════╝
 ██║   ██║   ██║       ██║██║  ██║█████╗
 ╚██╗ ██╔╝   ██║       ██║██║  ██║██╔══╝
  ╚████╔╝    ██║       ██║██████╔╝███████╗
   ╚═══╝     ╚═╝       ╚═╝╚═════╝ ╚══════╝
        AI-native Zed setup · companion to VT Terminal
```

AI-native [Zed](https://zed.dev) setup. Inline AI suggestions as you type, MCP tools wired into the agent panel, every dock pinned to the right, and a theme that doesn't hurt your eyes.

Part of [VT-Terminal-Project](https://github.com/ValentinTorassa/VT-Terminal-Project), under `ide/`. It used to be the separate VT-IDE-Project repo; its history is merged here.

---

## What it does

### AI suggestions in code (inline, as you type)
Powered by **Zeta**, Zed's built-in edit-prediction model - enabled by default, no sign-in required.

| Feature | What you get |
|---------|--------------|
| **Inline completions** | Ghost-text snippet suggestions while you type - accept with `Tab` |
| **Edit predictions** | Multi-line refactor suggestions Zed proposes from your recent edits |
| **Inline assist** | `Ctrl+Enter` on a selection → AI rewrites it in place |
| **Agent panel** | `Ctrl+Shift+A` → full chat with MCP tools attached |

### MCP tools wired into the agent panel
- **GitHub** - query PRs, issues, reviews directly from the agent panel (replaces the old `vt-pr` script)
- **Context7** - up-to-date library docs, kills the stale-training-data problem
- **Serena** - semantic code search + symbol-level edits

### Terminal scripts (Claude-backed, headless)
Kept the ones that work *outside* Zed and don't duplicate built-ins.

| Command | What it gives you |
|---------|-------------------|
| `vt-diff` | Structured summary of your diff: *Summary · Key changes · Impact · Risk* |
| `vt-review` | Code review on staged changes or a branch |
| `vt-conflict` | Merge-conflict resolver with repo context |
| `vt-ide` | Print the VT IDE banner |

> **Removed:** `vt-commit` (Zed's git panel generates commit messages with AI) and `vt-pr` (covered by the GitHub MCP server).

### Layout
Outline, git, agent, chat, notifications, debugger, and collaboration panels are all docked to the right. The project panel sits on the left, tab close buttons on the left. The editor stays the focus, the bottom dock stays free for the terminal.

### Zed setup
Catppuccin theme + icons (system light/dark), Discord presence, language packs for TOML / Dockerfile / `.env` / shell / GitHub Actions, inline git blame, format-on-save, Zeta inline AI predictions.

Full shortcut + script reference: [`cheatsheet/zed-shortcuts.md`](./cheatsheet/zed-shortcuts.md).

---

## Install

```bash
git clone https://github.com/ValentinTorassa/VT-Terminal-Project.git ~/.dotfiles
cd ~/.dotfiles && ./install.sh   # terminal + IDE
./ide/install.sh                 # or only the Zed part
```

`ide/install.sh` symlinks `~/.config/zed/settings.json` and `keymap.json` to `ide/zed/` (a real file already there is backed up as `<name>.backup.<timestamp>`) and the `vt-*` scripts into `~/.local/bin`.

## Requirements
macOS or Linux · Zed v0.200+ · [Claude Code CLI](https://claude.ai/claude-code) · `gh` · `jq` · `delta` · [`uv`](https://docs.astral.sh/uv/) (for Serena)

## MCP auth
- **GitHub**: `export GITHUB_PERSONAL_ACCESS_TOKEN=...` (scopes: `repo`, `read:org`) in `~/.zshrc.local`, launch Zed from that shell
- **Context7 / Serena**: no auth

## Secrets and local-only settings
`ide/zed/settings.json` is public and is the file Zed runs, so keys and private hosts stay out of it:
- Tokens go in `~/.zshrc.local` (sourced by VT Terminal's `.zshrc`, never committed). Zed sees them only when started from that shell (`zed .`).
- Provider API keys entered in Zed's agent settings are kept in the OS keychain, not in `settings.json`.
- For a temporary local tweak (bigger fonts for a recording), replace the symlink with a real file, then relink: `ln -sf ~/.dotfiles/ide/zed/settings.json ~/.config/zed/settings.json`.

## License
GPL-3.0 - see [LICENSE](./LICENSE).
