-- =============================================
-- Create jit.Requests Table
-- Access requests
-- =============================================

USE [DMAP_JIT_Permissions]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[jit].[Requests]') AND type in (N'U'))
    DROP TABLE [jit].[Requests]
GO

CREATE TABLE [jit].[Requests](
    [RequestId] [bigint] IDENTITY(1,1) NOT NULL,
    [UserId] [nvarchar](255) NOT NULL,
    [RequestedDurationMinutes] [int] NOT NULL,
    [Justification] [nvarchar](max) NULL,
    [TicketRef] [nvarchar](255) NULL,
    [Status] [nvarchar](50) NOT NULL,
    [UserDeptSnapshot] [nvarchar](255) NULL,
    [UserTitleSnapshot] [nvarchar](255) NULL,
    [EligibilitySnapshotJson] [nvarchar](max) NULL,
    [CreatedUtc] [datetime2](7) NOT NULL CONSTRAINT [DF_Requests_CreatedUtc] DEFAULT (GETUTCDATE()),
    [UpdatedUtc] [datetime2](7) NOT NULL CONSTRAINT [DF_Requests_UpdatedUtc] DEFAULT (GETUTCDATE()),
    [CreatedBy] [nvarchar](255) NOT NULL DEFAULT (SUSER_SNAME()),
    CONSTRAINT [PK_Requests] PRIMARY KEY CLUSTERED ([RequestId] ASC)
    WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
)

ALTER TABLE [jit].[Requests] WITH CHECK ADD CONSTRAINT [FK_Requests_Users] 
    FOREIGN KEY([UserId]) REFERENCES [jit].[Users] ([UserId])

ALTER TABLE [jit].[Requests] CHECK CONSTRAINT [FK_Requests_Users]

CREATE NONCLUSTERED INDEX [IX_Requests_UserId] ON [jit].[Requests]([UserId] ASC)
    WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)

CREATE NONCLUSTERED INDEX [IX_Requests_Status] ON [jit].[Requests]([Status] ASC)
    WHERE [Status] IN ('Pending', 'AutoApproved')
    WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)

GO

