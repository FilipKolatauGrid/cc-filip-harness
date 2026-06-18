#!/usr/bin/env bash
# PostToolUse hook: detect edits to harness files and remind session to re-run /validate-harness.
# Fires on Write and Edit tool calls. Non-blocking — always exits 0.
# Emits a status message when a harness file is touched so the impact can be measured.

set -euo pipefail

# Read stdin JSON (tool_input from the Write/Edit call)
input=$(cat)

# Extract file_path from tool_input
file_path=$(printf '%s' "$input" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    # PostToolUse: tool_input is nested under tool_input key
    ti = d.get('tool_input', d)
    print(ti.get('file_path', ti.get('path', '')))
except:
    print('')
" 2>/dev/null || echo "")

if [[ -z "$file_path" ]]; then
  exit 0
fi

# Patterns that constitute a harness file change
is_harness_file() {
  local f="$1"
  # Primary instruction file
  [[ "$f" == */CLAUDE.md ]] && return 0
  # Skill files
  [[ "$f" == */.claude/skills/*/SKILL.md ]] && return 0
  [[ "$f" == */.claude/skills/CLAUDE.md ]] && return 0
  # Agent definitions
  [[ "$f" == */.claude/agents/*.md ]] && return 0
  # Workflows
  [[ "$f" == */.claude/workflows/*.md ]] && return 0
  # Hook scripts
  [[ "$f" == */.claude/hooks/*.sh ]] && return 0
  # Registry and reference docs
  [[ "$f" == */docs/SKILL_REGISTRY.md ]] && return 0
  [[ "$f" == */docs/HARNESS_REFERENCE.md ]] && return 0
  [[ "$f" == */docs/ARCHITECTURE.md ]] && return 0
  [[ "$f" == */docs/META_PROMPTING.md ]] && return 0
  return 1
}

if is_harness_file "$file_path"; then
  echo "HARNESS CHANGE DETECTED: $(basename "$file_path") modified." >&2
  echo "Run /validate-harness to measure the impact of this change on harness score." >&2
fi

exit 0
