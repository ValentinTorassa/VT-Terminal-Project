# Zed Shortcuts — VT IDE Project

Full reference of every keybinding, CLI script, and prompt shipped with this setup.
Bindings use `ctrl` (Linux). On macOS, press `cmd` wherever you see `ctrl`.

---

## AI Suggestions in Code (auto-on)
Driven by the **Supermaven** extension + Zed's built-in edit predictions.
Both are auto-installed and enabled — no keymap needed for the suggestions themselves,
they appear inline as you type.

| Shortcut | Action |
|----------|--------|
| `Tab` | Accept the inline / edit-prediction suggestion |
| `Esc` | Dismiss the current suggestion |
| `Alt+\\` | Manually trigger an inline completion |

Tweak in `zed/settings.json` via `show_inline_completions`, `show_edit_predictions`,
and `edit_predictions.mode`.

## AI Assistant (custom — `zed/keymap.json`)
| Shortcut | Context | Action |
|----------|---------|--------|
| `Ctrl+Shift+A` | Workspace | Toggle AI agent panel (right dock) |
| `Ctrl+Shift+Enter` | Workspace | Inline AI assist (free-form prompt) |
| `Ctrl+Enter` | Editor | Inline assist on current selection |

## Editing (custom)
| Shortcut | Action |
|----------|--------|
| `Ctrl+Shift+D` | Duplicate line down |
| `Alt+Shift+K` | Delete line |
| `Alt+Up` / `Alt+Down` | Move line up / down |
| `Ctrl+D` | Select next occurrence (multi-cursor) |

## Navigation (custom)
| Shortcut | Action |
|----------|--------|
| `Ctrl+Shift+O` | File finder |
| `Ctrl+Shift+F` | Project-wide search |
| `Ctrl+Shift+G` | Toggle bottom dock |
| `` Ctrl+` `` | Toggle terminal panel |

---

## Layout — principal panels on the right
Outline, git, agent, chat, notifications, debugger, and collaboration are docked
to the right. The project panel stays on the left and tab close buttons are on
the left too. The editor stays centered, the bottom dock stays free for the terminal.

---

## Zed Built-ins (useful defaults, not remapped)
| Shortcut | Action |
|----------|--------|
| `Ctrl+Shift+P` | Command palette |
| `Ctrl+,` | Open settings |
| `Ctrl+K Ctrl+S` | View all keyboard shortcuts |
| `Ctrl+\\` | Toggle right sidebar |
| `Ctrl+J` | Toggle bottom panel |
| `Ctrl+Tab` | Switch between open files |
| `Ctrl+/` | Toggle line comment |
| `Ctrl+Shift+[` / `Ctrl+Shift+]` | Fold / unfold block |

---

## Terminal Scripts (`vt-*`)
Run these in any terminal (system or Zed's integrated). All use the `claude` CLI under the hood.

| Command | What it does |
|---------|--------------|
| `vt-diff` | Explain your current `git diff` (unstaged, staged, or vs branch) |
| `vt-review` | AI code review on staged changes or a branch |
| `vt-conflict` | AI-assisted merge conflict resolution |

> Removed because Zed/MCP already do the same job:
> - **commit messages** → Zed git panel → "Generate commit message"
> - **PR summaries** → GitHub MCP server in the agent panel

### Common `vt-diff` / `vt-review` usage
```bash
vt-diff                  # explain unstaged changes
vt-diff --staged         # explain what you're about to commit
vt-diff --branch main    # explain everything on this branch vs main
vt-diff src/app.ts       # explain changes in one file

vt-review                # review staged changes
vt-review --branch main  # review full branch diff
```

---

## Prompt Library (in `prompts/`)
Drop these into the agent panel or use them via the `claude` CLI.

| Prompt | Purpose |
|--------|---------|
| `/review` | Deep code review — security, performance, correctness |
| `/explain-diff` | Explain what changed and why |
| `/fix-conflict` | Resolve merge conflicts with context |

---

## Extensions (auto-installed via `settings.json`)
| Extension | Purpose |
|-----------|---------|
| `supermaven` | **AI inline completions / snippet suggestions in code** |
| `catppuccin` | Theme (Latte light / Mocha dark) |
| `catppuccin-icons` | Icon theme matching the colour scheme |
| `discord-presence` | Show current file/language in your Discord status |
| `toml`, `dockerfile`, `dotenv`, `basher`, `github-actions` | Language support packs |

---

## Platform Notes

**Linux:** `cmd` keys don't work — the Super/Windows key is captured by your
window manager before Zed sees it. This keymap uses `ctrl` throughout.

**macOS:** `ctrl` and `cmd` are distinct keys. Swap `ctrl` → `cmd` in
`zed/keymap.json` for native feel, or leave as-is (most bindings still fire).

**Discord Presence troubleshooting (Linux):**
- Native Discord: works out of the box (IPC socket at `/run/user/$UID/discord-ipc-0`)
- Flatpak/Snap Discord: IPC socket is sandboxed — symlink it manually or install native
- Enable Discord → Settings → Activity Privacy → "Share detected activities"
