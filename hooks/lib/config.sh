#!/usr/bin/env bash
# hooks/lib/config.sh — shared config loader for smart-dev plugin
# Source this from any hook that needs project config.
#
# Resolution order:
#   1. <git-root>/.claude/smart-dev.json   (project-local)
#   2. $PLUGIN_ROOT/profiles/default.json  (plugin fallback)
#   3. No config (safe generic defaults)

PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"

# Resolve project root via git (works from any subdirectory)
PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || echo "$PWD")

# Check jq availability once
if ! command -v jq &>/dev/null; then
  echo "[smart-dev] warning: jq not found — config will not be loaded. Install: brew install jq" >&2
  CONFIG_FILE=""
elif [ -f "$PROJECT_ROOT/.claude/smart-dev.json" ]; then
  # Validate JSON before using it
  if jq empty "$PROJECT_ROOT/.claude/smart-dev.json" 2>/dev/null; then
    CONFIG_FILE="$PROJECT_ROOT/.claude/smart-dev.json"
  else
    echo "[smart-dev] warning: $PROJECT_ROOT/.claude/smart-dev.json is not valid JSON — falling back to defaults" >&2
    CONFIG_FILE="$PLUGIN_ROOT/profiles/default.json"
  fi
elif [ -f "$PLUGIN_ROOT/profiles/default.json" ]; then
  CONFIG_FILE="$PLUGIN_ROOT/profiles/default.json"
else
  CONFIG_FILE=""
fi

# get_config <jq_expression> [default_value]
# Reads a value from the resolved config file using jq.
# Returns the default if config is missing or the key is absent.
get_config() {
  local key="$1" default="${2:-}"
  if [ -n "$CONFIG_FILE" ]; then
    local result
    result=$(jq -r "$key // empty" "$CONFIG_FILE" 2>/dev/null)
    if [ -n "$result" ]; then
      echo "$result"
    else
      echo "$default"
    fi
  else
    echo "$default"
  fi
}
