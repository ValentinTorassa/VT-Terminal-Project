# VT IDE Project

AI-native [Zed](https://zed.dev) setup. Claude-powered git scripts, MCP tools in the editor, and a theme that doesn't hurt your eyes.

Companion to [VT-Terminal-Project](https://github.com/ValentinTorassa/VT-Terminal-Project).

---

## What it does

### Terminal scripts (all Claude-backed)
| Command | What it gives you |
|---------|-------------------|
| `vt-diff` | Structured summary of your diff: *Summary · Key changes · Impact · Risk* |
| `vt-review` | Code review on staged changes or a branch |
| `vt-commit` | Conventional-Commits message from your staged diff |
| `vt-conflict` | Merge-conflict resolver with repo context |
| `vt-pr <n>` | Summarize any GitHub PR |

### In-editor AI (Zed)
| Shortcut | Action |
|----------|--------|
| `Ctrl+Shift+A` | Toggle AI panel |
| `Ctrl+Enter` | Inline assist on selection |
| `Ctrl+Shift+Enter` | Free-form inline prompt |

Full list: [`cheatsheet/zed-shortcuts.md`](./cheatsheet/zed-shortcuts.md).

### MCP tools wired into the AI panel
- **GitHub** — query PRs, issues, reviews directly from the AI panel
- **Context7** — up-to-date library docs, kills the stale-training-data problem
- **Serena** — semantic code search + symbol-level edits

### Zed setup
Catppuccin theme + icons (system light/dark), Discord presence, language packs for TOML / Dockerfile / `.env` / shell / GitHub Actions, inline git blame, format-on-save.

---

## Install

```bash
git clone https://github.com/ValentinTorassa/VT-IDE-Project.git ~/.ide-config
cd ~/.ide-config && ./install.sh
```

## Requirements
macOS or Linux · Zed v0.200+ · [Claude Code CLI](https://claude.ai/claude-code) · `gh` · `jq` · `delta` · [`uv`](https://docs.astral.sh/uv/) (for Serena)

## MCP auth
- **GitHub**: `export GITHUB_PERSONAL_ACCESS_TOKEN=...` (scopes: `repo`, `read:org`), launch Zed from that shell
- **Context7 / Serena**: no auth

## License
GPL-3.0 — see [LICENSE](./LICENSE).
