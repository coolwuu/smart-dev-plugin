/*
==============================================================================
Stored Procedure: [dbo].[{Prefix}_{Module}_{Function}_{YYYY.MM.DD}]
Description: {Brief description of what this procedure does}
Created: {YYYY-MM-DD}
Updated: {YYYY-MM-DD} - {What changed} (if updating existing procedure)
Epic: {Epic Name}
Feature: {Feature ID/Name}
==============================================================================

Purpose:
{Detailed explanation of what this procedure does and why it exists}

Parameters:
- @Param1 UNIQUEIDENTIFIER: Description of parameter 1
- @Param2 NVARCHAR(100): Description of parameter 2 (optional)

Returns:
{Description of what this procedure returns}

Business Rules:
- {Rule 1}
- {Rule 2}

Conventions:
- Uses WITH(NOLOCK) on all SELECT queries
- Uses GETDATE() for timestamps
- Returns error via THROW

CHANGELOG (when updating):
YYYY-MM-DD: Added @NewParam parameter for feature X
YYYY-MM-DD: Fixed bug in validation logic
==============================================================================
*/

CREATE PROCEDURE [dbo].[{Prefix}_{Module}_{Function}_{YYYY.MM.DD}]
    @Param1 UNIQUEIDENTIFIER,
    @Param2 NVARCHAR(100) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        -- Validation
        IF @Param1 IS NULL
        BEGIN
            RAISERROR('Parameter @Param1 cannot be NULL', 16, 1);
            RETURN;
        END

        -- Main logic here
        -- IMPORTANT: All SELECT queries MUST include WITH(NOLOCK)
        SELECT
            Id,
            Name,
            Description,
            IsActive,
            CreatedOn,
            ModifiedOn
        FROM dbo.{TableName} WITH(NOLOCK)
        WHERE Id = @Param1
            AND (@Param2 IS NULL OR Name LIKE '%' + @Param2 + '%')
            AND IsActive = 1;

    END TRY
    BEGIN CATCH
        -- Error handling
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();

        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END
GO

-- =============================================
-- Example Usage:
-- =============================================
-- EXEC [dbo].[{Prefix}_{Module}_{Function}_{YYYY.MM.DD}] @Param1 = 'A0000000-0000-0000-0000-000000000001', @Param2 = 'SearchTerm';
-- =============================================
