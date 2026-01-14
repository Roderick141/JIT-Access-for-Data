-- =============================================
-- Create Dimension Tables for Reporting
-- Dimension tables (Users, Roles) - SCD Type 2 (Slowly Changing Dimensions)
-- =============================================

USE [DMAP_JIT_Permissions_Reporting]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- Users Dimension (SCD Type 2 - tracks history)
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[reporting].[Users]') AND type in (N'U'))
    DROP TABLE [reporting].[Users]
GO

CREATE TABLE [reporting].[Users](
    [UserDimensionKey] [bigint] IDENTITY(1,1) NOT NULL,
    [UserId] [nvarchar](255) NOT NULL,
    [LoginName] [nvarchar](255) NOT NULL,
    [GivenName] [nvarchar](255) NULL,
    [Surname] [nvarchar](255) NULL,
    [DisplayName] [nvarchar](255) NULL,
    [Email] [nvarchar](255) NULL,
    [Division] [nvarchar](255) NULL,
    [Department] [nvarchar](255) NULL,
    [JobTitle] [nvarchar](255) NULL,
    [SeniorityLevel] [int] NULL,
    [IsAdmin] [bit] NOT NULL,
    [IsApprover] [bit] NOT NULL,
    [IsDataSteward] [bit] NOT NULL,
    [IsActive] [bit] NOT NULL,
    [LastAdSyncUtc] [datetime2](7) NULL,
    [CreatedUtc] [datetime2](7) NOT NULL,
    [UpdatedUtc] [datetime2](7) NOT NULL,
    [CreatedBy] [nvarchar](255) NOT NULL,
    [UpdatedBy] [nvarchar](255) NOT NULL,
    [StartDate] [datetime2](7) NOT NULL,
    [EndDate] [datetime2](7) NULL,
    [IsCurrent] [bit] NOT NULL CONSTRAINT [DF_Users_IsCurrent] DEFAULT (1),
    CONSTRAINT [PK_Users] PRIMARY KEY CLUSTERED ([UserDimensionKey] ASC)
    WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
)
GO

CREATE NONCLUSTERED INDEX [IX_Users_LoginName] ON [reporting].[Users]([LoginName] ASC)
    WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
GO

CREATE NONCLUSTERED INDEX [IX_Users_Division_Department] ON [reporting].[Users]([Division] ASC, [Department] ASC)
    WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
GO

-- Roles Dimension (SCD Type 2 - tracks history)
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[reporting].[Roles]') AND type in (N'U'))
    DROP TABLE [reporting].[Roles]
GO

CREATE TABLE [reporting].[Roles](
    [RoleDimensionKey] [bigint] IDENTITY(1,1) NOT NULL,
    [RoleId] [int] NOT NULL,
    [RoleName] [nvarchar](255) NOT NULL,
    [Description] [nvarchar](max) NULL,
    [MaxDurationMinutes] [int] NOT NULL,
    [RequiresTicket] [bit] NOT NULL,
    [TicketRegex] [nvarchar](255) NULL,
    [RequiresJustification] [bit] NOT NULL,
    [RequiresApproval] [bit] NOT NULL,
    [AutoApproveMinSeniority] [int] NULL,
    [IsEnabled] [bit] NOT NULL,
    [CreatedUtc] [datetime2](7) NOT NULL,
    [UpdatedUtc] [datetime2](7) NOT NULL,
    [CreatedBy] [nvarchar](255) NOT NULL,
    [UpdatedBy] [nvarchar](255) NOT NULL,
    [StartDate] [datetime2](7) NOT NULL,
    [EndDate] [datetime2](7) NULL,
    [IsCurrent] [bit] NOT NULL CONSTRAINT [DF_Roles_IsCurrent] DEFAULT (1),
    CONSTRAINT [PK_Roles] PRIMARY KEY CLUSTERED ([RoleDimensionKey] ASC)
    WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
)
GO

CREATE NONCLUSTERED INDEX [IX_Roles_RoleName] ON [reporting].[Roles]([RoleName] ASC)
    WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
GO
