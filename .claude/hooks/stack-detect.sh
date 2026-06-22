#!/usr/bin/env bash
# SessionStart hook: inspect repo root, detect tech stack, write .claude/stack-profile.json.
# B1–B5 per harness system instructions. Non-blocking — exit 0 always.
# Cross-platform: requires POSIX bash. Windows: use WSL2 or Git Bash.

set -euo pipefail

REPO_ROOT="${CLAUDE_PROJECT_DIR:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
PROFILE="$REPO_ROOT/.claude/stack-profile.json"

# ── B1: Package manager ──────────────────────────────────────────────────────
pm="unknown"
install_cmd="unknown"

if [[ -f "$REPO_ROOT/package.json" ]]; then
  if [[ -f "$REPO_ROOT/pnpm-lock.yaml" ]]; then
    pm="pnpm"; install_cmd="pnpm install"
  elif [[ -f "$REPO_ROOT/yarn.lock" ]]; then
    pm="yarn"; install_cmd="yarn install"
  else
    pm="npm"; install_cmd="npm install"
  fi
elif [[ -f "$REPO_ROOT/pyproject.toml" ]]; then
  if grep -q "\[tool.poetry\]" "$REPO_ROOT/pyproject.toml" 2>/dev/null; then
    pm="poetry"; install_cmd="poetry install"
  else
    pm="pip"; install_cmd="pip install -e ."
  fi
elif [[ -f "$REPO_ROOT/requirements.txt" ]]; then
  pm="pip"; install_cmd="pip install -r requirements.txt"
elif [[ -f "$REPO_ROOT/Cargo.toml" ]]; then
  pm="cargo"; install_cmd="cargo build"
elif [[ -f "$REPO_ROOT/go.mod" ]]; then
  pm="go"; install_cmd="go mod download"
elif [[ -f "$REPO_ROOT/pom.xml" ]]; then
  pm="maven"; install_cmd="mvn install -DskipTests"
elif [[ -f "$REPO_ROOT/build.gradle" ]] || [[ -f "$REPO_ROOT/build.gradle.kts" ]]; then
  pm="gradle"; install_cmd="./gradlew build -x test"
elif [[ -f "$REPO_ROOT/Gemfile" ]]; then
  pm="bundler"; install_cmd="bundle install"
fi

# ── B2: Entry points + start command ─────────────────────────────────────────
start_cmd="unknown"
entry_points_json="[]"

case "$pm" in
  npm|pnpm|yarn)
    start_script=$(python3 -c "
import json, sys
try:
    with open('$REPO_ROOT/package.json') as f:
        d = json.load(f)
    s = d.get('scripts', {})
    key = 'dev' if 'dev' in s else ('start' if 'start' in s else None)
    print(key or '')
except Exception:
    print('')
" 2>/dev/null || true)
    [[ -n "$start_script" ]] && start_cmd="$pm run $start_script"
    eps=()
    for f in "src/index.ts" "src/index.js" "src/main.ts" "src/main.js" \
             "index.ts" "index.js" "app.ts" "app.js"; do
      [[ -f "$REPO_ROOT/$f" ]] && eps+=("\"$f\"")
    done
    [[ ${#eps[@]} -gt 0 ]] && entry_points_json="[$(IFS=,; echo "${eps[*]}")]"
    ;;
  pip|poetry)
    eps=()
    for f in "main.py" "app.py" "manage.py" "src/main.py" "src/app.py"; do
      [[ -f "$REPO_ROOT/$f" ]] && eps+=("\"$f\"")
    done
    [[ ${#eps[@]} -gt 0 ]] && {
      entry_points_json="[$(IFS=,; echo "${eps[*]}")]"
      # strip first quote to get plain path for start_cmd
      first="${eps[0]//\"/}"
      start_cmd="python $first"
    }
    ;;
  go)   start_cmd="go run ."; [[ -d "$REPO_ROOT/cmd" ]] && entry_points_json='["cmd/"]' ;;
  cargo) start_cmd="cargo run" ;;
esac

# ── B3: Test runner ───────────────────────────────────────────────────────────
test_runner="unknown"
test_cmd="unknown"

case "$pm" in
  npm|pnpm|yarn)
    pkg_json="$REPO_ROOT/package.json"
    if grep -q '"vitest"' "$pkg_json" 2>/dev/null; then
      test_runner="vitest"; test_cmd="$pm run test"
    elif grep -q '"jest"' "$pkg_json" 2>/dev/null; then
      test_runner="jest"; test_cmd="$pm test"
    elif grep -q '"mocha"' "$pkg_json" 2>/dev/null; then
      test_runner="mocha"; test_cmd="$pm test"
    fi
    ;;
  pip|poetry)
    if [[ -f "$REPO_ROOT/pytest.ini" ]] || [[ -f "$REPO_ROOT/conftest.py" ]] \
       || grep -q "pytest" "$REPO_ROOT/pyproject.toml" 2>/dev/null; then
      test_runner="pytest"; test_cmd="pytest"
    fi
    ;;
  go)   test_runner="go-test";    test_cmd="go test ./..." ;;
  cargo) test_runner="cargo-test"; test_cmd="cargo test" ;;
  maven) test_runner="junit";     test_cmd="mvn test" ;;
  gradle) test_runner="junit";    test_cmd="./gradlew test" ;;
esac

# ── B4: Linter ────────────────────────────────────────────────────────────────
lint_cmd="unknown"

if [[ -f "$REPO_ROOT/.eslintrc.js" ]] || [[ -f "$REPO_ROOT/.eslintrc.json" ]] \
   || [[ -f "$REPO_ROOT/.eslintrc.cjs" ]] || [[ -f "$REPO_ROOT/eslint.config.js" ]] \
   || [[ -f "$REPO_ROOT/eslint.config.mjs" ]] || [[ -f "$REPO_ROOT/eslint.config.ts" ]]; then
  lint_cmd="${pm:-npx} run lint"
elif [[ -f "$REPO_ROOT/.ruff.toml" ]] \
     || grep -q "\[tool\.ruff\]" "$REPO_ROOT/pyproject.toml" 2>/dev/null; then
  lint_cmd="ruff check ."
elif [[ -f "$REPO_ROOT/.flake8" ]] || grep -q "\[flake8\]" "$REPO_ROOT/setup.cfg" 2>/dev/null; then
  lint_cmd="flake8 ."
elif [[ "$pm" == "go" ]]; then
  lint_cmd="go vet ./..."
elif [[ "$pm" == "cargo" ]]; then
  lint_cmd="cargo clippy -- -D warnings"
fi

# B4: Type checker
typecheck_cmd="unknown"

if [[ -f "$REPO_ROOT/tsconfig.json" ]]; then
  typecheck_cmd="npx tsc --noEmit"
elif [[ -f "$REPO_ROOT/mypy.ini" ]] \
     || grep -q "mypy" "$REPO_ROOT/pyproject.toml" 2>/dev/null; then
  typecheck_cmd="mypy ."
elif grep -q "pyright" "$REPO_ROOT/pyproject.toml" 2>/dev/null; then
  typecheck_cmd="pyright"
fi

# B4: shellcheck (for .claude/hooks/*.sh)
shellcheck_available=false
command -v shellcheck &>/dev/null && shellcheck_available=true

# ── B5: Composite verify chain ────────────────────────────────────────────────
chain_parts=()
[[ "$lint_cmd"      != "unknown" ]] && chain_parts+=("\"lint\"")
[[ "$typecheck_cmd" != "unknown" ]] && chain_parts+=("\"typecheck\"")
[[ "$test_cmd"      != "unknown" ]] && chain_parts+=("\"test\"")
[[ "$shellcheck_available" == "true" ]] && chain_parts+=("\"shellcheck\"")

if [[ ${#chain_parts[@]} -gt 0 ]]; then
  verify_chain="[$(IFS=,; echo "${chain_parts[*]}")]"
else
  verify_chain="[]"
fi

# ── Write stack-profile.json ──────────────────────────────────────────────────
detected_at=$(date -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || echo "unknown")

python3 - <<PYEOF
import json

profile = {
    "detected_at": "$detected_at",
    "package_manager": "$pm",
    "install_cmd": "$install_cmd",
    "start_cmd": "$start_cmd",
    "test_runner": "$test_runner",
    "test_cmd": "$test_cmd",
    "lint_cmd": "$lint_cmd",
    "typecheck_cmd": "$typecheck_cmd",
    "shellcheck_available": $( [[ "$shellcheck_available" == "true" ]] && echo "True" || echo "False" ),
    "verify_chain": $verify_chain,
    "entry_points": $entry_points_json,
}

with open("$PROFILE", "w") as f:
    json.dump(profile, f, indent=2)
PYEOF

# ── Emit context summary ──────────────────────────────────────────────────────
chain_display="$( [[ ${#chain_parts[@]} -gt 0 ]] && echo "${chain_parts[*]//\"/}" || echo "none detected" )"
summary="STACK PROFILE: pm=${pm} | test=${test_runner} | lint=$( [[ "$lint_cmd" != "unknown" ]] && echo "yes" || echo "none" ) | typecheck=$( [[ "$typecheck_cmd" != "unknown" ]] && echo "yes" || echo "none" ) | shellcheck=${shellcheck_available} | chain=${chain_display}"

summary_escaped=$(printf '%s' "$summary" | sed 's/\\/\\\\/g; s/"/\\"/g')
printf '{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"%s"}}' "$summary_escaped"
