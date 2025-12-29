USE [DMAP_JIT_Permissions]
GO

/****** Object:  StoredProcedure [JITA].[p_PIM_RolToekennen]    Script Date: 16-12-2025 14:13:56 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO




-- =============================================	
-- Date       | Author					| Description 
-- 2025-12-03 | Brigitte Burgemeestre	| Created 

-- =============================================
CREATE OR ALTER              PROCEDURE [JITA].[p_PIM_RolToekennen]

		@Aanvraag_ID bigint
AS
BEGIN
	DROP TABLE IF EXISTS #AanvraagItemLijst

	CREATE TABLE #AanvraagItemLijst(
	[User] [nvarchar](255),
	[PIM_ROL_ID] [nvarchar](255) ,
	[Relatie_PIM_ROL_ID] [bigint] ,
	[AanvraagItem_ID] [bigint] ,
	[StartDatum] [datetime],
	[EindDatum] [datetime]
	)


	IF (SELECT AanvraagStatus  FROM [JITA].[Aanvragen] WHERE Aanvraag_ID=@Aanvraag_ID)='Akkoord'
		BEGIN
		/*Ophalen van gegevens aangevraagde rechten*/
			INSERT INTO #AanvraagItemLijst(
			[User],
			[Relatie_PIM_ROL_ID],
			[AanvraagItem_ID],
			[StartDatum] 
			)
            SELECT A.Aanvrager,I.Relatie_PIM_ROL_ID,I.AanvraagItem_ID, GETDATE()
			FROM [JITA].[Aanvragen] A
			JOIN [JITA].[AanvraagItem] I
			ON I.Aanvraag_ID=A.Aanvraag_ID
			WHERE A.Aanvraag_ID=@Aanvraag_ID ;

			UPDATE #AanvraagItemLijst
			SET PIM_ROL_ID=R.PIM_Rol_ID,
			EindDatum=DATEADD(day,P.MaxDuur, A.StartDatum)
			FROM #AanvraagItemLijst A
			JOIN [JITA].[Relatie_PIM_Rol] R
			ON A.Relatie_PIM_ROL_ID=R.Relatie_PIM_Rol_ID
			JOIN [JITA].[PIM_Rollen] P
			ON P.PIM_Rol_ID=R.PIM_Rol_ID
			WHERE A.Relatie_PIM_ROL_ID=R.Relatie_PIM_Rol_ID

			IF EXISTS (
			SELECT 1 
			FROM [JITA].[RECHTEN] R
			JOIN #AanvraagItemLijst A
			ON R.[User]=A.[User] AND R.[PIM_ROL_ID]=A.[PIM_ROL_ID])

			PRINT N'Kan rol niet toekennen, user heeft PIM Rol al'
			ELSE 

			INSERT INTO [JITA].[Rechten]
           ([User]
           ,[PIM_ROL_ID]
           ,[Relatie_PIM_ROL_ID]
           ,[AanvraagItem_ID]
           ,[StartDatum]
           ,[EindDatum]
           ,[Sys_EditedBy]
           ,[Sys_InsertDate])
		   SELECT 
		   [User]
           ,[PIM_ROL_ID]
           ,[Relatie_PIM_ROL_ID]
           ,[AanvraagItem_ID]
           ,[StartDatum]
           ,[EindDatum]
           ,SYSTEM_USER
           ,GETDATE()
		   FROM 
		   #AanvraagItemLijst

		END
	ELSE PRINT N'Aanvraag is niet akkoord, kan rol niet toekennen';


END
GO


