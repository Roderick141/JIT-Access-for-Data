USE [DMAP_JIT_Permissions]
GO

/****** Object:  Index [JITA_Relatie_PIM_Rol_HT_CCI]    Script Date: 3-12-2025 13:43:34 ******/
DROP INDEX [JITA_Relatie_PIM_Rol_HT_CCI] ON [JITA].[Relatie_PIM_Rol_HT]
GO

/****** Object:  Table [JITA].[Relatie_PIM_Rol_HT]    Script Date: 3-12-2025 13:43:34 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[JITA].[Relatie_PIM_Rol_HT]') AND type in (N'U'))
DROP TABLE [JITA].[Relatie_PIM_Rol_HT]
GO

/****** Object:  Table [JITA].[Relatie_PIM_Rol_HT]    Script Date: 3-12-2025 13:43:34 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [JITA].[Relatie_PIM_Rol_HT](
	[Relatie_PIM_Rol_HT_ID] [bigint] IDENTITY(1,1) NOT NULL,
	[PIM_Rol_ID] [int] NOT NULL,
	[TypeRelatie] [nvarchar](255) NOT NULL,
	[RelatieNaam] [nvarchar](255) NOT NULL,
	[Relatie_PIM_RolStatus] [nvarchar](255) NULL,
	[StartDatum] [datetime] NULL,
	[EindDatum] [datetime] NULL,
	[ChangedBy] [nvarchar](255) NULL,
	[Hash] [varbinary](8000) NULL,
	[Sys_Recent] [bit] NOT NULL,
	[Sys_Voided] [bit] NOT NULL,
	[Sys_StartDate] [datetime] NOT NULL,
	[Sys_EndDate] [datetime] NOT NULL,
 CONSTRAINT [PK_JITA_Relatie_PIM_Rol_HT] PRIMARY KEY NONCLUSTERED 
(
	[Relatie_PIM_Rol_HT_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF, DATA_COMPRESSION = PAGE) ON [Indexen],
 CONSTRAINT [UNQ_JITA_Relatie_PIM_Rol_HT] UNIQUE NONCLUSTERED 
(
	[PIM_Rol_ID] ASC,
	[RelatieNaam] ASC,
	[Sys_EndDate] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF, DATA_COMPRESSION = PAGE) ON [Indexen]
) ON [PRIMARY]
GO

/****** Object:  Index [JITA_Relatie_PIM_Rol_HT_CCI]    Script Date: 3-12-2025 13:43:34 ******/
CREATE CLUSTERED COLUMNSTORE INDEX [JITA_Relatie_PIM_Rol_HT_CCI] ON [JITA].[Relatie_PIM_Rol_HT] WITH (DROP_EXISTING = OFF, COMPRESSION_DELAY = 0, DATA_COMPRESSION = COLUMNSTORE) ON [PRIMARY]
GO


