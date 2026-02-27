USE [DMAP_JIT_Permissions]
GO

IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[jit].[Role_Eligibility_Rules]') AND type in (N'U'))
    DROP TABLE [jit].[Role_Eligibility_Rules]
GO

CREATE TABLE [jit].[Role_Eligibility_Rules](
    [EligibilityRuleVersionId] [bigint] IDENTITY(1,1) NOT NULL,
    [EligibilityRuleId] [int] NOT NULL,
    [RoleId] [int] NOT NULL,
    [ScopeType] [nvarchar](50) NOT NULL,
    [ScopeValue] [nvarchar](255) NULL,
    [CanRequest] [bit] NOT NULL CONSTRAINT [DF_Role_Eligibility_Rules_CanRequest] DEFAULT (1),
    [Priority] [int] NOT NULL CONSTRAINT [DF_Role_Eligibility_Rules_Priority] DEFAULT (0),
    [MaxDurationMinutes] [int] NOT NULL CONSTRAINT [DF_Role_Eligibility_Rules_MaxDurationMinutes] DEFAULT (1440),
    [RequiresJustification] [bit] NOT NULL CONSTRAINT [DF_Role_Eligibility_Rules_RequiresJustification] DEFAULT (1),
    [RequiresApproval] [bit] NOT NULL CONSTRAINT [DF_Role_Eligibility_Rules_RequiresApproval] DEFAULT (1),
    [IsActive] [bit] NOT NULL CONSTRAINT [DF_Role_Eligibility_Rules_IsActive] DEFAULT (1),
    [ValidFromUtc] [datetime2](7) NOT NULL CONSTRAINT [DF_Role_Eligibility_Rules_ValidFromUtc] DEFAULT (GETUTCDATE()),
    [ValidToUtc] [datetime2](7) NULL,
    [CreatedUtc] [datetime2](7) NOT NULL CONSTRAINT [DF_Role_Eligibility_Rules_CreatedUtc] DEFAULT (GETUTCDATE()),
    [UpdatedUtc] [datetime2](7) NOT NULL CONSTRAINT [DF_Role_Eligibility_Rules_UpdatedUtc] DEFAULT (GETUTCDATE()),
    [CreatedBy] [nvarchar](255) NOT NULL DEFAULT (SUSER_SNAME()),
    [UpdatedBy] [nvarchar](255) NOT NULL DEFAULT (SUSER_SNAME()),
    CONSTRAINT [PK_Role_Eligibility_Rules] PRIMARY KEY CLUSTERED ([EligibilityRuleVersionId] ASC)
)
GO

CREATE INDEX [IX_Role_Eligibility_Rules_RoleId_Active] ON [jit].[Role_Eligibility_Rules]([RoleId], [IsActive], [ScopeType], [ScopeValue]);
GO

