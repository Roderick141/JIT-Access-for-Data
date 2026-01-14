-- =============================================
-- Create Fact Tables for Reporting
-- Fact tables (Requests, Grants, Approvals, AuditLog, Request_Roles) - full history
-- Includes dimension surrogate keys for star schema design
-- =============================================

USE [DMAP_JIT_Permissions_Reporting]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- Requests Fact Table (full history)
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[reporting].[Requests]') AND type in (N'U'))
    DROP TABLE [reporting].[Requests]
GO

CREATE TABLE [reporting].[Requests](
    [RequestId] [bigint] NOT NULL,
    [UserId] [nvarchar](255) NOT NULL,
    [UserDimensionKey] [bigint] NULL,
    [RequestedDurationMinutes] [int] NOT NULL,
    [Justification] [nvarchar](max) NULL,
    [TicketRef] [nvarchar](255) NULL,
    [Status] [nvarchar](50) NOT NULL,
    [UserDeptSnapshot] [nvarchar](255) NULL,
    [UserTitleSnapshot] [nvarchar](255) NULL,
    [CreatedUtc] [datetime2](7) NOT NULL,
    [UpdatedUtc] [datetime2](7) NOT NULL,
    [CreatedBy] [nvarchar](255) NOT NULL,
    CONSTRAINT [PK_Requests] PRIMARY KEY CLUSTERED ([RequestId] ASC)
    WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
)
GO

-- Grants Fact Table (full history)
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[reporting].[Grants]') AND type in (N'U'))
    DROP TABLE [reporting].[Grants]
GO

CREATE TABLE [reporting].[Grants](
    [GrantId] [bigint] NOT NULL,
    [RequestId] [bigint] NULL,
    [UserId] [nvarchar](255) NOT NULL,
    [UserDimensionKey] [bigint] NULL,
    [RoleId] [int] NOT NULL,
    [RoleDimensionKey] [bigint] NULL,
    [ValidFromUtc] [datetime2](7) NOT NULL,
    [ValidToUtc] [datetime2](7) NOT NULL,
    [RevokedUtc] [datetime2](7) NULL,
    [RevokeReason] [nvarchar](max) NULL,
    [IssuedByUserId] [nvarchar](255) NULL,
    [Status] [nvarchar](50) NOT NULL,
    CONSTRAINT [PK_Grants] PRIMARY KEY CLUSTERED ([GrantId] ASC)
    WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
)
GO

-- Approvals Fact Table (full history)
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[reporting].[Approvals]') AND type in (N'U'))
    DROP TABLE [reporting].[Approvals]
GO

CREATE TABLE [reporting].[Approvals](
    [ApprovalId] [bigint] NOT NULL,
    [RequestId] [bigint] NOT NULL,
    [ApproverUserId] [nvarchar](255) NULL,
    [ApproverUserDimensionKey] [bigint] NULL,
    [ApproverLoginName] [nvarchar](255) NOT NULL,
    [Decision] [nvarchar](50) NOT NULL,
    [DecisionComment] [nvarchar](max) NULL,
    [DecisionUtc] [datetime2](7) NOT NULL,
    CONSTRAINT [PK_Approvals] PRIMARY KEY CLUSTERED ([ApprovalId] ASC)
    WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
)
GO

-- Request_Roles Junction Table (full history)
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[reporting].[Request_Roles]') AND type in (N'U'))
    DROP TABLE [reporting].[Request_Roles]
GO

CREATE TABLE [reporting].[Request_Roles](
    [RequestId] [bigint] NOT NULL,
    [RoleId] [int] NOT NULL,
    [RoleDimensionKey] [bigint] NULL,
    [CreatedUtc] [datetime2](7) NOT NULL,
    CONSTRAINT [PK_Request_Roles] PRIMARY KEY CLUSTERED ([RequestId] ASC, [RoleId] ASC)
    WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
)
GO

-- AuditLog Fact Table (full history - copy-based, not CDC)
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[reporting].[AuditLog]') AND type in (N'U'))
    DROP TABLE [reporting].[AuditLog]
GO

CREATE TABLE [reporting].[AuditLog](
    [AuditId] [bigint] NOT NULL,
    [EventUtc] [datetime2](7) NOT NULL,
    [EventType] [nvarchar](100) NOT NULL,
    [ActorUserId] [nvarchar](255) NULL,
    [ActorUserDimensionKey] [bigint] NULL,
    [ActorLoginName] [nvarchar](255) NOT NULL,
    [TargetUserId] [nvarchar](255) NULL,
    [TargetUserDimensionKey] [bigint] NULL,
    [RequestId] [bigint] NULL,
    [GrantId] [bigint] NULL,
    [DetailsJson] [nvarchar](max) NULL,
    CONSTRAINT [PK_AuditLog] PRIMARY KEY CLUSTERED ([AuditId] ASC)
    WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
)
GO
