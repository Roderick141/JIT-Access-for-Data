-- =============================================
-- Create jit.DB_Roles Table
-- Database role metadata
-- =============================================

USE [DMAP_JIT_Permissions]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[jit].[DB_Roles]') AND type in (N'U'))
    DROP TABLE [jit].[DB_Roles]
GO

CREATE TABLE [jit].[DB_Roles](
    [DbRoleId] [int] IDENTITY(1,1) NOT NULL,
    [DbRoleName] [nvarchar](255) NOT NULL,
    [RoleType] [nvarchar](50) NULL,
    [Description] [nvarchar](max) NULL,
    [IsJitManaged] [bit] NOT NULL CONSTRAINT [DF_DB_Roles_IsJitManaged] DEFAULT (1),
    [HasUnmask] [bit] NOT NULL CONSTRAINT [DF_DB_Roles_HasUnmask] DEFAULT (0),
    [CreatedUtc] [datetime2](7) NOT NULL CONSTRAINT [DF_DB_Roles_CreatedUtc] DEFAULT (GETUTCDATE()),
    [UpdatedUtc] [datetime2](7) NOT NULL CONSTRAINT [DF_DB_Roles_UpdatedUtc] DEFAULT (GETUTCDATE()),
    [CreatedBy] [nvarchar](255) NOT NULL DEFAULT (SUSER_SNAME()),
    [UpdatedBy] [nvarchar](255) NOT NULL DEFAULT (SUSER_SNAME()),
    CONSTRAINT [PK_DB_Roles] PRIMARY KEY CLUSTERED ([DbRoleId] ASC)
    WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
)

CREATE UNIQUE NONCLUSTERED INDEX [IX_DB_Roles_DbRoleName] ON [jit].[DB_Roles]([DbRoleName] ASC)
    WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)

GO

