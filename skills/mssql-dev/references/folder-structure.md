# {Project}.Database Project Folder Structure

## Overview

The `{Project}.Database` project is an SDK-style SQL Server Database Project (.sqlproj) using `Microsoft.Build.Sql` SDK. All database objects must be organized in the correct folders and included in the `.sqlproj` file to be part of the build.

## Directory Structure

```
{Project}.Database/
├── dbo/
│   ├── Tables/              # Table definitions (.sql)
│   ├── Stored Procedures/   # Stored procedures (.sql)
│   ├── Views/               # Views (.sql)
│   ├── Functions/           # User-defined functions (.sql)
│   └── Types/               # User-defined types (.sql)
├── Security/
│   ├── Roles/               # Database roles (.sql)
│   ├── Users/               # Database users (.sql)
│   └── Logins/              # Server logins (.sql)
├── Scripts/
│   ├── Pre-Deployment/      # Scripts run before deployment
│   └── Post-Deployment/     # Scripts run after deployment (seed data, etc.)
└── {Project}.Database.sqlproj     # Project file
```

## File Placement Rules

### Tables
- **Location**: `{Project}.Database/dbo/Tables/`
- **Naming**: `{TableName}.sql` (e.g., `Users.sql`, `Orders.sql`)
- **Schema prefix**: Include in filename: `dbo.Users.sql` (if `IncludeSchemaNameInFileName` is true)

### Stored Procedures
- **Location**: `{Project}.Database/dbo/Stored Procedures/`
- **Naming**: `{ProcedureName}.sql` (e.g., `uspGetUserById.sql`, `uspCreateOrder.sql`)
- **Schema prefix**: Include in filename: `dbo.uspGetUserById.sql`

### Views
- **Location**: `{Project}.Database/dbo/Views/`
- **Naming**: `{ViewName}.sql` (e.g., `vwActiveUsers.sql`)

### Functions
- **Location**: `{Project}.Database/dbo/Functions/`
- **Naming**: `{FunctionName}.sql` (e.g., `fnCalculateAge.sql`)

### Seed/Migration Scripts
- **Location**: `{Project}.Database/Scripts/Post-Deployment/`
- **Naming**: Descriptive name with date prefix (e.g., `001_SeedRoles.sql`, `002_SeedTestUsers.sql`)
- **Note**: Post-deployment scripts run AFTER schema deployment

## Including Files in Build

After creating a `.sql` file, it MUST be added to the `.sqlproj` file under `<ItemGroup>`:

```xml
<ItemGroup>
  <Build Include="dbo\Tables\Users.sql" />
  <Build Include="dbo\Stored Procedures\uspGetUserById.sql" />
  <Build Include="dbo\Views\vwActiveUsers.sql" />
</ItemGroup>
```

### For Post-Deployment Scripts
```xml
<ItemGroup>
  <PostDeploy Include="Scripts\Post-Deployment\001_SeedRoles.sql" />
</ItemGroup>
```

## Important Notes

1. **Always use backslashes** in .sqlproj file paths (Windows convention)
2. **Schema prefix in filename** depends on `IncludeSchemaNameInFileName` property
3. **Post-deployment scripts** are idempotent (safe to run multiple times)
4. **Files not in .sqlproj** will NOT be included in the build
5. **Use `<Build Include="..." />`** for schema objects (tables, procs, views)
6. **Use `<PostDeploy Include="..." />`** for post-deployment scripts

## Checking if Files are Included

To verify a file is included in the build:
1. Open `{Project}.Database.sqlproj`
2. Look for the file path under `<ItemGroup>` sections
3. Ensure it has `<Build Include="..." />` or appropriate tag

## Build Output

When the project builds:
- Creates `.dacpac` file in `bin/Debug/` or `bin/Release/`
- Creates `{Project}.Database_Create.sql` script
- Validates all SQL syntax and dependencies
