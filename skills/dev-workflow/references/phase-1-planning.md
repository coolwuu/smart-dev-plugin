---
purpose: Phase 1 planning via OpenSpec artifact workflow
topics:
  - ask_user_question
  - openspec_delegation
  - artifact_sequence
  - approval_flow
---

# Phase 1: Planning (OpenSpec Delegation)

Phase 1 delegates planning to OpenSpec's artifact workflow. Instead of 5 separate documents,
invoke OpenSpec to produce 4 artifacts: proposal, specs, design, tasks.

## Critical First Step

**Use AskUserQuestion BEFORE starting artifact creation** to clarify:
- Unclear functional requirements
- Missing non-functional requirements
- Implementation preferences
- Priority and scope boundaries

## Artifact Sequence

| # | Artifact | Output | Purpose |
|---|----------|--------|---------|
| 1 | Proposal | proposal.md | Why, what changes, capabilities, impact |
| 2 | Specs | specs/*/spec.md | Delta specs per capability (WHEN/THEN scenarios) |
| 3 | Design | design.md | Technical decisions, architecture, approach |
| 4 | Tasks | tasks.md | Checkboxed implementation tasks in batches |

**Rule**: Create ONE artifact at a time via `openspec-continue-change`.
User approves each before proceeding to next.

## How It Works

### Step 1: Clarify Requirements
Use AskUserQuestion to gather context before creating any artifacts.

### Step 2: Create Artifacts via OpenSpec
Invoke `openspec-continue-change` skill repeatedly:
- Each invocation creates ONE artifact
- OpenSpec reads dependency artifacts for continuity
- User reviews and approves after each
- Continue until all 4 artifacts are complete

### Alternative: Fast-Forward
If user wants all artifacts created at once:
- Invoke `openspec-ff-change` skill
- Creates all artifacts in dependency order without stepping through
- Still requires user review of final result

## WHAT vs HOW (Natural Separation)

OpenSpec artifacts naturally separate concerns:
- **proposal.md** + **specs/** = WHAT (requirements, acceptance criteria, scenarios)
- **design.md** + **tasks.md** = HOW (technical decisions, implementation steps)

## Completion Validation

Phase 1 is complete when:
- All 4 artifacts exist in `openspec/changes/<name>/`
- All approvals recorded in context.md Key Decisions
