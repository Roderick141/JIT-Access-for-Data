USE [DMAP_JIT_Permissions]
GO

/****** Object:  StoredProcedure [JITA].[p_AanvraagAanmaken]    Script Date: 8-12-2025 13:23:23 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


-- =============================================	
-- Date       | Author					| Description 
-- 2025-12-08 | Brigitte Burgemeestre	| Created 

-- =============================================
CREATE OR ALTER     PROCEDURE [JITA].[p_AanvraagAanmaken]
		@Puik_ID nvarchar(255) NULL,
		@MotivatieAanvrager nvarchar(255) NULL,
		@StartDatum datetime NULL,
		@AanvraagID bigint output 


AS
BEGIN



INSERT INTO [JITA].[Aanvragen]
           ([Aanvrager]
     --      ,[Akkoordgever]
           ,[MotivatieAanvrager]
           ,[AanvraagStartDatum]
           ,[AanvraagStatus])
     VALUES
           (@Puik_ID
   --        ,<Akkoordgever, nvarchar(255),>
           ,@MotivatieAanvrager
           ,@StartDatum
           ,'Open')

SET @AanvraagID=(	SELECT Aanvraag_ID
					FROM [JITA].[Aanvragen]
					WHERE Aanvrager=@Puik_ID AND AanvraagStartDatum=@StartDatum AND AanvraagStatus='Open'
				) 

END
GO


