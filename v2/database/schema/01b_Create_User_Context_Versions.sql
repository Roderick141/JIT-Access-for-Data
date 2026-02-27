-- =============================================
-- Create jit.User_Context_Versions Table (SCD Type 2)
-- Tracks mutable AD / authorization context over time
-- =============================================

USE [DMAP_JIT_Permissions]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[jit].[User_Context_Versions]') AND type in (N'U'))
    DROP TABLE [jit].[User_Context_Versions]
GO

CREATE TABLE [jit].[User_Context_Versions](
    [UserContextVersionId] [bigint] IDENTITY(1,1) NOT NULL,
    [UserId] [nvarchar](255) NOT NULL,
    [Division] [nvarchar](255) NULL,
    [Department] [nvarchar](255) NULL,
    [JobTitle] [nvarchar](255) NULL,
    [SeniorityLevel] [int] NULL,
    [IsAdmin] [bit] NOT NULL CONSTRAINT [DF_UserContext_IsAdmin] DEFAULT (0),
    [IsApprover] [bit] NOT NULL CONSTRAINT [DF_UserContext_IsApprover] DEFAULT (0),
    [IsDataSteward] [bit] NOT NULL CONSTRAINT [DF_UserContext_IsDataSteward] DEFAULT (0),
    [IsEnabled] [bit] NOT NULL CONSTRAINT [DF_UserContext_IsEnabled] DEFAULT (1),
    [IsActive] [bit] NOT NULL CONSTRAINT [DF_UserContext_IsActive] DEFAULT (1),
    [LastAdSyncUtc] [datetime2](7) NULL,
    [ValidFromUtc] [datetime2](7) NOT NULL CONSTRAINT [DF_UserContext_ValidFromUtc] DEFAULT (GETUTCDATE()),
    [ValidToUtc] [datetime2](7) NULL,
    [CreatedUtc] [datetime2](7) NOT NULL CONSTRAINT [DF_UserContext_CreatedUtc] DEFAULT (GETUTCDATE()),
    [UpdatedUtc] [datetime2](7) NOT NULL CONSTRAINT [DF_UserContext_UpdatedUtc] DEFAULT (GETUTCDATE()),
    [CreatedBy] [nvarchar](255) NOT NULL DEFAULT (SUSER_SNAME()),
    [UpdatedBy] [nvarchar](255) NOT NULL DEFAULT (SUSER_SNAME()),
    CONSTRAINT [PK_User_Context_Versions] PRIMARY KEY CLUSTERED ([UserContextVersionId] ASC)
)

ALTER TABLE [jit].[User_Context_Versions] WITH CHECK ADD CONSTRAINT [FK_UserContext_Users]
    FOREIGN KEY([UserId]) REFERENCES [jit].[Users] ([UserId])

ALTER TABLE [jit].[User_Context_Versions] CHECK CONSTRAINT [FK_UserContext_Users]

ALTER TABLE [jit].[User_Context_Versions]
    ADD CONSTRAINT [CK_UserContext_Validity]
    CHECK ([ValidToUtc] IS NULL OR [ValidToUtc] >= [ValidFromUtc]);

CREATE UNIQUE NONCLUSTERED INDEX [UX_UserContext_UserId_Active]
    ON [jit].[User_Context_Versions]([UserId])
    WHERE [IsActive] = 1;

CREATE NONCLUSTERED INDEX [IX_UserContext_UserId_ValidFrom_ValidTo]
    ON [jit].[User_Context_Versions]([UserId], [ValidFromUtc], [ValidToUtc]);

CREATE NONCLUSTERED INDEX [IX_UserContext_IsEnabled_Active]
    ON [jit].[User_Context_Versions]([IsEnabled], [IsActive])
    WHERE [IsActive] = 1;

GO
