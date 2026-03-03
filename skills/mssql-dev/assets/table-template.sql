-- =============================================
-- Table: dbo.{TableName}
-- Description: {Brief description of the table purpose}
-- =============================================

CREATE TABLE dbo.{TableName}
(
    -- Primary Key (ADR-012: GUID PKs)
    Id UNIQUEIDENTIFIER NOT NULL DEFAULT NEWID() PRIMARY KEY,

    -- Core columns (add your specific columns here)
    Name NVARCHAR(200) NOT NULL,
    Description NVARCHAR(500) NULL,

    -- Status/State columns (customize as needed)
    IsActive BIT NOT NULL DEFAULT 1,

    -- Required audit columns (DO NOT REMOVE) - 4-column Extended pattern
    CreatedBy NVARCHAR(255) NOT NULL,       -- email string, e.g. user@example.com
    CreatedOn DATETIME2 NOT NULL DEFAULT GETDATE(),
    ModifiedBy NVARCHAR(255) NOT NULL,      -- email string
    ModifiedOn DATETIME2 NOT NULL DEFAULT GETDATE(),

    -- Optional: Unique constraints
    CONSTRAINT UQ_{TableName}_{UniqueColumn} UNIQUE ({UniqueColumn})
);
GO

-- Optional: Add indexes for common queries
CREATE NONCLUSTERED INDEX IX_{TableName}_{IndexColumn}
    ON dbo.{TableName} ({IndexColumn})
    WHERE IsActive = 1;
GO
