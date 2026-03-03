---
purpose: Phase 2 Convention & Readiness Review — domain detection, filtered loading, cross-check, violation resolution
topics:
  - domain_detection
  - filtered_convention_load
  - comprehension_re_read
  - checklist_format
  - violation_resolution
  - exit_conditions
---

# Phase 2: Convention & Readiness Review

Hard gate between planning and implementation. Loads ADRs and tech-stack gotchas relevant to the feature's domains, re-reads all 4 OpenSpec artifacts, cross-checks for convention violations, and resolves any violations in the spec **before implementation begins**.

No subagents required — this phase is performed by the main agent.

## Entry Condition (Phase 1 → Phase 2)

- All 4 OpenSpec artifacts exist in `openspec/changes/<name>/`
- All 4 approvals recorded in `context.md` Key Decisions

## Step 1: Domain Detection

Check CLAUDE.md `Subdirectory Instructions` section first. If subdirectory → domain mappings
are declared there, use them directly (most precise). Otherwise fall back to file extension
patterns from `tasks.md` content:

| Flag | Primary (CLAUDE.md subdirs) | Fallback (keywords / extensions) |
|------|-----------------------------|----------------------------------|
| `hasBackend`  | backend subdirectory declared | `.NET`, `C#`, controller, service, `.cs` files |
| `hasDatabase` | database subdirectory declared | stored procedure, SQL, migration, `.sql` files |
| `hasFrontend` | frontend subdirectory declared | Vue, Nuxt, component, composable, `.vue` files |
| `hasE2E`      | e2e subdirectory declared      | Playwright, E2E, test fixture |

## Step 2: Filtered Convention Load

**Tech-stack discovery**: Scan the project tech-stack directory (read `TechStackPath:` from CLAUDE.md; defaults to `.ai/tech-stack/`) subdirectories by domain flag. Load convention files from matched subdirectories. Do NOT hardcode filenames — the project's tech-stack directory structure is authoritative.

> ⚠️ If the project tech-stack directory does not exist: warn the user —
> "No project tech-stack found. Applying generic conventions only.
> Create tech-stack convention files to get project-specific guidance."

| Condition     | Load |
|---------------|------|
| Always        | ADR directory: read `AdrPath:` from CLAUDE.md; if absent, scan project root for any `adr/` directory. Load ALL files found. |
| `hasBackend`  | All files in the project tech-stack `backend/` subdirectory **except** `gotchas.md` |
| `hasDatabase` | All files in the project tech-stack `database/` subdirectory **except** `gotchas.md` |
| `hasFrontend` | All files in the project tech-stack `frontend/` subdirectory |
| `hasE2E`      | project tech-stack `testing/e2e.md` + `testing/vitest.md` |

> **Gotchas files are never loaded by default.** Load `gotchas.md` from the relevant
> subdirectory only when debugging a specific edge case or when Phase 4 review identifies
> a gotcha-class issue.

## Step 3: Comprehension Re-Read

Read all 4 OpenSpec artifacts in order:

1. `proposal.md`
2. `specs/*/spec.md` (all spec files)
3. `design.md`
4. `tasks.md`

## Step 4: Cross-Check & Produce Checklist

For each loaded ADR and tech-stack file, verify the design and tasks comply. Output a checklist in chat:

```
Convention & Readiness Review Checklist
Domains: Backend, Database

ADRs Reviewed: adr/architecture/ (all), adr/database/ (all)
Tech-stack: <discovered files>

Violations Found:
⚠ design.md proposes raw Exception — MUST use typed exceptions (backend/exceptions.md)
  → Resolution required: Update design.md

Clean Items:
✓ GUIDs used as PKs (ADR-012)
✓ SP naming follows {Project}_Entity_Op pattern (per project database conventions)
✓ WITH(NOLOCK) noted on all SELECT queries (database/sp-conventions.md)
...

Comprehension:
✓ All 4 OpenSpec artifacts re-read
✓ No blocking ambiguities in tasks.md
```

## Step 5: Resolve Violations (HARD GATE)

**NO BYPASSING.** For each `⚠` violation:

1. Update the relevant OpenSpec artifact (`design.md` or `tasks.md`)
2. Re-record the resolution in the checklist: `⚠ → ✓ RESOLVED: [what was changed]`
3. All violations must be resolved before Phase 3 begins

If a "violation" is determined to be a false positive (convention does not actually apply), document the reasoning as a clean item with a note.

## Step 6: Record in context.md

Under `## Key Decisions`:

```markdown
- Convention & Readiness Review complete (YYYY-MM-DD)
  Domains: Backend, Database
  ADRs: architecture/ (all), database/ (all) | Tech-stack: backend/exceptions.md, database/sp-conventions.md
  Violations found: 1 (resolved — design.md updated for typed exceptions)
```

If no violations:

```markdown
- Convention & Readiness Review complete (YYYY-MM-DD)
  Domains: Backend, Database
  ADRs: architecture/ (all), database/ (all) | Tech-stack: backend/exceptions.md, database/sp-conventions.md
  Violations found: 0
```

## Step 7: Implementer Reference Checklist

Emit the following checklist in chat at Phase 2 exit. The implementer carries it into Phase 3 as a quick-reference guard against the most frequently rediscovered conventions.

Only include sections whose domain flag is `true`:

```
Implementation Quick-Reference (carry into Phase 3)

[hasDatabase]
□ SP filename: {Project}_Entity_Op.sql — proc name: {Project}_Entity_Op_YYYY.MM.DD
□ WITH(NOLOCK) on every SELECT where required (SQL Server-specific hint; check project conventions); forbidden on writes
□ Audit columns: CreatedBy/ModifiedBy (NVARCHAR email), CreatedOn/ModifiedOn (GETUTCDATE)
□ GUID validation: = '00000000-0000-0000-0000-000000000000' (not <= 0)
□ @@ROWCOUNT captured BEFORE COMMIT

[hasBackend]
□ Typed exceptions only (NotFoundException, ValidationException, ConflictException)
□ Constructor injection; register in Program.cs
□ Async/await fully propagated — no .Result or .Wait()

[hasFrontend]
□ CSS custom properties only — no hardcoded hex
□ data-testid on interactive elements
□ SSR guard: import.meta.server before browser APIs
□ Project-specific API composable for authenticated calls (check project frontend conventions)
```

## Exit Condition (Phase 2 → Phase 3)

- Convention compliance checklist complete (all items are ✓ or ✓ RESOLVED)
- No open ⚠ violations remain
- Convention & Readiness Review recorded in context.md Key Decisions
- Implementer Reference Checklist emitted in chat
- User approves transition to Phase 3 (Implementation)
