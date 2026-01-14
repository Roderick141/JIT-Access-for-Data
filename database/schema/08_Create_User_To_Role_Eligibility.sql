-- =============================================
-- Create jit.User_To_Role_Eligibility Table
-- Explicit per-user overrides (takes precedence over scope rules)
-- =============================================

USE [DMAP_JIT_Permissions]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[jit].[User_To_Role_Eligibility]') AND type in (N'U'))
    DROP TABLE [jit].[User_To_Role_Eligibility]
GO

CREATE TABLE [jit].[User_To_Role_Eligibility](
    [UserId] [int] NOT NULL,
    [RoleId] [int] NOT NULL,
    [CanRequest] [bit] NOT NULL,
    [ValidFromUtc] [datetime2](7) NULL,
    [ValidToUtc] [datetime2](7) NULL,
    [Priority] [int] NOT NULL CONSTRAINT [DF_User_To_Role_Eligibility_Priority] DEFAULT (999),
    CONSTRAINT [PK_User_To_Role_Eligibility] PRIMARY KEY CLUSTERED ([UserId] ASC, [RoleId] ASC)
    WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
)

ALTER TABLE [jit].[User_To_Role_Eligibility] WITH CHECK ADD CONSTRAINT [FK_User_To_Role_Eligibility_Users] 
    FOREIGN KEY([UserId]) REFERENCES [jit].[Users] ([UserId])
    ON DELETE CASCADE

ALTER TABLE [jit].[User_To_Role_Eligibility] CHECK CONSTRAINT [FK_User_To_Role_Eligibility_Users]

ALTER TABLE [jit].[User_To_Role_Eligibility] WITH CHECK ADD CONSTRAINT [FK_User_To_Role_Eligibility_Roles] 
    FOREIGN KEY([RoleId]) REFERENCES [jit].[Roles] ([RoleId])
    ON DELETE CASCADE

ALTER TABLE [jit].[User_To_Role_Eligibility] CHECK CONSTRAINT [FK_User_To_Role_Eligibility_Roles]

CREATE NONCLUSTERED INDEX [IX_User_To_Role_Eligibility_UserId] ON [jit].[User_To_Role_Eligibility]([UserId] ASC)
    WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)

CREATE NONCLUSTERED INDEX [IX_User_To_Role_Eligibility_RoleId] ON [jit].[User_To_Role_Eligibility]([RoleId] ASC)
    WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)

GO

