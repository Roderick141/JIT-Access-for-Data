-- =============================================
-- Create jit.Role_Approvers Table
-- Approval routing configuration
-- =============================================

USE [DMAP_JIT_Permissions]
GO

IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[jit].[Role_Approvers]') AND type in (N'U'))
    DROP TABLE [jit].[Role_Approvers]
GO

CREATE TABLE [jit].[Role_Approvers](
    [RoleId] [int] NOT NULL,
    [ApproverUserId] [int] NULL,
    [ApproverLoginName] [nvarchar](255) NULL,
    [ApproverType] [nvarchar](50) NOT NULL,
    [Priority] [int] NOT NULL,
    CONSTRAINT [PK_Role_Approvers] PRIMARY KEY CLUSTERED ([RoleId] ASC, [ApproverUserId] ASC, [ApproverType] ASC, [Priority] ASC)
    WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
)

ALTER TABLE [jit].[Role_Approvers] WITH CHECK ADD CONSTRAINT [FK_Role_Approvers_Roles] 
    FOREIGN KEY([RoleId]) REFERENCES [jit].[Roles] ([RoleId])
    ON DELETE CASCADE

ALTER TABLE [jit].[Role_Approvers] CHECK CONSTRAINT [FK_Role_Approvers_Roles]

ALTER TABLE [jit].[Role_Approvers] WITH CHECK ADD CONSTRAINT [FK_Role_Approvers_Users] 
    FOREIGN KEY([ApproverUserId]) REFERENCES [jit].[Users] ([UserId])
    ON DELETE CASCADE

ALTER TABLE [jit].[Role_Approvers] CHECK CONSTRAINT [FK_Role_Approvers_Users]

CREATE NONCLUSTERED INDEX [IX_Role_Approvers_RoleId_Priority] ON [jit].[Role_Approvers]([RoleId] ASC, [Priority] ASC)
    WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)

GO

PRINT 'Table [jit].[Role_Approvers] created successfully'
GO

