# Parallel Execution Troubleshooting

Error handling, retry logic, and recovery procedures for subagent-based parallel execution.

## Error Handling Quick Reference

| Failure | Response | Auto-Recovery |
|---------|----------|---------------|
| Subagent timeout | Keep task `in_progress`, offer retry | Up to MaxRetries (default: 2) |
| Build failure post-batch | Identify causing task, offer targeted retry | Yes |
| Test failure post-batch | Report failures, ask user | No (user decides) |
| Scope violation | Warning logged, execution continues | N/A |
| Circular dependency (Step 1) | Block execution, ask user to restructure | No |
| Max retries exceeded | Force manual fix path | No |
| Conflicting parallel-exec session | Block start, show existing tasks | No |
| Plan file not found | Ask user for correct path | No |
| No clear tasks in plan | Agents propose split points | Yes |

---

## Subagent Failures

### Subagent Timeout

**Symptom:** Task tool call doesn't return within expected time.

**What happens:**
- Task stays `in_progress` in TaskList
- Other tasks in the batch are unaffected
- Tasks blocked by the timed-out task remain blocked

**Resolution:**
1. Skill offers retry with same prompt
2. If retry also times out, ask user:
   - **Retry again** (up to MaxRetries)
   - **Skip task** (mark as failed, unblock dependents with warning)
   - **Fix manually** (pause execution, user handles it)

### Subagent Returns Errors

**Symptom:** Subagent completes but reports build/compile errors.

**What happens:**
- Task marked `in_progress` (not completed)
- Error context captured from subagent response
- Retry prompt includes the error for context

**Resolution:**
```
Task api-auth failed:
Error: CS0246 - Type 'AuthRequestDTO' not found in AuthController.cs

Possible causes:
- shared-contracts task may not have created the expected DTO
- Import/namespace mismatch

[Retry with error context] [Fix manually] [Cancel remaining]
```

On retry, the prompt includes:
```
PREVIOUS ATTEMPT FAILED with error:
{error_message}

Please fix the issue and complete the task. Check that:
- All referenced types exist in the READ ONLY files
- Namespaces/imports are correct
- Interface implementations match contract signatures
```

### Partial Batch Failure

**Symptom:** Some tasks in a batch succeed, others fail.

**What happens:**
- Completed tasks stay completed (their work is preserved)
- Failed task only blocks its own dependents
- Unrelated tasks in the next batch can still proceed

**Example:**
```
Batch 2 Results:
| Task ID | Status | Blocks |
|---------|--------|--------|
| api-auth | Completed | test-unit, test-e2e, docs-api |
| api-middleware | FAILED | (nothing blocked) |
| ui-auth | Completed | test-e2e |

Impact: api-middleware failed but blocks nothing critical.
- test-unit: UNBLOCKED (only needed api-auth)
- test-e2e: UNBLOCKED (needed api-auth + ui-auth, both done)
- docs-api: UNBLOCKED (only needed api-auth)

→ Batch 3 can proceed fully. api-middleware retry is independent.
```

---

## Build & Test Failures

### Build Failure After Batch

**Symptom:** `AutoVerify: true` and build fails after a batch completes.

**Diagnosis steps:**
1. Check which files were changed by each task in the batch
2. Correlate build error location to a specific task
3. Offer targeted retry for that task only

**Resolution:**
```
Build failed after Batch 2:
Error in Api/Services/AuthService.cs:42 — CS0103: 'HashPassword' does not exist

This file was changed by task: api-auth (backend-developer)
Other Batch 2 tasks (api-middleware, ui-auth) are NOT affected.

[Retry api-auth only] [Fix manually] [Cancel]
```

### Test Failure After Batch

**Symptom:** Build passes but tests fail after batch.

**Resolution:**
- Report which tests failed and which task likely caused them
- Ask user to decide (tests may be expected to fail until later batches complete)

```
Tests after Batch 2:
- AuthServiceTests: 8/10 PASSING (2 failures)
  Failing: TestRefreshToken, TestTokenExpiry
  Likely caused by: api-middleware (JWT handling not complete)

Since api-middleware is still being retried, these failures may
resolve after retry. Proceed with Batch 3?

[Proceed - accept temporary failures] [Wait for retry] [Fix manually]
```

---

## Scope Violations

### File Ownership Conflict

**Symptom:** Subagent modifies a file in the DO NOT TOUCH list.

**What happens (ScopeEnforcement: strict):**
- Warning logged in task results
- Execution continues (not blocked)
- Reported in completion summary

```
Scope violation detected:
Task api-auth modified Web/types/auth.ts
This file is owned by task ui-auth

Impact: ui-auth may encounter merge conflicts or unexpected changes.
Recommendation: Review the change before proceeding with ui-auth.
```

**What happens (ScopeEnforcement: relaxed):**
- No warning, execution continues normally

### Resolving Scope Conflicts

If a task genuinely needs to modify a DO NOT TOUCH file:
1. Task reports it as a blocker
2. Orchestrator pauses the task
3. Options:
   - **Merge the tasks** (combine scope)
   - **Serialize them** (run one after the other)
   - **Allow the violation** (accept risk of conflicts)

---

## Dependency Issues

### Circular Dependency Detected

**Symptom:** Step 1 (Plan Agent) finds Task A → Task B → Task A.

**What happens:** Execution blocked. Cannot proceed.

**Resolution:**
```
Circular dependency detected:
  api-auth → shared-types → api-auth

This means:
- api-auth needs types from shared-types
- shared-types needs API contracts from api-auth

Suggestions:
1. Merge api-auth and shared-types into one task
2. Extract the shared interface to a separate "contracts" task (Batch 0)
3. Break the cycle by defining types first, then implementing API

[Restructure plan] [Merge tasks] [Cancel]
```

### Missing Dependency

**Symptom:** A subagent fails because a prerequisite wasn't captured as a dependency.

**Resolution:**
1. Pause the failed task
2. Identify the missing dependency
3. If the dependency task already completed: retry the failed task
4. If the dependency task is in a later batch: restructure batches

---

## Session & State Issues

### Conflicting Parallel-Execution Session

**Symptom:** TaskList shows existing `[parallel-exec]` tasks.

**Resolution:**
```
Existing parallel-execution tasks found:
| ID | Subject | Status |
|----|---------|--------|
| #5 | [parallel-exec] db-schema: Database Schema | in_progress |
| #6 | [parallel-exec] api-auth: Auth API | pending |

Cannot start a new parallel execution while tasks are active.

[Resume existing session] [Clean up and start fresh] [Cancel]
```

**Clean up:** Mark all `[parallel-exec]` tasks as `deleted` via TaskUpdate.

### Task State Inconsistency

**Symptom:** TaskList shows a task as `in_progress` but no subagent is running.

**Cause:** Subagent completed or failed without updating the task.

**Resolution:**
1. Check if the subagent's work was actually completed (files changed?)
2. If yes: manually mark task as `completed` via TaskUpdate
3. If no: retry the task

---

## Configuration Issues

### MaxParallelSessions Too High

**Symptom:** System becomes slow or unresponsive with many concurrent subagents.

**Recommendation:** Default is 10. Very high values may:
- Exceed API rate limits
- Cause context window pressure
- Lead to more merge conflicts

### AutoVerify Slowing Down Execution

**Symptom:** Build/test verification after each batch adds significant time.

**Options:**
- Set `AutoVerify: false` to skip verification between batches
- Only run verification after the final batch
- Use targeted verification (only test files changed in the batch)

---

## Recovery Procedures

### Clean Up After Failed Execution

```
1. Check TaskList for orphaned [parallel-exec] tasks
2. Mark all as deleted:
   TaskUpdate: taskId={id}, status=deleted
3. Review any partially completed work:
   git status
   git diff
4. Decide: keep partial changes or revert
```

### Resume Interrupted Execution

If execution was interrupted (session ended, crash):

1. Check TaskList — completed tasks are preserved
2. Identify which tasks are still `pending` or `in_progress`
3. For `in_progress` tasks: check if subagent work was actually done
4. Resume by re-running Step 5 (Batch Execution) from the current batch

### Start Fresh

1. Clean up tasks: mark all `[parallel-exec]` as `deleted`
2. Revert partial changes if needed: `git checkout .`
3. Re-run: `/parallel-execution path/to/plan.md`

---

## Best Practices

### 1. Keep Tasks Focused

Each task should:
- Have clear, bounded scope
- Own specific files exclusively
- Have well-defined completion criteria
- Be independently verifiable (build should pass)

### 2. Define Interfaces First

Use Batch 0 for shared contracts when soft dependencies exist:
- Shared type definitions (DTOs, interfaces)
- API contracts
- Database schemas used across tasks

### 3. Balance Workload

Tasks in the same batch should have similar complexity:
- Avoid: 1 large task + 2 tiny tasks (causes waiting)
- Prefer: 3 medium-sized tasks
- Use complexity estimates (S/M/L) from Step 1

### 4. Review Scope Isolation

Before approving (Step 3), verify:
- No file appears in multiple tasks' OWN lists
- READ ONLY files are correctly identified
- DO NOT TOUCH lists are comprehensive

### 5. Use Dynamic Re-batching

Keep `DynamicRebatching: true` (default) to maximize throughput. Tasks that complete early free up slots for the next batch.
