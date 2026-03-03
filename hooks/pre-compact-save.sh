#!/bin/bash
# Layer 2: Save metadata before auto-compaction
# Hook: PreCompact (auto) — runs before context is compressed
#
# Saves raw metadata as fallback if Layer 1 (Claude-generated handover)
# was not triggered. Skips if a recent handover already exists.

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"

# Read HandoverPath from CLAUDE.md (same pattern as feature-dev hook)
HANDOVER_DIR="$PROJECT_DIR/handover"
if [ -f "$PROJECT_DIR/CLAUDE.md" ]; then
  CUSTOM_PATH=$(grep -i "HandoverPath:" "$PROJECT_DIR/CLAUDE.md" | head -1 | sed 's/.*HandoverPath://;s/\*//g' | tr -d ' ' | tr -d '\r')
  if [ -n "$CUSTOM_PATH" ]; then
    HANDOVER_DIR="$PROJECT_DIR/$CUSTOM_PATH"
  fi
fi

# Check if Layer 1 already generated a handover (within last hour)
if [ -d "$HANDOVER_DIR" ]; then
  LATEST_HANDOVER=$(find "$HANDOVER_DIR" -name "*.md" -not -name ".gitkeep" -type f -print0 2>/dev/null | xargs -0 ls -t 2>/dev/null | head -1)
  if [ -n "$LATEST_HANDOVER" ]; then
    if [ "$(uname)" = "Darwin" ]; then
      FILE_AGE=$(( $(date +%s) - $(stat -f %m "$LATEST_HANDOVER") ))
    else
      FILE_AGE=$(( $(date +%s) - $(stat -c %Y "$LATEST_HANDOVER") ))
    fi
    if [ "$FILE_AGE" -lt 3600 ]; then
      exit 0  # Recent handover exists, skip
    fi
  fi
fi

# Create handover directory if needed
mkdir -p "$HANDOVER_DIR"

# Save metadata
METADATA_FILE="$HANDOVER_DIR/.pre-compact-metadata.txt"
{
  echo "timestamp=$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
  echo "branch=$(git -C "$PROJECT_DIR" rev-parse --abbrev-ref HEAD 2>/dev/null || echo 'unknown')"
  echo "cwd=$PROJECT_DIR"
  echo "handover_exists=false"
  echo "last_commit=$(git -C "$PROJECT_DIR" log -1 --format='%h %s' 2>/dev/null || echo 'unknown')"
  echo "modified_files=$(git -C "$PROJECT_DIR" diff --name-only HEAD 2>/dev/null | tr '\n' ',' | sed 's/,$//')"
  echo "untracked_files=$(git -C "$PROJECT_DIR" ls-files --others --exclude-standard 2>/dev/null | head -20 | tr '\n' ',' | sed 's/,$//')"
} > "$METADATA_FILE"

exit 0
