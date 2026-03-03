#!/bin/bash
# Insights Reminder — Nudges /project-insights if >7 days since last run
# Hook: SessionStart
#
# Reads stamp file to determine staleness. Silent if recent (<7 days).

set -eo pipefail

STAMP_FILE="/tmp/claude-insights-last-run.txt"
STALE_DAYS=7
STALE_SECONDS=$((STALE_DAYS * 86400))

NOW=$(date +%s)

# Check if stamp file exists
if [ -f "$STAMP_FILE" ]; then
  LAST=$(cat "$STAMP_FILE" 2>/dev/null | tr -d '[:space:]')
  if [[ "$LAST" =~ ^[0-9]+$ ]]; then
    ELAPSED=$((NOW - LAST))
    if [ "$ELAPSED" -lt "$STALE_SECONDS" ]; then
      exit 0  # Recent run, stay silent
    fi
  fi
fi

# Stamp is missing or stale — nudge
cat << EOF
{
  "hookSpecificOutput": {
    "hookEventName": "SessionStart",
    "additionalContext": "It has been ${STALE_DAYS}+ days since last /project-insights run. Consider running /project-insights to analyze recent session patterns."
  }
}
EOF

exit 0
