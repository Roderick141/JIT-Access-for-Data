-- =============================================
-- Create jit.Grant_DBRole_Assignments Table
-- Actual DB role membership operations
-- =============================================

USE [DMAP_JIT_Permissions]
GO

IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[jit].[Grant_DBRole_Assignments]') AND type in (N'U'))
    DROP TABLE [jit].[Grant_DBRole_Assignments]
GO

CREATE TABLE [jit].[Grant_DBRole_Assignments](
    [GrantId] [bigint] NOT NULL,
    [DbRoleId] [int] NOT NULL,
    [AddAttemptUtc] [datetime2](7) NULL,
    [AddSucceeded] [bit] NULL,
    [AddError] [nvarchar](max) NULL,
    [DropAttemptUtc] [datetime2](7) NULL,
    [DropSucceeded] [bit] NULL,
    [DropError] [nvarchar](max) NULL,
    CONSTRAINT [PK_Grant_DBRole_Assignments] PRIMARY KEY CLUSTERED ([GrantId] ASC, [DbRoleId] ASC)
    WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
)

ALTER TABLE [jit].[Grant_DBRole_Assignments] WITH CHECK ADD CONSTRAINT [FK_Grant_DBRole_Assignments_Grants] 
    FOREIGN KEY([GrantId]) REFERENCES [jit].[Grants] ([GrantId])
    ON DELETE CASCADE

ALTER TABLE [jit].[Grant_DBRole_Assignments] CHECK CONSTRAINT [FK_Grant_DBRole_Assignments_Grants]

ALTER TABLE [jit].[Grant_DBRole_Assignments] WITH CHECK ADD CONSTRAINT [FK_Grant_DBRole_Assignments_DB_Roles] 
    FOREIGN KEY([DbRoleId]) REFERENCES [jit].[DB_Roles] ([DbRoleId])
    ON DELETE CASCADE

ALTER TABLE [jit].[Grant_DBRole_Assignments] CHECK CONSTRAINT [FK_Grant_DBRole_Assignments_DB_Roles]

CREATE NONCLUSTERED INDEX [IX_Grant_DBRole_Assignments_GrantId] ON [jit].[Grant_DBRole_Assignments]([GrantId] ASC)
    WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)

GO

PRINT 'Table [jit].[Grant_DBRole_Assignments] created successfully'
GO

