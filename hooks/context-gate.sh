#!/bin/bash
# Context Gate — Triggers auto-handover at 70-80% context usage
# Hook: PreToolUse
#
# 75%: Warning — commit work and invoke /auto-handover soon
# 85%: Hard block — must invoke /auto-handover now

set -eo pipefail

WARN_THRESHOLD=75
BLOCK_THRESHOLD=85
COOLDOWN=300  # 5 min between warnings

INPUT=$(cat)

# Read used_percentage from hook JSON, fallback to statusline temp file
PCT=""
SESSION_ID=""
if command -v jq &>/dev/null; then
  SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // empty' 2>/dev/null || true)
  PCT=$(echo "$INPUT" | jq -r '.context_window.used_percentage // empty' 2>/dev/null || true)
fi

if [ -z "$PCT" ]; then
  PCT_FILE="/tmp/claude-context-pct-${SESSION_ID:-$$}.txt"
  [ -f "$PCT_FILE" ] || exit 0
  PCT=$(cat "$PCT_FILE" 2>/dev/null | tr -d '[:space:]')
fi

# Validate
[[ "$PCT" =~ ^[0-9]+$ ]] || exit 0

# Allow handover-related tools through even when blocked
TOOL_NAME=""
TOOL_INPUT=""
if command -v jq &>/dev/null; then
  TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty' 2>/dev/null || true)
  TOOL_INPUT=$(echo "$INPUT" | jq -r '.tool_input // empty' 2>/dev/null || true)
fi

is_handover_tool() {
  # Allow Skill tool invoking auto-handover or lesson
  if [ "$TOOL_NAME" = "Skill" ]; then
    local skill_name
    skill_name=$(echo "$TOOL_INPUT" | jq -r '.skill // empty' 2>/dev/null || true)
    echo "$skill_name" | grep -qi 'auto-handover' && return 0
    echo "$skill_name" | grep -qi 'lesson' && return 0
  fi
  # Allow Write tool targeting handover/ directory
  if [ "$TOOL_NAME" = "Write" ]; then
    echo "$TOOL_INPUT" | jq -r '.file_path // empty' 2>/dev/null | grep -q '/handover/' && return 0
  fi
  # Allow Read tool targeting handover/ directory
  if [ "$TOOL_NAME" = "Read" ]; then
    echo "$TOOL_INPUT" | jq -r '.file_path // empty' 2>/dev/null | grep -q '/handover/' && return 0
  fi
  # Allow Bash with mkdir for handover dir
  if [ "$TOOL_NAME" = "Bash" ]; then
    echo "$TOOL_INPUT" | jq -r '.command // empty' 2>/dev/null | grep -q 'handover' && return 0
  fi
  # Allow Glob/Grep targeting handover
  if [ "$TOOL_NAME" = "Glob" ] || [ "$TOOL_NAME" = "Grep" ]; then
    local path=$(echo "$TOOL_INPUT" | jq -r '.path // empty' 2>/dev/null || true)
    local pattern=$(echo "$TOOL_INPUT" | jq -r '.pattern // empty' 2>/dev/null || true)
    echo "${path}${pattern}" | grep -q 'handover' && return 0
  fi
  return 1
}

# Hard block at >=80% — except handover tools
if [ "$PCT" -ge "$BLOCK_THRESHOLD" ]; then
  if is_handover_tool; then
    exit 0  # Allow through
  fi
  cat >&2 << EOF
CONTEXT AT ${PCT}% — BLOCKED. You MUST invoke /auto-handover NOW.
Do NOT start any new work. Ask the user to commit before handover if needed.
EOF
  exit 2
fi

# Warn at 70-79% (with cooldown)
if [ "$PCT" -ge "$WARN_THRESHOLD" ]; then
  # Fallback to PID if session_id is missing (avoids cross-session collisions)
  STAMP="/tmp/claude-gate-warned-${SESSION_ID:-$$}.txt"
  NOW=$(date +%s)
  if [ -f "$STAMP" ]; then
    LAST=$(cat "$STAMP" 2>/dev/null | tr -d '[:space:]')
    [ $((NOW - ${LAST:-0})) -lt "$COOLDOWN" ] && exit 0
  fi
  echo "$NOW" > "$STAMP"

  cat << EOF
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "additionalContext": "Context window at ${PCT}%. Run /lesson to capture learnings, then ask user to commit and invoke /auto-handover."
  }
}
EOF
fi

exit 0
