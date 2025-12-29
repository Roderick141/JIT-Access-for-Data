USE [DMAP_JIT_Permissions]
GO

/****** Object:  Table [JITA].[DB_Rollen_HT]    Script Date: 25-11-2025 14:04:05 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [JITA].[DB_Rollen_HT](
	[DVK_DB_Rollen_HT_ID] [bigint] IDENTITY(1,1) NOT NULL,
	[PrincipalName] [nvarchar](255) NOT NULL,
	[principal_id] [int] NOT NULL,
	[role_principal_id] [int] NOT NULL,
	[DBName] [nvarchar](255) NOT NULL,
	[type] [char](1) NULL,
	[type_desc] [nvarchar](60) NULL,
	[default_schema_name] [nvarchar](255) NULL,
	[create_date] [datetime] NULL,
	[modify_date] [datetime] NULL,
	[authentication_type] [int] NULL,
	[authentication_type_desc] [nvarchar](60) NULL,
	[Hash] [varbinary](8000) NULL,
	[DVA_Recent] [bit] NOT NULL,
	[DVA_Voided] [bit] NOT NULL,
	[DVA_BeginDatum] [datetime] NOT NULL,
	[DVA_EindDatum] [datetime] NOT NULL,
	[DVA_InsertDate] [datetime] NOT NULL,
 CONSTRAINT [PK_JITA_DB_Rollen_HT] PRIMARY KEY NONCLUSTERED 
(
	[DVK_DB_Rollen_HT_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF, DATA_COMPRESSION = PAGE) ON [Indexen],
 CONSTRAINT [UNQ_JITA_DB_Rollen_HT] UNIQUE NONCLUSTERED 
(
	[role_principal_id] ASC,
	[DVA_EindDatum] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF, DATA_COMPRESSION = PAGE) ON [Indexen]
) ON [PRIMARY]
GO

/****** Object:  Index [JITA_DB_Rollen_HT_CCI]    Script Date: 25-11-2025 14:04:06 ******/
CREATE CLUSTERED COLUMNSTORE INDEX [JITA_DB_Rollen_HT_CCI] ON [JITA].[DB_Rollen_HT] WITH (DROP_EXISTING = OFF, COMPRESSION_DELAY = 0, DATA_COMPRESSION = COLUMNSTORE) ON [PRIMARY]
GO


