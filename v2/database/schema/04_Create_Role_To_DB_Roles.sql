USE [DMAP_JIT_Permissions]
GO

IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[jit].[Role_To_DB_Roles]') AND type in (N'U'))
    DROP TABLE [jit].[Role_To_DB_Roles]
GO

CREATE TABLE [jit].[Role_To_DB_Roles](
    [RoleDbRoleVersionId] [bigint] IDENTITY(1,1) NOT NULL,
    [RoleId] [int] NOT NULL,
    [DbRoleId] [int] NOT NULL,
    [IsRequired] [bit] NOT NULL CONSTRAINT [DF_Role_To_DB_Roles_IsRequired] DEFAULT (1),
    [IsActive] [bit] NOT NULL CONSTRAINT [DF_Role_To_DB_Roles_IsActive] DEFAULT (1),
    [ValidFromUtc] [datetime2](7) NOT NULL CONSTRAINT [DF_Role_To_DB_Roles_ValidFromUtc] DEFAULT (GETUTCDATE()),
    [ValidToUtc] [datetime2](7) NULL,
    CONSTRAINT [PK_Role_To_DB_Roles] PRIMARY KEY CLUSTERED ([RoleDbRoleVersionId] ASC)
)
GO

ALTER TABLE [jit].[Role_To_DB_Roles] WITH CHECK ADD CONSTRAINT [FK_Role_To_DB_Roles_DB_Roles]
    FOREIGN KEY([DbRoleId]) REFERENCES [jit].[DB_Roles] ([DbRoleId]);
GO

CREATE INDEX [IX_Role_To_DB_Roles_RoleId_Active] ON [jit].[Role_To_DB_Roles]([RoleId], [IsActive]);
CREATE INDEX [IX_Role_To_DB_Roles_DbRoleId_Active] ON [jit].[Role_To_DB_Roles]([DbRoleId], [IsActive]);
GO

