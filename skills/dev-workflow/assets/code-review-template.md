---
template: code-review
phase: 4
purpose: Document multi-agent code review findings and assessment
agents:
  wave0: code-reviewer (plan compliance)
  wave1_always: architect-reviewer, security-auditor, performance-engineer, test-automator
  wave1_conditional: csharp-developer (backend), database-optimizer (db), vue-expert (frontend), typescript-pro (frontend)
---

# Code Review - {Feature Name}

**Review Date:** {YYYY-MM-DD}
**Phase:** Phase 4 - Code Review (Multi-Agent)
**Overall Assessment:** {READY/NOT READY to close Phase 4} (Grade: {Letter}, {Score}/100)

**Domain Detection:** `git diff --name-only main...HEAD`

| Domain | Changed? | Wave 1 Agents Activated |
|--------|----------|------------------------|
| Backend (`{backend-dir}/`, `{backend-dir}.Tests/`) | {Yes/No} | `csharp-developer` |
| Database (`{database-dir}/`) | {Yes/No} | `database-optimizer` |
| Frontend (`{frontend-dir}/`) | {Yes/No} | `vue-expert`, `typescript-pro` |

---

## Executive Summary

{Brief summary of findings across all agents, test results, and overall quality assessment}

**Test Results:** {X}/{Total} tests passing ({Percentage}%)
- Backend (NUnit): {X} tests — {Coverage}% coverage
- Frontend (Vitest): {X} tests — {Coverage}% coverage
- E2E (Playwright): {X}/{Total} scenarios

**Build Status:** {✓ Successful / ✗ Failed} ({Warnings} warnings, {Errors} errors)

---

## Wave 0: Plan Compliance — `code-reviewer`

*Scope: proposal.md / specs/\*.spec.md / design.md vs actual implementation*

| Requirement | Status | Evidence |
|------------|--------|----------|
| {Requirement from proposal/specs} | {✓/✗} | {File:line reference} |

**Deviations from plan:**
- {List deviations, or "None — implementation matches spec ✓"}

**Verdict:** {PASS/FAIL} — {brief rationale}

---

## Wave 1: Architecture — `architect-reviewer`

*Scope: SOLID principles, layering, ADR-001–ADR-012, dependency injection*

**ADR Compliance:**

| ADR | Requirement | Status | Evidence |
|-----|------------|--------|----------|
| {ADR-###} | {Requirement} | {✓/✗} | {Evidence} |

**SOLID / Layering:**
- {✓/✗} Controller → Service → Repository pattern respected
- {✓/✗} No business logic in controllers
- {✓/✗} No direct DB access outside repository layer
- {✓/✗} Dependency injection via constructor (no service locator)

**Issues:** {List or "None"}

---

## Wave 1: Security — `backend-development:security-auditor`

*Scope: OWASP Top 10, auth flaws, injection, JWT/cookie security, input validation*

| Check | Status | Notes |
|-------|--------|-------|
| Input validation at API boundary | {✓/✗} | {Notes} |
| SQL injection prevention (parameterized queries) | {✓/✗} | {Notes} |
| Authentication/authorization checks | {✓/✗} | {Notes} |
| JWT token handling | {✓/✗} | {Notes} |
| Sensitive data exposure | {✓/✗} | {Notes} |
| OWASP Top 10 sweep | {✓/✗} | {Notes} |

**Issues:** {List blocking/non-blocking security issues, or "None"}

---

## Wave 1: Performance — `performance-engineer`

*Scope: N+1 queries, slow query patterns (e.g. missing query hints per project conventions), blocking async calls, expensive re-renders, index gaps (read-only analysis)*

**Database Performance:**
- {✓/✗} All SELECTs use `WITH(NOLOCK)` where required
- {✓/✗} No N+1 query patterns (single query per logical operation)
- {✓/✗} Index coverage for new query predicates

**Application Performance:**
- {✓/✗} No blocking `.Result` / `.Wait()` calls on async code
- {✓/✗} No unnecessary re-renders on the frontend
- {✓/✗} Expensive operations not in hot paths

**Issues:** {List or "None — no performance concerns identified"}

> *Performance fixes are applied in Phase 5 (profiling + optimization). This section is analysis only.*

---

## Wave 1: Backend .NET — `csharp-developer`

*Scope: .NET 8 patterns, Dapper, typed exceptions, async/await, nullable*

> **Skip this section if no `{backend-dir}/` or `{backend-dir}.Tests/` changes.**

**Conventions:**
- {✓/✗} Typed exceptions used (not generic `Exception` or `ApplicationException`)
- {✓/✗} Dapper query patterns correct (parameterized, no string interpolation)
- {✓/✗} Async/await properly propagated throughout call chain
- {✓/✗} Nullable reference types handled correctly

**Issues:** {List or "None"}

---

## Wave 1: Database — `database-optimizer`

*Scope: SP naming, WITH(NOLOCK), GUID validation, audit columns, @@ROWCOUNT*

> **Skip this section if no `{database-dir}/` changes.**

| Convention | Status | Notes |
|------------|--------|-------|
| SP filename: `{Project}_Entity_Op.sql` | {✓/✗} | {Notes} |
| SP proc name: `{Project}_Entity_Op_YYYY.MM.DD` | {✓/✗} | {Notes} |
| GUID validation: `= '00000000-0000-0000-0000-000000000000'` (not `<= 0`) | {✓/✗} | {Notes} |
| `WITH(NOLOCK)` on all SELECTs (forbidden on writes) | {✓/✗} | {Notes} |
| Audit columns: `CreatedBy`/`ModifiedBy` as email `NVARCHAR(255)` | {✓/✗} | {Notes} |
| `@@ROWCOUNT` check after writes (→ NotFoundException if 0) | {✓/✗} | {Notes} |

**Issues:** {List or "None"}

---

## Wave 1: Frontend Vue/Nuxt — `vue-expert`

*Scope: SSR safety, useFetch, composables, data-testid attributes, CSS custom props*

> **Skip this section if no `{frontend-dir}/` changes.**

**SSR Safety:**
- {✓/✗} No `window`/`document` access outside `onMounted` or `<ClientOnly>`
- {✓/✗} `useFetch` used for data fetching (not raw `fetch`)

**Component Quality:**
- {✓/✗} `data-testid` attributes on interactive elements
- {✓/✗} CSS custom properties used (no hardcoded hex colors in components)
- {✓/✗} ARIA landmarks and skip-to-content pattern followed (`layouts/default.vue`)

**Issues:** {List or "None"}

---

## Wave 1: TypeScript Safety — `typescript-pro`

*Scope: Strict mode, no implicit any, props/emits typing, composable return types*

> **Skip this section if no `{frontend-dir}/` changes.**

- {✓/✗} No `any` types (implicit or explicit)
- {✓/✗} Props defined with `defineProps<T>()` generic pattern
- {✓/✗} Emits defined with `defineEmits<T>()`
- {✓/✗} Composable return types explicitly typed (not inferred from `ref`)
- {✓/✗} TypeScript strict mode compliance (`noImplicitAny`, `strictNullChecks`)

**Issues:** {List or "None"}

---

## Wave 1: Test Quality — `test-automator`

*Scope: NUnit+Moq coverage (≥80%), Vitest (≥95%), Playwright fixtures, AAA pattern*

**Coverage:**
- Backend (NUnit+Moq): {X}% — {✓ ≥80% / ✗ Below threshold}
- Frontend (Vitest): {X}% — {✓ ≥95% / ✗ Below threshold}
- E2E (Playwright): {X}/{Total} scenarios covered

**Test Quality:**
- {✓/✗} AAA pattern (Arrange/Act/Assert) consistently applied
- {✓/✗} Moq mocks properly scoped and verified
- {✓/✗} Playwright fixtures used (not bare `page.goto()` navigation)
- {✓/✗} No flaky waits (`networkidle` preferred over arbitrary timeouts)

**Issues:** {List or "None"}

---

## Issues Summary

| # | Taxonomy | Agent | Category | Issue | File | Disposition |
|---|----------|-------|----------|-------|------|-------------|
| 1 | `[BLOCKER]` / `[SHOULD]` / `[NIT]` / `[QUESTION]` | {agent} | {category} | {description} | {file:line} | Fixed / User-approved skip / Answered |

**Taxonomy key:**
- `[BLOCKER]` — correctness bug, security flaw, or convention violation → must be fixed (no skip)
- `[SHOULD]` — best practice gap, not a hard violation → fixed OR user explicitly approves skip
- `[NIT]` — style preference → fixed OR user explicitly approves skip
- `[QUESTION]` — clarification needed → must be answered before Phase 4 closes

### Blockers (`[BLOCKER]`)
{List all blockers that must be fixed before Phase 4 can close, or "None identified. ✓"}

### Should-Fix (`[SHOULD]`)

| # | Issue | Agent | Disposition |
|---|-------|-------|-------------|
| 1 | {Issue} | {agent} | {Fixed / User-approved skip on YYYY-MM-DD} |

### Nits (`[NIT]`)

| # | Issue | Agent | Disposition |
|---|-------|-------|-------------|
| 1 | {Issue} | {agent} | {Fixed / User-approved skip on YYYY-MM-DD} |

### Questions (`[QUESTION]`)

| # | Question | Agent | Answer |
|---|----------|-------|--------|
| 1 | {Question} | {agent} | {Answer} |

---

## Key Files Reviewed

- {File path} — {Description}

---

## Final Assessment

### Grade: {Letter} ({Score}/100)

**Verdict:** **{READY/NOT READY} to close Phase 4**

{Detailed assessment paragraph}

**Strengths:**
- ✓ {Strength}

**Areas for Improvement (Non-blocking):**
- {Improvement area — labeled [SHOULD] or [NIT] in Issues Summary}

---

## Phase 4 Exit Checklist

*All items must be resolved before Phase 4 closes. User sign-off required.*

**Blockers:**
- [ ] All `[BLOCKER]` items: Fixed and tests pass ✓ _(no skip allowed)_

**Should-Fix:**
- [ ] All `[SHOULD]` items: Fixed **or** User explicitly approved skipping ✓

**Nits:**
- [ ] All `[NIT]` items: Fixed **or** User explicitly approved skipping ✓

**Questions:**
- [ ] All `[QUESTION]` items: Answered ✓

**Sign-off:**
- [ ] User has reviewed this checklist and approves Phase 4 closure

> Skipped `[SHOULD]` and `[NIT]` items must be recorded in context.md `## Key Decisions`.
> These items do NOT automatically become Phase 5 scope — Phase 5 is independently pre-scoped.
>
> **Two-Session Rule:** If total findings ≥ 5 or blockers ≥ 3, split into Session A (blockers only, commit) and Session B (should/nits). See `workflow-rules.md` → "Two-Session Rule".

---

**Review Completed:** {YYYY-MM-DD}
**Approved By:** (Pending user sign-off on exit checklist above)
