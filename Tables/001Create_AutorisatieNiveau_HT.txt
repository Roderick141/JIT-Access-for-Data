USE [DMAP_JIT_Permissions]
GO

/****** Object:  Index [JITA_AutorisatieNiveau_HT_CCI]    Script Date: 15-12-2025 09:59:52 ******/
DROP INDEX [JITA_AutorisatieNiveau_HT_CCI] ON [JITA].[AutorisatieNiveau_HT]
GO

/****** Object:  Table [JITA].[AutorisatieNiveau_HT]    Script Date: 15-12-2025 09:59:52 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[JITA].[AutorisatieNiveau_HT]') AND type in (N'U'))
DROP TABLE [JITA].[AutorisatieNiveau_HT]
GO

/****** Object:  Table [JITA].[AutorisatieNiveau_HT]    Script Date: 15-12-2025 09:59:52 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [JITA].[AutorisatieNiveau_HT](
	[DVK_AutorisatieNiveau_HT_ID] [bigint] IDENTITY(1,1) NOT NULL,
	[Puik_ID] [nvarchar](255) NOT NULL,
	[AutorisatieNiveau] [int] NULL,
	[InsertedBy] [nvarchar](255) NOT NULL,
	[DVA_Voided] [bit] NOT NULL,
	[DVA_Recent] [bit] NOT NULL,
	[DVA_BeginDatum] [datetime] NOT NULL,
	[DVA_EindDatum] [datetime] NOT NULL,
	[DVA_InsertDate] [datetime] NOT NULL,
 CONSTRAINT [PK_JITA_AutorisatieNiveau_HT] PRIMARY KEY NONCLUSTERED 
(
	[DVK_AutorisatieNiveau_HT_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF, DATA_COMPRESSION = PAGE) ON [Indexen],
 CONSTRAINT [UNQ_JITA_AutorisatieNiveau_HT] UNIQUE NONCLUSTERED 
(
	[Puik_ID] ASC,
	[DVA_EindDatum] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF, DATA_COMPRESSION = PAGE) ON [Indexen]
) ON [PRIMARY]
GO

/****** Object:  Index [JITA_AutorisatieNiveau_HT_CCI]    Script Date: 15-12-2025 09:59:53 ******/
CREATE CLUSTERED COLUMNSTORE INDEX [JITA_AutorisatieNiveau_HT_CCI] ON [JITA].[AutorisatieNiveau_HT] WITH (DROP_EXISTING = OFF, COMPRESSION_DELAY = 0, DATA_COMPRESSION = COLUMNSTORE) ON [PRIMARY]
GO


