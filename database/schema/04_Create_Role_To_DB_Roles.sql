-- =============================================
-- Create jit.Role_To_DB_Roles Table
-- Business role to DB role mapping
-- =============================================

USE [DMAP_JIT_Permissions]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[jit].[Role_To_DB_Roles]') AND type in (N'U'))
    DROP TABLE [jit].[Role_To_DB_Roles]
GO

CREATE TABLE [jit].[Role_To_DB_Roles](
    [RoleId] [int] NOT NULL,
    [DbRoleId] [int] NOT NULL,
    [IsRequired] [bit] NOT NULL CONSTRAINT [DF_Role_To_DB_Roles_IsRequired] DEFAULT (1),
    CONSTRAINT [PK_Role_To_DB_Roles] PRIMARY KEY CLUSTERED ([RoleId] ASC, [DbRoleId] ASC)
    WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
)

ALTER TABLE [jit].[Role_To_DB_Roles] WITH CHECK ADD CONSTRAINT [FK_Role_To_DB_Roles_Roles] 
    FOREIGN KEY([RoleId]) REFERENCES [jit].[Roles] ([RoleId])
    ON DELETE CASCADE

ALTER TABLE [jit].[Role_To_DB_Roles] CHECK CONSTRAINT [FK_Role_To_DB_Roles_Roles]

ALTER TABLE [jit].[Role_To_DB_Roles] WITH CHECK ADD CONSTRAINT [FK_Role_To_DB_Roles_DB_Roles] 
    FOREIGN KEY([DbRoleId]) REFERENCES [jit].[DB_Roles] ([DbRoleId])
    ON DELETE CASCADE

ALTER TABLE [jit].[Role_To_DB_Roles] CHECK CONSTRAINT [FK_Role_To_DB_Roles_DB_Roles]

CREATE NONCLUSTERED INDEX [IX_Role_To_DB_Roles_RoleId] ON [jit].[Role_To_DB_Roles]([RoleId] ASC)
    WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)

CREATE NONCLUSTERED INDEX [IX_Role_To_DB_Roles_DbRoleId] ON [jit].[Role_To_DB_Roles]([DbRoleId] ASC)
    WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)

GO

PRINT 'Table [jit].[Role_To_DB_Roles] created successfully'
GO

