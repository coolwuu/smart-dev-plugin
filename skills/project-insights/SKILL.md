---
name: project-insights
description: Cross-session analytics — parse JSONL session files to detect patterns and friction hotspots
---

# /project-insights — Cross-Session Analytics

## Purpose
Analyze Claude Code JSONL session files to identify recurring patterns, friction hotspots, and generate evidence-based CLAUDE.md recommendations.

## Usage
```
/project-insights              # Default: last 30 days, top 10
/project-insights --days 7     # Last 7 days only
/project-insights --top 5      # Top 5 results per category
```

## Workflow

### Step 1: Derive Sessions Directory
Claude Code stores session files at `~/.claude/projects/<mangled-path>/` where the mangled path replaces `/` with `-`.

Compute the sessions directory dynamically:
```bash
PROJECT_DIR=$(pwd)
MANGLED=$(echo "$PROJECT_DIR" | sed 's|/|-|g')
SESSIONS_DIR="$HOME/.claude/projects/$MANGLED"
```

Verify the directory exists before proceeding. If not found, ask the user.

### Step 2: Run Analysis Script
Execute the Python extraction script:
```bash
python3 ~/.claude/skills/project-insights/scripts/extract.py \
  --sessions-dir "$SESSIONS_DIR" \
  --days {DAYS} --top {TOP}
```

Pass through any `--days` or `--top` arguments from the user's command. Default: `--days 30 --top 10`.

**Timeout**: 5 minutes max. If the script fails, report the error and suggest reducing `--days`.

### Step 3: Parse JSON Output
The script outputs a JSON summary to stdout. Parse it and present a formatted report.

### Step 4: Present Report
Format the JSON output into a readable report with these sections:

1. **Overview** — Sessions analyzed, total messages, total tokens, error count
2. **Friction Patterns** — High-error sessions, most common error types
3. **Tool Usage** — Most used tools, tool distribution percentages
4. **File Hotspots** — Most frequently read/edited files
5. **Repetition Detection** — Recurring errors across sessions, common tool sequences
6. **CLAUDE.md Recommendations** — Prioritized suggestions:
   - HIGH (5+ occurrences): Should definitely be added
   - MEDIUM (3-4 occurrences): Worth considering
   - LOW (2 occurrences): Monitor for trend

### Step 5: Update Stamp File
After successful analysis, update the stamp file:
```bash
date +%s > /tmp/claude-insights-last-run.txt
```

This is used by the insights-reminder hook to determine when to suggest re-running.

## Guardrails

- **Never read JSONL directly** — always use the Python script (files can be 170MB+)
- **No file modifications** without explicit user request
- **No raw session content exposed** — only aggregated patterns and statistics
- **Evidence-based only** — recommendations must cite frequency counts
- **5-minute timeout** for script execution
