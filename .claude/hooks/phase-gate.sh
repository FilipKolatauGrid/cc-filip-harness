#!/usr/bin/env bash
# PreToolUse hook: block skill invocations when required prior phase is missing.
# Reads tool_input.command from stdin JSON, detects skill name, checks ACTIVE_TASK.md gates.
# Exit 2 = block with message to Claude. Exit 0 = allow.

set -euo pipefail

ACTIVE_TASK="${CLAUDE_PROJECT_DIR:-$(git -C "$(dirname "$0")" rev-parse --show-toplevel 2>/dev/null || pwd)}/ACTIVE_TASK.md"

# Read stdin JSON
input=$(cat)

# Extract command string from tool_input
command_str=$(printf '%s' "$input" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    print(d.get('tool_input', {}).get('command', ''))
except:
    print('')
" 2>/dev/null || echo "")

if [[ -z "$command_str" ]]; then
  exit 0
fi

# Skip git commands — skill names may appear in commit messages, branch names, etc.
if echo "$command_str" | grep -qE '^\s*git\s'; then
  exit 0
fi

# Detect which skill is being invoked — must be the leading token of the command
skill=""
if   echo "$command_str" | grep -qE '^\s*/review([[:space:]]|$)';  then skill="review"
elif echo "$command_str" | grep -qE '^\s*/audit([[:space:]]|$)';   then skill="audit"
elif echo "$command_str" | grep -qE '^\s*/deploy([[:space:]]|$)';  then skill="deploy"
elif echo "$command_str" | grep -qE '^\s*/verify([[:space:]]|$)';  then skill="verify"
elif echo "$command_str" | grep -qE '^\s*/code([[:space:]]|$)';    then skill="code"
elif echo "$command_str" | grep -qE '^\s*/ship([[:space:]]|$)';    then skill="ship"
elif echo "$command_str" | grep -qE '^\s*/close([[:space:]]|$)';   then skill="close"
fi

if [[ -z "$skill" ]]; then
  exit 0
fi

if [[ ! -f "$ACTIVE_TASK" ]]; then
  exit 0
fi

# Helper: check if a section has any Observation block with a given field=value
obs_has() {
  local section="$1" field="$2" value="$3"
  # Extract the section, then scan Observation blocks for the field
  awk "/^## ${section}/{found=1; next} found && /^## /{exit} found{print}" "$ACTIVE_TASK" \
    | grep -q "^- ${field}: ${value}" 2>/dev/null
}

# Helper: check if a section has any Observation block at all
section_has_obs() {
  local section="$1"
  awk "/^## ${section}/{found=1; next} found && /^## /{exit} found{print}" "$ACTIVE_TASK" \
    | grep -q "### Observation" 2>/dev/null
}

# Helper: check section is non-empty (has real content beyond comments)
section_non_empty() {
  local section="$1"
  local body
  body=$(awk "/^## ${section}/{found=1; next} found && /^## /{exit} found{print}" "$ACTIVE_TASK" \
    | grep -v "^<!--" | grep -v "^$" | head -1)
  [[ -n "$body" ]]
}

block() {
  local msg="$1"
  echo "PHASE GATE BLOCKED: ${msg}" >&2
  exit 2
}

case "$skill" in
  code)
    section_non_empty "Design" || block "/code requires ## Design. Run /design first."
    section_has_obs "Design"   || block "/code requires a Design Observation block. Run /design to completion."
    ;;
  verify)
    section_non_empty "Test Results" || block "/verify requires ## Test Results. Run /tests then /coverage first."
    obs_has "Test Results" "done-signal" "coverage-report" \
      || block "/verify requires coverage-report Observation in ## Test Results. Run /coverage first."
    ;;
  review)
    # Needs verify PASS with external-evidence
    obs_has "Test Results" "verdict" "PASS" \
      || block "/review requires verify PASS verdict. Current ## Test Results has no PASS Observation. Run /verify first."
    obs_has "Test Results" "verdict-source" "external-evidence" \
      || block "/review requires verdict-source: external-evidence. Self-reported verify is not sufficient. Re-run /verify with test runner output."
    ;;
  audit)
    section_non_empty "Review Findings" \
      || block "/audit requires ## Review Findings. Run /review first."
    section_has_obs "Review Findings" \
      || block "/audit requires a Review Findings Observation block. Run /review to completion."
    ;;
  deploy)
    section_non_empty "Review Findings" \
      || block "/deploy requires ## Review Findings. Run /review and /audit first."
    # Block if any CRITICAL unresolved in Review Findings
    if awk "/^## Review Findings/{found=1; next} found && /^## /{exit} found{print}" "$ACTIVE_TASK" \
        | grep -qiE "CRITICAL.*unresolved|verdict.*BLOCKED"; then
      block "/deploy blocked — unresolved CRITICAL findings in ## Review Findings. Resolve all CRITICAL items before deploying."
    fi
    ;;
  ship)
    section_non_empty "Deploy Checklist" \
      || block "/ship requires ## Deploy Checklist. Run /deploy first."
    section_has_obs "Deploy Checklist" \
      || block "/ship requires a Deploy Checklist Observation block. Run /deploy to completion."
    ;;
  close)
    section_non_empty "Requirement" \
      || block "/close requires ## Requirement. Nothing to close."
    section_non_empty "Review Findings" \
      || block "/close requires ## Review Findings. Run /review before closing."
    ;;
esac

exit 0
