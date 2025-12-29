USE [DMAP_JIT_Permissions]
GO

/****** Object:  Index [JITA_TypeRelatie_CCI]    Script Date: 2-12-2025 10:24:41 ******/
DROP INDEX [JITA_TypeRelatie_CCI] ON [JITA].[TypeRelatie]
GO

/****** Object:  Table [JITA].[TypeRelatie]    Script Date: 2-12-2025 10:24:41 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[JITA].[TypeRelatie]') AND type in (N'U'))
DROP TABLE [JITA].[TypeRelatie]
GO

/****** Object:  Table [JITA].[TypeRelatie]    Script Date: 2-12-2025 10:24:41 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [JITA].[TypeRelatie](
	[TypeRelatie_ID] [bigint] IDENTITY(1,1) NOT NULL,
	[TypeRelatie] [nvarchar](255) NOT NULL,
 CONSTRAINT [PK_JITA_TypeRelatie] PRIMARY KEY NONCLUSTERED 
(
	[TypeRelatie_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF, DATA_COMPRESSION = PAGE) ON [Indexen]
) ON [PRIMARY]
GO

/****** Object:  Index [JITA_TypeRelatie_CCI]    Script Date: 2-12-2025 10:24:41 ******/
CREATE CLUSTERED COLUMNSTORE INDEX [JITA_TypeRelatie_CCI] ON [JITA].[TypeRelatie] WITH (DROP_EXISTING = OFF, COMPRESSION_DELAY = 0, DATA_COMPRESSION = COLUMNSTORE) ON [PRIMARY]
GO


