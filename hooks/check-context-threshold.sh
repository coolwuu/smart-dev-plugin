#!/bin/bash
# Layer 1: Check context window usage, warn at threshold
# Hook: UserPromptSubmit — stdout is injected as context for Claude
#
# Also relays handover injection from SessionStart (flag file pattern)
#
# SESSION-AWARE: Uses session_id from hook JSON to read per-session file

# ── Read stdin once (consumed on first read) ──
INPUT=$(cat)

# ── Extract session_id early for scoped file paths ──
SESSION_ID=""
PCT=""
if command -v jq &>/dev/null; then
  SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // empty' 2>/dev/null || true)
  PCT=$(echo "$INPUT" | jq -r '.context_window.used_percentage // empty' 2>/dev/null || true)
fi

# ── Relay: emit pending handover reminder (one-shot) ──
# Use session-scoped flag file to avoid cross-session collisions
if [ -n "$SESSION_ID" ]; then
  FLAG_FILE="/tmp/claude-handover-inject-pending-${SESSION_ID}.txt"
else
  FLAG_FILE="/tmp/claude-handover-inject-pending.txt"
fi
if [ -f "$FLAG_FILE" ]; then
  cat "$FLAG_FILE"
  rm -f "$FLAG_FILE"
fi

# ── Context threshold check ──
THRESHOLD=85
COOLDOWN_SECONDS=300  # 5 min between warnings

# Fallback: read from statusline temp file
if [ -z "$PCT" ]; then
  if [ -n "$SESSION_ID" ]; then
    PCT_FILE="/tmp/claude-context-pct-${SESSION_ID}.txt"
  else
    PCT_FILE="/tmp/claude-context-pct.txt"
  fi
  if [ ! -f "$PCT_FILE" ]; then
    exit 0
  fi
  PCT=$(cat "$PCT_FILE" 2>/dev/null | tr -d '[:space:]')
fi

# Determine cooldown file path
if [ -n "$SESSION_ID" ]; then
  COOLDOWN_FILE="/tmp/claude-handover-warned-${SESSION_ID}.txt"
else
  COOLDOWN_FILE="/tmp/claude-handover-warned.txt"
fi

# Handle non-numeric or empty
if ! [[ "$PCT" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
  exit 0
fi

# Compare
OVER=$(awk "BEGIN {print ($PCT >= $THRESHOLD) ? 1 : 0}")

if [ "$OVER" -eq 0 ]; then
  exit 0
fi

# Check cooldown
if [ -f "$COOLDOWN_FILE" ]; then
  LAST_WARN=$(cat "$COOLDOWN_FILE" 2>/dev/null)
  NOW=$(date +%s)
  DIFF=$((NOW - LAST_WARN))
  if [ "$DIFF" -lt "$COOLDOWN_SECONDS" ]; then
    exit 0
  fi
fi

date +%s > "$COOLDOWN_FILE"

echo "CONTEXT WINDOW AT ${PCT}% — Approaching limit. You MUST invoke /auto-handover now to save session state before context is lost."
