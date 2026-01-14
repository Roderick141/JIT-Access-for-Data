-- =============================================
-- Create jit.Request_Roles Table
-- Junction table for many-to-many relationship between Requests and Roles
-- =============================================

USE [DMAP_JIT_Permissions]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[jit].[Request_Roles]') AND type in (N'U'))
    DROP TABLE [jit].[Request_Roles]
GO

CREATE TABLE [jit].[Request_Roles](
    [RequestId] [bigint] NOT NULL,
    [RoleId] [int] NOT NULL,
    [CreatedUtc] [datetime2](7) NOT NULL CONSTRAINT [DF_Request_Roles_CreatedUtc] DEFAULT (GETUTCDATE()),
    CONSTRAINT [PK_Request_Roles] PRIMARY KEY CLUSTERED ([RequestId] ASC, [RoleId] ASC)
    WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
)

ALTER TABLE [jit].[Request_Roles] WITH CHECK ADD CONSTRAINT [FK_Request_Roles_Requests] 
    FOREIGN KEY([RequestId]) REFERENCES [jit].[Requests] ([RequestId]) ON DELETE CASCADE

ALTER TABLE [jit].[Request_Roles] CHECK CONSTRAINT [FK_Request_Roles_Requests]

ALTER TABLE [jit].[Request_Roles] WITH CHECK ADD CONSTRAINT [FK_Request_Roles_Roles] 
    FOREIGN KEY([RoleId]) REFERENCES [jit].[Roles] ([RoleId])

ALTER TABLE [jit].[Request_Roles] CHECK CONSTRAINT [FK_Request_Roles_Roles]

CREATE NONCLUSTERED INDEX [IX_Request_Roles_RequestId] ON [jit].[Request_Roles]([RequestId] ASC)
    WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)

CREATE NONCLUSTERED INDEX [IX_Request_Roles_RoleId] ON [jit].[Request_Roles]([RoleId] ASC)
    WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)

GO

