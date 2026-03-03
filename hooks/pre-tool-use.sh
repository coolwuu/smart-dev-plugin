#!/usr/bin/env bash
# pre-tool-use.sh — Block dangerous Bash commands
# Matcher: Bash
# Event: PreToolUse

set -euo pipefail

# Read the tool input from stdin (JSON with "tool_input" containing the command)
INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

if [ -z "$COMMAND" ]; then
  exit 0
fi

# Block patterns
BLOCKED_PATTERNS=(
  'rm -rf /'
  'rm -rf ~'
  'rm -rf \.'
  'git push.*--force'
  'git push.*-f'
  'DROP TABLE'
  'DROP DATABASE'
  'TRUNCATE TABLE'
)

for pattern in "${BLOCKED_PATTERNS[@]}"; do
  if echo "$COMMAND" | grep -qi "$pattern"; then
    echo "BLOCKED: Command matches dangerous pattern: $pattern"
    echo "If you intended this, ask the user for explicit confirmation first."
    exit 2
  fi
done

exit 0
