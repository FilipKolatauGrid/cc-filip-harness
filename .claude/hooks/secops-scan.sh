#!/usr/bin/env bash
# PostToolUse hook: fast regex secops scan on any written/edited source file.
# Non-blocking — emits warnings only. Hard gate is sdlc-secops during /review.
# Skips markdown, .claude/, task-log/, docs/, examples/ paths.

set -euo pipefail

# Read stdin JSON and extract file path
input=$(cat)

file_path=$(printf '%s' "$input" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    ti = d.get('tool_input', {})
    # Write tool uses 'file_path', Edit tool uses 'file_path'
    print(ti.get('file_path', ''))
except:
    print('')
" 2>/dev/null || echo "")

if [[ -z "$file_path" || ! -f "$file_path" ]]; then
  exit 0
fi

# Skip non-source paths
case "$file_path" in
  */.claude/*|*/task-log/*|*/docs/*|*/examples/*|*.md|*.txt|*.json|*.yaml|*.yml|*.lock|*.gitignore)
    exit 0 ;;
esac

findings=()

# Secrets patterns
while IFS= read -r match; do
  [[ -n "$match" ]] && findings+=("SECRET: $match")
done < <(grep -nEi \
  '(api_key|api_secret|client_secret|access_token|auth_token|private_key|db_password|database_url)\s*[=:]\s*["\x27][^"\x27]{8,}' \
  "$file_path" 2>/dev/null | head -5 || true)

# Dangerous code patterns
while IFS= read -r match; do
  [[ -n "$match" ]] && findings+=("VULN: $match")
done < <(grep -nE \
  'eval\(|subprocess.*shell=True|dangerouslySetInnerHTML|innerHTML\s*=|yaml\.load\([^,)]*\)|pickle\.loads\(' \
  "$file_path" 2>/dev/null | head -5 || true)

# PII in logs
while IFS= read -r match; do
  [[ -n "$match" ]] && findings+=("PII-LOG: $match")
done < <(grep -nEi \
  '(console\.log|print|logger\.(info|debug|warn))\s*\(.*\b(email|password|ssn|credit_card|token)\b' \
  "$file_path" 2>/dev/null | head -3 || true)

if [[ ${#findings[@]} -eq 0 ]]; then
  exit 0
fi

# Build warning output (non-blocking)
rel_path="${file_path#${CLAUDE_PROJECT_DIR:-}/}"
warning="SECOPS SCAN — ${rel_path}:"
for f in "${findings[@]}"; do
  warning="${warning}\n  ${f}"
done
warning="${warning}\nReview before /review phase. sdlc-secops will hard-gate on these."

# Escape newlines and quotes for JSON
warning_json=$(printf '%s' "$warning" | python3 -c "
import sys, json
print(json.dumps(sys.stdin.read()))
" 2>/dev/null || printf '"%s"' "$warning")

printf '{"output":%s}' "$warning_json"
exit 0
