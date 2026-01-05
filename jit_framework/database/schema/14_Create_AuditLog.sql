-- =============================================
-- Create jit.AuditLog Table
-- Comprehensive audit trail
-- =============================================

USE [DMAP_JIT_Permissions]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[jit].[AuditLog]') AND type in (N'U'))
    DROP TABLE [jit].[AuditLog]
GO

CREATE TABLE [jit].[AuditLog](
    [AuditId] [bigint] IDENTITY(1,1) NOT NULL,
    [EventUtc] [datetime2](7) NOT NULL CONSTRAINT [DF_AuditLog_EventUtc] DEFAULT (GETUTCDATE()),
    [EventType] [nvarchar](100) NOT NULL,
    [ActorUserId] [int] NULL,
    [ActorLoginName] [nvarchar](255) NOT NULL,
    [TargetUserId] [int] NULL,
    [RequestId] [bigint] NULL,
    [GrantId] [bigint] NULL,
    [DetailsJson] [nvarchar](max) NULL,
    CONSTRAINT [PK_AuditLog] PRIMARY KEY CLUSTERED ([AuditId] ASC)
    WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
)

ALTER TABLE [jit].[AuditLog] WITH CHECK ADD CONSTRAINT [FK_AuditLog_ActorUsers] 
    FOREIGN KEY([ActorUserId]) REFERENCES [jit].[Users] ([UserId])

ALTER TABLE [jit].[AuditLog] CHECK CONSTRAINT [FK_AuditLog_ActorUsers]

ALTER TABLE [jit].[AuditLog] WITH CHECK ADD CONSTRAINT [FK_AuditLog_TargetUsers] 
    FOREIGN KEY([TargetUserId]) REFERENCES [jit].[Users] ([UserId])

ALTER TABLE [jit].[AuditLog] CHECK CONSTRAINT [FK_AuditLog_TargetUsers]

ALTER TABLE [jit].[AuditLog] WITH CHECK ADD CONSTRAINT [FK_AuditLog_Requests] 
    FOREIGN KEY([RequestId]) REFERENCES [jit].[Requests] ([RequestId])

ALTER TABLE [jit].[AuditLog] CHECK CONSTRAINT [FK_AuditLog_Requests]

ALTER TABLE [jit].[AuditLog] WITH CHECK ADD CONSTRAINT [FK_AuditLog_Grants] 
    FOREIGN KEY([GrantId]) REFERENCES [jit].[Grants] ([GrantId])

ALTER TABLE [jit].[AuditLog] CHECK CONSTRAINT [FK_AuditLog_Grants]

CREATE NONCLUSTERED INDEX [IX_AuditLog_EventUtc_EventType_ActorLoginName] ON [jit].[AuditLog]([EventUtc] DESC, [EventType] ASC, [ActorLoginName] ASC)
    WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)

CREATE NONCLUSTERED INDEX [IX_AuditLog_TargetUserId] ON [jit].[AuditLog]([TargetUserId] ASC)
    WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)

CREATE NONCLUSTERED INDEX [IX_AuditLog_RequestId] ON [jit].[AuditLog]([RequestId] ASC)
    WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)

CREATE NONCLUSTERED INDEX [IX_AuditLog_GrantId] ON [jit].[AuditLog]([GrantId] ASC)
    WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)

GO

PRINT 'Table [jit].[AuditLog] created successfully'
GO

