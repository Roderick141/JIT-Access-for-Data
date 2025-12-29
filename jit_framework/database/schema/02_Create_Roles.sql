-- =============================================
-- Create jit.Roles Table
-- Business role catalog (requestable roles)
-- =============================================

USE [DMAP_JIT_Permissions]
GO

IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[jit].[Roles]') AND type in (N'U'))
    DROP TABLE [jit].[Roles]
GO

CREATE TABLE [jit].[Roles](
    [RoleId] [int] IDENTITY(1,1) NOT NULL,
    [RoleName] [nvarchar](255) NOT NULL,
    [Description] [nvarchar](max) NULL,
    [MaxDurationMinutes] [int] NOT NULL,
    [RequiresTicket] [bit] NOT NULL CONSTRAINT [DF_Roles_RequiresTicket] DEFAULT (0),
    [TicketRegex] [nvarchar](255) NULL,
    [RequiresJustification] [bit] NOT NULL CONSTRAINT [DF_Roles_RequiresJustification] DEFAULT (1),
    [RequiresApproval] [bit] NOT NULL CONSTRAINT [DF_Roles_RequiresApproval] DEFAULT (1),
    [AutoApproveMinSeniority] [int] NULL,
    [IsEnabled] [bit] NOT NULL CONSTRAINT [DF_Roles_IsEnabled] DEFAULT (1),
    [CreatedUtc] [datetime2](7) NOT NULL CONSTRAINT [DF_Roles_CreatedUtc] DEFAULT (GETUTCDATE()),
    [UpdatedUtc] [datetime2](7) NOT NULL CONSTRAINT [DF_Roles_UpdatedUtc] DEFAULT (GETUTCDATE()),
    [CreatedBy] [nvarchar](255) NOT NULL DEFAULT (SUSER_SNAME()),
    [UpdatedBy] [nvarchar](255) NOT NULL DEFAULT (SUSER_SNAME()),
    CONSTRAINT [PK_Roles] PRIMARY KEY CLUSTERED ([RoleId] ASC)
    WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
)

CREATE UNIQUE NONCLUSTERED INDEX [IX_Roles_RoleName] ON [jit].[Roles]([RoleName] ASC)
    WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)

CREATE NONCLUSTERED INDEX [IX_Roles_IsEnabled] ON [jit].[Roles]([IsEnabled] ASC)
    WHERE [IsEnabled] = 1
    WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)

GO

PRINT 'Table [jit].[Roles] created successfully'
GO

