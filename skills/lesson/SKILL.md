---
name: lesson
description: Post-session retrospective — append tagged learnings (with severity) to configured learnings file (default: `learnings.md`)
---

# /lesson — Session Learning Capture

## Purpose

Extract actionable, project-specific learnings from friction encountered in the current session and append them to the configured learnings file (default: `learnings.md`, reads `lessonFilePath` from project config when set) with domain and severity tags.

## Workflow

### Step 1: Scan for Friction Patterns

Review the current conversation for these pattern types, ordered by priority:

| Pattern | Signal | Example |
|---------|--------|---------|
| **Repeated failure** | Same error/approach tried 2+ times | Forgot `WITH(NOLOCK)` again, same enum serialization bug |
| **Troubleshooting spiral** | 3+ back-and-forth attempts to fix one issue | 4 tries to fix login fixture timing before finding networkidle |
| **Wrong assumption** | Approach based on incorrect mental model | Assumed `MustAsync` runs in same pipeline as sync validators |
| **User correction** | User had to redirect or correct the agent | "No, use Dapper not EF" or "That's the wrong table" |
| **Convention violation** | Broke a project convention, had to redo | Missing audit columns, wrong SP naming, hardcoded hex colors |
| **Tool/API surprise** | Tool or API behaved unexpectedly | `git add` silently fails with bracket paths in zsh |
| **Failed tool use** | Tool invoked incorrectly, skipped, or retried unnecessarily | Used Edit before Read, used Bash grep instead of Grep tool, wrong sqlcmd flag syntax |
| **Process shortcut** | Skipped a required workflow step | Claimed completion without running tests, made design decision without AskUserQuestion, skipped EnterPlanMode for 3+ file change |

### Step 2: Extract Tagged + Severity-Labeled Learnings

Each learning gets:
- **Date**: `YYYY-MM-DD`
- **Domain tag**: `[backend]`, `[frontend]`, `[db]`, `[e2e]`, `[workflow]`, `[tooling]`, `[shell]`, `[process]`
  - `[process]` — tool discipline violations, skipped workflow steps, wrong-sequence tool use
- **Severity tag**: `[one-off]`, `[recurring]`, `[spiral]`
  - `[one-off]` — happened once, but non-obvious enough to record
  - `[recurring]` — same mistake or pattern seen before (check existing entries in the configured learnings file)
  - `[spiral]` — required 3+ attempts or a long back-and-forth to resolve

Quality bar: project-specific, actionable, non-obvious, 1-2 sentences max.

For `[recurring]` entries: read the configured learnings file to check if a similar entry already exists. If so, append a count bump like `(x3)` to the new entry to track frequency.

### Step 3: Append to the configured learnings file (default: `learnings.md`)

Silently append — no `AskUserQuestion`, no multi-file routing. Just append.

Entry format:
```
- **2026-02-23** [backend] [spiral] Login fixture timing — 4 attempts before finding networkidle fix
- **2026-02-23** [db] [recurring] (x3) Forgot WITH(NOLOCK) on SELECT query
- **2026-02-23** [tooling] [one-off] SP parameter order mismatch caused silent null
- **2026-02-23** [process] [recurring] (x2) Used Edit before Read — always Read the file first, even for "obvious" edits
- **2026-02-23** [process] [one-off] Skipped EnterPlanMode for 4-file change — caused rework; use plan mode for 3+ files
```

**Mistake entries must include the correction** — record not just what failed, but what to do instead next time.

## Guardrails

- **No invented learnings** — only extract from actual friction observed in the conversation
- **No general advice** — "always test your code" is not a valid learning; "Moq.Dapper fails on scalar Guid — wrap in record IdResult" is
- **Keep it concise** — each learning should be 1-2 sentences max
- **For `[recurring]` tagging** — quickly scan existing entries in the configured learnings file (the only file read)
- **`[process]` entries must include the correction** — "Used Edit before Read" is incomplete; "Used Edit before Read — always Read first to confirm line content" is valid
