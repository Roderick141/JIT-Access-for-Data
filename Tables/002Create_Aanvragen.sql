USE [DMAP_JIT_Permissions]
GO

/****** Object:  Index [JITA_Aanvragen_CCI]    Script Date: 8-12-2025 11:00:11 ******/
DROP INDEX [JITA_Aanvragen_CCI] ON [JITA].[Aanvragen]
GO

/****** Object:  Table [JITA].[Aanvragen]    Script Date: 8-12-2025 11:00:11 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[JITA].[Aanvragen]') AND type in (N'U'))
DROP TABLE [JITA].[Aanvragen]
GO

/****** Object:  Table [JITA].[Aanvragen]    Script Date: 8-12-2025 11:00:11 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [JITA].[Aanvragen](
	[Aanvraag_ID] [bigint] IDENTITY(1,1) NOT NULL,
	[Aanvrager] [nvarchar](255) NOT NULL,
	[Akkoordgever] [nvarchar](255) NULL,
	[MotivatieAanvrager] [nvarchar](255) NULL,
	[MotivatieAkkoordgever] [nvarchar](255) NULL,
	[AanvraagStartDatum] [datetime] NULL,
	[AanvraagEindDatum] [datetime] NULL,
	[AanvraagStatus] [nvarchar](255) NULL,
 CONSTRAINT [PK_JITA_Aanvragen] PRIMARY KEY NONCLUSTERED 
(
	[Aanvraag_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF, DATA_COMPRESSION = PAGE) ON [Indexen]
) ON [PRIMARY]
GO

/****** Object:  Index [JITA_Aanvragen_CCI]    Script Date: 8-12-2025 11:00:11 ******/
CREATE CLUSTERED COLUMNSTORE INDEX [JITA_Aanvragen_CCI] ON [JITA].[Aanvragen] WITH (DROP_EXISTING = OFF, COMPRESSION_DELAY = 0, DATA_COMPRESSION = COLUMNSTORE) ON [PRIMARY]
GO


