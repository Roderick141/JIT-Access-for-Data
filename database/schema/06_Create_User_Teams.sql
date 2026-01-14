-- =============================================
-- Create jit.User_Teams Table
-- User-to-Team membership (many-to-many)
-- =============================================

USE [DMAP_JIT_Permissions]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[jit].[User_Teams]') AND type in (N'U'))
    DROP TABLE [jit].[User_Teams]
GO

CREATE TABLE [jit].[User_Teams](
    [UserId] [int] NOT NULL,
    [TeamId] [int] NOT NULL,
    [IsActive] [bit] NOT NULL CONSTRAINT [DF_User_Teams_IsActive] DEFAULT (1),
    [AssignedUtc] [datetime2](7) NOT NULL CONSTRAINT [DF_User_Teams_AssignedUtc] DEFAULT (GETUTCDATE()),
    [RemovedUtc] [datetime2](7) NULL,
    CONSTRAINT [PK_User_Teams] PRIMARY KEY CLUSTERED ([UserId] ASC, [TeamId] ASC)
    WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
)

ALTER TABLE [jit].[User_Teams] WITH CHECK ADD CONSTRAINT [FK_User_Teams_Users] 
    FOREIGN KEY([UserId]) REFERENCES [jit].[Users] ([UserId])
    ON DELETE CASCADE

ALTER TABLE [jit].[User_Teams] CHECK CONSTRAINT [FK_User_Teams_Users]

ALTER TABLE [jit].[User_Teams] WITH CHECK ADD CONSTRAINT [FK_User_Teams_Teams] 
    FOREIGN KEY([TeamId]) REFERENCES [jit].[Teams] ([TeamId])
    ON DELETE CASCADE

ALTER TABLE [jit].[User_Teams] CHECK CONSTRAINT [FK_User_Teams_Teams]

CREATE NONCLUSTERED INDEX [IX_User_Teams_TeamId_IsActive] ON [jit].[User_Teams]([TeamId] ASC, [IsActive] ASC)
    WHERE [IsActive] = 1
    WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)

CREATE NONCLUSTERED INDEX [IX_User_Teams_UserId] ON [jit].[User_Teams]([UserId] ASC)
    WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)

GO

