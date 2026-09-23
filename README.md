# VT Terminal Project

```
 ██╗   ██╗████████╗   ████████╗███████╗██████╗ ███╗   ███╗
 ██║   ██║╚══██╔══╝   ╚══██╔══╝██╔════╝██╔══██╗████╗ ████║
 ██║   ██║   ██║         ██║   █████╗  ██████╔╝██╔████╔██║
 ╚██╗ ██╔╝   ██║         ██║   ██╔══╝  ██╔══██╗██║╚██╔╝██║
  ╚████╔╝    ██║         ██║   ███████╗██║  ██║██║ ╚═╝ ██║
   ╚═══╝     ╚═╝         ╚═╝   ╚══════╝╚═╝  ╚═╝╚═╝     ╚═╝
     Personal dotfiles & terminal setup · companion to VT IDE
```

Personal dotfiles and terminal setup for macOS and Linux. One script to bootstrap a new machine with a fully configured terminal environment.

Companion to [VT-IDE-Project](https://github.com/ValentinTorassa/VT-IDE-Project).

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
| `vt-term` | print the VT Terminal banner |
| `cr` | choose and resume any personal/team Claude conversation |
| `cl` | resume the newest Claude conversation across both accounts |
| `vt check` / `vt which` | run or explain a repo's check/test/build (see [vt](#vt-one-command-vocabulary)) |

## AI features

Set `VT_ANTHROPIC_KEY` to enable:

| Command | Action |
|---------|--------|
| `ai "question"` | Get a terminal command suggestion |
| `aiexplain [question]` | Explain last output (or pipe: `cmd \| aiexplain "why"`) |
| `aicommit` | Generate commit message from staged changes |
| `Alt+A` | AI auto-complete current command |
| `cr` | Search Claude history by account, date, and project directory |
| `cl` | Resume the most recently active Claude conversation |

## vt: one command vocabulary

`vt` runs the same five commands in any repo, without adding files to the
repos. It reads what the repo already declares and never invents a command.

```bash
vt check            # lint + typecheck + tests, as the repo declares them
vt test             # the test suite
vt build            # the build
vt setup            # install declared dependencies (lockfile installs only)
vt doctor           # read-only: toolchain on PATH, deps installed, what resolves
vt which [cmd]      # what would run, and which file it came from
vt test --dry-run   # print instead of run (works on every command)
vt -C ~/code/repo check
```

Resolution, first match per command:

| Source | check | test | build | setup |
|--------|-------|------|-------|-------|
| `.vt` override (`name=command` lines) | `check=` | `test=` | `build=` | `setup=` |
| `package.json` scripts | `verify`, else the `lint`/`typecheck`/`test` scripts that exist | `test` | `build` | `npm ci` (or the pnpm/yarn/bun frozen install), only with a lockfile |
| `pyproject.toml` + `uv.lock` | declared ruff/mypy + tests | `uv run --locked python -m pytest` (or `unittest`) | `uv build` | `uv sync --locked` |
| `pyproject.toml` / `requirements*.txt` | declared ruff/mypy + tests | `python -m pytest` if pytest is used, else `unittest` | only if `build` is declared | `pip install` into `.venv` |
| `Cargo.toml` | `cargo test --locked` | `cargo test --locked` | `cargo build --release --locked` | `cargo fetch --locked` |
| `go.mod` | `go vet ./... && go test ./...` | `go test ./...` | `go build ./...` | `go mod download` |
| `Makefile` | `make check` | `make test` | `make build` | not used |
| no project file, nested projects | lists the subprojects, runs nothing | | | |
| no project file | `shellcheck -S warning` on tracked shell scripts + `tests/test_*.py` | `tests/test_*.py` | | |

Details that keep it honest:

- A `verify` script only counts as a check when it calls other scripts or a
  test/lint/typecheck tool; `node src/cli.js verify` (an app subcommand) does not.
- mypy runs only when its config sets `files`; `--extra dev` is added when
  `pyproject.toml` declares a `dev` extra; `--locked` only when the lockfile exists.
- `vt setup` never runs `npm install` without a lockfile, never uses a
  Makefile or package `setup` target, and never installs into the system Python.
- There is no `clean`. A denylist refuses recursive `rm`, `rimraf`,
  `find -delete`, `prune`, `down -v`, `docker rm`, `reset --hard`, `clean`,
  `push`, `deploy`, `publish`, `destroy`, dropping databases, `sudo` and
  piping into a shell. It checks the command, every npm script it calls
  (with pre/post hooks and install lifecycle scripts) and the make recipes it
  runs, and it applies to `.vt` too.

A `.vt` file is optional, for the repos whose files do not say what you mean
(`name=` with nothing after it disables a command):

```
# .vt
test=bash tests/vt-test.sh
check=
```

Across every repo of a workspace (the git repos directly under `-C`,
`$VT_WORKSPACE` or the current directory):

```bash
vt -C ~/Documents/Github/Personal each which        # table: what each repo resolves to
vt -C ~/Documents/Github/Personal each check        # pass/fail/skip table, logs in $TMPDIR
vt each setup                                       # dry run; add --run to install
```

Exit codes: 0 ok, 1 failed, 2 usage, 3 nothing to run, 4 refused.
Tests: `bash tests/vt-test.sh` (fixture repos in a temp dir; also runs on
macOS `/bin/bash` 3.2 in CI).

## License

GPL-3.0 - see [LICENSE](./LICENSE).

## Sesiones y foco

`cheat workflow` abre la rutina de inicio/cierre y el formato de handoff. `wt <tarea>` crea una rama y worktree aislados; `VT_WORKTREE_ROOT` permite elegir dónde guardarlos. Ctrl+T busca desde el directorio actual; `ffall` es la búsqueda explícita de toda la máquina. Eliminar un worktree terminado solo después de revisar su estado y preservar/mergear su trabajo.
