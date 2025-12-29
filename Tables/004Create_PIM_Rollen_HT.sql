USE [DMAP_JIT_Permissions]
GO

/****** Object:  Index [JITA_PIM_Rollen_HT_CCI]    Script Date: 15-12-2025 09:55:45 ******/
DROP INDEX [JITA_PIM_Rollen_HT_CCI] ON [JITA].[PIM_Rollen_HT]
GO

/****** Object:  Table [JITA].[PIM_Rollen_HT]    Script Date: 15-12-2025 09:55:45 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[JITA].[PIM_Rollen_HT]') AND type in (N'U'))
DROP TABLE [JITA].[PIM_Rollen_HT]
GO

/****** Object:  Table [JITA].[PIM_Rollen_HT]    Script Date: 15-12-2025 09:55:45 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [JITA].[PIM_Rollen_HT](
	[PIM_Rollen_HT_ID] [bigint] IDENTITY(1,1) NOT NULL,
	[PIM_Rol_ID] [int] NOT NULL,
	[PIM_Rol_Naam] [nvarchar](255) NOT NULL,
	[Omschrijving] [nvarchar](255) NULL,
	[MaxDuur] [int] NULL,
	[Vertrouwelijkheid] [nvarchar](255) NULL,
	[AutorisatieNiveau] [int] NULL,
	[PIM_RolStatus] [nvarchar](1) NOT NULL,
	[CreatedBy] [nvarchar](255) NULL,
	[ChangedBy] [nvarchar](255) NULL,
	[Hash] [varbinary](8000) NULL,
	[Sys_Recent] [bit] NOT NULL,
	[Sys_StartDate] [datetime] NOT NULL,
	[Sys_EndDate] [datetime] NOT NULL,
 CONSTRAINT [PK_JITA_PIM_Rollen_HT] PRIMARY KEY NONCLUSTERED 
(
	[PIM_Rollen_HT_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF, DATA_COMPRESSION = PAGE) ON [Indexen],
 CONSTRAINT [UNQ_JITA_PIM_Rollen_HT] UNIQUE NONCLUSTERED 
(
	[PIM_Rol_ID] ASC,
	[Sys_EndDate] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF, DATA_COMPRESSION = PAGE) ON [Indexen]
) ON [PRIMARY]
GO

/****** Object:  Index [JITA_PIM_Rollen_HT_CCI]    Script Date: 15-12-2025 09:55:45 ******/
CREATE CLUSTERED COLUMNSTORE INDEX [JITA_PIM_Rollen_HT_CCI] ON [JITA].[PIM_Rollen_HT] WITH (DROP_EXISTING = OFF, COMPRESSION_DELAY = 0, DATA_COMPRESSION = COLUMNSTORE) ON [PRIMARY]
GO


