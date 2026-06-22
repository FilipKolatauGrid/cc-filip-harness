#!/usr/bin/env bash
# PostToolUse hook (Write|Edit): targeted verification based on changed file + stack profile.
# B3+B4 per harness system instructions. Non-blocking — exit 0 always, emits warnings only.
# Cross-platform: requires POSIX bash. Windows: use WSL2 or Git Bash.

set -euo pipefail

REPO_ROOT="${CLAUDE_PROJECT_DIR:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
PROFILE="$REPO_ROOT/.claude/stack-profile.json"

# Read stdin and extract file path
input=$(cat)
file_path=$(printf '%s' "$input" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    print(d.get('tool_input', {}).get('file_path', ''))
except Exception:
    print('')
" 2>/dev/null || true)

# Skip if no file path or file doesn't exist
[[ -z "$file_path" || ! -f "$file_path" ]] && exit 0

# Skip noise paths
case "$file_path" in
  */.git/*|*/node_modules/*|*/__pycache__/*|*/target/*|*/.cache/*)
    exit 0 ;;
esac

# Load stack profile if available; otherwise skip verification
if [[ ! -f "$PROFILE" ]]; then
  exit 0
fi

lint_cmd=$(python3 -c "
import json
try:
    with open('$PROFILE') as f:
        d = json.load(f)
    v = d.get('lint_cmd', 'unknown')
    print('' if v == 'unknown' else v)
except Exception:
    print('')
" 2>/dev/null || true)

typecheck_cmd=$(python3 -c "
import json
try:
    with open('$PROFILE') as f:
        d = json.load(f)
    v = d.get('typecheck_cmd', 'unknown')
    print('' if v == 'unknown' else v)
except Exception:
    print('')
" 2>/dev/null || true)

test_cmd=$(python3 -c "
import json
try:
    with open('$PROFILE') as f:
        d = json.load(f)
    v = d.get('test_cmd', 'unknown')
    print('' if v == 'unknown' else v)
except Exception:
    print('')
" 2>/dev/null || true)

shellcheck_available=$(python3 -c "
import json
try:
    with open('$PROFILE') as f:
        d = json.load(f)
    print('true' if d.get('shellcheck_available') else 'false')
except Exception:
    print('false')
" 2>/dev/null || echo "false")

# ── Determine checks by file type ────────────────────────────────────────────
ext="${file_path##*.}"
filename="${file_path##*/}"
warnings=()

case "$ext" in
  sh)
    # B4: shellcheck for all shell scripts, especially .claude/hooks/
    if [[ "$shellcheck_available" == "true" ]]; then
      sc_out=$(shellcheck -f gcc "$file_path" 2>&1 || true)
      if [[ -n "$sc_out" ]]; then
        warnings+=("SHELLCHECK — ${file_path#${REPO_ROOT}/}:")
        while IFS= read -r line; do
          warnings+=("  $line")
        done <<< "$sc_out"
      fi
    else
      # shellcheck unavailable — remind user
      case "$file_path" in
        */.claude/hooks/*)
          warnings+=("ADVISORY: shellcheck not found. Install it to lint ${file_path#${REPO_ROOT}/} (brew install shellcheck).")
          ;;
      esac
    fi
    ;;

  ts|tsx|js|jsx|mts|mjs|cts|cjs)
    # B3+B4: lint then typecheck for JS/TS files
    [[ -n "$lint_cmd" ]] && \
      warnings+=("VERIFY REMINDER: TS/JS file changed → run: $lint_cmd")
    [[ -n "$typecheck_cmd" ]] && \
      warnings+=("VERIFY REMINDER: TS/JS file changed → run: $typecheck_cmd")
    # B3: test file → run targeted test
    case "$filename" in
      *.spec.*|*.test.*)
        [[ -n "$test_cmd" ]] && \
          warnings+=("VERIFY REMINDER: test file changed → run: $test_cmd $file_path")
        ;;
    esac
    ;;

  py)
    # B4: lint Python files
    [[ -n "$lint_cmd" ]] && \
      warnings+=("VERIFY REMINDER: Python file changed → run: $lint_cmd")
    # B4: typecheck if available
    [[ -n "$typecheck_cmd" ]] && \
      warnings+=("VERIFY REMINDER: Python file changed → run: $typecheck_cmd")
    # B3: test file → targeted test
    case "$filename" in
      test_*.py|*_test.py)
        [[ -n "$test_cmd" ]] && \
          warnings+=("VERIFY REMINDER: test file changed → run: $test_cmd $file_path")
        ;;
    esac
    ;;

  go)
    warnings+=("VERIFY REMINDER: Go file changed → run: go vet ./... && go test ./...")
    ;;

  rs)
    warnings+=("VERIFY REMINDER: Rust file changed → run: cargo clippy && cargo test")
    ;;
esac

# B1: dependency manifest changes → remind to install
case "$filename" in
  package.json|requirements.txt|pyproject.toml|Cargo.toml|go.mod|Gemfile|pom.xml)
    install_cmd=$(python3 -c "
import json
try:
    with open('$PROFILE') as f:
        d = json.load(f)
    print(d.get('install_cmd', ''))
except Exception:
    print('')
" 2>/dev/null || true)
    [[ -n "$install_cmd" ]] && \
      warnings+=("B1 DEPENDENCY CHANGE: $filename modified → run: $install_cmd")
    ;;
esac

[[ ${#warnings[@]} -eq 0 ]] && exit 0

# Build output
rel_path="${file_path#${REPO_ROOT}/}"
msg="ADAPTIVE-VERIFY — ${rel_path}:"
for w in "${warnings[@]}"; do
  msg="${msg}\n  ${w}"
done

msg_json=$(printf '%s' "$msg" | python3 -c "
import sys, json
print(json.dumps(sys.stdin.read()))
" 2>/dev/null || printf '"%s"' "$msg")

printf '{"output":%s}' "$msg_json"
exit 0
