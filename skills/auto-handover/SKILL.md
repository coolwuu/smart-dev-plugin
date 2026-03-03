---
name: auto-handover
description: Save current session state to a handover document for seamless continuation in a new session. Invoke manually or triggered automatically when context window reaches 85%.
user_invocable: true
---

# Auto-Handover: Save Session State

Generate a comprehensive handover document that captures the current session state for seamless continuation in a new session.

## Instructions

### Step 1: Determine Output Location

1. Read `CLAUDE.md` in the project root and look for `HandoverPath:` configuration
2. If found, use `{project_root}/{HandoverPath}/` as the output directory
3. If not found, use `{project_root}/handover/` as fallback, creating it if needed
4. Filename: `{feature-or-task}-{phase(if any)}-{status}.md`
   - **feature-or-task**: kebab-case name of the feature or task (e.g., `epic-3.2-availability`, `guid-migration`, `security-remediation`)
   - **phase**: include only if in a dev-workflow phase (e.g., `phase2`, `phase3`). Omit if N/A.
   - **status**: current state — `in-progress`, `complete`, `blocked`, etc.
   - Examples:
     - `epic-3.2-availability-phase3-complete.md`
     - `guid-migration-complete.md`
     - `security-remediation-phase2-in-progress.md`

5. **One file per feature (overwrite rule)**: Before writing the new handover file, check the output directory for any existing file whose name starts with the same `{feature-or-task}` prefix. If found, **delete it** — the new file replaces it. This prevents file accumulation when the same feature progresses through phases.
   - Example: saving `epic-3.2-availability-phase3-complete.md` should first delete any existing `epic-3.2-availability-*.md`

### Step 2: Gather Context

Collect the following information (use your full conversation context — this is why it's important to run this BEFORE context is lost):

1. **Read `/tmp/claude-context-pct.txt`** if it exists — include the percentage in metadata
2. **Check git state**: current branch, uncommitted changes, last commit
3. **Review the conversation**: identify key decisions, learnings, completed work, and remaining tasks
4. **Identify important files**: files that were created, modified, or are critical for continuing

### Step 3: Generate Handover Document

Write the document with this exact structure:

```markdown
---
auto_continue: false
threshold_triggered: {percentage from temp file, or "manual" if invoked manually}
created_at: {ISO 8601 timestamp}
session_branch: {current git branch}
feature: {feature name if in feature-dev workflow, otherwise "general"}
phase: {current phase number if in feature-dev workflow, otherwise "N/A"}
working_directory: {absolute path to project}
worktree: {worktree path if applicable, otherwise omit}
---

# Session Handover: {Short Description}

## Context
{1-2 sentences: What was the user working on? What was the overall goal of this session?}

## Key Decisions Made
{Bullet list of architectural, design, or implementation decisions made during this session.
Each decision should include WHY it was made, not just WHAT was decided.}

## Key Learnings
{Bullet list of important discoveries, gotchas, or patterns found during this session.
Focus on things that would be lost if context were cleared — things not documented elsewhere.}

## What Was Completed
{Numbered list of completed work items. Include file paths for each item.
Be specific — "Implemented X in Y file" not just "Worked on X".}

## Important Files
{Markdown table with columns: File Path | Purpose | Status (new/modified/reviewed)}

## Current State
{Describe the exact state right now:
- Are there uncommitted changes? What are they?
- Do tests pass? Which ones were run?
- Is the build clean?
- Any errors or issues currently unresolved?}

## What Needs To Continue
{Ordered list of remaining work items with enough detail to resume without prior context.
Each item should be actionable — not "finish the feature" but "implement the validation logic in X file for Y scenario".}

## Resume Instructions
{Step-by-step instructions for the next session to pick up exactly where this one left off:
1. What branch/worktree to be on
2. What to read first to get oriented
3. What command to run to verify state
4. What task to start with}
```

### Step 4: Clean Up

1. **Delete all cooldown files**: `rm -f /tmp/claude-handover-warned.txt /tmp/claude-auto-handover-blocked.txt /tmp/claude-context-gate-lock.txt /tmp/claude-context-growth.txt /tmp/claude-context-warned-warn.txt /tmp/claude-context-warned-urge.txt` (resets context gate + legacy warnings for future sessions)
2. **Delete any pre-compact metadata**: Remove `.pre-compact-metadata.txt` from the handover directory if it exists (the full handover supersedes it)

### Step 5: Inform User

After generating the handover, inform the user:

```
✅ Handover saved to: {file path}

When ready, run /clear to reset context, then /resume-handover to continue.
```

**Check user preference**: If this was triggered automatically (not manually), ask the user:
- "Would you like me to continue working in the current context, or are you ready to /clear?"
- If the user says "keep continue" or similar, note this preference — future handovers in this session should just save without prompting.

## Important Notes

- **Do NOT skip sections** — every section must be filled in, even if brief
- **Be specific** — vague handovers are useless. File paths, function names, exact state
- **Prioritize what's NOT documented elsewhere** — don't repeat what's in CLAUDE.md or feature docs
- **This is your last chance** to capture session knowledge before it's lost
