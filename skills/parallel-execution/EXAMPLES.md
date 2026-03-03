# Parallel Execution Examples

Complete examples showing the parallel-execution skill v2 with automated subagent orchestration.

## Example 1: User Authentication Feature

### Input Plan

**File:** `docs/auth-feature-plan.md`

```markdown
# User Authentication Implementation Plan

1. Create users table with password hashing
2. Create auth stored procedures (login, register, token refresh)
3. Define shared DTOs and service interfaces
4. Implement authentication API endpoints
5. Add JWT token handling middleware
6. Build login/register UI components
7. Write unit tests for auth logic
8. Write E2E tests for auth flow
9. Update API documentation
```

### Step 1 Output: Dependency Analysis (Plan Agent)

```
Tasks:
- db-users: Database Schema | Category: database | Complexity: M
  Files: Database/Tables/Users.sql, Database/SPs/Auth_*.sql
  Hard deps: none
  Soft deps: none
  Optional deps: none

- shared-contracts: Shared Contracts | Category: backend-models | Complexity: S
  Files: Api/DTOs/Auth*.cs, Api/Interfaces/IAuthService.cs
  Hard deps: none
  Soft deps: none
  Optional deps: none

- api-auth: Auth API | Category: backend-api | Complexity: L
  Files: Api/Controllers/AuthController.cs, Api/Services/AuthService.cs
  Hard deps: db-users, shared-contracts
  Soft deps: none
  Optional deps: none

- api-middleware: JWT Middleware | Category: backend-api | Complexity: M
  Files: Api/Middleware/JwtMiddleware.cs, Api/Extensions/AuthExtensions.cs
  Hard deps: shared-contracts
  Soft deps: none
  Optional deps: api-auth

- ui-auth: Auth UI | Category: frontend-ui | Complexity: M
  Files: Web/pages/login.vue, Web/pages/register.vue, Web/composables/useAuth.ts
  Hard deps: shared-contracts
  Soft deps: api-auth
  Optional deps: none

- test-unit: Unit Tests | Category: unit-tests | Complexity: M
  Files: Api.Tests/Services/AuthServiceTests.cs
  Hard deps: api-auth
  Soft deps: none
  Optional deps: none

- test-e2e: E2E Tests | Category: e2e-tests | Complexity: M
  Files: E2E/tests/api/auth.spec.ts, E2E/tests/ui/login.spec.ts
  Hard deps: api-auth, ui-auth
  Soft deps: none
  Optional deps: none

- docs-api: API Docs | Category: documentation | Complexity: S
  Files: Documentation/api-auth.md
  Hard deps: api-auth
  Soft deps: none
  Optional deps: none

Circular Dependencies: none
File Conflicts: none
Interface Contracts:
- IAuthService (login, register, refreshToken)
- AuthRequestDTO, AuthResponseDTO, UserDTO
```

### Step 2 Output: Batch Schedule (Architect Agent)

```
Batch Schedule:
- Batch 1 (parallel): db-users [backend-developer], shared-contracts [csharp-developer]
- Batch 2 (parallel): api-auth [backend-developer], api-middleware [backend-developer], ui-auth [vue-expert]
- Batch 3 (parallel): test-unit [csharp-developer], test-e2e [test-automator], docs-api [general-purpose]

Scope Isolation:
- db-users:
  OWN: Database/Tables/Users.sql, Database/SPs/Auth_*.sql
  DO NOT TOUCH: Api/*, Web/*, E2E/*
  READ ONLY: shared-contracts output (interfaces)

- shared-contracts:
  OWN: Api/DTOs/Auth*.cs, Api/Interfaces/IAuthService.cs
  DO NOT TOUCH: Database/*, Web/*, E2E/*
  READ ONLY: none

- api-auth:
  OWN: Api/Controllers/AuthController.cs, Api/Services/AuthService.cs
  DO NOT TOUCH: Database/*, Web/*, E2E/*
  READ ONLY: Api/DTOs/*, Api/Interfaces/*

- ui-auth:
  OWN: Web/pages/login.vue, Web/pages/register.vue, Web/composables/useAuth.ts
  DO NOT TOUCH: Api/*, Database/*, E2E/*
  READ ONLY: Api/DTOs/* (for type reference)
```

### Step 3: Approval Presentation

**Mermaid Dependency Graph:**

```mermaid
graph TD
    subgraph "Batch 1"
        T1[db-users: Database Schema<br/>backend-developer | M]
        T2[shared-contracts: Shared Contracts<br/>csharp-developer | S]
    end
    subgraph "Batch 2"
        T3[api-auth: Auth API<br/>backend-developer | L]
        T4[api-middleware: JWT Middleware<br/>backend-developer | M]
        T5[ui-auth: Auth UI<br/>vue-expert | M]
    end
    subgraph "Batch 3"
        T6[test-unit: Unit Tests<br/>csharp-developer | M]
        T7[test-e2e: E2E Tests<br/>test-automator | M]
        T8[docs-api: API Docs<br/>general-purpose | S]
    end

    T1 -->|hard| T3
    T2 -->|hard| T3
    T2 -->|hard| T4
    T2 -->|hard| T5
    T3 -.->|optional| T4
    T3 -->|hard| T6
    T3 -->|hard| T7
    T5 -->|hard| T7
    T3 -->|hard| T8

    classDef batch1 fill:#e1f5fe
    classDef batch2 fill:#f3e5f5
    classDef batch3 fill:#e8f5e9
    class T1,T2 batch1
    class T3,T4,T5 batch2
    class T6,T7,T8 batch3
```

**Batch Schedule Table:**

```
| Task ID | Name | Batch | Complexity | Subagent Type |
|---------|------|-------|------------|---------------|
| db-users | Database Schema | 1 | M | backend-developer |
| shared-contracts | Shared Contracts | 1 | S | csharp-developer |
| api-auth | Auth API | 2 | L | backend-developer |
| api-middleware | JWT Middleware | 2 | M | backend-developer |
| ui-auth | Auth UI | 2 | M | vue-expert |
| test-unit | Unit Tests | 3 | M | csharp-developer |
| test-e2e | E2E Tests | 3 | M | test-automator |
| docs-api | API Docs | 3 | S | general-purpose |
```

**Scope Isolation Matrix:**

```
| Task ID | OWN | DO NOT TOUCH | READ ONLY |
|---------|-----|-------------|-----------|
| db-users | Database/Tables/*, Database/SPs/* | Api/*, Web/*, E2E/* | — |
| shared-contracts | Api/DTOs/Auth*.cs, Api/Interfaces/* | Database/*, Web/* | — |
| api-auth | Api/Controllers/Auth*, Api/Services/Auth* | Database/*, Web/*, E2E/* | Api/DTOs/*, Api/Interfaces/* |
| api-middleware | Api/Middleware/*, Api/Extensions/Auth* | Database/*, Web/*, E2E/* | Api/Interfaces/* |
| ui-auth | Web/pages/login.vue, Web/pages/register.vue, Web/composables/useAuth.ts | Api/*, Database/*, E2E/* | Api/DTOs/* |
| test-unit | Api.Tests/Services/AuthServiceTests.cs | Database/*, Web/*, E2E/* | Api/* (all) |
| test-e2e | E2E/tests/api/auth.spec.ts, E2E/tests/ui/login.spec.ts | Api/*, Database/*, Web/* | — |
| docs-api | Documentation/api-auth.md | Api/*, Database/*, Web/*, E2E/* | Api/Controllers/* |
```

### Step 4: TaskCreate Entries

```
TaskCreate #1: subject="[parallel-exec] db-users: Database Schema"
  activeForm="Executing Database Schema"
  description={full prompt from template}

TaskCreate #2: subject="[parallel-exec] shared-contracts: Shared Contracts"
  activeForm="Executing Shared Contracts"
  description={full prompt from template}

TaskCreate #3: subject="[parallel-exec] api-auth: Auth API"
  activeForm="Executing Auth API"
  addBlockedBy=["#1", "#2"]

TaskCreate #4: subject="[parallel-exec] api-middleware: JWT Middleware"
  activeForm="Executing JWT Middleware"
  addBlockedBy=["#2"]

TaskCreate #5: subject="[parallel-exec] ui-auth: Auth UI"
  activeForm="Executing Auth UI"
  addBlockedBy=["#2"]

TaskCreate #6: subject="[parallel-exec] test-unit: Unit Tests"
  activeForm="Executing Unit Tests"
  addBlockedBy=["#3"]

TaskCreate #7: subject="[parallel-exec] test-e2e: E2E Tests"
  activeForm="Executing E2E Tests"
  addBlockedBy=["#3", "#5"]

TaskCreate #8: subject="[parallel-exec] docs-api: API Docs"
  activeForm="Executing API Docs"
  addBlockedBy=["#3"]
```

### Step 5: Batch Execution

**Batch 1 dispatch:**
```
Batch 1 requires the following subagents:
- backend-developer for db-users: Create users table and auth stored procedures
- csharp-developer for shared-contracts: Define auth DTOs and IAuthService interface

[AskUserQuestion: Proceed with Batch 1? Yes / Skip / Cancel]
```

Then 2 Task tool calls in parallel → collect results → verify build → report:

```
Batch 1 Complete:
| Task ID | Status | Files Changed | Notes |
|---------|--------|---------------|-------|
| db-users | Completed | 3 files | Users table + 3 SPs created |
| shared-contracts | Completed | 2 files | IAuthService + 3 DTOs defined |

Verification: Build passing
```

**Batch 2 dispatch** (3 subagents in parallel), then **Batch 3**.

### Step 7: Completion Report

```
══════════════════════════════════════════════
 PARALLEL EXECUTION COMPLETE
══════════════════════════════════════════════

Summary:
| Task ID | Status | Subagent | Files Changed |
|---------|--------|----------|---------------|
| db-users | Completed | backend-developer | 3 files |
| shared-contracts | Completed | csharp-developer | 2 files |
| api-auth | Completed | backend-developer | 2 files |
| api-middleware | Completed | backend-developer | 2 files |
| ui-auth | Completed | vue-expert | 3 files |
| test-unit | Completed | csharp-developer | 1 file |
| test-e2e | Completed | test-automator | 2 files |
| docs-api | Completed | general-purpose | 1 file |

Verification:
- Build: Passing
- Backend tests: 12/12 passing
- E2E tests: 5/5 passing

Next Steps:
1. Review all changes (/code-review)
2. Commit changes
3. Run full test suite
```

---

## Example 2: E-Commerce Feature with Dynamic Re-batching

### Input Plan

**File:** `plans/shopping-cart.md` (14 steps, condensed to 9 tasks)

### Batch Schedule with Soft Dependencies

```
Batch Schedule:
- Batch 0: cart-interfaces [csharp-developer] — defines ICartService, IOrderService, shared DTOs
- Batch 1 (parallel): db-products [backend-developer], db-cart [backend-developer], db-orders [backend-developer]
- Batch 2 (parallel): api-products [backend-developer], api-cart [backend-developer], api-checkout [backend-developer]
- Batch 3 (parallel): ui-catalog [vue-expert], ui-cart [vue-expert], ui-checkout [vue-expert]
```

### Dynamic Re-batching in Action

During Batch 2 execution:

```
Batch 2 status:
| Task ID | Status | Progress |
|---------|--------|----------|
| api-products | Completed (2m ago) | 100% |
| api-cart | In progress | ~70% |
| api-checkout | In progress | ~50% |

Dynamic re-batching check:
- ui-catalog blockedBy: [api-products] → ALL COMPLETED
- Currently running: 2 subagents (api-cart, api-checkout)
- MaxParallelSessions: 10
- Available slots: 8

→ "Task ui-catalog is now unblocked (api-products completed).
   Start early? Currently 2/10 subagent slots in use."
   [Yes - start ui-catalog now] [No - wait for Batch 3]
```

If user approves, `ui-catalog` starts immediately instead of waiting for all of Batch 2 to finish. This saves wall-clock time when tasks have uneven completion times.

### Mermaid Graph (with soft deps)

```mermaid
graph TD
    subgraph "Batch 0"
        T0[cart-interfaces<br/>csharp-developer | S]
    end
    subgraph "Batch 1"
        T1[db-products<br/>backend-developer | M]
        T2[db-cart<br/>backend-developer | M]
        T3[db-orders<br/>backend-developer | M]
    end
    subgraph "Batch 2"
        T4[api-products<br/>backend-developer | M]
        T5[api-cart<br/>backend-developer | L]
        T6[api-checkout<br/>backend-developer | L]
    end
    subgraph "Batch 3"
        T7[ui-catalog<br/>vue-expert | M]
        T8[ui-cart<br/>vue-expert | M]
        T9[ui-checkout<br/>vue-expert | L]
    end

    T0 -.->|soft| T1
    T0 -.->|soft| T2
    T0 -.->|soft| T3
    T1 -->|hard| T4
    T2 -->|hard| T5
    T3 -->|hard| T6
    T4 -->|hard| T7
    T5 -->|hard| T8
    T6 -->|hard| T9

    classDef batch0 fill:#fff3e0
    classDef batch1 fill:#e1f5fe
    classDef batch2 fill:#f3e5f5
    classDef batch3 fill:#e8f5e9
    class T0 batch0
    class T1,T2,T3 batch1
    class T4,T5,T6 batch2
    class T7,T8,T9 batch3
```

---

## Example 3: Handling Retry on Failure

During Batch 2 of the e-commerce example:

```
Batch 2 Results:
| Task ID | Status | Files Changed | Notes |
|---------|--------|---------------|-------|
| api-products | Completed | 3 files | — |
| api-cart | FAILED | 2 files | Build error in CartService.cs |
| api-checkout | Completed | 4 files | — |

Build verification: FAILED
Error: CartService.cs(42): CS0246 - Type 'CartItemDTO' not found

Retry attempt 1/2 for api-cart:
- Error context will be included in retry prompt
- api-products and api-checkout results preserved
- Tasks blocked by api-cart (ui-cart) remain blocked

[Retry api-cart] [Skip and fix manually] [Cancel remaining]
```

---

## Quick Test Plan

For verifying the skill works end-to-end:

```markdown
# Test Feature Plan

1. Add a "status" column to the projects table
2. Create a GET /api/projects/:id/status endpoint
3. Build a StatusBadge Vue component
4. Write unit tests for the status endpoint
```

**Expected behavior:**
1. Plan agent identifies 4 tasks with clear layer boundaries
2. Architect schedules: Batch 1 (db-status), Batch 2 (api-status, ui-badge), Batch 3 (test-status)
3. Approval shows Mermaid graph with hard deps: db → api → test, db → ui
4. TaskCreate entries created with proper blockedBy
5. Subagents dispatch (1 → 2 → 1)
6. Completion report shows all tasks and verification
