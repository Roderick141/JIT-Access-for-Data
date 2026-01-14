-- =============================================
-- Create jit.Grants Table
-- Active and historical access grants
-- =============================================

USE [DMAP_JIT_Permissions]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[jit].[Grants]') AND type in (N'U'))
    DROP TABLE [jit].[Grants]
GO

CREATE TABLE [jit].[Grants](
    [GrantId] [bigint] IDENTITY(1,1) NOT NULL,
    [RequestId] [bigint] NULL,
    [UserId] [nvarchar](255) NOT NULL,
    [RoleId] [int] NOT NULL,
    [ValidFromUtc] [datetime2](7) NOT NULL,
    [ValidToUtc] [datetime2](7) NOT NULL,
    [RevokedUtc] [datetime2](7) NULL,
    [RevokeReason] [nvarchar](max) NULL,
    [IssuedByUserId] [nvarchar](255) NULL,
    [Status] [nvarchar](50) NOT NULL,
    CONSTRAINT [PK_Grants] PRIMARY KEY CLUSTERED ([GrantId] ASC)
    WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
)

ALTER TABLE [jit].[Grants] WITH CHECK ADD CONSTRAINT [FK_Grants_Requests] 
    FOREIGN KEY([RequestId]) REFERENCES [jit].[Requests] ([RequestId])

ALTER TABLE [jit].[Grants] CHECK CONSTRAINT [FK_Grants_Requests]

ALTER TABLE [jit].[Grants] WITH CHECK ADD CONSTRAINT [FK_Grants_Users] 
    FOREIGN KEY([UserId]) REFERENCES [jit].[Users] ([UserId])

ALTER TABLE [jit].[Grants] CHECK CONSTRAINT [FK_Grants_Users]

ALTER TABLE [jit].[Grants] WITH CHECK ADD CONSTRAINT [FK_Grants_Roles] 
    FOREIGN KEY([RoleId]) REFERENCES [jit].[Roles] ([RoleId])

ALTER TABLE [jit].[Grants] CHECK CONSTRAINT [FK_Grants_Roles]

ALTER TABLE [jit].[Grants] WITH CHECK ADD CONSTRAINT [FK_Grants_IssuedByUsers] 
    FOREIGN KEY([IssuedByUserId]) REFERENCES [jit].[Users] ([UserId])

ALTER TABLE [jit].[Grants] CHECK CONSTRAINT [FK_Grants_IssuedByUsers]

CREATE NONCLUSTERED INDEX [IX_Grants_UserId_RoleId_Status_ValidToUtc] ON [jit].[Grants]([UserId] ASC, [RoleId] ASC, [Status] ASC, [ValidToUtc] ASC)
    WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)

CREATE NONCLUSTERED INDEX [IX_Grants_Status_ValidToUtc] ON [jit].[Grants]([Status] ASC, [ValidToUtc] ASC)
    WHERE [Status] = 'Active'
    WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)

CREATE NONCLUSTERED INDEX [IX_Grants_RequestId] ON [jit].[Grants]([RequestId] ASC)
    WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)

GO

