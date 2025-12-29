USE [DMAP_JIT_Permissions]
GO

/****** Object:  StoredProcedure [JITA].[p_AanvraagbareRollen]    Script Date: 15-12-2025 10:03:22 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


-- =============================================	
-- Date       | Author					| Description 
-- 2025-11-26 | Brigitte Burgemeestre	| Created 

-- =============================================
CREATE OR ALTER      PROCEDURE [JITA].[p_AanvraagbareRollen]
		@Puik_ID nvarchar(255) NULL

AS
BEGIN
--Haal de gegevens van de gebruiker op
/*Dit moet nog uitgebreid worden met projecten waarin de users zitten. Waar halen we deze info vandaan?*/
	WITH CTE_UserInfo AS (
		SELECT RelatieNaam= A.Username,
		TypeRelatie='Username' 
		FROM [DMAP_MetaServices].[audit].[ADUserInfo_HT] A
		WHERE A.Username=@Puik_ID 
		UNION 
		SELECT RelatieNaam= A.Department,
		TypeRelatie='Department' 
		FROM [DMAP_MetaServices].[audit].[ADUserInfo_HT] A
		WHERE A.Username=@Puik_ID 
		UNION
		SELECT RelatieNaam= A.Division,
		TypeRelatie='Division' 
		FROM [DMAP_MetaServices].[audit].[ADUserInfo_HT] A
		WHERE A.Username=@Puik_ID 
		UNION
		SELECT RelatieNaam= 'UWV',
		TypeRelatie='Organization' 
		FROM [DMAP_MetaServices].[audit].[ADUserInfo_HT] A
		WHERE A.Username=@Puik_ID 
	),
--Haal alle beschikbare rollen op 
	CTE_AllRoles AS (
		SELECT P.PIM_Rol_ID,P.PIM_Rol_Naam, P.Omschrijving, P.MaxDuur, P.Vertrouwelijkheid, P.AutorisatieNiveau, C.TypeRelatie
		FROM [JITA].[Relatie_PIM_Rol] U
		JOIN [JITA].[PIM_Rollen] P
		ON U.PIM_Rol_ID=P.PIM_Rol_ID 
		JOIN CTE_USERInfo C
		ON C.RelatieNaam=U.RelatieNaam and C.TypeRelatie=U.TypeRelatie 
		WHERE	U.Relatie_PIM_RolStatus='Actief'
			AND P.PIM_RolStatus='A'),
--Haal voor elke PIM_Rol het minst specifieke type relatie op
	CTE_RelationRoles AS (
		SELECT C.PIM_Rol_Naam, Max(C.TypeRelatie) as MaxRelatie
		FROM CTE_AllRoles C
		GROUP BY C.PIM_Rol_Naam)
--Haal de unieke PIM rollen zien
 SELECT A.PIM_Rol_ID, A.PIM_Rol_Naam, A.Omschrijving, A.MaxDuur, A.Vertrouwelijkheid, A.AutorisatieNiveau, A.TypeRelatie
		FROM CTE_AllRoles A
		JOIN CTE_RelationRoles R
		ON A.PIM_Rol_Naam=R.PIM_Rol_Naam and A.TypeRelatie=R.MaxRelatie
  
END
GO


