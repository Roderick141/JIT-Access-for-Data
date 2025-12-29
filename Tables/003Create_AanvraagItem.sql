USE [DMAP_JIT_Permissions]
GO

/****** Object:  Index [JITA_AanvraagItem_CCI]    Script Date: 15-12-2025 15:00:57 ******/
DROP INDEX [JITA_AanvraagItem_CCI] ON [JITA].[AanvraagItem]
GO

/****** Object:  Table [JITA].[AanvraagItem]    Script Date: 15-12-2025 15:00:57 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[JITA].[AanvraagItem]') AND type in (N'U'))
DROP TABLE [JITA].[AanvraagItem]
GO

/****** Object:  Table [JITA].[AanvraagItem]    Script Date: 15-12-2025 15:00:57 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [JITA].[AanvraagItem](
	[AanvraagItem_ID] [bigint] IDENTITY(1,1) NOT NULL,
	[Aanvraag_ID] [bigint] NOT NULL,
	[Relatie_PIM_ROL_ID] [bigint] NOT NULL,
 CONSTRAINT [PK_JITA_AanvraagItem] PRIMARY KEY NONCLUSTERED 
(
	[AanvraagItem_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF, DATA_COMPRESSION = PAGE) ON [Indexen]
) ON [PRIMARY]
GO

/****** Object:  Index [JITA_AanvraagItem_CCI]    Script Date: 15-12-2025 15:00:57 ******/
CREATE CLUSTERED COLUMNSTORE INDEX [JITA_AanvraagItem_CCI] ON [JITA].[AanvraagItem] WITH (DROP_EXISTING = OFF, COMPRESSION_DELAY = 0, DATA_COMPRESSION = COLUMNSTORE) ON [PRIMARY]
GO


