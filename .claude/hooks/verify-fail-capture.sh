#!/usr/bin/env bash
# UserPromptSubmit hook: when /verify is submitted and a prior FAIL verdict exists,
# inject the failure blockers into context so Claude acts on them immediately.

set -euo pipefail

ACTIVE_TASK="${CLAUDE_PROJECT_DIR:-$(git -C "$(dirname "$0")" rev-parse --show-toplevel 2>/dev/null || pwd)}/ACTIVE_TASK.md"

# Read stdin JSON and extract prompt text
input=$(cat)

prompt=$(printf '%s' "$input" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    # UserPromptSubmit passes the prompt in different fields depending on version
    print(d.get('prompt', d.get('message', d.get('user_input', ''))))
except:
    print('')
" 2>/dev/null || echo "")

# Only fire on /verify invocations
if ! echo "$prompt" | grep -qE '^\s*/verify\b|^\s*verify\b'; then
  exit 0
fi

if [[ ! -f "$ACTIVE_TASK" ]]; then
  exit 0
fi

# Find last verify Observation block
last_verify_obs=$(grep -n "phase: testing/verify" "$ACTIVE_TASK" | tail -1)
if [[ -z "$last_verify_obs" ]]; then
  exit 0  # No prior verify run — first run, no context to inject
fi

obs_line=$(echo "$last_verify_obs" | cut -d: -f1)
# Back up to find the ### Observation header (within 3 lines above)
obs_start=$((obs_line > 3 ? obs_line - 3 : 1))
obs_block=$(sed -n "${obs_start},+15p" "$ACTIVE_TASK")

# Check if last verify was a FAIL
verdict=$(echo "$obs_block" | grep -m1 "^- verdict:" | sed 's/- verdict: *//' | tr -d '\r')

if [[ "$verdict" != "FAIL" ]]; then
  exit 0  # Last verify passed or verdict unknown — no injection needed
fi

# Extract blockers from ## Test Results section (lines after last verify obs)
blockers=$(awk "NR>=${obs_line}{print}" "$ACTIVE_TASK" | \
  grep -A 20 "### Blockers\|blockers:\|FAIL" | \
  grep -E "^[-*]|^  [-*]|AC#|criterion|coverage|e2e" | \
  head -8 | sed 's/^/  /' || echo "  (see ## Test Results for details)")

context="PREVIOUS /verify RESULT: FAIL
Blockers from last run:
${blockers}
Fix blockers before re-running /verify. Common fixes: run /tdd for missing E2E tests, run /refactor if coverage is below target."

# Escape for JSON
context_json=$(printf '%s' "$context" | python3 -c "
import sys, json
print(json.dumps(sys.stdin.read()))
" 2>/dev/null || printf '"%s"' "$context")

printf '{"hookSpecificOutput":{"hookEventName":"UserPromptSubmit","additionalContext":%s}}' "$context_json"
exit 0
