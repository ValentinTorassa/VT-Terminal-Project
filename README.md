# VT IDE Project

Personal IDE setup for macOS. Zed editor + Claude AI agent + AI-powered git workflows.

Companion to [VT-Terminal-Project](https://github.com/ValentinTorassa/VT-Terminal-Project) - same philosophy, but for the editor layer.

## What's included

### Zed Configuration
- Editor settings optimized for speed and readability
- Custom keybindings for git workflows and AI commands (Linux-friendly `ctrl` bindings — see [cheatsheet](./cheatsheet/zed-shortcuts.md))
- Catppuccin theme + icons (Latte for light, Mocha for dark)
- Extension management (Catppuccin, Catppuccin Icons, Discord Presence)

### AI Agent Integration
- Claude Agent via ACP (Agent Client Protocol) in Zed
- Custom prompt library for the AI assistant
- Inline code review, diff explanation, and conflict resolution

### AI Workflow Scripts
- `vt-pr` — Fetch and summarize any PR with AI
- `vt-diff` — Show current diff with AI-generated explanation
- `vt-review` — AI code review on staged changes or a branch
- `vt-conflict` — AI-assisted merge conflict resolution
- `vt-commit` — Generate smart commit messages from staged changes

### Prompt Library
- `/review` — Deep code review with security and performance analysis
- `/explain-diff` — Explain what changed and why
- `/fix-conflict` — Resolve merge conflicts with context
- `/pr-summary` — Generate PR title and description

## Quick Setup

```bash
git clone https://github.com/ValentinTorassa/VT-IDE-Project.git ~/.ide-config
cd ~/.ide-config
./install.sh
```

## Repository Structure

```
.
├── zed/
│   ├── settings.json        # Editor configuration
│   └── keymap.json           # Custom keybindings
├── prompts/
│   ├── review.md             # Code review prompt
│   ├── explain-diff.md       # Diff explanation prompt
│   ├── fix-conflict.md       # Merge conflict resolver prompt
│   └── pr-summary.md         # PR summary generator prompt
├── scripts/
│   ├── vt-pr                 # PR summary tool
│   ├── vt-diff               # AI diff explainer
│   ├── vt-review             # AI code reviewer
│   ├── vt-conflict           # Merge conflict solver
│   └── vt-commit             # Smart commit message generator
├── cheatsheet/
│   └── zed-shortcuts.md      # Searchable keybinding reference
├── install.sh                # One-command setup
└── README.md
```

## Requirements

- macOS (Apple Silicon) or Linux
- [Zed](https://zed.dev) (v0.200+)
- [GitHub CLI](https://cli.github.com/) (`gh`)
- [Claude Code](https://claude.ai/claude-code) CLI (for AI scripts)
- [jq](https://jqlang.github.io/jq/) (for JSON processing)
- [delta](https://github.com/dandavella/delta) (for pretty diffs)

## License

MIT

