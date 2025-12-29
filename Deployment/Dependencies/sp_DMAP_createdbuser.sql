USE [master]
GO
/****** Object:  StoredProcedure [dbo].[sp_DMAP_createdbuser]    Script Date: 6-11-2025 10:37:13 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER procedure [dbo].[sp_DMAP_createdbuser]
	@loginname       sysname
as
    -- SETUP RUNTIME OPTIONS / DECLARE VARIABLES --
	set nocount on
	declare @ret        int,    -- return value of sp call
			@stmtU		nvarchar(4000),
			@stmtS		nvarchar(4000),
			@bericht	varchar(500)

    -- CHECK PERMISSIONS (Shiloh Check) --
    if (not is_member('db_accessadmin') = 1) and
       	(not is_member('db_owner') = 1)
    begin
    	dbcc auditevent (109, 1, 0, @loginname, NULL, NULL, NULL, NULL, NULL)
    	raiserror(15247,-1,-1)
    	return (1)
    end

    -- DISALLOW USER TRANSACTION --
	set implicit_transactions off
	IF (@@trancount > 0)
	begin
		raiserror(15002,-1,-1,'sys.sp_DMAP_createdbuser')
		return (1)
	end

	-- VALIDATE LOGIN NAME --
	if (quotename(@loginname) is null or datalength(@loginname) = 0)
	begin
		select @bericht = 'Loginnaam '
		select @bericht += @loginname
		select @bericht += ' voldoet niet aan de eisen en is leeg of NULL'
		print @bericht
		return(1)
	end
	
	if not exists (SELECT [name] FROM master.sys.server_principals WHERE [name] = @loginname)
	begin
		select @bericht = 'Login '
		select @bericht += @loginname
		select @bericht += ' bestaat niet'
		print @bericht
		return (1)
	end

	if exists (SELECT [name] FROM sys.database_principals WHERE [name] = @loginname)
	begin
		select @bericht = 'User '
		select @bericht += @loginname
		select @bericht += ' bestaat al in '
		select @bericht += db_name()
		print @bericht
		return (1)
	end

	-- Form Create User statement
	select @stmtU = 'CREATE USER '
	select @stmtU += quotename(@loginname, ']')
	select @stmtU += ' FOR LOGIN '
	select @stmtU += quotename(@loginname, ']')

	BEGIN TRANSACTION

	-- create the user
	exec (@stmtU)
	if @@error <> 0
	begin
		ROLLBACK TRANSACTION
		return (1)
	end

	COMMIT TRANSACTION
	select @bericht = 'User '
	select @bericht += @loginname
	select @bericht += ' is aangemaakt in '
	select @bericht += db_name()
	print @bericht
    -- RETURN SUCCESS STATUS --
    return (0)	-- sp_grantdbaccess
