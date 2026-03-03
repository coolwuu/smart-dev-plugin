#!/usr/bin/env bash
# hooks/post-tool-use.sh — remind to run tests after file edits
# Reads testHint from .claude/smart-dev.json (or plugin default profile).
# Matcher: Edit|Write|MultiEdit

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/config.sh"

INPUT=$(cat)

# Extract file path from tool input
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // .tool_input.new_file_path // empty' 2>/dev/null || true)

# Skip if no file path detected
[ -z "$FILE_PATH" ] && exit 0

# Normalize to lowercase for case-insensitive matching
FILE_LOWER=$(echo "$FILE_PATH" | tr '[:upper:]' '[:lower:]')

# Skip test/spec/doc files — single regex covers all common patterns
if [[ "$FILE_LOWER" =~ /(tests?|__tests__)/ ]] || \
   [[ "$FILE_LOWER" =~ \.(spec|test)\.[^/]+$ ]] || \
   [[ "$FILE_LOWER" =~ \.md$ ]]; then
  exit 0
fi

TEST_HINT=$(get_config '.testHint' '')

# Only inject reminder if there's a meaningful test hint
if [ -n "$TEST_HINT" ]; then
  jq -n --arg ctx "File edited. Run tests: ${TEST_HINT}" \
    '{hookSpecificOutput:{additionalContext:$ctx}}'
fi
