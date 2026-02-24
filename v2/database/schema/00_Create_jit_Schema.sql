-- =============================================
-- Create jit Schema
-- JIT Access Framework - Schema Creation
-- =============================================
-- This script creates the jit schema for the Just-In-Time access framework
-- =============================================

USE [master]
GO

-- Create database if it doesn't exist (modify database name as needed)
IF NOT EXISTS (SELECT * FROM sys.databases WHERE name = 'DMAP_JIT_Permissions')
BEGIN
    CREATE DATABASE [DMAP_JIT_Permissions]
END
GO

USE [DMAP_JIT_Permissions]
GO

-- Create jit schema
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'jit')
BEGIN
    EXEC('CREATE SCHEMA [jit]')
END
GO

