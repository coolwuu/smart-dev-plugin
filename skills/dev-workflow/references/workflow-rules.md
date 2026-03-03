---
purpose: Phase sequence, validation, approvals, and execution rules
topics:
  - startup_flow
  - phase_sequence
  - validation_rules
  - approval_gates
  - tdd_enforcement
  - commit_approval
---

# Workflow Rules

Single source of truth for phase sequence, validation, approvals, and execution rules.

## Startup Flow

### On Invocation

1. **Load config** from project's CLAUDE.md:
   - `Phases`: Which phases to execute (default: 0,1,2,3,8)
   - `TDD`: required | optional | none (default: optional)
   - `FeatureDocsPath`: Where context.md lives (default: Documentation/Requirements/Feature)

2. **Get feature name** from user input or ask if not provided

3. **Detect mode**:
   - If `{FeatureDocsPath}/doing/{feature-name}/context.md` exists → RESUME
   - Otherwise → START (begin Phase 0)

4. **Phase 0 sequence** (mandatory, in order):
   a. **Create worktree** — `git worktree add` with feature branch (ALWAYS first)
   b. **Switch to worktree** — all subsequent work happens there
   c. **Create context.md** + OpenSpec init in the worktree
   d. **Run `/openspec-explore`** — design thinking before artifact generation
   e. **Run `/brainstorm`** *(optional — skill may not be available inside worktree context)* — structured brainstorming after explore
   f. **Run `Explore` agent** — codebase investigation

5. **Execute phases** 1-8 in configured sequence with validation at each transition (all within worktree)

## Phase Sequence

> **Schema Source:** `schema/phases.txt` (single source of truth for phase names, emojis, descriptions)

| Phase | Name | Required | Can Skip To |
|-------|------|----------|-------------|
| 0 | Worktree + Context Setup + Explore | Always | 1 only |
| 1 | Planning | Always | 2 only |
| 2 | Convention & Readiness Review | Always | 3 only |
| 3 | Implementation | Always | 4 only |
| 4 | Code Review — All findings resolved within Phase 4 | Always | 5 only |
| 5 | Refactor — Pre-scoped, behavior-preserving structural improvement | Always | 6, 7, or 8 |
| 6 | Summarization | Optional* | 7 or 8 |
| 7 | Retrospective | Optional* | 8 only |
| 8 | Approval & Commit | Always | Complete |

*Phases 6-7 require explicit user approval even if configured.

**Mandatory phases**: 0, 1, 2, 3, 4, 5, 8 (auto-added if missing from config)

### Phase 1 Sub-Activities (OpenSpec Artifacts)

Planning delegates to OpenSpec (defined in `schema/phases.txt`):

| Sub-Phase | Name | Output |
|-----------|------|--------|
| 1.1 | Proposal | proposal.md |
| 1.2 | Specifications | specs/*/spec.md |
| 1.3 | Design | design.md |
| 1.4 | Tasks | tasks.md |

**Rule**: Invoke `openspec-continue-change` per artifact. One at a time. User approves each.
Alternative: `openspec-ff-change` for batch creation.

## Phase Validation Rules

### Phase 0 → Phase 1

**Required:**
- Git worktree exists for feature branch
- Feature directory exists: `{FeatureDocsPath}/doing/{feature-name}/`
- context.md exists with required sections (including `**Worktree:**` path)
- OpenSpec change exists: `openspec/changes/{feature-name}/`
- context.md has `**OpenSpec Change:**` field populated
- `/openspec-explore` has been run (design thinking completed)
- `Explore` agent has been invoked

### Phase 1 → Phase 2

**Required (OpenSpec artifacts in openspec/changes/<name>/):**
- proposal.md exists
- specs/ directory non-empty (at least one spec)
- design.md exists
- tasks.md exists

**Required Approvals (in context.md Key Decisions):**
- Proposal approved
- Specifications approved
- Design approved
- Tasks approved

### Phase 2 → Phase 3

**Required:**
- Convention compliance checklist completed (all items are ✓ or ✓ RESOLVED)
- No open ⚠ violations remain — all resolved in OpenSpec artifacts
- Convention & Readiness Review recorded in context.md Key Decisions
- User approves transition to Phase 3 (Implementation)

### Phase 3 → Phase 4

**Required:**
- All tasks in OpenSpec tasks.md completed (`- [x]`)
- All tests passing
- Build succeeds

### Phase 4 → Phase 5

**Required:**
- Code review checklist completed
- ALL `[BLOCKER]` findings fixed and tests pass
- ALL `[SHOULD]` findings: Fixed or user-approved skip (recorded in context.md `## Key Decisions`)
- ALL `[NIT]` findings: Fixed or user-approved skip (recorded in context.md `## Key Decisions`)
- ALL `[QUESTION]` findings answered
- Phase 4 Exit Checklist signed off by user in code-review document

### Phase 5 → Phase 6/7/8

**Required:**
- Tests still passing after refactoring
- Build succeeds

### Phase 8 Complete

**Required:**
- All tests passing
- Build succeeds
- User explicitly approved commit

## Approval Gates

### Phase 1 Approvals (4 mandatory, via OpenSpec)

| Gate | After Creating | Action if Rejected |
|------|---------------|-------------------|
| 1.1 | proposal.md | Revise via openspec-continue-change |
| 1.2 | specs/*/spec.md | Revise via openspec-continue-change |
| 1.3 | design.md | Revise via openspec-continue-change |
| 1.4 | tasks.md | Revise via openspec-continue-change |

### Phase Transition Approvals

| Transition | Approval Required |
|------------|------------------|
| 0 → 1 | Yes (proceed to planning?) |
| 1 → 2 | Yes (all planning approved, start convention review?) |
| 2 → 3 | Yes (convention review complete, start implementation?) |
| 3 → 4 | Yes (implementation complete, start review?) |
| 4 → 5 | Yes (review complete, start refactor?) |
| 5 → 6/7/8 | Yes (choose next phase) |
| 8 Complete | **CRITICAL** - Explicit commit approval |

### Recording Approvals

Record all approvals in context.md `## Key Decisions` section:
```markdown
## Key Decisions
- Proposal approved (YYYY-MM-DD)
- Specifications approved (YYYY-MM-DD)
- Design approved (YYYY-MM-DD)
- Tasks approved (YYYY-MM-DD)
```

## TDD Enforcement (Phase 3)

| Setting | Behavior |
|---------|----------|
| `required` | Must write failing test before implementation. Block transition if tests missing. |
| `optional` | Suggest TDD but allow implementation-first. |
| `none` | No TDD reminders. Still validate tests exist before Phase 3. |

**TDD Cycle**: RED (failing test) → GREEN (make pass) → REFACTOR (improve)

## Code Review (Phase 4)

**Checklist categories:**
- Functionality: Requirements met, edge cases handled
- Code Quality: Conventions, no duplication, naming
- Testing: 80%+ coverage, meaningful tests
- Security: Input validation, no injection vulnerabilities
- Performance: Optimized queries, no N+1

**Process**: Skill presents checklist → User performs review → User marks complete

### Review Comment Taxonomy

Every finding from any sub-agent MUST be labeled before Phase 4 can close:

| Label | When to Use | Can Block Phase 4 Exit? | Disposition Rule |
|-------|-------------|------------------------|------------------|
| `[BLOCKER]` | Correctness bug, security flaw, convention violation | YES — must be fixed | No skip allowed |
| `[SHOULD]` | Best practice gap, not a hard violation | Only if user hasn't approved skip | Fixed OR user explicitly approves skip |
| `[NIT]` | Style preference within author's discretion | Only if user hasn't approved skip | Fixed OR user explicitly approves skip |
| `[QUESTION]` | Intent unclear, needs clarification | Only if unanswered | Must be answered before Phase 4 closes |

**Reviewer Authority** — what CAN carry `[BLOCKER]`:
- Correctness: code produces wrong output for defined inputs
- Security: OWASP vulnerability, missing auth check, injection risk
- Test failure: any test that does not pass
- Convention violation: rule explicitly defined in project tech-stack docs

**What CANNOT be a blocker:**
- Style preferences not codified in conventions
- "I would have done it differently"
- Refactoring requests that change structure without fixing a defect

### Phase 4 Disposition Requirement

Before Phase 4 closes, ALL sub-agent findings must have a recorded disposition:

1. `[BLOCKER]` — Fixed and tests pass (no skip allowed under any circumstances)
2. `[SHOULD]` — Fixed **OR** user explicitly approves skipping
3. `[NIT]` — Fixed **OR** user explicitly approves skipping
4. `[QUESTION]` — Answered before Phase 4 closes

**Nothing disappears silently.** Every finding needs a recorded disposition.
User approval of skipped items must be recorded in context.md `## Key Decisions`.

### Two-Session Rule (Phase 4)

If Phase 4 produces **≥ 5 total findings** or **≥ 3 blockers**, split into two sessions:

- **Session A** — Fix all `[BLOCKER]` findings only. Commit: `[BEHAVIORAL]: fix Phase 4 blockers`
- **Session B** — Address remaining `[SHOULD]` / `[NIT]` / `[QUESTION]` items

Record the split in context.md:
```markdown
- Phase 4 split: Session A (blockers, YYYY-MM-DD) | Session B (should/nits, YYYY-MM-DD)
```

This ensures blockers are always committed before context runs out. If findings are below the threshold, complete everything in one session as normal.

## Refactor (Phase 5)

**Definition:** Restructuring existing, *correct* code to improve internal design WITHOUT changing observable behavior.

**Proof of preservation:** The full test suite passes **before** and **after**, with **zero test file changes**.
If any test had to change, it was not a refactor — it was a behavior change.

**Pre-scoping rule:** Phase 5 scope MUST be declared in Phase 1 `tasks.md` or at Phase 3 start.
Phase 5 is NEVER triggered by Phase 4 findings.

**Skipping:** If nothing was pre-scoped, Phase 5 is simply skipped. No obligation.

**What IS a refactor:**
- Extract an 80-line service method into smaller, focused methods
- Rename an unclear SP parameter to match the project's SP naming convention
- Simplify deeply nested `if` chains in a controller action
- Move duplicated validation logic into a shared helper

**What is NOT a refactor:**
- Adding a missing query hint required by project conventions — that's a bug fix (`[BLOCKER]`)
- Changing SP parameter types — that's a behavior change
- Adding a new field to a DTO — that's a feature
- Rewriting a composable's API shape — that changes callers

**Validation steps:**
1. Run full test suite — confirm all pass (baseline)
2. Make structural changes
3. Run full test suite again — confirm still all pass
4. `git diff --name-only` — confirm zero test files changed

## Commit Approval (Phase 8)

**Pre-commit validation:**
- All tests passing
- Build succeeds
- All tasks completed

**CRITICAL**: Never commit without explicit user approval.

**Post-commit:**
- Move feature directory from `doing/` to `done/`
- Update context.md status to Complete
