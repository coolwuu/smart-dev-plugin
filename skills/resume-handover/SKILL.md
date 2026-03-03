---
name: resume-handover
description: Resume work from a handover document created by /auto-handover. Finds the most recent handover, verifies state, and continues where the previous session left off.
user_invocable: true
---

# Resume from Handover

Resume a previous session using a handover document.

## Instructions

### Step 1: Find the Handover Document

Check the skill arguments first. The user may invoke this as `/resume-handover path/to/file.md`.

1. **User-provided path (argument)**: If the user provides a file path as an argument, use it directly — **skip all discovery below and go straight to Step 2**. Do NOT list other files or ask which one to use.
2. **Project handover directory** (only if no argument provided): Read `HandoverPath:` from `CLAUDE.md` (fallback: `./handover/`)
   - Find the most recent `.md` file in that directory
   - If multiple handover files exist, list the 5 most recent and ask the user which one to use
3. **Pre-compact metadata** (only if no `.md` handover found): Check for `.pre-compact-metadata.txt` in the handover directory
   - If this exists but no `.md` handover exists, inform the user: "Only pre-compact metadata is available. The previous session was compacted before a full handover could be generated."
   - Read the metadata and present what's available

### Step 2: Read and Parse

1. **Read the handover document** completely
2. **Parse YAML frontmatter** for metadata:
   - `auto_continue`: if `true`, proceed without asking; if `false`, present plan and confirm
   - `session_branch`: verify we're on the correct git branch
   - `feature` / `phase`: understand the workflow context
   - `working_directory` / `worktree`: verify we're in the right location

### Step 3: Verify Current State

Run these checks and report any discrepancies:

1. **Git branch**: Does current branch match `session_branch`? If not, warn.
2. **Working directory**: Are we in the right project?
3. **Key files**: Do the files listed in "Important Files" still exist?
4. **Uncommitted changes**: Does git state match what "Current State" describes?
5. **Build check**: If the handover mentions build state, verify it's still clean

### Step 4: Present Resumption Plan

Display a concise summary:

```
📋 Resuming from: {handover filename}
   Created: {created_at}
   Feature: {feature} | Phase: {phase} | Branch: {session_branch}

✅ Previously completed:
   {numbered list from "What Was Completed" — abbreviated}

📝 Continuing with:
   1. {first item from "What Needs To Continue"}
   2. {second item}
   ...

{Any discrepancies found during verification}
```

### Step 5: Begin Work

- If `auto_continue: true` → proceed directly to the first item in "What Needs To Continue"
- If `auto_continue: false` → ask the user: "Ready to continue with item 1?"
- Follow the "Resume Instructions" section for orientation steps before diving in

## Handling Pre-Compact Metadata Only

If only `.pre-compact-metadata.txt` exists (no full handover):

1. Read the metadata file
2. Present what's available:
   ```
   ⚠️ No full handover found. Pre-compact metadata available:
      Branch: {branch}
      Last commit: {last_commit}
      Modified files: {modified_files}
      Untracked files: {untracked_files}
   ```
3. Suggest: "I can reconstruct context from git history, modified files, and project docs. Shall I investigate and create a work plan?"
4. If user agrees, read the modified/untracked files and recent git log to reconstruct what was being worked on

## Important Notes

- **Always verify state before resuming** — things may have changed between sessions
- **Don't assume** — if something in the handover doesn't match current state, ask the user
- **Clean up after successful resume**: Once work is underway, the handover file can stay for reference (don't delete it)
