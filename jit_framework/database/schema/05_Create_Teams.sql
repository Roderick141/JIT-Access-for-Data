-- =============================================
-- Create jit.Teams Table
-- Team metadata table
-- =============================================

USE [DMAP_JIT_Permissions]
GO

IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[jit].[Teams]') AND type in (N'U'))
    DROP TABLE [jit].[Teams]
GO

CREATE TABLE [jit].[Teams](
    [TeamId] [int] IDENTITY(1,1) NOT NULL,
    [TeamName] [nvarchar](255) NOT NULL,
    [Description] [nvarchar](max) NULL,
    [Division] [nvarchar](255) NULL,
    [Department] [nvarchar](255) NULL,
    [IsActive] [bit] NOT NULL CONSTRAINT [DF_Teams_IsActive] DEFAULT (1),
    [CreatedUtc] [datetime2](7) NOT NULL CONSTRAINT [DF_Teams_CreatedUtc] DEFAULT (GETUTCDATE()),
    [UpdatedUtc] [datetime2](7) NOT NULL CONSTRAINT [DF_Teams_UpdatedUtc] DEFAULT (GETUTCDATE()),
    [CreatedBy] [nvarchar](255) NOT NULL DEFAULT (SUSER_SNAME()),
    [UpdatedBy] [nvarchar](255) NOT NULL DEFAULT (SUSER_SNAME()),
    CONSTRAINT [PK_Teams] PRIMARY KEY CLUSTERED ([TeamId] ASC)
    WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
)

CREATE UNIQUE NONCLUSTERED INDEX [IX_Teams_TeamName] ON [jit].[Teams]([TeamName] ASC)
    WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)

CREATE NONCLUSTERED INDEX [IX_Teams_IsActive] ON [jit].[Teams]([IsActive] ASC)
    WHERE [IsActive] = 1
    WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)

GO

PRINT 'Table [jit].[Teams] created successfully'
GO

