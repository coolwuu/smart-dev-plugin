---
name: mssql-dev
description: SQL Server database development specialist. Use when creating tables, stored procedures, migrations, or troubleshooting SQL Server/Docker issues. Reads project tech-stack directory conventions if present; falls back to generic SQL Server patterns (UNIQUEIDENTIFIER PKs, CreatedOn/ModifiedOn with GETUTCDATE(), no FK constraints, WITH(NOLOCK), SARG optimization, stored proc naming {Product}_{Module}_{Function}_{Date}).
---

# MSSQL Development Skill

## Overview

This skill provides specialized guidance for Microsoft SQL Server database development across projects. Enforce project-wide database conventions (read from project config when available), manage SQL Server Database Project structure, and provide troubleshooting support for common SQL Server and Docker issues.

> **Note:** Naming conventions (stored procedure prefix, project name placeholder `{Product}`) come from the project's `tech-stack directory` config. When no project config exists, the generic `{Product}` placeholder is used throughout and the skill applies the fallback conventions in `references/conventions.md`.

## When to Use This Skill

Activate this skill when:
- Creating new database tables
- Writing or updating stored procedures, views, or functions
- Creating migration scripts or seed data
- Troubleshooting SQL Server on Docker
- Diagnosing database schema synchronization issues
- Working with `.sql` files in SQL Server Database projects
- Questions about database conventions or patterns

## Core Capabilities

### 1. Enforce Organization Database Conventions

> **Project conventions take precedence.** Before applying conventions below, check if the
> project has `tech-stack directory`. If a SQL/database conventions file exists there (e.g.
> `mssql.md`), read it first — it is the authoritative source and overrides any generic
> guidance in this skill.
>
> If `tech-stack directory` does not exist: apply the generic conventions below and note that
> project-specific rules are unavailable.

All database objects must follow project-wide conventions documented in the project's tech-stack directory conventions file (see references/conventions.md for generic fallback). Critical requirements:

- **Required audit columns**: Every table MUST have `CreatedOn DATETIME2 NOT NULL DEFAULT GETUTCDATE()` and `ModifiedOn DATETIME2 NOT NULL DEFAULT GETUTCDATE()`
- **Timestamp naming**: Use `CreatedOn`/`ModifiedOn` (NEVER `CreatedDate`/`CreatedAt`/`UpdatedAt`)
- **Timestamp function**: Use `GETUTCDATE()` (UTC; NEVER `GETDATE()` which is timezone-dependent)
- **Primary key**: `Id UNIQUEIDENTIFIER NOT NULL DEFAULT NEWID() PRIMARY KEY` (per ADR-012)
- **Foreign keys**: AVOID foreign key constraints (per ADR-006); use application-level integrity
- **Data types**: `DATETIME2` for timestamps, `NVARCHAR` for strings, `BIT` for booleans, `DECIMAL(18,2)` for money
- **Naming**: PascalCase for tables/columns, boolean prefix with `Is`, FK columns end with `Id`
- **Stored procedure naming**: `[dbo].[{Product}_{Module}_{Function}_{YYYY.MM.DD}]` (e.g., `{Product}_Auth_UserLogin_2025.11.22`)
- **Stored procedure versioning**: When updating a procedure, UPDATE the existing file in-place and change the date suffix (don't create new separate files for new versions)
- **Query hints**: All SELECT queries MUST include `WITH(NOLOCK)` to prevent read locks
- **SARG optimization**: Use SARG-able predicates when possible (avoid functions on columns in WHERE clauses)

### 2. Manage Database Project Structure

Ensure all database objects are properly organized and included in builds. See `references/folder-structure.md` for details.

**File Organization** (example layout):
- Tables → `{Project}.Database/dbo/Tables/{TableName}.sql`
- Stored Procedures → `{Project}.Database/dbo/Stored Procedures/{ProcName}.sql`
- Views → `{Project}.Database/dbo/Views/{ViewName}.sql`
- Migration Scripts → `{Project}.Database/Scripts/Post-Deployment/{###_Description}.sql`

**Critical Build Step**: After creating any `.sql` file, ALWAYS update `{Project}.Database.sqlproj`:

```xml
<ItemGroup>
  <Build Include="dbo\Tables\YourTable.sql" />
  <Build Include="dbo\Stored Procedures\uspYourProc.sql" />
  <PostDeploy Include="Scripts\Post-Deployment\001_SeedData.sql" />
</ItemGroup>
```

**Verification Steps**:
1. Create the `.sql` file in the correct folder
2. Add `<Build Include="..." />` entry to `.sqlproj`
3. Run `dotnet build {Project}.Database/{Project}.Database.sqlproj` to validate
4. Verify `.dacpac` is generated in `bin/Debug/`

### 3. Use Templates for Consistency

Templates are provided in the `assets/` folder to ensure consistency:

- **`assets/table-template.sql`**: Standard table structure with required audit columns
- **`assets/stored-proc-template.sql`**: Stored procedure with error handling
- **`assets/migration-template.sql`**: Idempotent migration script pattern

Copy and customize these templates rather than creating from scratch.

### 4. Troubleshooting Support

Provide solutions for common issues documented in `references/troubleshooting.md`:

- **SQL Server on Docker**: Container startup failures, connection issues, password complexity
- **Schema sync issues**: Tables exist in code but not database, missing columns, deployment problems
- **Build errors**: Files not included in `.sqlproj`, circular dependencies, syntax errors
- **Connection string issues**: Authentication failures, database access problems

## Workflow for Common Tasks

### Creating a New Table

1. **Read conventions**: Review `references/conventions.md` for current standards
2. **Copy template**: Use `assets/table-template.sql` as starting point
3. **Customize**: Replace `{TableName}` and add specific columns
4. **Save file**: Place in `{Project}.Database/dbo/Tables/{TableName}.sql`
5. **Update project**: Add `<Build Include="dbo\Tables\{TableName}.sql" />` to `.sqlproj`
6. **Validate**: Run `dotnet build {Project}.Database/{Project}.Database.sqlproj`
7. **Verify**: Ensure `.dacpac` builds without errors

### Creating a Stored Procedure

1. **Copy template**: Use `assets/stored-proc-template.sql`
2. **Customize**: Replace placeholders with actual procedure logic
3. **Save file**: Place in `{Project}.Database/dbo/Stored Procedures/usp{ProcName}.sql`
4. **Update project**: Add `<Build Include="dbo\Stored Procedures\usp{ProcName}.sql" />` to `.sqlproj`
5. **Validate**: Build the project

### Creating a Migration Script

1. **Copy template**: Use `assets/migration-template.sql`
2. **Make idempotent**: Ensure script can run multiple times safely (use `IF NOT EXISTS` checks)
3. **Number sequentially**: Use format `###_DescriptiveName.sql` (e.g., `001_CreateUsersTable.sql`)
4. **Save file**: Place in `{Project}.Database/Scripts/Post-Deployment/`
5. **Update project**: Add `<PostDeploy Include="Scripts\Post-Deployment\###_Name.sql" />` to `.sqlproj`

### Troubleshooting "Table Not Found" Errors

1. **Check file location**: Verify `.sql` file is in `{Project}.Database/dbo/Tables/`
2. **Check .sqlproj**: Search for filename in `{Project}.Database.sqlproj`
3. **Verify build entry**: Ensure `<Build Include="..." />` exists
4. **Rebuild**: Run `dotnet build {Project}.Database/{Project}.Database.sqlproj`
5. **Check deployment**: Verify `.dacpac` was deployed to target database
6. **Query database**: Run `SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'YourTable'`

### Troubleshooting SQL Server Docker Issues

1. **Check logs**: Run `docker logs <container-name>`
2. **Verify password**: Must be 8+ chars with uppercase, lowercase, numbers, symbols
3. **Check memory**: SQL Server needs at least 2GB RAM
4. **Verify EULA**: Ensure `ACCEPT_EULA=Y` is set
5. **Test connection**: Use `docker exec -it <container> /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P YourPassword -C`
6. **See full guide**: Reference `references/troubleshooting.md` for detailed solutions

## Best Practices

- **Always enforce conventions**: Review project's tech-stack directory conventions file (see references/conventions.md for generic fallback) before creating objects
- **Never skip .sqlproj updates**: Files not in the project won't be deployed
- **Use templates**: Start with provided templates for consistency
- **Make migrations idempotent**: Scripts should be safe to run multiple times
- **Validate builds**: Always run `dotnet build` after making changes
- **Avoid FK constraints**: Follow ADR-006 (application-level referential integrity)
- **Document stored procedures**: Include clear descriptions and parameter documentation
- **Test thoroughly**: Verify schema changes don't break existing queries

## Key Reference Files

- **`references/conventions.md`**: Generic database conventions (MUST READ when no project-specific tech-stack file exists)
- **`references/folder-structure.md`**: Database project organization and build integration
- **`references/troubleshooting.md`**: Common issues and solutions for SQL Server and Docker
- **`assets/table-template.sql`**: Standard table template
- **`assets/stored-proc-template.sql`**: Stored procedure template
- **`assets/migration-template.sql`**: Migration script template

## Important Reminders

1. **CreatedOn/ModifiedOn are REQUIRED** on every table (not CreatedDate/CreatedAt)
2. **Use GETUTCDATE() not GETDATE()** for timestamps (UTC; timezone-independent)
3. **No foreign key constraints** (per ADR-006)
4. **Stored procedure naming**: `[dbo].[{Product}_{Module}_{Function}_{YYYY.MM.DD}]`
5. **All SELECT queries MUST use WITH(NOLOCK)** to prevent read locks
6. **Use SARG-able predicates** - avoid functions on columns in WHERE clauses
7. **Always update .sqlproj** after creating .sql files
8. **Build the project** to validate changes
9. **Make migrations idempotent** for safe re-execution
10. **Follow naming conventions**: PascalCase, `Is` prefix for booleans, `Id` suffix for foreign keys
