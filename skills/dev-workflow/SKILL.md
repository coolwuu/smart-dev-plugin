---
name: dev-workflow
description: Configurable 9-phase feature development workflow enforcer (Phase 0 Context Setup → Phase 8 Approval & Commit). Delegates planning to OpenSpec (proposal→specs→design→tasks) and enhances execution with superpowers skills (TDD, subagent-driven-development, worktrees, verification). Auto-validates phase transitions, manages state via context.md, and orchestrates specialized agents. Use when user says "start feature" or "resume feature", mentions implementing/building/creating a feature, needs structured development process, references TDD or test-driven development, asks about feature planning or implementation phases, references 9-phase workflow or mentions "Phase 1" or "Planning phase", needs approval gates or phase validation, or asks "how do I start a feature" or "what's the development workflow".
---

# Feature Development Skill

Enforce configurable 9-phase feature development workflow with phase validation, state management, and approval gates.

## Configuration

Read from project's `CLAUDE.md`:

```markdown
## Feature Development Workflow

**Phases:** 0,1,2,3,4,7
**TDD:** required
**FeatureDocsPath:** Documentation/Requirements/Feature
```

| Option | Values | Default |
|--------|--------|---------|
| **Phases** | 0-8 (comma-separated) | 0,1,2,3,8 |
| **TDD** | required / optional / none | optional |
| **FeatureDocsPath** | Path from root | Documentation/Requirements/Feature |

**Note:** Phases 0, 1, 2, 3, 4, 5, 8 are mandatory (auto-added if missing). Phases 6-7 require explicit approval.

## 9-Phase Workflow

> **Schema Source:** `schema/phases.txt` (single source of truth for phase names, emojis, statuses)

| Phase | Name | Status |
|-------|------|--------|
| 0 | Worktree + Context Setup + Explore | Required |
| 1 | Planning (4 OpenSpec artifacts) | Required |
| 2 | Convention & Readiness Review | Required |
| 3 | Implementation | Required |
| 4 | Code Review — All findings resolved within Phase 4 | Required |
| 5 | Refactor — Pre-scoped structural improvement, independent of review findings | Required |
| 6 | Summarization | Optional* |
| 7 | Retrospective | Optional* |
| 8 | Approval & Commit | Required |

*Phases 6-7 require explicit user approval before execution.

### Phase 1 Sub-Phases (OpenSpec Artifacts)

| Sub-Phase | Output |
|-----------|--------|
| 1.1 Proposal | proposal.md |
| 1.2 Specifications | specs/*/spec.md |
| 1.3 Design | design.md |
| 1.4 Tasks | tasks.md |

Phase 1 delegates to OpenSpec skills (`openspec-continue-change` or `openspec-ff-change`).

## How to Use

1. **Load config** from CLAUDE.md
2. **Detect mode**: context.md exists → resume, otherwise → start Phase 0
3. **Phase 0 sequence** (mandatory, in order):
   a. **Create worktree** — feature branch + worktree is ALWAYS the first step
   b. **All subsequent work happens in the worktree** — context.md, OpenSpec, code, everything
   c. **Create context.md** + OpenSpec init in the worktree
   d. **Run `/openspec-explore`** — design thinking before artifact generation
   e. **Run `/brainstorm`** *(optional — only if available in current context)* — structured brainstorming after explore
4. **Execute phases** 1-8 in configured sequence (all within worktree)
5. **Validate** completion before transitions
6. **Get approvals** at gates
7. **Update context.md** after every step

## State Management

- **Single file**: `{FeatureDocsPath}/doing/{feature-name}/context.md`
- **Skill updates**: Status, Current Phase, Last Updated
- **Hook updates**: What's Been Completed, Next Todo
- **After completion**: Move to `done/` directory

## Schema

| File | Purpose |
|------|---------|
| **schema/phases.txt** | Single source of truth for phases, sub-phases, and statuses |

The schema file defines:
- Main phases (0-8) with names, emojis, descriptions
- Sub-phases for Phase 1 (1.1-1.4) with OpenSpec output files
- Valid status values (in_progress, complete, blocked, paused)

Both the skill templates and stop hook read from this schema.

## References (6 files)

| File | Purpose |
|------|---------|
| **workflow-rules.md** | Phase sequence, validation, approvals, TDD, commit |
| **context-file.md** | context.md format, updates, parsing |
| **phase-1-planning.md** | Phase 1 sub-activities and WHAT vs HOW |
| **phase-2-convention-review.md** | Phase 2 convention loading, cross-check, violation rules |
| **agents.md** | Agent orchestration strategy |
| **errors.md** | Error scenarios and recovery |

## Templates

| Template | Purpose |
|----------|---------|
| context-template.md | context.md structure (includes OpenSpec change link) |
| code-review-template.md | Phase 4 code review |
| retrospective-template.md | Phase 7 learnings |

**Note:** Phase 1 uses OpenSpec's own artifact templates (via `openspec instructions`).

## Critical Rules

1. Load configuration from CLAUDE.md first
2. Phases 0, 1, 2, 3, 4, 5, 8 are mandatory
3. **Worktree is ALWAYS the first step** — create feature branch + worktree before anything else
4. **All work happens in the worktree** — context.md, OpenSpec, implementation, everything
5. **`/openspec-explore` before Phase 1** — design thinking is mandatory before artifact generation
6. Use ONLY context.md for state
7. Validate phase completion before transitions
8. **Phase 1**: Delegate to OpenSpec — `openspec-continue-change` per artifact → Get approval → Next (4 gates)
9. **Update context.md header** (Status, Current Phase, Last Updated) after every step
10. **Never commit without explicit user approval**
11. **MANDATORY AGENT INVOCATION** - See below

## MANDATORY: Agent Invocation Protocol

**YOU MUST FOLLOW THIS PROTOCOL FOR EVERY PHASE TRANSITION:**

### Step 1: Announce (REQUIRED)
Before starting any phase, announce which agents are required:
```
Phase {N} ({Name}) requires these agents:
- {agent-name}: {specific purpose for this feature}
```

### Step 2: Confirm (REQUIRED)
Use AskUserQuestion to get explicit confirmation:
```
Options:
- "Invoke all agents" (Recommended)
- "Skip agents" (Must provide reason)
```

### Step 3: Invoke (REQUIRED unless user skips)
Use Task tool with appropriate subagent_type for each approved agent.

### Step 4: Report (REQUIRED)
After each agent completes, summarize key findings before proceeding.

### Required Agents by Phase

| Phase | Agent | When Required |
|-------|-------|---------------|
| 0 | `Explore` | ALWAYS |
| 1 | `Plan` | ALWAYS |
| 1 | `backend-architect` | If backend changes |
| 1 | `database-optimizer` | If database changes |
| 2 | (none — main agent reads files) | Always |
| 3 | `test-automator` | When TDD: required |
| 3 | `csharp-developer` | For .NET code |
| 3 | `vue-expert` | For Vue/Nuxt code |
| 4 | `code-reviewer`                        | Always — Wave 0 anchor (plan compliance) |
| 4 | `architect-reviewer`                   | Always — Wave 1 parallel (SOLID, ADRs) |
| 4 | `backend-development:security-auditor` | Always — Wave 1 parallel (OWASP, auth, injection) |
| 4 | `performance-engineer`                 | Always — Wave 1 parallel (N+1, slow query patterns, blocking calls) |
| 4 | `csharp-developer`                     | If {backend}/ or {backend}.Tests/ changed — Wave 1 |
| 4 | `database-optimizer`                   | If {database}/ changed — Wave 1 |
| 4 | `vue-expert`                           | If {frontend}/ changed — Wave 1 |
| 4 | `typescript-pro`                       | If {frontend}/ changed — Wave 1 |
| 4 | `test-automator`                       | Always — Wave 1 parallel (test quality) |
| 5 | `performance-engineer` | If issues found |
| 7 | `claude-md-management:revise-claude-md` | ALWAYS |
| 7 | `claude-code-setup:claude-automation-recommender` | ALWAYS |

**Phase 4 domain detection** (run `git diff --name-only main...HEAD` before announcing):
Wave 0 runs first; Wave 1 agents run in parallel after Wave 0 completes.
Announce only applicable agents based on changed directories.

### NEVER Skip Silently

If you proceed without invoking required agents:
1. You are violating the workflow
2. User may miss important analysis
3. Quality may suffer

**Always announce → confirm → invoke → report**

## Integration

**Schema**: Both skill and stop hook read from `schema/phases.txt`.

**Stop hook**: Updates "What's Been Completed" and "Next Todo" (supports OpenSpec artifacts with fallback).

**Superpowers skills** (Phase 0): `using-git-worktrees` (mandatory — always create worktree first)
**OpenSpec skills** (Phase 0): `opsx:explore` (mandatory — design thinking before artifacts)
**OpenSpec skills** (Phase 1): `openspec-new-change`, `openspec-continue-change`, `openspec-ff-change`
**OpenSpec skills** (Phase 8): `openspec-verify-change`, `openspec-archive-change`, `openspec-sync-specs`
**Superpowers skills** (Phase 3): `test-driven-development`, `subagent-driven-development`, `executing-plans`, `dispatching-parallel-agents`
**Superpowers skills** (Phase 4-5): `requesting-code-review`, `receiving-code-review`
**CLAUDE.md management** (Phase 7): `claude-md-management:revise-claude-md`, `claude-code-setup:claude-automation-recommender`
**Superpowers skills** (Phase 8): `verification-before-completion`, `finishing-a-development-branch`

**Related skills**: `mssql-dev` for database work.
**Workflow docs**: project workflow directory (e.g. `.ai/workflows/implementation.md` if present)
