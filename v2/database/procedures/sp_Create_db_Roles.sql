-- =============================================
-- Script: Create Database Roles for JIT Framework
-- Purpose: Creates database roles (jita_{schema}_read) for every schema 
--          in databases from DMAP_Maskering_Classificatie table
--          Grants SELECT and VIEW DEFINITION on all tables in each schema
-- =============================================

USE [DMAP_JIT_Permissions];
GO

SET NOCOUNT ON;

DECLARE @DatabaseName NVARCHAR(128);
DECLARE @SQL NVARCHAR(MAX);
DECLARE @ErrorOccurred BIT = 0;

BEGIN TRY
    -- Create a temp table to hold the list of databases
    CREATE TABLE #DatabaseList (DatabaseName NVARCHAR(128));

    -- Fill the temp table with database names
    INSERT INTO #DatabaseList (DatabaseName)
    SELECT DISTINCT [Laag] AS DatabaseName 
    FROM msdb.dbo.DMAP_Maskering_Classificatie 
    WHERE [Laag] IS NOT NULL 
      AND [Laag] NOT IN ('LOAD', 'STAGE', 'DMAP_StagingIn', 'STUUR', 'TRANS', 
                         'DHH_Prod', 'DHH_Analyse', 'DMAP_Operations', 
                         'DMAP_BAL', 'DMAP_MetaServices');

    -- Cursor to iterate through each database
    DECLARE DatabaseCursor CURSOR LOCAL STATIC FORWARD_ONLY READ_ONLY FOR
        SELECT DatabaseName FROM #DatabaseList;

    OPEN DatabaseCursor;
    FETCH NEXT FROM DatabaseCursor INTO @DatabaseName;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        BEGIN TRY
            -- Check if the database exists and is accessible
            IF DB_ID(@DatabaseName) IS NOT NULL
            BEGIN
                PRINT 'Processing database: ' + @DatabaseName;

                -- Build dynamic SQL to execute in the target database
                -- Note: We need to concatenate @DatabaseName as a string literal since USE changes database context
                SET @SQL = N'
                USE ' + QUOTENAME(@DatabaseName) + ';
                DECLARE @SchemaName NVARCHAR(128);
                DECLARE @RoleName NVARCHAR(128);
                DECLARE @TableName NVARCHAR(128);
                DECLARE @GrantSQL NVARCHAR(MAX);
                DECLARE @CurrentDatabaseName NVARCHAR(128) = ''' + REPLACE(@DatabaseName, '''', '''''') + ''';
                
                -- Schema cursor declaration
                DECLARE SchemaCursor CURSOR LOCAL STATIC FORWARD_ONLY READ_ONLY FOR
                    SELECT TRIM([schema])
                    FROM msdb.dbo.DMAP_Maskering_Classificatie
                    WHERE [schema] NOT IN (''sys'', ''INFORMATION_SCHEMA'')
                      AND [schema] NOT LIKE ''db_%''
                      AND laag = @CurrentDatabaseName
                
                OPEN SchemaCursor;
                FETCH NEXT FROM SchemaCursor INTO @SchemaName;
                
                WHILE @@FETCH_STATUS = 0
                BEGIN
                    SET @RoleName = ''jita_'' + @SchemaName + ''_read'';
                    
                    -- Create role if it doesn''t exist
                    IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = @RoleName AND type = ''R'')
                    BEGIN
                        SET @GrantSQL = ''CREATE ROLE '' + QUOTENAME(@RoleName);
                        EXEC sp_executesql @GrantSQL;
                        PRINT ''Created role: '' + @RoleName;
                    END
                    ELSE
                    BEGIN
                        PRINT ''Role already exists: '' + @RoleName;
                    END
                    
                    -- Table cursor declaration and logic
                    DECLARE TableCursor CURSOR LOCAL STATIC FORWARD_ONLY READ_ONLY FOR
                        SELECT TRIM(tabel)
                        FROM msdb.dbo.DMAP_Maskering_Classificatie
                        WHERE [schema] = @SchemaName
                        AND laag = @CurrentDatabaseName;
                    
                    OPEN TableCursor;
                    FETCH NEXT FROM TableCursor INTO @TableName;
                    
                    WHILE @@FETCH_STATUS = 0
                    BEGIN
                        -- Grant SELECT permission
                        SET @GrantSQL = ''GRANT SELECT ON '' + QUOTENAME(@SchemaName) + ''.'' + QUOTENAME(@TableName) + '' TO '' + QUOTENAME(@RoleName) + '';'';
                        EXEC sp_executesql @GrantSQL;
                        
                        -- Grant VIEW DEFINITION permission
                        SET @GrantSQL = ''GRANT VIEW DEFINITION ON '' + QUOTENAME(@SchemaName) + ''.'' + QUOTENAME(@TableName) + '' TO '' + QUOTENAME(@RoleName) + '';'';
                        EXEC sp_executesql @GrantSQL;
                        
                        PRINT ''Granted permissions on '' + QUOTENAME(@SchemaName) + ''.'' + QUOTENAME(@TableName) + '' to '' + @RoleName;
                        
                        FETCH NEXT FROM TableCursor INTO @TableName;
                    END
                    
                    -- Clean up table cursor
                    IF CURSOR_STATUS(''local'', ''TableCursor'') >= 0
                    BEGIN
                        CLOSE TableCursor;
                        DEALLOCATE TableCursor;
                    END
                    
                    -- Fetch next schema
                    FETCH NEXT FROM SchemaCursor INTO @SchemaName;
                END
                
                -- Clean up schema cursor
                IF CURSOR_STATUS(''local'', ''SchemaCursor'') >= 0
                BEGIN
                    CLOSE SchemaCursor;
                    DEALLOCATE SchemaCursor;
                END
                ';

                -- Execute the dynamic SQL for this database
                EXEC sp_executesql @SQL;
                
                PRINT 'Completed processing database: ' + @DatabaseName;
            END
            ELSE
            BEGIN
                PRINT 'Database [' + @DatabaseName + '] does not exist or is not accessible. Skipping.';
            END
        END TRY
        BEGIN CATCH
            PRINT 'Error processing database [' + @DatabaseName + ']: ' + ERROR_MESSAGE();
            SET @ErrorOccurred = 1;
            -- Continue with next database instead of stopping
        END CATCH

        -- Fetch next database
        FETCH NEXT FROM DatabaseCursor INTO @DatabaseName;
    END

    -- Clean up database cursor
    IF CURSOR_STATUS('local', 'DatabaseCursor') >= 0
    BEGIN
        CLOSE DatabaseCursor;
        DEALLOCATE DatabaseCursor;
    END

    -- Drop temp table
    DROP TABLE #DatabaseList;

    IF @ErrorOccurred = 1
    BEGIN
        PRINT 'Script completed with errors. Please review the output above.';
    END
    ELSE
    BEGIN
        PRINT 'Script completed successfully.';
    END
END TRY
BEGIN CATCH
    -- Clean up cursor if it exists
    IF CURSOR_STATUS('local', 'DatabaseCursor') >= 0
    BEGIN
        IF CURSOR_STATUS('local', 'DatabaseCursor') > -1
            CLOSE DatabaseCursor;
        DEALLOCATE DatabaseCursor;
    END

    -- Clean up temp table if it exists
    IF OBJECT_ID('tempdb..#DatabaseList') IS NOT NULL
        DROP TABLE #DatabaseList;

    PRINT 'Fatal error: ' + ERROR_MESSAGE();
    PRINT 'Error Number: ' + CAST(ERROR_NUMBER() AS NVARCHAR(10));
    PRINT 'Error Line: ' + CAST(ERROR_LINE() AS NVARCHAR(10));
    THROW;
END CATCH
GO
