#!/bin/bash
# Agent Model Guard — Blocks Agent tool calls that omit the `model` parameter
# Hook: PreToolUse (Agent)
#
# Exit 0 = allow, Exit 2 = block
#
# Policy (from CLAUDE.md):
#   - Default: sonnet for all subagents
#   - Haiku: read-only lookups (<5 tool uses)
#   - Opus: handover, planning, or explicit user request
#   - NEVER omit the model parameter

set -eo pipefail

INPUT=$(cat)

# Extract model from Agent tool_input
MODEL=""
if command -v jq &>/dev/null; then
  MODEL=$(echo "$INPUT" | jq -r '.tool_input.model // empty' 2>/dev/null || true)
fi

# model parameter present — allow
[ -n "$MODEL" ] && exit 0

# Extract agent name and type for the error message
AGENT_NAME=$(echo "$INPUT" | jq -r '.tool_input.name // "unnamed"' 2>/dev/null || true)
AGENT_TYPE=$(echo "$INPUT" | jq -r '.tool_input.subagent_type // "unknown"' 2>/dev/null || true)

echo ""
echo "✗  BLOCKED: Agent '${AGENT_NAME}' (${AGENT_TYPE}) invoked without explicit model parameter!"
echo ""
echo "   Policy: Every Agent call MUST specify model: \"sonnet\" | \"haiku\" | \"opus\""
echo ""
echo "   Quick guide:"
echo "     sonnet  — default for all agents"
echo "     haiku   — read-only lookups (<5 tool uses)"
echo "     opus    — handover, planning, or user-requested"
echo ""
exit 2
