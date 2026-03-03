---
name: e2e-troubleshoot
description: Structured E2E test troubleshooting using the 6-layer diagnostic ladder (Frontend → API → SP/Schema → Infra → CI/CD). Use when any E2E test fails, UI doesn't render, auth drops, unexpected status codes, CI passes locally but fails in pipeline, or any test failure where the root cause is unclear. Routes to the correct read-only diagnostic agent based on the symptom, walks the sequential ladder with [EVIDENCE]/[HANDOFF]/[ROOT-CAUSE] taxonomy, and enforces the Fix Gate (no action before root cause confirmed).
---

# E2E Troubleshoot Skill

Orchestrate the 6-layer diagnostic ladder to identify root causes of E2E test failures and
system bugs. **Read-only throughout** — emit findings only, user decides the fix.

---

## Quick Workflow

```
1. Receive symptom from user
2. Look up symptom in references/routing.md → determine starting layer
3. Invoke the correct diagnostic agent for that layer
4. Agent emits [EVIDENCE] and either:
   a. [ROOT-CAUSE] → stop, surface to user
   b. [HANDOFF] → move to next layer, invoke next agent
   c. [DEAD-END] → surface all evidence, ask user for direction
5. Never emit [ACTION] without a confirmed [ROOT-CAUSE]
```

**Fix Gate:** Do NOT suggest any code or config change until `[ROOT-CAUSE]` is confirmed with at
least one `[EVIDENCE]` entry. If uncertain after all 6 layers, emit `[DEAD-END]`.

---

## Layer Agent Table

| Layer | Agent | Trigger Keywords |
|-------|-------|-----------------|
| L1 — Frontend | `frontend-troubleshooter` | table empty, UI not rendering, button no effect, selectOption fails, test cascade, storageState, data-testid, loading skeleton |
| L2 — API | `api-troubleshooter` | status code, CORS, curl, filter wrong, enum binding, response shape, 401, ZERO_GUID |
| L3+L4 — SP/Schema | `db-troubleshooter` | SP returns 0 rows, 500 after schema change, @@ROWCOUNT, param typo, column mismatch, DACPAC, global.setup stuck |
| L5 — Infrastructure | `infra-troubleshooter` | container crash, port conflict, disk full, SSL error, env var, 502, connection refused |
| L6 — CI/CD | `cicd-troubleshooter` | passes locally fails CI, secrets missing, wrong image deployed, health check, type drift |

---

## Routing Rules

1. **Known symptom** — look up in `references/routing.md` → start at the mapped layer.
2. **Unknown symptom** — start at L1 (Frontend) and walk the ladder sequentially.
3. **Infra shortcut** — if symptom is clearly infrastructure (container crash, CI failure, disk full),
   skip directly to L5 or L6 per `references/routing.md`.

See `references/routing.md` for the full symptom → agent → key check table.

---

## Comment Taxonomy

All diagnostic output uses this structured taxonomy:

| Label | Meaning | Constraint |
|-------|---------|-----------|
| `[EVIDENCE]` | Confirmed fact from command or file | Must cite source (path, command, line) |
| `[HYPOTHESIS]` | Unconfirmed theory | Must validate before promoting to ROOT-CAUSE |
| `[ROOT-CAUSE]` | Confirmed root cause | Requires at least one [EVIDENCE] entry |
| `[ACTION]` | Recommended fix | Only after [ROOT-CAUSE] confirmed — never before |
| `[HANDOFF]` | Layer cleared, passing to next | Must list all evidence from this layer |
| `[DEAD-END]` | All layers exhausted, no root cause | Surface all evidence, ask user for direction |

**Rules:**
- Never emit `[ACTION]` without `[ROOT-CAUSE]`.
- Never emit `[ROOT-CAUSE]` without `[EVIDENCE]`.
- `[HYPOTHESIS]` must be validated or invalidated — never left hanging.
- `[DEAD-END]` means stop and ask — no speculative fixes.

---

## Reference Files

- `references/routing.md` — symptom → layer routing table (all 6 layers)
- `references/layers.md` — per-layer checklists, diagnostic commands, cross-layer root causes,
  DACPAC redeploy checklist
