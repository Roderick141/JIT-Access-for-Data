USE [DMAP_JIT_Permissions]
GO

/****** Object:  StoredProcedure [JITA].[p_AanvraagItemAanmaken]    Script Date: 15-12-2025 15:00:14 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



-- =============================================	
-- Date       | Author					| Description 
-- 2025-12-08 | Brigitte Burgemeestre	| Created 

-- =============================================
CREATE OR ALTER     PROCEDURE [JITA].[p_AanvraagItemAanmaken]
		@Aanvraag_ID bigint NULL,
		@Relatie_PIM_ROL_ID bigint NULL


AS
BEGIN


INSERT INTO [JITA].[AanvraagItem]
           ([Aanvraag_ID]
           ,[Relatie_PIM_ROL_ID])
     VALUES
           (@Aanvraag_ID
           ,@Relatie_PIM_ROL_ID)

END
GO


