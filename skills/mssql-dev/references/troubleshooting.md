# SQL Server Troubleshooting Guide

## Common Issues and Solutions

### 1. SQL Server on Docker Not Working

#### Issue: Container won't start
**Symptoms**:
- Docker container exits immediately
- Error: "SQL Server 2022 will run as non-root by default"
- Container logs show startup failures

**Solutions**:

1. **Check password complexity**:
   ```bash
   # Password MUST be at least 8 characters with uppercase, lowercase, numbers, and symbols
   docker run -e "ACCEPT_EULA=Y" -e "SA_PASSWORD=YourStrong@Password123" ...
   ```

2. **Check memory allocation**:
   ```bash
   # SQL Server needs at least 2GB RAM
   docker run -e "MSSQL_MEMORY_LIMIT_MB=2048" ...
   ```

3. **Check Docker logs**:
   ```bash
   docker logs <container-name>
   ```

4. **Verify EULA acceptance**:
   ```bash
   docker run -e "ACCEPT_EULA=Y" ...
   ```

#### Issue: Cannot connect to SQL Server container
**Symptoms**:
- Connection timeout
- "Server not found or not accessible"

**Solutions**:

1. **Check container is running**:
   ```bash
   docker ps
   ```

2. **Verify port mapping**:
   ```bash
   docker run -p 1433:1433 ...
   # Access via localhost:1433
   ```

3. **Check connection string**:
   ```
   Server=localhost,1433;Database={DbName};User Id=sa;Password=YourPassword;TrustServerCertificate=True
   ```

4. **Test with sqlcmd**:
   ```bash
   docker exec -it <container-name> /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P YourPassword -C
   ```

5. **Check firewall/network**:
   ```bash
   # macOS - check if port is listening
   lsof -i :1433
   ```

### 2. Table Schema / Database Code Not Up to Date

#### Issue: Table doesn't exist in database but exists in code
**Symptoms**:
- "Invalid object name" errors
- Table queries fail
- Application throws SQL exceptions

**Solutions**:

1. **Check if file is in .sqlproj**:
   - Open `{Project}.Database/{Project}.Database.sqlproj`
   - Search for the table filename
   - Ensure it has `<Build Include="dbo\Tables\YourTable.sql" />`

2. **Rebuild database project**:
   ```bash
   cd {Project}.Database
   dotnet build
   ```

3. **Deploy the database**:
   ```bash
   # Check if .dacpac was generated
   ls bin/Debug/{Project}.Database.dacpac

   # Deploy using sqlpackage or publish profile
   ```

4. **Verify deployment**:
   ```sql
   -- Check if table exists
   SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'YourTable'
   ```

#### Issue: Database has old schema version
**Symptoms**:
- Missing columns
- Wrong data types
- Deployment succeeded but changes not reflected

**Solutions**:

1. **Check deployment method**:
   - Are you using dacpac deployment?
   - Are you running scripts manually?
   - Are migration scripts idempotent?

2. **Force schema update**:
   ```bash
   # Rebuild and redeploy
   dotnet build {Project}.Database/{Project}.Database.sqlproj
   # Then deploy the dacpac
   ```

3. **Check for blocking sessions**:
   ```sql
   -- Find blocking sessions
   SELECT * FROM sys.dm_exec_requests WHERE blocking_session_id <> 0
   ```

### 3. Build Errors

#### Issue: SQL file not included in build
**Symptoms**:
- Objects missing after deployment
- No build errors but objects don't appear

**Solution**:
Add to `.sqlproj`:
```xml
<ItemGroup>
  <Build Include="dbo\Tables\YourTable.sql" />
</ItemGroup>
```

#### Issue: Circular dependency errors
**Symptoms**:
- Build fails with dependency errors
- "Could not resolve reference to object"

**Solutions**:
1. Check for circular references between views/procedures
2. Ensure referenced objects are defined first
3. Use `WITH SCHEMABINDING` carefully

#### Issue: Syntax errors in SQL files
**Symptoms**:
- Build fails with SQL syntax errors
- "Incorrect syntax near..."

**Solutions**:
1. Validate SQL syntax in SQL Server Management Studio
2. Check for missing GO statements between batches
3. Ensure proper termination of statements (semicolons)

### 4. Connection String Issues

#### Issue: Cannot connect from .NET application
**Symptoms**:
- "Login failed for user"
- "Cannot open database"

**Solutions**:

1. **Verify connection string format**:
   ```json
   "ConnectionStrings": {
     "DefaultConnection": "Server=localhost,1433;Database={DbName};User Id=sa;Password=YourPassword;TrustServerCertificate=True"
   }
   ```

2. **Check user permissions**:
   ```sql
   -- Create database user
   USE [{DbName}]
   GO
   CREATE USER [AppUser] FOR LOGIN [AppUser]
   GO
   ALTER ROLE [db_datareader] ADD MEMBER [AppUser]
   GO
   ALTER ROLE [db_datawriter] ADD MEMBER [AppUser]
   GO
   ```

3. **Enable SQL Server authentication**:
   - Mixed Mode authentication must be enabled
   - Check in SQL Server Configuration Manager

### 5. Performance Issues

#### Issue: Slow queries
**Solutions**:
1. Add appropriate indexes
2. Use execution plans to identify bottlenecks
3. Avoid SELECT * queries
4. Use WHERE clauses efficiently

#### Issue: Deadlocks
**Solutions**:
1. Keep transactions short
2. Access tables in consistent order
3. Use appropriate isolation levels
4. Check deadlock graphs in SQL Server logs

## Diagnostic Commands

### Check Database Status
```sql
SELECT name, state_desc, recovery_model_desc
FROM sys.databases
WHERE name = '{DbName}'
```

### List All Tables
```sql
SELECT TABLE_SCHEMA, TABLE_NAME
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_TYPE = 'BASE TABLE'
ORDER BY TABLE_SCHEMA, TABLE_NAME
```

### Check Last Deployment
```sql
SELECT * FROM sys.dm_db_log_space_usage
```

### Docker Container Health
```bash
docker inspect <container-name> --format='{{.State.Health.Status}}'
```

## Quick Reference

### Start SQL Server Docker Container
```bash
docker run -e "ACCEPT_EULA=Y" \
  -e "SA_PASSWORD=YourStrong@Password123" \
  -p 1433:1433 \
  --name {project}-sqlserver \
  -d mcr.microsoft.com/mssql/server:2022-latest
```

### Connect to Container
```bash
docker exec -it {project}-sqlserver bash
```

### Stop and Remove Container
```bash
docker stop {project}-sqlserver
docker rm {project}-sqlserver
```

### Check Database Build
```bash
cd {Project}.Database
dotnet build
# Look for .dacpac in bin/Debug/
```
