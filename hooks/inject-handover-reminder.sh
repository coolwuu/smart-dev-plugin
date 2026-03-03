#!/bin/bash
# Layer 3: Remind about available handover after clear/compact
# Hook: SessionStart (compact|clear)
#
# RELAY PATTERN: SessionStart stdout is NOT injected into conversation context.
# Instead, we write the reminder to a flag file. The UserPromptSubmit hook
# (check-context-threshold.sh) reads and emits it on the first user message.
#
# Also cleans up all cooldown files so new sessions start fresh

# Read session_id from stdin for session-scoped flag files
_INPUT=$(cat)
_SESSION_ID=""
if command -v jq &>/dev/null; then
  _SESSION_ID=$(echo "$_INPUT" | jq -r '.session_id // empty' 2>/dev/null || true)
fi

# Clean up cooldown files from previous sessions
rm -f /tmp/claude-handover-warned.txt
rm -f /tmp/claude-auto-handover-blocked.txt

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"

# Read HandoverPath from CLAUDE.md
HANDOVER_DIR="$PROJECT_DIR/handover"
if [ -f "$PROJECT_DIR/CLAUDE.md" ]; then
  CUSTOM_PATH=$(grep -i "HandoverPath:" "$PROJECT_DIR/CLAUDE.md" | head -1 | sed 's/.*HandoverPath://;s/\*//g' | tr -d ' ' | tr -d '\r')
  if [ -n "$CUSTOM_PATH" ]; then
    HANDOVER_DIR="$PROJECT_DIR/$CUSTOM_PATH"
  fi
fi

if [ ! -d "$HANDOVER_DIR" ]; then
  exit 0
fi

# Use session-scoped flag file to avoid cross-session collisions
if [ -n "$_SESSION_ID" ]; then
  FLAG_FILE="/tmp/claude-handover-inject-pending-${_SESSION_ID}.txt"
else
  FLAG_FILE="/tmp/claude-handover-inject-pending.txt"
fi

# Collect all handover .md files (sorted newest first)
HANDOVER_FILES=()
while IFS= read -r -d '' f; do
  HANDOVER_FILES+=("$f")
done < <(find "$HANDOVER_DIR" -name "*.md" -not -name ".gitkeep" -type f -print0 2>/dev/null | xargs -0 ls -t 2>/dev/null | tr '\n' '\0')

if [ "${#HANDOVER_FILES[@]}" -eq 0 ]; then
  exit 0
fi

# Build a list with age info
FILE_LIST=""
RECENT_COUNT=0
NOW=$(date +%s)
for f in "${HANDOVER_FILES[@]}"; do
  if [ "$(uname)" = "Darwin" ]; then
    FILE_AGE=$(( NOW - $(stat -f %m "$f") ))
  else
    FILE_AGE=$(( NOW - $(stat -c %Y "$f") ))
  fi
  BASENAME=$(basename "$f" .md)
  if [ "$FILE_AGE" -lt 60 ]; then
    AGE_STR="just now"
  elif [ "$FILE_AGE" -lt 3600 ]; then
    AGE_STR="$((FILE_AGE / 60))m ago"
  elif [ "$FILE_AGE" -lt 86400 ]; then
    AGE_STR="$((FILE_AGE / 3600))h ago"
  else
    AGE_STR="$((FILE_AGE / 86400))d ago"
  fi
  FILE_LIST="${FILE_LIST}  - ${BASENAME} (${AGE_STR}): ${f}\n"
  RECENT_COUNT=$((RECENT_COUNT + 1))
done

if [ "$RECENT_COUNT" -gt 0 ]; then
  printf "HANDOVER FILES AVAILABLE (%d found):\n%bIMPORTANT INSTRUCTION: You MUST use AskUserQuestion to present these handover files as options and let the user choose which one to resume (include a 'None — start fresh' option). After the user picks one, invoke /resume-handover with that file path. Do NOT auto-resume without asking." "$RECENT_COUNT" "$FILE_LIST" > "$FLAG_FILE"
  exit 0
fi

# Check for pre-compact metadata (Layer 2 fallback)
METADATA_FILE="$HANDOVER_DIR/.pre-compact-metadata.txt"
if [ -f "$METADATA_FILE" ]; then
  if [ "$(uname)" = "Darwin" ]; then
    META_AGE=$(( $(date +%s) - $(stat -f %m "$METADATA_FILE") ))
  else
    META_AGE=$(( $(date +%s) - $(stat -c %Y "$METADATA_FILE") ))
  fi

  if [ "$META_AGE" -lt 3600 ]; then
    echo "Context was compacted but no handover document was generated. Pre-compact metadata saved at: $METADATA_FILE. Run /auto-handover to generate a handover from current state, or /resume-handover to check metadata." > "$FLAG_FILE"
    exit 0
  fi
fi

exit 0
