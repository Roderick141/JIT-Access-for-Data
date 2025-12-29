USE [DMAP_JIT_Permissions]
GO

/****** Object:  Index [JITA_Relatie_PIM_Rol_CCI]    Script Date: 4-12-2025 11:49:50 ******/
DROP INDEX [JITA_Relatie_PIM_Rol_CCI] ON [JITA].[Relatie_PIM_Rol]
GO

/****** Object:  Table [JITA].[Relatie_PIM_Rol]    Script Date: 4-12-2025 11:49:50 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[JITA].[Relatie_PIM_Rol]') AND type in (N'U'))
DROP TABLE [JITA].[Relatie_PIM_Rol]
GO

/****** Object:  Table [JITA].[Relatie_PIM_Rol]    Script Date: 4-12-2025 11:49:50 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [JITA].[Relatie_PIM_Rol](
	[Relatie_PIM_Rol_ID] [bigint] IDENTITY(1,1) NOT NULL,
	[PIM_Rol_ID] [int] NOT NULL,
	[TypeRelatie] [nvarchar](255) NOT NULL,
	[RelatieNaam] [nvarchar](255) NOT NULL,
	[Relatie_PIM_RolStatus] [nvarchar](255) NULL,
	[Sys_EditedBy] [nvarchar](255) NOT NULL,
	[Sys_InsertDate] [datetime] NOT NULL,
 CONSTRAINT [PK_JITA_Relatie_PIM_Rol] PRIMARY KEY NONCLUSTERED 
(
	[Relatie_PIM_Rol_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF, DATA_COMPRESSION = PAGE) ON [Indexen],
 CONSTRAINT [UNQ_JITA_Relatie_PIM_Rol] UNIQUE NONCLUSTERED 
(
	[PIM_Rol_ID] ASC,
	[RelatieNaam] ASC,
	[TypeRelatie] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF, DATA_COMPRESSION = PAGE) ON [Indexen]
) ON [PRIMARY]
GO

/****** Object:  Index [JITA_Relatie_PIM_Rol_CCI]    Script Date: 4-12-2025 11:49:50 ******/
CREATE CLUSTERED COLUMNSTORE INDEX [JITA_Relatie_PIM_Rol_CCI] ON [JITA].[Relatie_PIM_Rol] WITH (DROP_EXISTING = OFF, COMPRESSION_DELAY = 0, DATA_COMPRESSION = COLUMNSTORE) ON [PRIMARY]
GO


