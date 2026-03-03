# Scenario Routing Table

Use this table to determine which agent to invoke for a given symptom.

Source: project troubleshooting guide — Section D

---

## Layer 1 — Frontend Scenarios

| Symptom | Start Agent | Key Check |
|---------|------------|-----------|
| E2E table empty / no data rendered | `frontend-troubleshooter` | storageState missing in newContext() |
| Button click has no visible effect | `frontend-troubleshooter` | Then check CORS (may handoff to L2) |
| `selectOption` fails silently | `frontend-troubleshooter` | Option text doesn't match DB seed |
| E2E test cascade (many tests fail after first) | `frontend-troubleshooter` | Fix only first failing test |
| Status badge shows wrong state | `frontend-troubleshooter` | `.includes()` vs exact match |
| Fixture URL returns wrong data | `frontend-troubleshooter` | Relative URL missing API_BASE_URL prefix |
| Loading skeleton never resolves | `frontend-troubleshooter` | Composable error swallowed silently |
| `data-testid` not found | `frontend-troubleshooter` | Duplicate or missing testid in template |

---

## Layer 2 — API Scenarios

| Symptom | Start Agent | Key Check |
|---------|------------|-----------|
| Unexpected status code (400/404/500) | `api-troubleshooter` | curl + token to isolate frontend vs API |
| curl works, browser doesn't | `api-troubleshooter` | CORS preflight missing verb |
| Filter returns all records (ignores filter) | `api-troubleshooter` | Enum binding: int? vs string? + TryParse |
| CORS error in browser console | `api-troubleshooter` | WithMethods() missing PATCH/DELETE |
| Response shape doesn't match frontend expectation | `api-troubleshooter` | PaginatedResponse<T> vs bare list |
| 401 on endpoint that should allow access | `api-troubleshooter` | Missing or wrong [Authorize] attribute |
| API returns 400 instead of 404 | `api-troubleshooter` | ZERO_GUID guard fires before DB lookup |

---

## Layer 3+4 — SP/Schema Scenarios

| Symptom | Start Agent | Key Check |
|---------|------------|-----------|
| SP returns 0 rows for valid GUID | `db-troubleshooter` | New column not added to SP SELECT |
| API 500 after schema change | `db-troubleshooter` | DACPAC not redeployed + API not restarted |
| @@ROWCOUNT anomaly (writes succeed but return 0) | `db-troubleshooter` | @@ROWCOUNT not captured before next statement |
| SP parameter ignored | `db-troubleshooter` | Param name typo — C# repo passes different name |
| Column type mismatch (truncation, cast error) | `db-troubleshooter` | INFORMATION_SCHEMA vs entity/DTO types |
| global.setup.ts stuck at login URL | `db-troubleshooter` | API binary/schema mismatch → 500 on all queries |

---

## Layer 5 — Infrastructure Scenarios

| Symptom | Start Agent | Key Check |
|---------|------------|-----------|
| Container exits immediately / restart loop | `infra-troubleshooter` | docker logs — startup error or OOM |
| API unreachable (connection refused) | `infra-troubleshooter` | Port not bound, container not running |
| Works locally, fails on server | `infra-troubleshooter` | Env var misconfiguration on server |
| Intermittent 502 | `infra-troubleshooter` | Reverse proxy upstream mismatch or resource exhaustion |
| SSL/TLS handshake failure | `infra-troubleshooter` | Cert expired or CN/SAN mismatch |
| Disk full errors | `infra-troubleshooter` | df -h, docker system df, prune needed |

---

## Layer 6 — CI/CD Scenarios

| Symptom | Start Agent | Key Check |
|---------|------------|-----------|
| Passes locally, fails in CI | `cicd-troubleshooter` | Build command diff, runtime version drift |
| Secrets not injected (empty values) | `cicd-troubleshooter` | Secret name mismatch between config and CI |
| Wrong/stale code deployed | `cicd-troubleshooter` | Image tag mismatch, :latest used |
| Post-deploy crash (worked in staging) | `cicd-troubleshooter` | Env var diff between environments |
| Health check fails after deploy | `cicd-troubleshooter` | Slow startup exceeds probe timeout |
| Type drift (runtime deserialization error) | `cicd-troubleshooter` | API contract changed, consumer not redeployed |
