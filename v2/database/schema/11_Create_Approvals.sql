-- =============================================
-- Create jit.Approvals Table
-- Approval decisions
-- =============================================

USE [DMAP_JIT_Permissions]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[jit].[Approvals]') AND type in (N'U'))
    DROP TABLE [jit].[Approvals]
GO

CREATE TABLE [jit].[Approvals](
    [ApprovalId] [bigint] IDENTITY(1,1) NOT NULL,
    [RequestId] [bigint] NOT NULL,
    [ApproverUserId] [nvarchar](255) NULL,
    [ApproverUserContextVersionId] [bigint] NULL,
    [ApproverLoginName] [nvarchar](255) NOT NULL,
    [Decision] [nvarchar](50) NOT NULL,
    [DecisionComment] [nvarchar](max) NULL,
    [DecisionUtc] [datetime2](7) NOT NULL CONSTRAINT [DF_Approvals_DecisionUtc] DEFAULT (GETUTCDATE()),
    CONSTRAINT [PK_Approvals] PRIMARY KEY CLUSTERED ([ApprovalId] ASC)
    WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
)

ALTER TABLE [jit].[Approvals] WITH CHECK ADD CONSTRAINT [FK_Approvals_Requests] 
    FOREIGN KEY([RequestId]) REFERENCES [jit].[Requests] ([RequestId])
    ON DELETE CASCADE

ALTER TABLE [jit].[Approvals] CHECK CONSTRAINT [FK_Approvals_Requests]

ALTER TABLE [jit].[Approvals] WITH CHECK ADD CONSTRAINT [FK_Approvals_Users] 
    FOREIGN KEY([ApproverUserId]) REFERENCES [jit].[Users] ([UserId])

ALTER TABLE [jit].[Approvals] CHECK CONSTRAINT [FK_Approvals_Users]

ALTER TABLE [jit].[Approvals] WITH CHECK ADD CONSTRAINT [FK_Approvals_UserContextVersions]
    FOREIGN KEY([ApproverUserContextVersionId]) REFERENCES [jit].[User_Context_Versions] ([UserContextVersionId])

ALTER TABLE [jit].[Approvals] CHECK CONSTRAINT [FK_Approvals_UserContextVersions]

CREATE NONCLUSTERED INDEX [IX_Approvals_RequestId] ON [jit].[Approvals]([RequestId] ASC)
    WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)

CREATE NONCLUSTERED INDEX [IX_Approvals_ApproverUserId] ON [jit].[Approvals]([ApproverUserId] ASC)
    WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)

CREATE NONCLUSTERED INDEX [IX_Approvals_ApproverUserContextVersionId] ON [jit].[Approvals]([ApproverUserContextVersionId] ASC)
    WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)

GO

