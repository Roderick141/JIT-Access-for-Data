USE [DMAP_JIT_Permissions];
GO

    DECLARE @DatabaseName NVARCHAR(128);
    DECLARE @SQL NVARCHAR(MAX);

    -- Create a temp table to hold the list of databases
    CREATE TABLE #DatabaseList (DatabaseName NVARCHAR(128));

	--Fill the temp table with database names
	SELECT DISTINCT [Laag] AS DatabaseName FROM msdb.ddm.DMAP_Maskering_Classificatie WHERE laag IS NOT NULL and laag NOT IN ('LOAD', 'STAGE', 'DMAP_StagingIn', 'STUUR', 'TRANS', 'DHH_Prod', 'DHH_Analyse', 'DMAP_Operations', 'DMAP_BAL', 'DMAP_MetaServices');

    -- Cursor to iterate through each database
    DECLARE DatabaseCursor CURSOR FOR
    SELECT DatabaseName FROM #DatabaseList;

    OPEN DatabaseCursor;
    FETCH NEXT FROM DatabaseCursor INTO @DatabaseName;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- Check if the database exists and is accessible
        IF DB_ID(@DatabaseName) IS NOT NULL
        BEGIN
            PRINT 'Processing database: ' + @DatabaseName;
		END
		        ELSE
        BEGIN
            PRINT 'Database [' + @DatabaseName + '] does not exist or is not accessible. Skipping.';
        END

		    CLOSE DatabaseCursor;
    DEALLOCATE DatabaseCursor;

    DROP TABLE #DatabasesList;
END;

            SET @SQL = N'
            USE ' + QUOTENAME(@DatabaseName) + ';
            DECLARE @SchemaName NVARCHAR(128);
            DECLARE @RoleName NVARCHAR(128);
            DECLARE @TableName NVARCHAR(128);
            DECLARE @InnerSQL NVARCHAR(MAX);
            ';

            -- Schema cursor declaration
            SET @SQL += N'
            DECLARE SchemaCursor CURSOR FOR
            SELECT name
            FROM sys.schemas
            WHERE name NOT IN (''sys'', ''INFORMATION_SCHEMA'', ''db_accessadmin'', ''db_backupoperator'',
                               ''db_datareader'', ''db_datawriter'', ''db_ddladmin'', ''db_denydatareader'',
                               ''db_denydatawriter'', ''db_owner'', ''db_securityadmin'');
            ';

            -- Schema cursor logic
            SET @SQL += N'
            OPEN SchemaCursor;
            FETCH NEXT FROM SchemaCursor INTO @SchemaName;
            WHILE @@FETCH_STATUS = 0
            BEGIN
                SET @RoleName = ''jita_'' + @SchemaName + ''_read'';
                IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = @RoleName AND type = ''R'')
                BEGIN
                    SET @InnerSQL = ''CREATE ROLE '' + QUOTENAME(@RoleName);
                    EXEC sp_executesql @InnerSQL;
                    PRINT ''Created role '' + @RoleName;
                END
                ELSE
                BEGIN
                    PRINT ''Role '' + @RoleName + '' already exists. Skipping.'';
                END
            ';

            -- Table cursor declaration and logic
            SET @SQL += N'
                DECLARE TableCursor CURSOR FOR
                SELECT t.name
                FROM sys.tables t
                JOIN sys.schemas s ON t.schema_id = s.schema_id
                WHERE s.name = @SchemaName;
                OPEN TableCursor;
                FETCH NEXT FROM TableCursor INTO @TableName;
                WHILE @@FETCH_STATUS = 0
                BEGIN
                    SET @InnerSQL = ''GRANT SELECT ON '' + QUOTENAME(@SchemaName) + ''.'' + QUOTENAME(@TableName) + '' TO '' + QUOTENAME(@RoleName);
                    SET @InnerSQL += ''GRANT VIEW DEFINITION ON '' + QUOTENAME(@SchemaName) + ''.'' + QUOTENAME(@TableName) + '' TO '' + QUOTENAME(@RoleName);
                    EXEC sp_executesql @InnerSQL;
                    PRINT ''Granted SELECT on '' + @SchemaName + ''.'' + @TableName + '' to '' + @RoleName;
                    FETCH NEXT FROM TableCursor INTO @TableName;
                END
                CLOSE TableCursor;
                DEALLOCATE TableCursor;
            ';

            -- Schema cursor cleanup and next iteration
            SET @SQL += N'
                FETCH NEXT FROM SchemaCursor INTO @SchemaName;
            END
            CLOSE SchemaCursor;
            DEALLOCATE SchemaCursor;
            ';

            EXEC sp_executesql @SQL;
        END
        ELSE
        BEGIN
            PRINT 'Database [' + @DatabaseName + '] does not exist or is not accessible. Skipping.';
        END

        FETCH NEXT FROM DatabaseCursor INTO @DatabaseName;
    END

    CLOSE DatabaseCursor;
    DEALLOCATE DatabaseCursor;

    DROP TABLE #Databases;
END;
GO
