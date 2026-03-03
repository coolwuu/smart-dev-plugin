<!--
Template Variables (populated by parallel-execution skill):

Identity & Context:
- {{task_id}}: Unique task identifier (e.g., "db-schema", "api-endpoints")
- {{task_name}}: Human-readable task name
- {{task_number}}: Task number for ordering (1-N)
- {{total_tasks}}: Total number of tasks in this execution
- {{batch_number}}: Which batch this task belongs to
- {{total_batches}}: Total number of batches
- {{plan_file_path}}: Original action plan file
- {{feature_name}}: Feature being implemented
- {{subagent_type}}: Assigned subagent type (e.g., "backend-developer")

Scheduling:
- {{batch_schedule}}: Visual batch schedule (all batches)
- {{other_tasks_in_batch}}: Other tasks running in parallel in this batch
- {{hard_deps}}: Tasks that must complete before this (enforced via blockedBy)
- {{soft_deps}}: Tasks whose interfaces are needed (contracts defined in Batch 0)
- {{optional_deps}}: Tasks that would help but aren't required
- {{blocked_tasks}}: Tasks waiting on this one to complete

Scope & Isolation:
- {{own_files}}: Files this task creates/modifies exclusively (OWN tier)
- {{do_not_touch_files}}: Files owned by other tasks (DO NOT TOUCH tier)
- {{read_only_files}}: Shared files for reference only (READ ONLY tier)
- {{scope_description}}: What this task implements
- {{subtask_list}}: Ordered list of subtasks

Contracts & Integration:
- {{interface_contracts}}: Shared interfaces/types this task defines or consumes
- {{contract_role}}: "defines" or "consumes" for each contract

Verification:
- {{verification_steps}}: How to verify completion
- {{expected_tests}}: Test success criteria
- {{build_command}}: Build command to run (e.g., "dotnet build")
- {{test_command}}: Test command to run (e.g., "dotnet test")
-->

# Task {{task_id}}: {{task_name}}

**Parallel Execution Task {{task_number}} of {{total_tasks}} | Batch {{batch_number}} of {{total_batches}}**

## Context

You are implementing **Task {{task_id}}** (`{{task_name}}`) as part of an automated parallel execution plan.

- **Parent Plan:** `{{plan_file_path}}`
- **Feature:** {{feature_name}}
- **Your Subagent Type:** {{subagent_type}}

### Batch Schedule

```
{{batch_schedule}}
```

### Other Tasks Running in Parallel (This Batch)

{{other_tasks_in_batch}}

> These tasks are running simultaneously. Do NOT modify their files.

### Dependencies

| Type | Tasks | Status |
|------|-------|--------|
| **Hard** (must be done) | {{hard_deps}} | Completed before you started |
| **Soft** (interfaces only) | {{soft_deps}} | Contracts defined, implementation may be in progress |
| **Optional** (nice to have) | {{optional_deps}} | May or may not be done |
| **Blocks** (waiting on you) | {{blocked_tasks}} | Will start after you complete |

---

## Scope

### What to Implement

{{scope_description}}

### Subtasks (in order)

{{subtask_list}}

---

## File Ownership (3-Tier Scope Isolation)

### OWN — Files You Create/Modify

These files are exclusively yours. Create, modify, or delete as needed:

{{own_files}}

### DO NOT TOUCH — Other Tasks' Files

These files belong to other parallel tasks. **Do not create, modify, or delete any of these:**

{{do_not_touch_files}}

> Scope violation warning: If you find you need to modify a DO NOT TOUCH file, STOP and report it as a blocker. The orchestrator will resolve the conflict.

### READ ONLY — Shared Reference Files

You may read these files for context but must not modify them:

{{read_only_files}}

---

## Interface Contracts

{{interface_contracts}}

If you **define** a contract: implement the exact signatures specified above.
If you **consume** a contract: code against the interface, not the implementation.

---

## Verification

When you believe the task is complete, verify:

{{verification_steps}}

### Build & Test

```bash
# Build (must pass)
{{build_command}}

# Tests (must pass)
{{test_command}}
```

### Expected Results

{{expected_tests}}

---

## Completion

When done, report:

1. **Files changed** — list all files you created or modified
2. **Tests passing** — confirm build and test results
3. **Blockers** — any issues that need orchestrator attention
4. **Scope violations** — if you needed to touch any DO NOT TOUCH files (explain why)

Commit format: `[TASK-{{task_id}}]: {{task_name}}`
