USE [master]
GO
/****** Object:  StoredProcedure [dbo].[sp_DMAP_createloginfromwindows]    Script Date: 6-11-2025 10:39:13 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER procedure [dbo].[sp_DMAP_createloginfromwindows]
    @windowsaccount		sysname
AS
    -- SETUP RUNTIME OPTIONS / DECLARE VARIABLES --
	set nocount on
	declare @exec_stmt nvarchar(4000),
	 @hextext varchar(256),
	 @ret int,
	 @bericht varchar(4000)

	if (not is_srvrolemember('sysadmin') = 1) and
	   (not is_srvrolemember('securityadmin') = 1)
    begin
    	dbcc auditevent (109, 1, 0, @windowsaccount, NULL, NULL, NULL, NULL, NULL)
    	raiserror(15247,-1,-1)
    	return (1)
    end

    -- DISALLOW USER TRANSACTION --
	set implicit_transactions off
	IF (@@trancount > 0)
	begin
		raiserror(15002,-1,-1,'sp_DMAP_createloginfromwindows')
		return (1)
	end

    -- VALIDATE ACCOUNT NAME --
	if (quotename(@windowsaccount) is null or datalength(@windowsaccount) = 0)
	begin
		select @bericht = 'Loginnaam '
		select @bericht = @bericht + @windowsaccount
		select @bericht = @bericht + ' voldoet niet aan de eisen en is leeg of NULL'
		print @bericht
		return(1)
	end

    -- VALIDATE IF LOGIN ALREADY EXISTS --
	if exists (SELECT [name] FROM master.sys.server_principals WHERE [name] = @windowsaccount)
	begin
		select @bericht = 'Login '
		select @bericht += @windowsaccount
		select @bericht += ' bestaat al'
		print @bericht
		return (1)
	end

    -- ASSEMBLE CREATE STATEMENT
	select @exec_stmt = 'CREATE LOGIN ' 
	select @exec_stmt += quotename(@windowsaccount)
	select @exec_stmt += ' FROM WINDOWS'

	-- EXECUTE STATEMENT
	exec (@exec_stmt)
	if @@error <> 0
		return (1)

	select @bericht = 'Login '
	select @bericht += @windowsaccount
	select @bericht += ' is aangemaakt'
	print @bericht
    -- RETURN SUCCESS --
	return  (0)
