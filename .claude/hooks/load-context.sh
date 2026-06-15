#!/usr/bin/env bash
# SessionStart hook: parse ACTIVE_TASK.md, inject current harness state into context window.
# Emits additionalContext JSON so Claude sees phase/verdict/next-skill without cold file read.

set -euo pipefail

ACTIVE_TASK="${CLAUDE_PROJECT_DIR:-$(git -C "$(dirname "$0")" rev-parse --show-toplevel 2>/dev/null || pwd)}/ACTIVE_TASK.md"

if [[ ! -f "$ACTIVE_TASK" ]]; then
  exit 0
fi

content=$(cat "$ACTIVE_TASK")

# Check if requirement section is empty (clean state)
req_section=$(awk '/^## Requirement/{found=1; next} found && /^## /{exit} found{print}' "$ACTIVE_TASK" | tr -d '[:space:]')
if [[ -z "$req_section" || "$req_section" == "<!--taskwriteshere-->" ]]; then
  # Clean state — inject minimal nudge
  context="HARNESS STATE: no active task. Run /task to start."
  printf '{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"%s"}}' "$context"
  exit 0
fi

# Find last Observation block
last_obs=$(grep -n "### Observation" "$ACTIVE_TASK" | tail -1)
if [[ -z "$last_obs" ]]; then
  context="HARNESS STATE: active task found, no Observation blocks yet. Resume from first incomplete phase."
  printf '{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"%s"}}' "$context"
  exit 0
fi

last_obs_line=$(echo "$last_obs" | cut -d: -f1)

# Extract fields from last Observation block (read up to 10 lines after it)
obs_block=$(tail -n +"$last_obs_line" "$ACTIVE_TASK" | head -10)

phase=$(echo "$obs_block"    | grep -m1 "^- phase:"        | sed 's/- phase: *//' | tr -d '\r')
signal=$(echo "$obs_block"   | grep -m1 "^- done-signal:"  | sed 's/- done-signal: *//' | tr -d '\r')
verdict=$(echo "$obs_block"  | grep -m1 "^- verdict:"      | sed 's/- verdict: *//' | tr -d '\r')
vsource=$(echo "$obs_block"  | grep -m1 "^- verdict-source:"| sed 's/- verdict-source: *//' | tr -d '\r')

# Derive next skill from phase
case "$phase" in
  intake/task)          next="init or design" ;;
  planning/design)      next="grill" ;;
  planning/grill)       next="risk" ;;
  planning/risk)        next="code" ;;
  implementation/code)  next="tdd" ;;
  implementation/tdd)   next="tests" ;;
  implementation/refactor) next="tests" ;;
  testing/tests)        next="coverage" ;;
  testing/coverage)     next="verify" ;;
  testing/verify)
    if [[ "$verdict" == "PASS" ]]; then next="review"
    else next="fix blockers then re-run verify"; fi ;;
  review/review)        next="audit" ;;
  review/audit)         next="deploy" ;;
  integration/deploy)   next="ship" ;;
  integration/ship)     next="close" ;;
  integration/close)    next="task (next task)" ;;
  *)                    next="check ACTIVE_TASK.md" ;;
esac

# Build summary line
summary="HARNESS STATE: phase=${phase:-unknown} | done-signal=${signal:-none} | next=/${next}"
if [[ -n "$verdict" ]]; then
  summary="${summary} | verdict=${verdict} (${vsource:-unknown-source})"
fi

# Escape for JSON string (double-quotes and backslashes)
summary_escaped=$(printf '%s' "$summary" | sed 's/\\/\\\\/g; s/"/\\"/g')

printf '{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"%s"}}' "$summary_escaped"
