-- =============================================
-- Create jit.Users Table
-- User identity and AD enrichment
-- =============================================

USE [DMAP_JIT_Permissions]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[jit].[Users]') AND type in (N'U'))
    DROP TABLE [jit].[Users]
GO

CREATE TABLE [jit].[Users](
    [UserId] [int] IDENTITY(1,1) NOT NULL,
    [LoginName] [nvarchar](255) NOT NULL,
    [GivenName] [nvarchar](255) NULL,
    [Surname] [nvarchar](255) NULL,
    [DisplayName] [nvarchar](255) NULL,
    [Email] [nvarchar](255) NULL,
    [Division] [nvarchar](255) NULL,
    [Department] [nvarchar](255) NULL,
    [JobTitle] [nvarchar](255) NULL,
    [SeniorityLevel] [int] NULL,
    [ManagerLoginName] [nvarchar](255) NULL,
    [IsAdmin] [bit] NOT NULL CONSTRAINT [DF_Users_IsAdmin] DEFAULT (0),
    [IsActive] [bit] NOT NULL CONSTRAINT [DF_Users_IsActive] DEFAULT (1),
    [LastAdSyncUtc] [datetime2](7) NULL,
    [CreatedUtc] [datetime2](7) NOT NULL CONSTRAINT [DF_Users_CreatedUtc] DEFAULT (GETUTCDATE()),
    [UpdatedUtc] [datetime2](7) NOT NULL CONSTRAINT [DF_Users_UpdatedUtc] DEFAULT (GETUTCDATE()),
    [CreatedBy] [nvarchar](255) NOT NULL DEFAULT (SUSER_SNAME()),
    [UpdatedBy] [nvarchar](255) NOT NULL DEFAULT (SUSER_SNAME()),
    CONSTRAINT [PK_Users] PRIMARY KEY CLUSTERED ([UserId] ASC)
    WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
)

CREATE UNIQUE NONCLUSTERED INDEX [IX_Users_LoginName] ON [jit].[Users]([LoginName] ASC)
    WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)

CREATE NONCLUSTERED INDEX [IX_Users_IsActive] ON [jit].[Users]([IsActive] ASC)
    WHERE [IsActive] = 1
    WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)

CREATE NONCLUSTERED INDEX [IX_Users_IsAdmin] ON [jit].[Users]([IsAdmin] ASC)
    WHERE [IsAdmin] = 1
    WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)

CREATE NONCLUSTERED INDEX [IX_Users_Division_SeniorityLevel] ON [jit].[Users]([Division] ASC, [SeniorityLevel] ASC)
    WHERE [Division] IS NOT NULL AND [SeniorityLevel] IS NOT NULL
    WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)

GO

