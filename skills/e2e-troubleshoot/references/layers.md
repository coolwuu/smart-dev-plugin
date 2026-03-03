# Layer Checklists & Diagnostic Commands

Per-layer "What to check" checklists, diagnostic bash commands, cross-layer root causes table,
and DACPAC redeploy checklist.

Source: project troubleshooting guide — Sections L1–L4 + cross-layer tables

---

## Layer 1: Frontend

### What to check
- [ ] `test-results/<test-name>/error-context.md` — actual page snapshot at failure point
  - `"An error occurred"` on page → API failure, not frontend bug → go to Layer 2
  - `[plugin:vite:vue] The service is no longer running` → esbuild crashed; kill and restart Nuxt dev server
- [ ] Vue component uses correct `data-testid` (strict mode requires exactly one match)
- [ ] Composable calls API with correct params and HTTP verb
- [ ] `$fetch` error is surfaced (not silently swallowed by `.catch(() => {})`)
- [ ] Status text comparisons use exact match, not `.includes()` (e.g. `"inactive".includes("active") === true`)
- [ ] Loading skeleton wait is properly handled before asserting data freshness

### Diagnostic commands (E2E)
```bash
# View actual page state at failure
cat test-results/<test-name>/error-context.md

# Run single failing test with headed browser for visual inspection
cd {e2e-dir} && npx playwright test <test-file> --headed --project=chromium
```

---

## Layer 2: API

### What to check
- [ ] Hit the endpoint directly with `curl + token` — bypass frontend entirely
- [ ] Controller `[FromQuery]` param names match what frontend sends (enum binding: use `string?` + `Enum.TryParse`, not `int?`)
- [ ] CORS `WithMethods(...)` in `Program.cs` includes all required HTTP verbs (especially `PATCH`, `DELETE`)
- [ ] Service pre-validation fires before DB call (service catches `THROW` as `SqlException` → 500, not `ValidationException`)
- [ ] Response shape matches what frontend/E2E expects (`PaginatedResponse<T>` vs bare list)
- [ ] `ZERO_GUID` guard: service layer returns 400 for `00000000-...` before reaching DB

### Diagnostic commands
```bash
# Get auth token — use Python to avoid zsh ! expansion issues with passwords
# Replace credentials and URL with your project's test user and API base URL
TOKEN=$(python3 -c "
import urllib.request, json
data = json.dumps({'email': '<test-user-email>', 'password': '<test-password>'}).encode()
req = urllib.request.Request('<api-base-url>/api/v1/auth/login', data, {'Content-Type': 'application/json'})
with urllib.request.urlopen(req) as r: print(json.loads(r.read()).get('accessToken', ''))
")

# Hit endpoint directly
curl -s -H "Authorization: Bearer $TOKEN" \
  "<api-base-url>/api/v1/<resource>/<id>" | python3 -m json.tool

# Hit with body (POST/PATCH)
curl -s -X PATCH \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"field":"value"}' \
  "<api-base-url>/api/v1/<resource>/<id>/action" | python3 -m json.tool
```

> **Note:** Never use `curl -d '...'` with passwords containing `!` in zsh — use Python instead.

---

## Layer 3: Stored Procedure

### What to check
- [ ] SP parameter names match what the repository passes (case-insensitive but typos happen)
- [ ] All SELECT statements have `WITH(NOLOCK)` where required by project conventions
- [ ] `@@ROWCOUNT` is checked and SP returns meaningful error when 0 rows affected
- [ ] `THROW 5xxxx` in SP surfaces as `SqlException` → 500 — move validation to service layer instead
- [ ] SP handles GUID inputs correctly: guard is `@Id = '00000000-0000-0000-0000-000000000000'`, not `@Id <= 0`
- [ ] `OPENJSON WITH(...)` clauses use `UNIQUEIDENTIFIER` not `INT` for GUID columns

### Diagnostic commands
```bash
# Execute SP directly in Docker container (NEVER quote password — zsh ! expansion)
docker exec {db-container} bash -c "/opt/mssql-tools18/bin/sqlcmd \
  -S localhost -U sa -P $DB_SA_PASSWORD -C \
  -d {DbName} \
  -Q \"EXEC {Project}_Entity_GetById_YYYY.MM.DD @Id = 'your-guid-here'\""

# Check SP definition
docker exec {db-container} bash -c "/opt/mssql-tools18/bin/sqlcmd \
  -S localhost -U sa -P $DB_SA_PASSWORD -C \
  -d {DbName} \
  -Q \"SELECT OBJECT_DEFINITION(OBJECT_ID('{Project}_Entity_GetById_YYYY.MM.DD'))\""
```

---

## Layer 4: Table Schema

### What to check
- [ ] Column names in SP SELECT match actual table columns (case-insensitive but check for typos)
- [ ] GUID columns are `UNIQUEIDENTIFIER`, not `NVARCHAR` or `INT`
- [ ] `CreatedBy`/`ModifiedBy` are `NVARCHAR(255)` (email strings — NOT GUIDs)
- [ ] `CreatedOn`/`ModifiedOn` are `DATETIME2` with `GETUTCDATE()` default
- [ ] Nullable vs NOT NULL matches DTO/entity nullability annotations
- [ ] New columns added to table AND to all existing SPs that SELECT that entity

### Diagnostic commands
```bash
# Inspect table schema
docker exec {db-container} bash -c "/opt/mssql-tools18/bin/sqlcmd \
  -S localhost -U sa -P $DB_SA_PASSWORD -C \
  -d {DbName} \
  -Q \"SELECT COLUMN_NAME, DATA_TYPE, IS_NULLABLE, CHARACTER_MAXIMUM_LENGTH \
       FROM INFORMATION_SCHEMA.COLUMNS \
       WHERE TABLE_NAME = 'YourTable' \
       ORDER BY ORDINAL_POSITION\""

# Check if DACPAC has been deployed (compare SP date vs source file date)
docker exec {db-container} bash -c "/opt/mssql-tools18/bin/sqlcmd \
  -S localhost -U sa -P $DB_SA_PASSWORD -C \
  -d {DbName} \
  -Q \"SELECT name, create_date, modify_date FROM sys.objects \
       WHERE type = 'P' ORDER BY modify_date DESC\""
```

---

## Common Cross-Layer Root Causes

These bugs look like one layer but live in another:

| Symptom | Looks like | Actually |
|---------|-----------|----------|
| UI filter returns wrong data | Vue component bug | Enum sent as string, `[FromQuery] int?` silently binds `null` → Layer 2 |
| Button click has no effect, badge unchanged | Vue reactivity bug | CORS preflight blocks PATCH — missing `"PATCH"` in `WithMethods` → Layer 2 |
| E2E table empty / 403 | Auth failure | `browser.newPage()` creates context without `storageState` → Layer 1 |
| API returns 400 instead of 404 | DB record missing | Service ZERO_GUID guard fires before DB lookup → Layer 2 |
| E2E `global.setup.ts` stuck at login URL | Wrong credentials | API binary/schema mismatch → 500 on all queries → Layer 4 |
| SP returns 0 rows for valid GUID | No data | New column added to table but SP not updated, SP errors silently → Layer 3 |
| API 500 on update | Business logic bug | SP `THROW` raises `SqlException`, not typed exception; pre-validate in service → Layer 3 |
| E2E fixture `selectOption` fails silently | Wrong test ID | Dept name doesn't match DB seed — always query `GET /api/v1/departments` first → Layer 1 |

---

## DACPAC Redeploy Checklist

When schema or SP changes are involved, binary + schema atomicity is required:

```bash
# 1. Run setup script (deploys DACPAC to local Docker DB)
bash scripts/setup-test-db.sh

# 2. Restart API (picks up schema + binary together)
# Kill existing dotnet process, then:
dotnet run --project {ApiProject}

# 3. Verify with direct curl (Layer 2 diagnostic above)
```

**Never** restart only the API or only redeploy the DACPAC — do both atomically or 500s will persist.

---

## Quick Checklist (Paste into any debug session)

```
[ ] Layer 1: Checked error-context.md / browser console / composable call
[ ] Layer 2: curl + token hit endpoint directly — confirmed status + body
[ ] Layer 3: Executed SP directly in Docker — confirmed params + output
[ ] Layer 4: Queried INFORMATION_SCHEMA.COLUMNS — confirmed schema matches entity
[ ] Cross-layer: checked enum binding, CORS verbs, DACPAC atomicity
```

Do not claim root cause until all applicable boxes are checked.
