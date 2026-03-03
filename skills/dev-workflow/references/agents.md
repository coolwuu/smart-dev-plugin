---
purpose: Agent orchestration strategy (MANDATORY ENFORCEMENT)
topics:
  - mandatory_invocation_protocol
  - agent_selection_by_phase
  - technology_specific_agents
  - confirmation_required
  - failure_handling
---

# Agent Orchestration (MANDATORY)

**CRITICAL: Agent invocation is MANDATORY, not optional. You MUST announce, confirm, and invoke agents at each phase transition.**

## Mandatory Invocation Protocol

### Step 1: ANNOUNCE (Required)
Before starting any phase, list required agents:
```
Phase {N} ({Name}) requires these agents:
- {agent-name}: {specific purpose for this feature}
- {agent-name}: {specific purpose for this feature}
```

### Step 2: CONFIRM (Required)
Use AskUserQuestion with options:
- "Invoke all agents" (Recommended)
- "Skip agents" (User must provide reason)

### Step 3: INVOKE (Required unless user explicitly skips)
Use Task tool with subagent_type for each approved agent.

### Step 4: REPORT (Required)
Summarize key findings from each agent before proceeding.

## Agent Selection by Phase

| Phase | Agent | Condition | MANDATORY? |
|-------|-------|-----------|------------|
| 0 | `using-git-worktrees` | Always (first step) | **YES** |
| 0 | `opsx:explore` | Always (after context setup) | **YES** |
| 0 | `Explore` | Always | **YES** |
| 1 | `Plan` | Always | **YES** |
| 1 | `backend-architect` | If backend changes | YES |
| 1 | `database-optimizer` | If database changes | YES |
| 2 | (none — main agent reads files) | Always | N/A |
| 3 | `test-automator` | When TDD: required | **YES** |
| 3 | `csharp-developer` | For .NET code | YES |
| 3 | `vue-expert` | For Vue/Nuxt code | YES |
| 4 | `code-reviewer`                        | Always — Wave 0 anchor (plan compliance) | **YES** |
| 4 | `architect-reviewer`                   | Always — Wave 1 parallel (SOLID, ADRs) | **YES** |
| 4 | `backend-development:security-auditor` | Always — Wave 1 parallel (OWASP, auth, injection) | **YES** |
| 4 | `performance-engineer`                 | Always — Wave 1 parallel (N+1, slow query patterns, blocking calls) | **YES** |
| 4 | `csharp-developer`                     | If backend domain changed — Wave 1 | Conditional |
| 4 | `database-optimizer`                   | If database domain changed — Wave 1 | Conditional |
| 4 | `vue-expert`                           | If frontend domain changed — Wave 1 | Conditional |
| 4 | `typescript-pro`                       | If frontend domain changed — Wave 1 | Conditional |
| 4 | `test-automator`                       | Always — Wave 1 parallel (test quality) | **YES** |
| 5 | `performance-engineer` | If issues found | YES |

## Phase 4 Execution Protocol

### Step 0: Domain Detection

```bash
git diff --name-only main...HEAD
```
Derive domain boundaries in priority order:
1. Read CLAUDE.md `Subdirectory Instructions` for explicit subdirectory → domain mappings
2. Fallback — file extension patterns from `git diff --name-only main...HEAD`:
   - `hasBackendChanges`  → `.cs` or `.csproj` files
   - `hasFrontendChanges` → `.vue` or `.ts` files
   - `hasDatabaseChanges` → `.sql` files

### Wave 0 (Sequential Anchor)

Invoke `code-reviewer` first. Scope: plan compliance only (proposal/specs/design.md vs implementation).
Pass Wave 0 summary to all Wave 1 agents as context.

### Wave 1 (Parallel — after Wave 0 completes)

Invoke all applicable agents simultaneously:

| Agent | Scope (No-Overlap Guarantee) | Condition |
|-------|------------------------------|-----------|
| `architect-reviewer` | SOLID principles, layering, ADR-001–ADR-012, DI | Always |
| `backend-development:security-auditor` | OWASP Top 10, auth flaws, injection, JWT/cookie security, input validation | Always |
| `performance-engineer` | N+1 queries, slow query patterns, blocking async calls, expensive re-renders, index gaps (read-only) | Always |
| `csharp-developer` | .NET 8 patterns: Dapper, typed exceptions, async/await, nullable | backend domain changed |
| `database-optimizer` | SP naming, query hints, GUID validation, audit columns, @@ROWCOUNT, timestamp functions | database domain changed |
| `vue-expert` | SSR safety, useFetch, composables, data-testid, CSS custom props | frontend domain changed |
| `typescript-pro` | Strict mode, no implicit any, props/emits typing, composable return types | frontend domain changed |
| `test-automator` | NUnit+Moq coverage (80%+), Vitest (95%+, project testing tech-stack guide), Playwright fixtures, AAA pattern | Always |

> `performance-engineer` in Phase 4 is **read-only** (identify issues). Phase 5 scope is profiling + fixing.

## Technology-Specific Agents

| Technology | Agents |
|------------|--------|
| Backend (.NET/C#) | csharp-developer, backend-architect |
| Database (SQL Server) | database-optimizer + suggest mssql-dev skill |
| Frontend (Vue/Nuxt) | typescript-pro, vue-expert, frontend-developer |
| UI/UX | ui-designer, ux-researcher |

## Skip Conditions (User MUST Explicitly Approve)

Agents may ONLY be skipped if:
- User explicitly says "skip agents" in AskUserQuestion response
- Feature is explicitly marked as "trivial" complexity
- Same agent already ran in current session with same scope

**NEVER silently skip agent invocation.**

## User Communication

**Before invoking (REQUIRED):**
```
Phase {N} requires the following agents:
- {agent-name}: {purpose}

[AskUserQuestion: Invoke agents?]
```

**After completion (REQUIRED):**
```
{Agent-name} complete. Key findings:
- {finding 1}
- {finding 2}
```

## Agent Failure

If agent fails or times out:
1. Inform user of issue
2. Offer to retry or continue manually
3. Log failure in context.md
4. Don't block workflow

## CRITICAL RULES

1. **ANNOUNCE → CONFIRM → INVOKE → REPORT** (mandatory sequence)
2. **NEVER skip without explicit user approval**
3. Agents assist decisions, don't replace them
4. User can override any agent suggestion
5. Never auto-invoke for commit approval

## Violation Consequences

If you proceed without following the protocol:
- User misses important analysis
- Quality may suffer
- Workflow is incomplete
- **This is a workflow violation**

## Superpowers Skill Integration

Superpowers skills enhance execution at specific phases.

### Phase-to-Skill Mapping

| Phase | Superpowers Skill | Purpose |
|-------|-------------------|---------|
| 0 | `using-git-worktrees` | Workspace isolation (mandatory, always first) |
| 0 | `opsx:explore` | Design thinking before artifact generation |
| 3 | `test-driven-development` | TDD enforcement (when TDD: required) |
| 3 | `subagent-driven-development` | Per-task subagent execution + 2-stage review |
| 3 | `executing-plans` | Batch execution with checkpoints |
| 3 | `dispatching-parallel-agents` | Parallel independent task streams |
| 4 | `requesting-code-review` | Dispatch review subagent with template |
| 5 | `receiving-code-review` | Technical rigor, no performative agreement |
| 8 | `verification-before-completion` | Evidence before claims |
| 8 | `finishing-a-development-branch` | Merge/PR/keep/discard options |

### Phase 3: Execution Model Choice

At the start of Phase 3, present the user with:

```
How should implementation be executed?

A) Subagent-Driven (superpowers:subagent-driven-development)
   → Fresh subagent per task, 2-stage review (spec + code quality)

B) Team Mode (spawn parallel agent team)
   → Requires team mode enabled in Claude Code settings
   → Spawns specialized agents per task stream (DB, backend, frontend, E2E)

C) Batch Execution (superpowers:executing-plans)
   → Execute tasks in batches of 3, review checkpoints between

D) Direct Implementation
   → Manual task-by-task, no delegation

[AskUserQuestion]
```

OpenSpec's `tasks.md` serves as the plan for all execution models.

### Phase 3: Team Mode (When Enabled)

If user chooses Team Mode and Claude Code team features are available:

1. **Parse OpenSpec tasks.md** for independent task streams/batches
2. **Create team** via TeamCreate with feature name
3. **Create tasks** via TaskCreate from OpenSpec tasks.md items
4. **Spawn teammates** via Task tool with `team_name` parameter:
   - Assign `subagent_type` based on task domain (e.g., `csharp-developer`, `vue-expert`, `database-optimizer`)
   - Each teammate gets: task description, relevant OpenSpec artifacts (design.md, specs/), file scope
5. **Coordinate**: Mark tasks in TaskList as teammates complete them
6. **Sync back**: When all teammates done, update OpenSpec tasks.md checkboxes (`- [x]`)
7. **Shutdown team** via SendMessage shutdown_request to each teammate

Team mode follows the same file ownership boundaries:
- DB agent: database domain (`.sql` files / database subdirectory per CLAUDE.md)
- Backend agent: backend domain (`.cs`/`.csproj` files / backend subdirectory)
- Frontend agent: frontend domain (`.vue`/`.ts` files / frontend subdirectory)
- E2E agent: e2e domain (playwright config / e2e subdirectory)

### Phase 8: Verification + Finalization

1. `superpowers:verification-before-completion` — run tests, provide evidence
2. `openspec-verify-change` — validate implementation matches specs/tasks
3. `superpowers:finishing-a-development-branch` — present 4 options (merge/PR/keep/discard)
4. `openspec-archive-change` + optional `openspec-sync-specs` — finalize artifacts
