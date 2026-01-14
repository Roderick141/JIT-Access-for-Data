-- =============================================
-- Create jit.Role_Eligibility_Rules Table
-- Multi-scope eligibility rules
-- =============================================

USE [DMAP_JIT_Permissions]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[jit].[Role_Eligibility_Rules]') AND type in (N'U'))
    DROP TABLE [jit].[Role_Eligibility_Rules]
GO

CREATE TABLE [jit].[Role_Eligibility_Rules](
    [EligibilityRuleId] [int] IDENTITY(1,1) NOT NULL,
    [RoleId] [int] NOT NULL,
    [ScopeType] [nvarchar](50) NOT NULL,
    [ScopeValue] [nvarchar](255) NULL,
    [CanRequest] [bit] NOT NULL CONSTRAINT [DF_Role_Eligibility_Rules_CanRequest] DEFAULT (1),
    [ValidFromUtc] [datetime2](7) NULL,
    [ValidToUtc] [datetime2](7) NULL,
    [Priority] [int] NOT NULL CONSTRAINT [DF_Role_Eligibility_Rules_Priority] DEFAULT (0),
    [CreatedUtc] [datetime2](7) NOT NULL CONSTRAINT [DF_Role_Eligibility_Rules_CreatedUtc] DEFAULT (GETUTCDATE()),
    [UpdatedUtc] [datetime2](7) NOT NULL CONSTRAINT [DF_Role_Eligibility_Rules_UpdatedUtc] DEFAULT (GETUTCDATE()),
    [CreatedBy] [nvarchar](255) NOT NULL DEFAULT (SUSER_SNAME()),
    [UpdatedBy] [nvarchar](255) NOT NULL DEFAULT (SUSER_SNAME()),
    CONSTRAINT [PK_Role_Eligibility_Rules] PRIMARY KEY CLUSTERED ([EligibilityRuleId] ASC)
    WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
)

ALTER TABLE [jit].[Role_Eligibility_Rules] WITH CHECK ADD CONSTRAINT [FK_Role_Eligibility_Rules_Roles] 
    FOREIGN KEY([RoleId]) REFERENCES [jit].[Roles] ([RoleId])
    ON DELETE CASCADE

ALTER TABLE [jit].[Role_Eligibility_Rules] CHECK CONSTRAINT [FK_Role_Eligibility_Rules_Roles]

CREATE NONCLUSTERED INDEX [IX_Role_Eligibility_Rules_RoleId] ON [jit].[Role_Eligibility_Rules]([RoleId] ASC, [ScopeType] ASC, [ScopeValue] ASC)
    WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)

CREATE NONCLUSTERED INDEX [IX_Role_Eligibility_Rules_Priority] ON [jit].[Role_Eligibility_Rules]([RoleId] ASC, [Priority] DESC)
    WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)

GO

