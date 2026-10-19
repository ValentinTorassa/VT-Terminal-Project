# Changelog

Releases follow [Semantic Versioning](https://semver.org). Each release is a git tag; its notes are
the section below with the same version.

## [1.0.0] - 2026-10-19

First tagged release: six months of the setup in daily use on macOS and Linux.

### Terminal and shell
- Zsh with Oh My Zsh and Powerlevel10k, Ghostty with Catppuccin Mocha.
- Modern CLI tools wired in: eza, bat, fzf, ripgrep, zoxide, delta (git pager with styled diffs and
  git aliases), dust, thefuck, tldr, plus lazygit and lazydocker.
- Fuzzy, searchable cheatsheets (`cheat`), including the start/close session routine.
- `wt <task>` creates an isolated branch and worktree; Ctrl+T searches from the current directory and
  `ffall` across the whole machine.
- `vt-term` banner on install.

### AI in the shell
- `ai`, `aiexplain`, `aicommit` and Alt+A completion, enabled with `VT_ANTHROPIC_KEY`.
- `cr` searches Claude history by account, date and project; `cl` resumes the latest conversation.
- Interactive agents (Codex, Gemini) keep their TTY: the output-capture hook skips them.

### `vt`: one command vocabulary
- The same five commands in any repository, read from what the repository already declares; it
  never invents a command and adds no files to the repositories.

### Zed IDE (`ide/`)
- Settings and keymap (Linux-friendly), Catppuccin Frappé, language extensions and three MCP servers.
- `vt-diff`, `vt-review` and `vt-conflict`, Claude-backed review scripts that hold up on large diffs.
- VT-IDE-Project merged in with its full history.

### Git guard hooks
- `git/hooks/`, installed per folder through `core.hooksPath`: `commit-msg` strips Claude
  attribution lines, `pre-push` refuses commits that still carry them, and every other hook runs the
  repository's own.

### Install and CI
- One-line install: `bootstrap.sh` clones a fixed release and runs `install.sh`.
- Linux installer with verified downloads in a temporary directory, Ghostty from apt or snap.
- CI: ShellCheck on the installers and scripts, Zed JSONC validation, `vt` tests on Linux and on
  macOS's Bash 3.2, CodeQL, actions pinned by SHA, Ubuntu image pinned to 24.04.
- GPL-3.0 license.

[1.0.0]: https://github.com/ValentinTorassa/VT-Terminal-Project/releases/tag/v1.0.0
