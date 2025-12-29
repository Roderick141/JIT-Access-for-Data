/*Uitrollen basis logins, database users en rollen voor DMAP_JIT_Permissions*/

--Create Logins
USE [master]
GO

EXEC sp_DMAP_createloginfromwindows @windowsaccount = 'UWPOL\UWVSPG-UG-UWV-P-DWH-DMAP-SECURITYOFFICER_uwv'
EXEC sp_DMAP_createloginfromwindows @windowsaccount = 'UWPOL\UWVSPG-UG-UWV-P-DWH-DMAP-Ontwikkelaar_uwv'

--Create Users in DMAP_JIT_Permissions
USE [DMAP_JIT_Permissions]
GO

EXEC sp_DMAP_createdbuser @loginname = 'UWPOL\UWVSPG-UG-UWV-P-DWH-DMAP-SECURITYOFFICER_uwv'
EXEC sp_DMAP_createdbuser @loginname = 'UWPOL\UWVSPG-UG-UWV-P-DWH-DMAP-Ontwikkelaar_uwv'

--Create Roles in DMAP_JIT_Permissions


