-- =============================================
-- Migration Script: {###_DescriptiveName.sql}
-- Description: {What this migration does}
-- Date: {YYYY-MM-DD}
-- =============================================
-- NOTE: This script should be IDEMPOTENT (safe to run multiple times)
-- =============================================

-- Check if migration already applied (optional tracking)
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = '{TableName}')
BEGIN
    PRINT 'Creating table {TableName}...';

    CREATE TABLE dbo.{TableName}
    (
        Id UNIQUEIDENTIFIER NOT NULL DEFAULT NEWID() PRIMARY KEY,
        Name NVARCHAR(200) NOT NULL,
        Description NVARCHAR(500) NULL,
        IsActive BIT NOT NULL DEFAULT 1,

        -- Required audit columns
        CreatedOn DATETIME2 NOT NULL DEFAULT GETDATE(),
        ModifiedOn DATETIME2 NOT NULL DEFAULT GETDATE()
    );

    PRINT 'Table {TableName} created successfully.';
END
ELSE
BEGIN
    PRINT 'Table {TableName} already exists. Skipping creation.';
END
GO

-- Add columns (idempotent)
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('dbo.{TableName}') AND name = 'NewColumn')
BEGIN
    PRINT 'Adding column NewColumn to {TableName}...';

    ALTER TABLE dbo.{TableName}
    ADD NewColumn NVARCHAR(100) NULL;

    PRINT 'Column NewColumn added successfully.';
END
ELSE
BEGIN
    PRINT 'Column NewColumn already exists. Skipping.';
END
GO

-- Seed data (idempotent)
IF NOT EXISTS (SELECT 1 FROM dbo.{TableName} WHERE Name = 'Default Value')
BEGIN
    PRINT 'Inserting default data...';

    INSERT INTO dbo.{TableName} (Name, Description, IsActive)
    VALUES ('Default Value', 'Default description', 1);

    PRINT 'Default data inserted successfully.';
END
ELSE
BEGIN
    PRINT 'Default data already exists. Skipping.';
END
GO

-- Create indexes (idempotent)
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_{TableName}_Name' AND object_id = OBJECT_ID('dbo.{TableName}'))
BEGIN
    PRINT 'Creating index IX_{TableName}_Name...';

    CREATE NONCLUSTERED INDEX IX_{TableName}_Name
        ON dbo.{TableName} (Name)
        WHERE IsActive = 1;

    PRINT 'Index IX_{TableName}_Name created successfully.';
END
ELSE
BEGIN
    PRINT 'Index IX_{TableName}_Name already exists. Skipping.';
END
GO

PRINT 'Migration completed successfully.';
GO
