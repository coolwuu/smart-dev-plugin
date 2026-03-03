#!/bin/bash
# Worktree Guard — Warns when writing to main repo while worktrees exist
# Hook: PreToolUse (Write, Edit)
#
# This is a WARNING (exit 0), not a block (exit 2).
# There are legitimate reasons to write to main repo (CLAUDE.md, docs, etc.).
# Fires once per session via cooldown file.

set -eo pipefail

INPUT=$(cat)

# Extract file_path from tool_input
FILE_PATH=""
if command -v jq &>/dev/null; then
  FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty' 2>/dev/null || true)
fi
[ -z "$FILE_PATH" ] && exit 0

# Get session ID for cooldown
SESSION_ID=""
if command -v jq &>/dev/null; then
  SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // empty' 2>/dev/null || true)
fi

# Per-session cooldown — warn only ONCE per session
# Fallback to PPID if session_id is missing (avoids cross-session collisions)
STAMP="/tmp/claude-worktree-warned-${SESSION_ID:-$$}.txt"
[ -f "$STAMP" ] && exit 0

# Count worktrees (main repo always counts as 1)
WORKTREE_COUNT=$(git worktree list 2>/dev/null | wc -l | tr -d '[:space:]')
[ -z "$WORKTREE_COUNT" ] && exit 0
[ "$WORKTREE_COUNT" -le 1 ] && exit 0

# Get main repo root
MAIN_REPO=$(git rev-parse --show-toplevel 2>/dev/null || true)
[ -z "$MAIN_REPO" ] && exit 0

# Collect non-main worktree paths
WORKTREE_PATHS=$(git worktree list 2>/dev/null | grep -v "^${MAIN_REPO} " | awk '{print $1}' | tr '\n' ', ' | sed 's/,$//')

# Skip if file_path is inside a worktree directory (not actually main repo)
while IFS= read -r WT_PATH; do
  case "$FILE_PATH" in
    "$WT_PATH"/*) exit 0 ;;
  esac
done < <(git worktree list 2>/dev/null | grep -v "^${MAIN_REPO} " | awk '{print $1}')

# Allowlist — paths that are always safe to write in main repo
REL_PATH="${FILE_PATH#"$MAIN_REPO"/}"
case "$REL_PATH" in
  .ai/*|.claude/*|CLAUDE.md|handover/*) exit 0 ;;
esac

# Check if file_path is under the main repo directory
case "$FILE_PATH" in
  "$MAIN_REPO"/*)

    # Mark as warned for this session
    echo "1" > "$STAMP"

    cat << EOF
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "additionalContext": "Active worktree(s) detected: ${WORKTREE_PATHS}. You're writing to the main repo. If you should be working in a worktree, switch now."
  }
}
EOF
    ;;
esac

exit 0
