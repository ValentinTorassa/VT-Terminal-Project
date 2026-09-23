#!/usr/bin/env bash
# Tests for scripts/vt. Builds throwaway fixture repos in a temp dir and checks
# what vt resolves, the reasons it gives, the denylist, dry runs and `each`.
# Needs git and jq; never runs npm/uv/cargo/go (only `which` and --dry-run on
# those fixtures). Runs under bash 3.2: /bin/bash tests/vt-test.sh
set -uo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
VT="$ROOT/scripts/vt"
SH="${BASH:-bash}"

for dependency in git jq; do
  if ! command -v "$dependency" >/dev/null 2>&1; then
    echo "vt-test: $dependency is required" >&2
    exit 2
  fi
done

unset VIRTUAL_ENV VT_WORKSPACE
TMP="$(mktemp -d "${TMPDIR:-/tmp}/vt-test.XXXXXX")"
trap 'command rm -rf "$TMP"' EXIT

PASS=0
FAIL=0
OUT=""
RC=0

ok() {
  PASS=$((PASS + 1))
  printf 'ok    %s\n' "$1"
}

not_ok() {
  FAIL=$((FAIL + 1))
  printf 'FAIL  %s\n' "$1"
  if [ -n "${2:-}" ]; then
    printf '%s\n' "$2" | sed 's/^/        /'
  fi
}

# vt <args...>: runs vt, keeps stdout+stderr in OUT and the exit code in RC.
vt() {
  OUT=$("$SH" "$VT" "$@" 2>&1)
  RC=$?
}

# expect_cmd <dir> <command> <expected command line>
expect_cmd() {
  local line status cmd
  line=$("$SH" "$VT" -C "$1" which "$2" --porcelain 2>&1)
  status=$(printf '%s' "$line" | cut -f2)
  cmd=$(printf '%s' "$line" | cut -f4)
  if [ "$status" = run ] && [ "$cmd" = "$3" ]; then
    ok "$(basename "$1") $2 = $3"
  else
    not_ok "$(basename "$1") $2: expected '$3'" "$line"
  fi
}

# expect_status <dir> <command> <status>
expect_status() {
  local line status
  line=$("$SH" "$VT" -C "$1" which "$2" --porcelain 2>&1)
  status=$(printf '%s' "$line" | cut -f2)
  if [ "$status" = "$3" ]; then
    ok "$(basename "$1") $2 is $3"
  else
    not_ok "$(basename "$1") $2: expected status $3" "$line"
  fi
}

expect_rc() {
  if [ "$RC" = "$1" ]; then
    ok "$2 (exit $1)"
  else
    not_ok "$2: expected exit $1, got $RC" "$OUT"
  fi
}

expect_out() {
  case "$OUT" in
    *"$1"*) ok "$2" ;;
    *) not_ok "$2: output lacks '$1'" "$OUT" ;;
  esac
}

expect_no_out() {
  case "$OUT" in
    *"$1"*) not_ok "$2: output has '$1'" "$OUT" ;;
    *) ok "$2" ;;
  esac
}

# repo <name>: a fresh git repo; files are written by the caller, then track.
repo() {
  local d="$TMP/$1"
  mkdir -p "$d"
  git -C "$d" init -q
  printf '%s' "$d"
}

track() { git -C "$1" add -A; }

write() {
  mkdir -p "$(dirname "$1")"
  cat >"$1"
}

# --------------------------------------------------------------------------
# package.json
# --------------------------------------------------------------------------

D=$(repo node-verify)
write "$D/package.json" <<'EOF'
{"scripts": {"verify": "npm run lint && npm test", "lint": "eslint .", "test": "vitest run", "build": "vite build"},
 "devDependencies": {"vitest": "^3.0.0"}}
EOF
echo '{}' >"$D/package-lock.json"
track "$D"
expect_cmd "$D" check "npm run verify"
expect_cmd "$D" test "npm test"
expect_cmd "$D" build "npm run build"
expect_cmd "$D" setup "npm ci"
vt -C "$D" which check
expect_out 'package.json scripts.verify = "npm run lint && npm test"' "which check says which script it came from"

D=$(repo node-chain)
write "$D/package.json" <<'EOF'
{"scripts": {"lint": "eslint .", "typecheck": "tsc --noEmit", "test": "node --test"}}
EOF
track "$D"
expect_cmd "$D" check "npm run lint && npm run typecheck && npm test"
expect_status "$D" setup none
vt -C "$D" which setup
expect_out "declares no dependencies" "setup without dependencies explains itself"

D=$(repo node-app-verify)
write "$D/package.json" <<'EOF'
{"scripts": {"verify": "node src/cli.js verify", "setup": "node src/cli.js setup"},
 "dependencies": {"discord.js": "^14.0.0"}}
EOF
track "$D"
expect_status "$D" check none
vt -C "$D" which check
expect_out "is not used" "an app 'verify' subcommand is not treated as a check"
vt -C "$D" which setup
expect_out "no npm lockfile" "setup refuses to resolve without a lockfile"
expect_no_out "npm run setup" "the package's own 'setup' script is never used"
vt -C "$D" check
expect_rc 3 "check with nothing declared"

D=$(repo node-placeholder)
write "$D/package.json" <<'EOF'
{"scripts": {"test": "echo \"Error: no test specified\" && exit 1"}}
EOF
track "$D"
expect_status "$D" test none

D=$(repo node-pnpm)
write "$D/package.json" <<'EOF'
{"scripts": {"test": "vitest run", "typecheck": "tsc -b"}, "dependencies": {"x": "1"}}
EOF
: >"$D/pnpm-lock.yaml"
track "$D"
expect_cmd "$D" test "pnpm test"
expect_cmd "$D" check "pnpm run typecheck && pnpm test"
expect_cmd "$D" setup "pnpm install --frozen-lockfile"

D=$(repo node-yarn)
write "$D/package.json" <<'EOF'
{"scripts": {"build": "tsc"}, "dependencies": {"x": "1"}}
EOF
: >"$D/yarn.lock"
track "$D"
expect_cmd "$D" build "yarn run build"
expect_cmd "$D" setup "yarn install --frozen-lockfile"

# --------------------------------------------------------------------------
# Python
# --------------------------------------------------------------------------

D=$(repo uv-pytest)
write "$D/pyproject.toml" <<'EOF'
[project]
name = "demo"
dependencies = ["click>=8"]

[project.optional-dependencies]
dev = [
    "pytest>=8.2,<9",
    "ruff>=0.5",
]

[build-system]
requires = ["hatchling"]
build-backend = "hatchling.build"

[tool.ruff]
line-length = 100
EOF
: >"$D/uv.lock"
write "$D/tests/test_demo.py" <<'EOF'
def test_ok():
    assert True
EOF
track "$D"
expect_cmd "$D" setup "uv sync --locked --extra dev"
expect_cmd "$D" test "uv run --locked --extra dev python -m pytest"
expect_cmd "$D" check "uv run --locked --extra dev ruff check && uv run --locked --extra dev python -m pytest"
expect_cmd "$D" build "uv build"

D=$(repo uv-unittest)
write "$D/pyproject.toml" <<'EOF'
[project]
name = "demo"
dependencies = ["mypy>=1"]

[tool.mypy]
strict = true
EOF
: >"$D/uv.lock"
write "$D/tests/test_a.py" <<'EOF'
import unittest
EOF
track "$D"
expect_cmd "$D" test "uv run --locked python -m unittest discover -s tests"
expect_cmd "$D" check "uv run --locked python -m unittest discover -s tests"
vt -C "$D" which check
expect_out "no config sets 'files'" "mypy without a files setting is not guessed"
expect_status "$D" build none

D=$(repo pip-pytest)
printf 'requests\n' >"$D/requirements.txt"
printf 'pytest\n' >"$D/requirements-dev.txt"
write "$D/tests/conftest.py" </dev/null
write "$D/tests/test_x.py" </dev/null
track "$D"
expect_cmd "$D" test "python3 -m pytest"
expect_cmd "$D" setup "python3 -m venv .venv && .venv/bin/python -m pip install -r requirements.txt -r requirements-dev.txt"
mkdir -p "$D/.venv/bin"
printf '#!/bin/sh\n' >"$D/.venv/bin/python"
chmod +x "$D/.venv/bin/python"
expect_cmd "$D" test ".venv/bin/python -m pytest"
expect_cmd "$D" setup ".venv/bin/python -m pip install -r requirements.txt -r requirements-dev.txt"
expect_status "$D" build none

D=$(repo pip-unittest)
write "$D/pyproject.toml" <<'EOF'
[project]
name = "cli"
dependencies = []
EOF
write "$D/tests/test_cli.py" <<'EOF'
import unittest
EOF
track "$D"
expect_cmd "$D" test "python3 -m unittest discover -s tests"
expect_cmd "$D" setup "python3 -m venv .venv && .venv/bin/python -m pip install -e ."

# --------------------------------------------------------------------------
# Rust, Go, Make
# --------------------------------------------------------------------------

D=$(repo cargo-locked)
printf '[package]\nname = "x"\n' >"$D/Cargo.toml"
: >"$D/Cargo.lock"
track "$D"
expect_cmd "$D" test "cargo test --locked"
expect_cmd "$D" build "cargo build --release --locked"
expect_cmd "$D" setup "cargo fetch --locked"

D=$(repo cargo-unlocked)
printf '[package]\nname = "x"\n' >"$D/Cargo.toml"
track "$D"
expect_cmd "$D" test "cargo test"

D=$(repo node-postinstall-cargo)
write "$D/package.json" <<'EOF'
{"scripts": {"postinstall": "cargo build --release"}}
EOF
printf '[package]\nname = "x"\n' >"$D/Cargo.toml"
: >"$D/Cargo.lock"
track "$D"
expect_cmd "$D" check "cargo test --locked"
expect_cmd "$D" setup "cargo fetch --locked"

D=$(repo go-mod)
printf 'module example.com/x\n\ngo 1.24\n' >"$D/go.mod"
track "$D"
expect_cmd "$D" check "go vet ./... && go test ./..."
expect_cmd "$D" test "go test ./..."
expect_cmd "$D" build "go build ./..."
expect_cmd "$D" setup "go mod download"

D=$(repo make-targets)
printf 'check: lint\n\t./lint.sh\n\nlint:\n\techo lint\n\ntest:\n\techo test\n\nbuild:\n\techo build\n\nsetup:\n\techo setup\n' >"$D/Makefile"
track "$D"
expect_cmd "$D" check "make check"
expect_cmd "$D" test "make test"
expect_cmd "$D" build "make build"
expect_status "$D" setup none
vt -C "$D" which setup
expect_out "setup target, but vt setup only runs" "a Makefile setup target is not used"

D=$(repo make-lint-only)
printf 'VAR := x\nlint:\n\techo lint\n' >"$D/Makefile"
track "$D"
expect_status "$D" check none

# --------------------------------------------------------------------------
# Repos without a project file at the root
# --------------------------------------------------------------------------

D=$(repo shell-only)
printf '#!/usr/bin/env bash\necho a\n' >"$D/a.sh"
mkdir -p "$D/bin" "$D/zsh"
printf '#!/usr/bin/env bash\necho tool\n' >"$D/bin/tool"
printf '#!/usr/bin/env zsh\necho z\n' >"$D/bin/zonly"
printf 'echo not a script\n' >"$D/bin/notes"
printf 'alias x=y\n' >"$D/zsh/aliases.zsh"
printf '#!/bin/sh\necho deploy\n' >"$D/deploy.sh"
track "$D"
expect_cmd "$D" check "shellcheck -S warning a.sh bin/tool deploy.sh"
expect_status "$D" test none
expect_status "$D" setup none

D=$(repo monorepo)
write "$D/apps/web/package.json" <<'EOF'
{"scripts": {"test": "vitest run"}}
EOF
mkdir -p "$D/services/api"
printf 'module example.com/svc\n' >"$D/services/api/go.mod"
printf '#!/bin/sh\necho hi\n' >"$D/run.sh"
write "$D/tools/fixtures/pkg/package.json" <<'EOF'
{}
EOF
mkdir -p "$D/apps/web/src"
track "$D"
expect_status "$D" check monorepo
expect_status "$D" setup monorepo
vt -C "$D" which check
expect_out "apps/web" "the monorepo listing names apps/web"
expect_out "services/api" "the monorepo listing names services/api"
expect_no_out "tools/fixtures" "fixture directories are not subprojects"
vt -C "$D" test
expect_rc 3 "a command at a monorepo root runs nothing"
vt -C "$D/apps/web/src" which test --porcelain
case "$OUT" in
  *"npm test"*) ok "vt walks up from a subdirectory to the nearest project file" ;;
  *) not_ok "walk up to apps/web" "$OUT" ;;
esac

D=$(repo py-tests-only)
write "$D/tests/test_gate.py" <<'EOF'
import unittest
EOF
printf '#!/bin/sh\necho x\n' >"$D/sync.sh"
track "$D"
expect_cmd "$D" test "python3 -m unittest discover -s tests"
expect_cmd "$D" check "shellcheck -S warning sync.sh && python3 -m unittest discover -s tests"
expect_status "$D" setup none

D=$(repo empty)
printf '# readme\n' >"$D/README.md"
track "$D"
expect_status "$D" check none
expect_status "$D" build none

# --------------------------------------------------------------------------
# .vt overrides and the denylist
# --------------------------------------------------------------------------

D=$(repo override)
write "$D/package.json" <<'EOF'
{"scripts": {"test": "vitest run", "build": "vite build", "lint": "eslint ."}}
EOF
write "$D/.vt" <<'EOF'
# overrides
test = echo from-vt > vt-ran.txt
check=
build=npm run build && npm run deploy
clean=rm -rf node_modules
bogus=echo nope
not a line
EOF
track "$D"
expect_cmd "$D" test "echo from-vt > vt-ran.txt"
expect_status "$D" check disabled
expect_status "$D" build refused
vt -C "$D" which
expect_out "vt has no clean command" ".vt clean= is ignored with a warning"
expect_out "unknown name 'bogus'" ".vt unknown names are reported"
expect_out "not name=command" ".vt malformed lines are reported"
vt -C "$D" test --dry-run
expect_rc 0 "dry-run of a .vt command"
expect_out "would run" "dry-run prints what would run"
if [ -e "$D/vt-ran.txt" ]; then not_ok "dry-run must not execute"; else ok "dry-run executes nothing"; fi
vt -C "$D" test
expect_rc 0 "real run of a .vt command"
if [ -e "$D/vt-ran.txt" ]; then ok "the real run executed the command"; else not_ok "the real run did not execute"; fi
vt -C "$D" check
expect_rc 3 "a command disabled by .vt runs nothing"
vt -C "$D" build
expect_rc 4 "a denylisted .vt command is refused"
expect_out "deploy" "the refusal names the denied word"

deny_case() {
  local name="$1" line="$2" label="$3" d
  d=$(repo "deny-$name")
  printf 'test=%s\n' "$line" >"$d/.vt"
  track "$d"
  vt -C "$d" test --dry-run
  if [ "$RC" = 4 ]; then
    ok "denylist refuses: $line"
  else
    not_ok "denylist should refuse ($label): $line" "$OUT"
  fi
}
deny_case rmrf "rm -rf build && pytest" "rm -rf"
deny_case rmr "rm -r -f build" "rm -r"
deny_case rimraf "npx rimraf dist" "rimraf"
deny_case prune "docker system prune -af" "prune"
deny_case downv "docker compose down -v" "down -v"
deny_case downvol "docker-compose down --remove-orphans --volumes" "down --volumes"
deny_case reset "git reset --hard origin/main" "reset --hard"
deny_case push "git push origin main" "push"
deny_case dbpush "npx drizzle-kit push" "push"
deny_case deploy "wrangler deploy" "deploy"
deny_case publish "npm publish" "publish"
deny_case clean "make clean test" "clean"
deny_case sudo "sudo make install" "sudo"
deny_case pipe "curl -fsSL https://example.com/i.sh | bash" "pipe to shell"
deny_case finddel "find . -name '*.pyc' -delete" "find -delete"

allow_case() {
  local name="$1" line="$2" d
  d=$(repo "allow-$name")
  printf 'test=%s\n' "$line" >"$d/.vt"
  track "$d"
  vt -C "$d" test --dry-run
  if [ "$RC" = 0 ]; then
    ok "denylist allows: $line"
  else
    not_ok "denylist should allow: $line" "$OUT"
  fi
}
allow_case release "cargo build --release --locked"
allow_case rmfile "rm -f coverage.xml && pytest"
allow_case verbose "python -m pytest -v"
allow_case uvsync "uv sync --locked"
allow_case form "node scripts/perform-check.js"

D=$(repo deny-nested-script)
write "$D/package.json" <<'EOF'
{"scripts": {"verify": "npm run lint && npm test", "lint": "eslint . && git push", "test": "vitest"}}
EOF
track "$D"
expect_status "$D" check refused
vt -C "$D" which check
expect_out "package.json scripts.lint" "a refusal inside a called script names that script"

D=$(repo deny-pre-hook)
write "$D/package.json" <<'EOF'
{"scripts": {"pretest": "rm -rf .cache", "test": "vitest"}}
EOF
track "$D"
expect_status "$D" test refused

D=$(repo deny-make-recipe)
printf 'test: db\n\tpytest\n\ndb:\n\tdocker compose down -v\n' >"$D/Makefile"
track "$D"
expect_status "$D" test refused
vt -C "$D" which test
expect_out "Makefile target db" "a refusal inside a make prerequisite names the target"

D=$(repo deny-setup-lifecycle)
write "$D/package.json" <<'EOF'
{"scripts": {"postinstall": "rm -rf ~/.cache/x"}, "dependencies": {"x": "1"}}
EOF
echo '{}' >"$D/package-lock.json"
track "$D"
expect_status "$D" setup refused

# --------------------------------------------------------------------------
# Command line and `each`
# --------------------------------------------------------------------------

vt clean
expect_rc 2 "vt clean does not exist"
vt frobnicate
expect_rc 2 "unknown commands are usage errors"
vt --help
expect_rc 0 "vt --help"
vt -C "$TMP/node-verify" which bogus
expect_rc 2 "which rejects unknown commands"

WS="$TMP/workspace"
mkdir -p "$WS"
for name in alpha beta gamma delta; do
  mkdir -p "$WS/$name"
  git -C "$WS/$name" init -q
done
printf 'test=true\nsetup=touch setup-ran.txt\n' >"$WS/alpha/.vt"
printf 'test=false\n' >"$WS/beta/.vt"
printf 'test=git push\n' >"$WS/gamma/.vt"
printf '# nothing here\n' >"$WS/delta/README.md"
mkdir -p "$WS/not-a-repo"
for name in alpha beta gamma delta; do track "$WS/$name"; done

vt -C "$WS" check
expect_rc 3 "vt check in a workspace directory runs nothing"
expect_out "is a workspace" "a workspace directory points at vt each"

vt -C "$WS" each which test
expect_rc 0 "each which"
expect_out "alpha" "each which lists alpha"
expect_no_out "not-a-repo" "each only visits git repos"

vt -C "$WS" each test --dry-run
expect_rc 0 "each --dry-run"
expect_out "dry-run" "each --dry-run marks rows as dry-run"

vt -C "$WS" each test
expect_rc 1 "each test fails when a repo fails or is refused"
expect_out "1 pass, 1 fail, 1 skip, 1 refused" "each test counts pass/fail/skip/refused"

vt -C "$WS" each setup
expect_rc 0 "each setup"
expect_out "add --run to install" "each setup is a dry run by default"
if [ -e "$WS/alpha/setup-ran.txt" ]; then not_ok "each setup must not install without --run"; else ok "each setup ran nothing"; fi
vt -C "$WS" each setup --run
if [ -e "$WS/alpha/setup-ran.txt" ]; then ok "each setup --run installs"; else not_ok "each setup --run did not run" "$OUT"; fi

OUT=$(cd "$TMP" && VT_WORKSPACE="$WS" "$SH" "$VT" each which test 2>&1)
case "$OUT" in
  *alpha*) ok "each uses VT_WORKSPACE as the root" ;;
  *) not_ok "each with VT_WORKSPACE" "$OUT" ;;
esac

vt -C "$TMP/node-verify" doctor --dry-run
case "$RC" in
  0 | 1) ok "doctor runs (exit $RC)" ;;
  *) not_ok "doctor exit $RC" "$OUT" ;;
esac
expect_out "check: npm run verify" "doctor lists the resolved commands"

printf '\n%d passed, %d failed\n' "$PASS" "$FAIL"
[ "$FAIL" = 0 ]
