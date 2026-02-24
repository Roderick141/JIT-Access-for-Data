USE [DMAP_JIT_Permissions]
GO

IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[jit].[Roles]') AND type in (N'U'))
    DROP TABLE [jit].[Roles]
GO

CREATE TABLE [jit].[Roles](
    [RoleVersionId] [bigint] IDENTITY(1,1) NOT NULL,
    [RoleId] [int] NOT NULL,
    [RoleName] [nvarchar](255) NOT NULL,
    [Description] [nvarchar](max) NULL,
    [SensitivityLevel] [nvarchar](50) NOT NULL CONSTRAINT [DF_Roles_SensitivityLevel] DEFAULT ('Standard'),
    [IconName] [nvarchar](100) NOT NULL CONSTRAINT [DF_Roles_IconName] DEFAULT ('Database'),
    [IconColor] [nvarchar](100) NOT NULL CONSTRAINT [DF_Roles_IconColor] DEFAULT ('bg-blue-500'),
    [IsEnabled] [bit] NOT NULL CONSTRAINT [DF_Roles_IsEnabled] DEFAULT (1),
    [IsActive] [bit] NOT NULL CONSTRAINT [DF_Roles_IsActive] DEFAULT (1),
    [ValidFromUtc] [datetime2](7) NOT NULL CONSTRAINT [DF_Roles_ValidFromUtc] DEFAULT (GETUTCDATE()),
    [ValidToUtc] [datetime2](7) NULL,
    [CreatedUtc] [datetime2](7) NOT NULL CONSTRAINT [DF_Roles_CreatedUtc] DEFAULT (GETUTCDATE()),
    [UpdatedUtc] [datetime2](7) NOT NULL CONSTRAINT [DF_Roles_UpdatedUtc] DEFAULT (GETUTCDATE()),
    [CreatedBy] [nvarchar](255) NOT NULL DEFAULT (SUSER_SNAME()),
    [UpdatedBy] [nvarchar](255) NOT NULL DEFAULT (SUSER_SNAME()),
    CONSTRAINT [PK_Roles] PRIMARY KEY CLUSTERED ([RoleVersionId] ASC)
)
GO

CREATE INDEX [IX_Roles_RoleId_IsActive] ON [jit].[Roles]([RoleId], [IsActive]);
CREATE INDEX [IX_Roles_RoleName_IsActive] ON [jit].[Roles]([RoleName], [IsActive]);
CREATE INDEX [IX_Roles_ValidFrom_ValidTo] ON [jit].[Roles]([ValidFromUtc], [ValidToUtc]);
GO

