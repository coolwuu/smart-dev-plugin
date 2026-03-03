# Database Conventions

> **Project conventions take precedence.**
> Always read the project's tech-stack conventions file first (e.g. `CLAUDE.md` or a dedicated `mssql.md`).
> The rules below are generic fallbacks only — use when no project-specific file exists.

## Generic Fallback Conventions

### Timestamps
- Column names: `CreatedOn` / `ModifiedOn` (never `CreatedAt`, `UpdatedAt`, `CreatedDate`)
- Function: `GETUTCDATE()` (UTC; never `GETDATE()` which is timezone-dependent)
- Type: `DATETIME2`

### Primary Keys
- `Id UNIQUEIDENTIFIER NOT NULL DEFAULT NEWID() PRIMARY KEY`

### Audit Columns (required on every table)
- `CreatedBy NVARCHAR(255) NOT NULL`
- `CreatedOn DATETIME2 NOT NULL DEFAULT GETUTCDATE()`
- `ModifiedBy NVARCHAR(255) NOT NULL`
- `ModifiedOn DATETIME2 NOT NULL DEFAULT GETUTCDATE()`

### Query Hints
- All SELECT queries MUST include `WITH(NOLOCK)`

### SARG Optimization
- Avoid functions on columns in WHERE clauses (prevents index use)

### Naming
- Tables/columns: PascalCase
- Boolean columns: `Is` prefix (e.g. `IsActive`)
- FK columns: `{Entity}Id` suffix
- Stored procedures: `[dbo].[{Product}_{Module}_{Function}_{YYYY.MM.DD}]`
