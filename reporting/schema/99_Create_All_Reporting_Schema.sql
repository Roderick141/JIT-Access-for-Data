-- =============================================
-- Master Script: Create All Reporting Database Schema
-- Run this script to create all reporting database objects
-- =============================================

USE [DMAP_JIT_Permissions_Reporting]
GO

PRINT 'Creating Reporting Database Schema...'
GO

-- Create schema
:r "schema\00_Create_Reporting_Schema.sql"
GO

-- Create supporting tables
:r "schema\00a_Create_Supporting_Tables.sql"
GO

-- Create dimension tables
:r "schema\01_Create_Dimension_Tables.sql"
GO

-- Create fact tables
:r "schema\02_Create_Fact_Tables.sql"
GO

-- Create indexes
:r "schema\03_Create_Indexes.sql"
GO

PRINT 'Reporting Database Schema created successfully!'
GO
