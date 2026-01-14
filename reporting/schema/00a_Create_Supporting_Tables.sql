-- =============================================
-- Create Supporting Tables for ETL and Sync State
-- =============================================

USE [DMAP_JIT_Permissions_Reporting]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- CDC Sync State table - tracks last processed LSN for each table
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[reporting].[CDC_SyncState]') AND type in (N'U'))
    DROP TABLE [reporting].[CDC_SyncState]
GO

CREATE TABLE [reporting].[CDC_SyncState](
    [TableName] [nvarchar](128) NOT NULL,
    [CaptureInstance] [nvarchar](128) NOT NULL,
    [LastSyncLSN] [binary](10) NULL,
    [LastSyncUtc] [datetime2](7) NULL,
    [LastRowCount] [bigint] NULL,
    CONSTRAINT [PK_CDC_SyncState] PRIMARY KEY CLUSTERED ([TableName] ASC)
    WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
)
GO

-- ETL Log table - logs ETL operations
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[reporting].[ETL_Log]') AND type in (N'U'))
    DROP TABLE [reporting].[ETL_Log]
GO

CREATE TABLE [reporting].[ETL_Log](
    [LogId] [bigint] IDENTITY(1,1) NOT NULL,
    [LogUtc] [datetime2](7) NOT NULL CONSTRAINT [DF_ETL_Log_LogUtc] DEFAULT (GETUTCDATE()),
    [TableName] [nvarchar](128) NOT NULL,
    [Operation] [nvarchar](50) NOT NULL,
    [Status] [nvarchar](50) NOT NULL,
    [RowsProcessed] [int] NULL,
    [ErrorMessage] [nvarchar](max) NULL,
    [Details] [nvarchar](max) NULL,
    CONSTRAINT [PK_ETL_Log] PRIMARY KEY CLUSTERED ([LogId] ASC)
    WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
)
GO

CREATE NONCLUSTERED INDEX [IX_ETL_Log_LogUtc_TableName] ON [reporting].[ETL_Log]([LogUtc] DESC, [TableName] ASC)
    WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
GO

CREATE NONCLUSTERED INDEX [IX_ETL_Log_Status] ON [reporting].[ETL_Log]([Status] ASC)
    WHERE [Status] = 'Error'
    WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
GO
