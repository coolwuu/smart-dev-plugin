#!/usr/bin/env bash
# user-prompt-submit.sh — Inject git branch + status into session context
# Matcher: all
# Event: UserPromptSubmit

set -euo pipefail

# Only inject if we're in a git repo
if ! git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
  exit 0
fi

BRANCH=$(git branch --show-current 2>/dev/null || echo "detached")
STATUS=$(git status --short 2>/dev/null | head -20)
CHANGED=$(echo "$STATUS" | grep -c '^.' || true)
CHANGED=${CHANGED:-0}

if [ "$CHANGED" -gt 0 ]; then
  echo "Git: branch=$BRANCH, $CHANGED file(s) changed"
else
  echo "Git: branch=$BRANCH, working tree clean"
fi

exit 0
