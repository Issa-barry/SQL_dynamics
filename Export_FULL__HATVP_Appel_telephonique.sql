WITH

-- ============================================================
-- CTE : Origine Appel — SystemUser interne unique (mask = 1)
-- ============================================================
OrigineAppel AS (
    SELECT
        ap.ActivityId,
        TRIM(ISNULL(su.FirstName,'') + ' ' + ISNULL(su.LastName,'')) AS Nom,
        su.DomainName                                                  AS MAIA
    FROM dbo.ActivityParty AS ap
    INNER JOIN dbo.SystemUser AS su
        ON  su.SystemUserId        = ap.PartyId
    WHERE ap.ParticipationTypeMask = 1
      AND ap.IsPartyDeleted        = 0
)

SELECT
    pc.ActivityId,
    pc.Subject                          AS Libelle,
    pc.OwnerIdName                      AS Proprietaire,
    pc.Description,

    -- ============================================================
    -- Concernant
    -- ============================================================
    CASE
        WHEN pc.RegardingObjectTypeCode = 2 THEN
        (
            SELECT
                ISNULL(c.LastName,  '-') + ' | ' +
                ISNULL(c.FirstName, '-') + ' | ' +
                ISNULL(sm_fonc.Value, '-')
            FROM dbo.Contact AS c
            LEFT JOIN dbo.StringMap AS sm_fonc
                ON  sm_fonc.ObjectTypeCode = 2
                AND sm_fonc.AttributeName  = 'grdf_fonction'
                AND sm_fonc.AttributeValue = c.grdf_fonction
                AND sm_fonc.LangId         = 1036
            WHERE c.ContactId = pc.RegardingObjectId
        )
        WHEN pc.RegardingObjectTypeCode = 1 THEN
            (SELECT a.Name FROM dbo.Account AS a WHERE a.AccountId = pc.RegardingObjectId)
        WHEN pc.RegardingObjectTypeCode = 3 THEN
            (SELECT o.Name FROM dbo.Opportunity AS o WHERE o.OpportunityId = pc.RegardingObjectId)
        WHEN pc.RegardingObjectTypeCode = 4 THEN
            (SELECT l.Subject FROM dbo.Lead AS l WHERE l.LeadId = pc.RegardingObjectId)
        WHEN pc.RegardingObjectTypeCode = 4402 THEN
            (SELECT ca.Subject FROM dbo.CampaignActivity AS ca WHERE ca.ActivityId = pc.RegardingObjectId)
        WHEN pc.RegardingObjectTypeCode = 10118 THEN
            (SELECT ct.grdf_name FROM dbo.grdf_contrat AS ct WHERE ct.grdf_contratId = pc.RegardingObjectId)
        WHEN pc.RegardingObjectTypeCode = 10121 THEN
            (SELECT loc.grdf_nom FROM dbo.grdf_local AS loc WHERE loc.grdf_localid = pc.RegardingObjectId)
        ELSE pc.RegardingObjectIdName
    END                                 AS Concernant,

    -- ============================================================
    -- Compte / Campagne rattaché(e)
    -- ============================================================
    CASE
        WHEN pc.RegardingObjectTypeCode = 1 THEN
            (SELECT a.Name FROM dbo.Account AS a WHERE a.AccountId = pc.RegardingObjectId)
        WHEN pc.RegardingObjectTypeCode = 2 THEN
            (SELECT a.Name FROM dbo.Contact AS c INNER JOIN dbo.Account AS a ON a.AccountId = c.AccountId WHERE c.ContactId = pc.RegardingObjectId)
        WHEN pc.RegardingObjectTypeCode = 3 THEN
            (SELECT a.Name FROM dbo.Opportunity AS o INNER JOIN dbo.Account AS a ON a.AccountId = o.AccountId WHERE o.OpportunityId = pc.RegardingObjectId)
        WHEN pc.RegardingObjectTypeCode = 4 THEN
            (SELECT a.Name FROM dbo.Lead AS l INNER JOIN dbo.Account AS a ON a.AccountId = l.ParentAccountId WHERE l.LeadId = pc.RegardingObjectId)
        WHEN pc.RegardingObjectTypeCode = 4402 THEN
            (SELECT c.Name FROM dbo.CampaignActivity AS ca INNER JOIN dbo.Campaign AS c ON c.CampaignId = ca.RegardingObjectId WHERE ca.ActivityId = pc.RegardingObjectId)
        WHEN pc.RegardingObjectTypeCode = 10118 THEN
            (SELECT a.Name FROM dbo.grdf_contrat AS ct INNER JOIN dbo.Account AS a ON a.AccountId = ct.grdf_Compte WHERE ct.grdf_contratId = pc.RegardingObjectId)
        WHEN pc.RegardingObjectTypeCode = 10121 THEN
            (SELECT a.Name FROM dbo.grdf_local AS loc INNER JOIN dbo.Account AS a ON a.AccountId = loc.grdf_compteid WHERE loc.grdf_localid = pc.RegardingObjectId)
        ELSE NULL
    END                                 AS [Compte / Campagne rattaché(e)],

    -- ============================================================
    -- Type du concernant
    -- ============================================================
    CASE
        WHEN pc.RegardingObjectTypeCode = 2     THEN 'Contact'
        WHEN pc.RegardingObjectTypeCode = 1     THEN 'Compte'
        WHEN pc.RegardingObjectTypeCode = 3     THEN 'Projet'
        WHEN pc.RegardingObjectTypeCode = 4     THEN 'Lead'
        WHEN pc.RegardingObjectTypeCode = 4400  THEN 'Campagne'
        WHEN pc.RegardingObjectTypeCode = 4402  THEN 'Activité de campagne'
        WHEN pc.RegardingObjectTypeCode = 10118 THEN 'Contrat'
        WHEN pc.RegardingObjectTypeCode = 10121 THEN 'Local'
        ELSE CAST(pc.RegardingObjectTypeCode AS NVARCHAR(50))
    END                                 AS TypeConcernant,

    -- ============================================================
    -- Référence compte
    -- ============================================================
    CASE
        WHEN pc.RegardingObjectTypeCode = 1     THEN (SELECT '''' + ISNULL(CAST(a.grdf_reference AS NVARCHAR(50)), '') FROM dbo.Account AS a WHERE a.AccountId = pc.RegardingObjectId)
        WHEN pc.RegardingObjectTypeCode = 2     THEN (SELECT '''' + ISNULL(CAST(a.grdf_reference AS NVARCHAR(50)), '') FROM dbo.Contact AS c INNER JOIN dbo.Account AS a ON a.AccountId = c.AccountId WHERE c.ContactId = pc.RegardingObjectId)
        WHEN pc.RegardingObjectTypeCode = 3     THEN (SELECT '''' + ISNULL(CAST(a.grdf_reference AS NVARCHAR(50)), '') FROM dbo.Opportunity AS o INNER JOIN dbo.Account AS a ON a.AccountId = o.AccountId WHERE o.OpportunityId = pc.RegardingObjectId)
        WHEN pc.RegardingObjectTypeCode = 4     THEN (SELECT '''' + ISNULL(CAST(a.grdf_reference AS NVARCHAR(50)), '') FROM dbo.Lead AS l INNER JOIN dbo.Account AS a ON a.AccountId = l.ParentAccountId WHERE l.LeadId = pc.RegardingObjectId)
        WHEN pc.RegardingObjectTypeCode = 10118 THEN (SELECT '''' + ISNULL(CAST(a.grdf_reference AS NVARCHAR(50)), '') FROM dbo.grdf_contrat AS ct INNER JOIN dbo.Account AS a ON a.AccountId = ct.grdf_Compte WHERE ct.grdf_contratId = pc.RegardingObjectId)
        WHEN pc.RegardingObjectTypeCode = 10121 THEN (SELECT '''' + ISNULL(CAST(a.grdf_reference AS NVARCHAR(50)), '') FROM dbo.grdf_local AS loc INNER JOIN dbo.Account AS a ON a.AccountId = loc.grdf_compteid WHERE loc.grdf_localid = pc.RegardingObjectId)
        ELSE NULL
    END                                 AS RefCompte,

    -- ============================================================
    -- Référence Atout Prisca
    -- ============================================================
    CASE
        WHEN pc.RegardingObjectTypeCode = 1     THEN (SELECT a.grdf_reference_atoutprisca FROM dbo.Account AS a WHERE a.AccountId = pc.RegardingObjectId)
        WHEN pc.RegardingObjectTypeCode = 2     THEN (SELECT a.grdf_reference_atoutprisca FROM dbo.Contact AS c INNER JOIN dbo.Account AS a ON a.AccountId = c.AccountId WHERE c.ContactId = pc.RegardingObjectId)
        WHEN pc.RegardingObjectTypeCode = 3     THEN (SELECT a.grdf_reference_atoutprisca FROM dbo.Opportunity AS o INNER JOIN dbo.Account AS a ON a.AccountId = o.AccountId WHERE o.OpportunityId = pc.RegardingObjectId)
        WHEN pc.RegardingObjectTypeCode = 4     THEN (SELECT a.grdf_reference_atoutprisca FROM dbo.Lead AS l INNER JOIN dbo.Account AS a ON a.AccountId = l.ParentAccountId WHERE l.LeadId = pc.RegardingObjectId)
        WHEN pc.RegardingObjectTypeCode = 10118 THEN (SELECT a.grdf_reference_atoutprisca FROM dbo.grdf_contrat AS ct INNER JOIN dbo.Account AS a ON a.AccountId = ct.grdf_Compte WHERE ct.grdf_contratId = pc.RegardingObjectId)
        WHEN pc.RegardingObjectTypeCode = 10121 THEN (SELECT a.grdf_reference_atoutprisca FROM dbo.grdf_local AS loc INNER JOIN dbo.Account AS a ON a.AccountId = loc.grdf_compteid WHERE loc.grdf_localid = pc.RegardingObjectId)
        ELSE NULL
    END                                 AS RefAtoutPrisca,

    -- ============================================================
    -- Code INSEE
    -- ============================================================
    CASE
        WHEN pc.RegardingObjectTypeCode = 1     THEN (SELECT '''' + RIGHT('00000' + ISNULL(CAST(a.grdf_code_insee AS NVARCHAR(5)), ''), 5) FROM dbo.Account AS a WHERE a.AccountId = pc.RegardingObjectId)
        WHEN pc.RegardingObjectTypeCode = 2     THEN (SELECT '''' + RIGHT('00000' + ISNULL(CAST(a.grdf_code_insee AS NVARCHAR(5)), ''), 5) FROM dbo.Contact AS c INNER JOIN dbo.Account AS a ON a.AccountId = c.AccountId WHERE c.ContactId = pc.RegardingObjectId)
        WHEN pc.RegardingObjectTypeCode = 3     THEN (SELECT '''' + RIGHT('00000' + ISNULL(CAST(a.grdf_code_insee AS NVARCHAR(5)), ''), 5) FROM dbo.Opportunity AS o INNER JOIN dbo.Account AS a ON a.AccountId = o.AccountId WHERE o.OpportunityId = pc.RegardingObjectId)
        WHEN pc.RegardingObjectTypeCode = 4     THEN (SELECT '''' + RIGHT('00000' + ISNULL(CAST(a.grdf_code_insee AS NVARCHAR(5)), ''), 5) FROM dbo.Lead AS l INNER JOIN dbo.Account AS a ON a.AccountId = l.ParentAccountId WHERE l.LeadId = pc.RegardingObjectId)
        WHEN pc.RegardingObjectTypeCode = 10118 THEN (SELECT '''' + RIGHT('00000' + ISNULL(CAST(a.grdf_code_insee AS NVARCHAR(5)), ''), 5) FROM dbo.grdf_contrat AS ct INNER JOIN dbo.Account AS a ON a.AccountId = ct.grdf_Compte WHERE ct.grdf_contratId = pc.RegardingObjectId)
        WHEN pc.RegardingObjectTypeCode = 10121 THEN (SELECT '''' + RIGHT('00000' + ISNULL(CAST(a.grdf_code_insee AS NVARCHAR(5)), ''), 5) FROM dbo.grdf_local AS loc INNER JOIN dbo.Account AS a ON a.AccountId = loc.grdf_compteid WHERE loc.grdf_localid = pc.RegardingObjectId)
        ELSE NULL
    END                                 AS CodeINSEE,

    -- ============================================================
    -- Code SIRET
    -- ============================================================
    CASE
        WHEN pc.RegardingObjectTypeCode = 1     THEN (SELECT '''' + RIGHT('00000000000000' + ISNULL(CAST(a.grdf_siret AS NVARCHAR(14)), ''), 14) FROM dbo.Account AS a WHERE a.AccountId = pc.RegardingObjectId)
        WHEN pc.RegardingObjectTypeCode = 2     THEN (SELECT '''' + RIGHT('00000000000000' + ISNULL(CAST(a.grdf_siret AS NVARCHAR(14)), ''), 14) FROM dbo.Contact AS c INNER JOIN dbo.Account AS a ON a.AccountId = c.AccountId WHERE c.ContactId = pc.RegardingObjectId)
        WHEN pc.RegardingObjectTypeCode = 3     THEN (SELECT '''' + RIGHT('00000000000000' + ISNULL(CAST(a.grdf_siret AS NVARCHAR(14)), ''), 14) FROM dbo.Opportunity AS o INNER JOIN dbo.Account AS a ON a.AccountId = o.AccountId WHERE o.OpportunityId = pc.RegardingObjectId)
        WHEN pc.RegardingObjectTypeCode = 4     THEN (SELECT '''' + RIGHT('00000000000000' + ISNULL(CAST(a.grdf_siret AS NVARCHAR(14)), ''), 14) FROM dbo.Lead AS l INNER JOIN dbo.Account AS a ON a.AccountId = l.ParentAccountId WHERE l.LeadId = pc.RegardingObjectId)
        WHEN pc.RegardingObjectTypeCode = 10118 THEN (SELECT '''' + RIGHT('00000000000000' + ISNULL(CAST(a.grdf_siret AS NVARCHAR(14)), ''), 14) FROM dbo.grdf_contrat AS ct INNER JOIN dbo.Account AS a ON a.AccountId = ct.grdf_Compte WHERE ct.grdf_contratId = pc.RegardingObjectId)
        WHEN pc.RegardingObjectTypeCode = 10121 THEN (SELECT '''' + RIGHT('00000000000000' + ISNULL(CAST(a.grdf_siret AS NVARCHAR(14)), ''), 14) FROM dbo.grdf_local AS loc INNER JOIN dbo.Account AS a ON a.AccountId = loc.grdf_compteid WHERE loc.grdf_localid = pc.RegardingObjectId)
        ELSE NULL
    END                                 AS CodeSIRET,

    -- ============================================================
    -- Code SIREN
    -- ============================================================
    CASE
        WHEN pc.RegardingObjectTypeCode = 1     THEN (SELECT '''' + RIGHT('000000000' + ISNULL(LEFT(CAST(a.grdf_siret AS NVARCHAR(14)), 9), ''), 9) FROM dbo.Account AS a WHERE a.AccountId = pc.RegardingObjectId)
        WHEN pc.RegardingObjectTypeCode = 2     THEN (SELECT '''' + RIGHT('000000000' + ISNULL(LEFT(CAST(a.grdf_siret AS NVARCHAR(14)), 9), ''), 9) FROM dbo.Contact AS c INNER JOIN dbo.Account AS a ON a.AccountId = c.AccountId WHERE c.ContactId = pc.RegardingObjectId)
        WHEN pc.RegardingObjectTypeCode = 3     THEN (SELECT '''' + RIGHT('000000000' + ISNULL(LEFT(CAST(a.grdf_siret AS NVARCHAR(14)), 9), ''), 9) FROM dbo.Opportunity AS o INNER JOIN dbo.Account AS a ON a.AccountId = o.AccountId WHERE o.OpportunityId = pc.RegardingObjectId)
        WHEN pc.RegardingObjectTypeCode = 4     THEN (SELECT '''' + RIGHT('000000000' + ISNULL(LEFT(CAST(a.grdf_siret AS NVARCHAR(14)), 9), ''), 9) FROM dbo.Lead AS l INNER JOIN dbo.Account AS a ON a.AccountId = l.ParentAccountId WHERE l.LeadId = pc.RegardingObjectId)
        WHEN pc.RegardingObjectTypeCode = 10118 THEN (SELECT '''' + RIGHT('000000000' + ISNULL(LEFT(CAST(a.grdf_siret AS NVARCHAR(14)), 9), ''), 9) FROM dbo.grdf_contrat AS ct INNER JOIN dbo.Account AS a ON a.AccountId = ct.grdf_Compte WHERE ct.grdf_contratId = pc.RegardingObjectId)
        WHEN pc.RegardingObjectTypeCode = 10121 THEN (SELECT '''' + RIGHT('000000000' + ISNULL(LEFT(CAST(a.grdf_siret AS NVARCHAR(14)), 9), ''), 9) FROM dbo.grdf_local AS loc INNER JOIN dbo.Account AS a ON a.AccountId = loc.grdf_compteid WHERE loc.grdf_localid = pc.RegardingObjectId)
        ELSE NULL
    END                                 AS CodeSIREN,

    -- Direction (Entrant/Sortant)
    CASE WHEN pc.DirectionCode = 1 THEN 'Sortant' ELSE 'Entrant' END AS Direction,

    -- ============================================================
    -- ORIGINE APPEL : 1 seul appelant SystemUser (mask = 1)
    -- ============================================================
    MAX(oa.Nom)                         AS Origine_Appel,
    MAX(oa.MAIA)                        AS MAIA_Origine_Appel,

    -- ============================================================
    -- Au moins un Député, Sénateur ou Préfet
    -- ============================================================
    CASE
        WHEN EXISTS (
            SELECT 1 FROM dbo.ActivityParty AS ap
            INNER JOIN dbo.Contact AS c ON c.ContactId = ap.PartyId
                AND c.grdf_fonction IN (996270020, 996270072, 996270055)
            WHERE ap.ActivityId = pc.ActivityId AND ap.ParticipationTypeMask IN (1, 2) AND ap.IsPartyDeleted = 0
        )
        OR EXISTS (
            SELECT 1 FROM dbo.Contact AS c
            WHERE c.ContactId = pc.RegardingObjectId AND pc.RegardingObjectTypeCode = 2
              AND c.grdf_fonction IN (996270020, 996270072, 996270055)
        )
        THEN 'Oui'
        ELSE 'Non'
    END                                 AS ContientDeputeOuSenateurOuPrefet,

    -- ============================================================
    -- DESTINATAIRES APPEL : 15 × 3 colonnes fixes (Contacts, mask=2)
    -- ============================================================

    -- Destinataire 1
    (SELECT TRIM(ISNULL(c.FirstName,'') + ' ' + ISNULL(c.LastName,''))   FROM (SELECT ap.PartyId, ROW_NUMBER() OVER (ORDER BY ap.PartyIdName) AS rn FROM dbo.ActivityParty AS ap WHERE ap.ActivityId = pc.ActivityId AND ap.ParticipationTypeMask = 2 AND ap.IsPartyDeleted = 0) x INNER JOIN dbo.Contact AS c ON c.ContactId = x.PartyId WHERE x.rn = 1)  AS Destinataire_Appel_Nom_1,
    (SELECT ISNULL(sm.Value,'-')         FROM (SELECT ap.PartyId, ROW_NUMBER() OVER (ORDER BY ap.PartyIdName) AS rn FROM dbo.ActivityParty AS ap WHERE ap.ActivityId = pc.ActivityId AND ap.ParticipationTypeMask = 2 AND ap.IsPartyDeleted = 0) x INNER JOIN dbo.Contact AS c ON c.ContactId = x.PartyId LEFT JOIN dbo.StringMap AS sm ON sm.ObjectTypeCode = 2 AND sm.AttributeName = 'grdf_fonction' AND sm.AttributeValue = c.grdf_fonction AND sm.LangId = 1036 WHERE x.rn = 1)  AS Destinataire_Appel_Fonction_1,
    (SELECT CASE WHEN c.grdf_hatvp = 1 THEN 'Oui' ELSE 'Non' END        FROM (SELECT ap.PartyId, ROW_NUMBER() OVER (ORDER BY ap.PartyIdName) AS rn FROM dbo.ActivityParty AS ap WHERE ap.ActivityId = pc.ActivityId AND ap.ParticipationTypeMask = 2 AND ap.IsPartyDeleted = 0) x INNER JOIN dbo.Contact AS c ON c.ContactId = x.PartyId WHERE x.rn = 1)  AS Destinataire_Appel_HATVP_1,

    -- Destinataire 2
    (SELECT TRIM(ISNULL(c.FirstName,'') + ' ' + ISNULL(c.LastName,''))   FROM (SELECT ap.PartyId, ROW_NUMBER() OVER (ORDER BY ap.PartyIdName) AS rn FROM dbo.ActivityParty AS ap WHERE ap.ActivityId = pc.ActivityId AND ap.ParticipationTypeMask = 2 AND ap.IsPartyDeleted = 0) x INNER JOIN dbo.Contact AS c ON c.ContactId = x.PartyId WHERE x.rn = 2)  AS Destinataire_Appel_Nom_2,
    (SELECT ISNULL(sm.Value,'-')         FROM (SELECT ap.PartyId, ROW_NUMBER() OVER (ORDER BY ap.PartyIdName) AS rn FROM dbo.ActivityParty AS ap WHERE ap.ActivityId = pc.ActivityId AND ap.ParticipationTypeMask = 2 AND ap.IsPartyDeleted = 0) x INNER JOIN dbo.Contact AS c ON c.ContactId = x.PartyId LEFT JOIN dbo.StringMap AS sm ON sm.ObjectTypeCode = 2 AND sm.AttributeName = 'grdf_fonction' AND sm.AttributeValue = c.grdf_fonction AND sm.LangId = 1036 WHERE x.rn = 2)  AS Destinataire_Appel_Fonction_2,
    (SELECT CASE WHEN c.grdf_hatvp = 1 THEN 'Oui' ELSE 'Non' END        FROM (SELECT ap.PartyId, ROW_NUMBER() OVER (ORDER BY ap.PartyIdName) AS rn FROM dbo.ActivityParty AS ap WHERE ap.ActivityId = pc.ActivityId AND ap.ParticipationTypeMask = 2 AND ap.IsPartyDeleted = 0) x INNER JOIN dbo.Contact AS c ON c.ContactId = x.PartyId WHERE x.rn = 2)  AS Destinataire_Appel_HATVP_2,

    -- Destinataire 3
    (SELECT TRIM(ISNULL(c.FirstName,'') + ' ' + ISNULL(c.LastName,''))   FROM (SELECT ap.PartyId, ROW_NUMBER() OVER (ORDER BY ap.PartyIdName) AS rn FROM dbo.ActivityParty AS ap WHERE ap.ActivityId = pc.ActivityId AND ap.ParticipationTypeMask = 2 AND ap.IsPartyDeleted = 0) x INNER JOIN dbo.Contact AS c ON c.ContactId = x.PartyId WHERE x.rn = 3)  AS Destinataire_Appel_Nom_3,
    (SELECT ISNULL(sm.Value,'-')         FROM (SELECT ap.PartyId, ROW_NUMBER() OVER (ORDER BY ap.PartyIdName) AS rn FROM dbo.ActivityParty AS ap WHERE ap.ActivityId = pc.ActivityId AND ap.ParticipationTypeMask = 2 AND ap.IsPartyDeleted = 0) x INNER JOIN dbo.Contact AS c ON c.ContactId = x.PartyId LEFT JOIN dbo.StringMap AS sm ON sm.ObjectTypeCode = 2 AND sm.AttributeName = 'grdf_fonction' AND sm.AttributeValue = c.grdf_fonction AND sm.LangId = 1036 WHERE x.rn = 3)  AS Destinataire_Appel_Fonction_3,
    (SELECT CASE WHEN c.grdf_hatvp = 1 THEN 'Oui' ELSE 'Non' END        FROM (SELECT ap.PartyId, ROW_NUMBER() OVER (ORDER BY ap.PartyIdName) AS rn FROM dbo.ActivityParty AS ap WHERE ap.ActivityId = pc.ActivityId AND ap.ParticipationTypeMask = 2 AND ap.IsPartyDeleted = 0) x INNER JOIN dbo.Contact AS c ON c.ContactId = x.PartyId WHERE x.rn = 3)  AS Destinataire_Appel_HATVP_3,

    -- Destinataire 4
    (SELECT TRIM(ISNULL(c.FirstName,'') + ' ' + ISNULL(c.LastName,''))   FROM (SELECT ap.PartyId, ROW_NUMBER() OVER (ORDER BY ap.PartyIdName) AS rn FROM dbo.ActivityParty AS ap WHERE ap.ActivityId = pc.ActivityId AND ap.ParticipationTypeMask = 2 AND ap.IsPartyDeleted = 0) x INNER JOIN dbo.Contact AS c ON c.ContactId = x.PartyId WHERE x.rn = 4)  AS Destinataire_Appel_Nom_4,
    (SELECT ISNULL(sm.Value,'-')         FROM (SELECT ap.PartyId, ROW_NUMBER() OVER (ORDER BY ap.PartyIdName) AS rn FROM dbo.ActivityParty AS ap WHERE ap.ActivityId = pc.ActivityId AND ap.ParticipationTypeMask = 2 AND ap.IsPartyDeleted = 0) x INNER JOIN dbo.Contact AS c ON c.ContactId = x.PartyId LEFT JOIN dbo.StringMap AS sm ON sm.ObjectTypeCode = 2 AND sm.AttributeName = 'grdf_fonction' AND sm.AttributeValue = c.grdf_fonction AND sm.LangId = 1036 WHERE x.rn = 4)  AS Destinataire_Appel_Fonction_4,
    (SELECT CASE WHEN c.grdf_hatvp = 1 THEN 'Oui' ELSE 'Non' END        FROM (SELECT ap.PartyId, ROW_NUMBER() OVER (ORDER BY ap.PartyIdName) AS rn FROM dbo.ActivityParty AS ap WHERE ap.ActivityId = pc.ActivityId AND ap.ParticipationTypeMask = 2 AND ap.IsPartyDeleted = 0) x INNER JOIN dbo.Contact AS c ON c.ContactId = x.PartyId WHERE x.rn = 4)  AS Destinataire_Appel_HATVP_4,

    -- Destinataire 5
    (SELECT TRIM(ISNULL(c.FirstName,'') + ' ' + ISNULL(c.LastName,''))   FROM (SELECT ap.PartyId, ROW_NUMBER() OVER (ORDER BY ap.PartyIdName) AS rn FROM dbo.ActivityParty AS ap WHERE ap.ActivityId = pc.ActivityId AND ap.ParticipationTypeMask = 2 AND ap.IsPartyDeleted = 0) x INNER JOIN dbo.Contact AS c ON c.ContactId = x.PartyId WHERE x.rn = 5)  AS Destinataire_Appel_Nom_5,
    (SELECT ISNULL(sm.Value,'-')         FROM (SELECT ap.PartyId, ROW_NUMBER() OVER (ORDER BY ap.PartyIdName) AS rn FROM dbo.ActivityParty AS ap WHERE ap.ActivityId = pc.ActivityId AND ap.ParticipationTypeMask = 2 AND ap.IsPartyDeleted = 0) x INNER JOIN dbo.Contact AS c ON c.ContactId = x.PartyId LEFT JOIN dbo.StringMap AS sm ON sm.ObjectTypeCode = 2 AND sm.AttributeName = 'grdf_fonction' AND sm.AttributeValue = c.grdf_fonction AND sm.LangId = 1036 WHERE x.rn = 5)  AS Destinataire_Appel_Fonction_5,
    (SELECT CASE WHEN c.grdf_hatvp = 1 THEN 'Oui' ELSE 'Non' END        FROM (SELECT ap.PartyId, ROW_NUMBER() OVER (ORDER BY ap.PartyIdName) AS rn FROM dbo.ActivityParty AS ap WHERE ap.ActivityId = pc.ActivityId AND ap.ParticipationTypeMask = 2 AND ap.IsPartyDeleted = 0) x INNER JOIN dbo.Contact AS c ON c.ContactId = x.PartyId WHERE x.rn = 5)  AS Destinataire_Appel_HATVP_5,

    -- Destinataire 6
    (SELECT TRIM(ISNULL(c.FirstName,'') + ' ' + ISNULL(c.LastName,''))   FROM (SELECT ap.PartyId, ROW_NUMBER() OVER (ORDER BY ap.PartyIdName) AS rn FROM dbo.ActivityParty AS ap WHERE ap.ActivityId = pc.ActivityId AND ap.ParticipationTypeMask = 2 AND ap.IsPartyDeleted = 0) x INNER JOIN dbo.Contact AS c ON c.ContactId = x.PartyId WHERE x.rn = 6)  AS Destinataire_Appel_Nom_6,
    (SELECT ISNULL(sm.Value,'-')         FROM (SELECT ap.PartyId, ROW_NUMBER() OVER (ORDER BY ap.PartyIdName) AS rn FROM dbo.ActivityParty AS ap WHERE ap.ActivityId = pc.ActivityId AND ap.ParticipationTypeMask = 2 AND ap.IsPartyDeleted = 0) x INNER JOIN dbo.Contact AS c ON c.ContactId = x.PartyId LEFT JOIN dbo.StringMap AS sm ON sm.ObjectTypeCode = 2 AND sm.AttributeName = 'grdf_fonction' AND sm.AttributeValue = c.grdf_fonction AND sm.LangId = 1036 WHERE x.rn = 6)  AS Destinataire_Appel_Fonction_6,
    (SELECT CASE WHEN c.grdf_hatvp = 1 THEN 'Oui' ELSE 'Non' END        FROM (SELECT ap.PartyId, ROW_NUMBER() OVER (ORDER BY ap.PartyIdName) AS rn FROM dbo.ActivityParty AS ap WHERE ap.ActivityId = pc.ActivityId AND ap.ParticipationTypeMask = 2 AND ap.IsPartyDeleted = 0) x INNER JOIN dbo.Contact AS c ON c.ContactId = x.PartyId WHERE x.rn = 6)  AS Destinataire_Appel_HATVP_6,

    -- Destinataire 7
    (SELECT TRIM(ISNULL(c.FirstName,'') + ' ' + ISNULL(c.LastName,''))   FROM (SELECT ap.PartyId, ROW_NUMBER() OVER (ORDER BY ap.PartyIdName) AS rn FROM dbo.ActivityParty AS ap WHERE ap.ActivityId = pc.ActivityId AND ap.ParticipationTypeMask = 2 AND ap.IsPartyDeleted = 0) x INNER JOIN dbo.Contact AS c ON c.ContactId = x.PartyId WHERE x.rn = 7)  AS Destinataire_Appel_Nom_7,
    (SELECT ISNULL(sm.Value,'-')         FROM (SELECT ap.PartyId, ROW_NUMBER() OVER (ORDER BY ap.PartyIdName) AS rn FROM dbo.ActivityParty AS ap WHERE ap.ActivityId = pc.ActivityId AND ap.ParticipationTypeMask = 2 AND ap.IsPartyDeleted = 0) x INNER JOIN dbo.Contact AS c ON c.ContactId = x.PartyId LEFT JOIN dbo.StringMap AS sm ON sm.ObjectTypeCode = 2 AND sm.AttributeName = 'grdf_fonction' AND sm.AttributeValue = c.grdf_fonction AND sm.LangId = 1036 WHERE x.rn = 7)  AS Destinataire_Appel_Fonction_7,
    (SELECT CASE WHEN c.grdf_hatvp = 1 THEN 'Oui' ELSE 'Non' END        FROM (SELECT ap.PartyId, ROW_NUMBER() OVER (ORDER BY ap.PartyIdName) AS rn FROM dbo.ActivityParty AS ap WHERE ap.ActivityId = pc.ActivityId AND ap.ParticipationTypeMask = 2 AND ap.IsPartyDeleted = 0) x INNER JOIN dbo.Contact AS c ON c.ContactId = x.PartyId WHERE x.rn = 7)  AS Destinataire_Appel_HATVP_7,

    -- Destinataire 8
    (SELECT TRIM(ISNULL(c.FirstName,'') + ' ' + ISNULL(c.LastName,''))   FROM (SELECT ap.PartyId, ROW_NUMBER() OVER (ORDER BY ap.PartyIdName) AS rn FROM dbo.ActivityParty AS ap WHERE ap.ActivityId = pc.ActivityId AND ap.ParticipationTypeMask = 2 AND ap.IsPartyDeleted = 0) x INNER JOIN dbo.Contact AS c ON c.ContactId = x.PartyId WHERE x.rn = 8)  AS Destinataire_Appel_Nom_8,
    (SELECT ISNULL(sm.Value,'-')         FROM (SELECT ap.PartyId, ROW_NUMBER() OVER (ORDER BY ap.PartyIdName) AS rn FROM dbo.ActivityParty AS ap WHERE ap.ActivityId = pc.ActivityId AND ap.ParticipationTypeMask = 2 AND ap.IsPartyDeleted = 0) x INNER JOIN dbo.Contact AS c ON c.ContactId = x.PartyId LEFT JOIN dbo.StringMap AS sm ON sm.ObjectTypeCode = 2 AND sm.AttributeName = 'grdf_fonction' AND sm.AttributeValue = c.grdf_fonction AND sm.LangId = 1036 WHERE x.rn = 8)  AS Destinataire_Appel_Fonction_8,
    (SELECT CASE WHEN c.grdf_hatvp = 1 THEN 'Oui' ELSE 'Non' END        FROM (SELECT ap.PartyId, ROW_NUMBER() OVER (ORDER BY ap.PartyIdName) AS rn FROM dbo.ActivityParty AS ap WHERE ap.ActivityId = pc.ActivityId AND ap.ParticipationTypeMask = 2 AND ap.IsPartyDeleted = 0) x INNER JOIN dbo.Contact AS c ON c.ContactId = x.PartyId WHERE x.rn = 8)  AS Destinataire_Appel_HATVP_8,

    -- Destinataire 9
    (SELECT TRIM(ISNULL(c.FirstName,'') + ' ' + ISNULL(c.LastName,''))   FROM (SELECT ap.PartyId, ROW_NUMBER() OVER (ORDER BY ap.PartyIdName) AS rn FROM dbo.ActivityParty AS ap WHERE ap.ActivityId = pc.ActivityId AND ap.ParticipationTypeMask = 2 AND ap.IsPartyDeleted = 0) x INNER JOIN dbo.Contact AS c ON c.ContactId = x.PartyId WHERE x.rn = 9)  AS Destinataire_Appel_Nom_9,
    (SELECT ISNULL(sm.Value,'-')         FROM (SELECT ap.PartyId, ROW_NUMBER() OVER (ORDER BY ap.PartyIdName) AS rn FROM dbo.ActivityParty AS ap WHERE ap.ActivityId = pc.ActivityId AND ap.ParticipationTypeMask = 2 AND ap.IsPartyDeleted = 0) x INNER JOIN dbo.Contact AS c ON c.ContactId = x.PartyId LEFT JOIN dbo.StringMap AS sm ON sm.ObjectTypeCode = 2 AND sm.AttributeName = 'grdf_fonction' AND sm.AttributeValue = c.grdf_fonction AND sm.LangId = 1036 WHERE x.rn = 9)  AS Destinataire_Appel_Fonction_9,
    (SELECT CASE WHEN c.grdf_hatvp = 1 THEN 'Oui' ELSE 'Non' END        FROM (SELECT ap.PartyId, ROW_NUMBER() OVER (ORDER BY ap.PartyIdName) AS rn FROM dbo.ActivityParty AS ap WHERE ap.ActivityId = pc.ActivityId AND ap.ParticipationTypeMask = 2 AND ap.IsPartyDeleted = 0) x INNER JOIN dbo.Contact AS c ON c.ContactId = x.PartyId WHERE x.rn = 9)  AS Destinataire_Appel_HATVP_9,

    -- Destinataire 10
    (SELECT TRIM(ISNULL(c.FirstName,'') + ' ' + ISNULL(c.LastName,''))   FROM (SELECT ap.PartyId, ROW_NUMBER() OVER (ORDER BY ap.PartyIdName) AS rn FROM dbo.ActivityParty AS ap WHERE ap.ActivityId = pc.ActivityId AND ap.ParticipationTypeMask = 2 AND ap.IsPartyDeleted = 0) x INNER JOIN dbo.Contact AS c ON c.ContactId = x.PartyId WHERE x.rn = 10) AS Destinataire_Appel_Nom_10,
    (SELECT ISNULL(sm.Value,'-')         FROM (SELECT ap.PartyId, ROW_NUMBER() OVER (ORDER BY ap.PartyIdName) AS rn FROM dbo.ActivityParty AS ap WHERE ap.ActivityId = pc.ActivityId AND ap.ParticipationTypeMask = 2 AND ap.IsPartyDeleted = 0) x INNER JOIN dbo.Contact AS c ON c.ContactId = x.PartyId LEFT JOIN dbo.StringMap AS sm ON sm.ObjectTypeCode = 2 AND sm.AttributeName = 'grdf_fonction' AND sm.AttributeValue = c.grdf_fonction AND sm.LangId = 1036 WHERE x.rn = 10) AS Destinataire_Appel_Fonction_10,
    (SELECT CASE WHEN c.grdf_hatvp = 1 THEN 'Oui' ELSE 'Non' END        FROM (SELECT ap.PartyId, ROW_NUMBER() OVER (ORDER BY ap.PartyIdName) AS rn FROM dbo.ActivityParty AS ap WHERE ap.ActivityId = pc.ActivityId AND ap.ParticipationTypeMask = 2 AND ap.IsPartyDeleted = 0) x INNER JOIN dbo.Contact AS c ON c.ContactId = x.PartyId WHERE x.rn = 10) AS Destinataire_Appel_HATVP_10,

    -- Destinataire 11
    (SELECT TRIM(ISNULL(c.FirstName,'') + ' ' + ISNULL(c.LastName,''))   FROM (SELECT ap.PartyId, ROW_NUMBER() OVER (ORDER BY ap.PartyIdName) AS rn FROM dbo.ActivityParty AS ap WHERE ap.ActivityId = pc.ActivityId AND ap.ParticipationTypeMask = 2 AND ap.IsPartyDeleted = 0) x INNER JOIN dbo.Contact AS c ON c.ContactId = x.PartyId WHERE x.rn = 11) AS Destinataire_Appel_Nom_11,
    (SELECT ISNULL(sm.Value,'-')         FROM (SELECT ap.PartyId, ROW_NUMBER() OVER (ORDER BY ap.PartyIdName) AS rn FROM dbo.ActivityParty AS ap WHERE ap.ActivityId = pc.ActivityId AND ap.ParticipationTypeMask = 2 AND ap.IsPartyDeleted = 0) x INNER JOIN dbo.Contact AS c ON c.ContactId = x.PartyId LEFT JOIN dbo.StringMap AS sm ON sm.ObjectTypeCode = 2 AND sm.AttributeName = 'grdf_fonction' AND sm.AttributeValue = c.grdf_fonction AND sm.LangId = 1036 WHERE x.rn = 11) AS Destinataire_Appel_Fonction_11,
    (SELECT CASE WHEN c.grdf_hatvp = 1 THEN 'Oui' ELSE 'Non' END        FROM (SELECT ap.PartyId, ROW_NUMBER() OVER (ORDER BY ap.PartyIdName) AS rn FROM dbo.ActivityParty AS ap WHERE ap.ActivityId = pc.ActivityId AND ap.ParticipationTypeMask = 2 AND ap.IsPartyDeleted = 0) x INNER JOIN dbo.Contact AS c ON c.ContactId = x.PartyId WHERE x.rn = 11) AS Destinataire_Appel_HATVP_11,

    -- Destinataire 12
    (SELECT TRIM(ISNULL(c.FirstName,'') + ' ' + ISNULL(c.LastName,''))   FROM (SELECT ap.PartyId, ROW_NUMBER() OVER (ORDER BY ap.PartyIdName) AS rn FROM dbo.ActivityParty AS ap WHERE ap.ActivityId = pc.ActivityId AND ap.ParticipationTypeMask = 2 AND ap.IsPartyDeleted = 0) x INNER JOIN dbo.Contact AS c ON c.ContactId = x.PartyId WHERE x.rn = 12) AS Destinataire_Appel_Nom_12,
    (SELECT ISNULL(sm.Value,'-')         FROM (SELECT ap.PartyId, ROW_NUMBER() OVER (ORDER BY ap.PartyIdName) AS rn FROM dbo.ActivityParty AS ap WHERE ap.ActivityId = pc.ActivityId AND ap.ParticipationTypeMask = 2 AND ap.IsPartyDeleted = 0) x INNER JOIN dbo.Contact AS c ON c.ContactId = x.PartyId LEFT JOIN dbo.StringMap AS sm ON sm.ObjectTypeCode = 2 AND sm.AttributeName = 'grdf_fonction' AND sm.AttributeValue = c.grdf_fonction AND sm.LangId = 1036 WHERE x.rn = 12) AS Destinataire_Appel_Fonction_12,
    (SELECT CASE WHEN c.grdf_hatvp = 1 THEN 'Oui' ELSE 'Non' END        FROM (SELECT ap.PartyId, ROW_NUMBER() OVER (ORDER BY ap.PartyIdName) AS rn FROM dbo.ActivityParty AS ap WHERE ap.ActivityId = pc.ActivityId AND ap.ParticipationTypeMask = 2 AND ap.IsPartyDeleted = 0) x INNER JOIN dbo.Contact AS c ON c.ContactId = x.PartyId WHERE x.rn = 12) AS Destinataire_Appel_HATVP_12,

    -- Destinataire 13
    (SELECT TRIM(ISNULL(c.FirstName,'') + ' ' + ISNULL(c.LastName,''))   FROM (SELECT ap.PartyId, ROW_NUMBER() OVER (ORDER BY ap.PartyIdName) AS rn FROM dbo.ActivityParty AS ap WHERE ap.ActivityId = pc.ActivityId AND ap.ParticipationTypeMask = 2 AND ap.IsPartyDeleted = 0) x INNER JOIN dbo.Contact AS c ON c.ContactId = x.PartyId WHERE x.rn = 13) AS Destinataire_Appel_Nom_13,
    (SELECT ISNULL(sm.Value,'-')         FROM (SELECT ap.PartyId, ROW_NUMBER() OVER (ORDER BY ap.PartyIdName) AS rn FROM dbo.ActivityParty AS ap WHERE ap.ActivityId = pc.ActivityId AND ap.ParticipationTypeMask = 2 AND ap.IsPartyDeleted = 0) x INNER JOIN dbo.Contact AS c ON c.ContactId = x.PartyId LEFT JOIN dbo.StringMap AS sm ON sm.ObjectTypeCode = 2 AND sm.AttributeName = 'grdf_fonction' AND sm.AttributeValue = c.grdf_fonction AND sm.LangId = 1036 WHERE x.rn = 13) AS Destinataire_Appel_Fonction_13,
    (SELECT CASE WHEN c.grdf_hatvp = 1 THEN 'Oui' ELSE 'Non' END        FROM (SELECT ap.PartyId, ROW_NUMBER() OVER (ORDER BY ap.PartyIdName) AS rn FROM dbo.ActivityParty AS ap WHERE ap.ActivityId = pc.ActivityId AND ap.ParticipationTypeMask = 2 AND ap.IsPartyDeleted = 0) x INNER JOIN dbo.Contact AS c ON c.ContactId = x.PartyId WHERE x.rn = 13) AS Destinataire_Appel_HATVP_13,

    -- Destinataire 14
    (SELECT TRIM(ISNULL(c.FirstName,'') + ' ' + ISNULL(c.LastName,''))   FROM (SELECT ap.PartyId, ROW_NUMBER() OVER (ORDER BY ap.PartyIdName) AS rn FROM dbo.ActivityParty AS ap WHERE ap.ActivityId = pc.ActivityId AND ap.ParticipationTypeMask = 2 AND ap.IsPartyDeleted = 0) x INNER JOIN dbo.Contact AS c ON c.ContactId = x.PartyId WHERE x.rn = 14) AS Destinataire_Appel_Nom_14,
    (SELECT ISNULL(sm.Value,'-')         FROM (SELECT ap.PartyId, ROW_NUMBER() OVER (ORDER BY ap.PartyIdName) AS rn FROM dbo.ActivityParty AS ap WHERE ap.ActivityId = pc.ActivityId AND ap.ParticipationTypeMask = 2 AND ap.IsPartyDeleted = 0) x INNER JOIN dbo.Contact AS c ON c.ContactId = x.PartyId LEFT JOIN dbo.StringMap AS sm ON sm.ObjectTypeCode = 2 AND sm.AttributeName = 'grdf_fonction' AND sm.AttributeValue = c.grdf_fonction AND sm.LangId = 1036 WHERE x.rn = 14) AS Destinataire_Appel_Fonction_14,
    (SELECT CASE WHEN c.grdf_hatvp = 1 THEN 'Oui' ELSE 'Non' END        FROM (SELECT ap.PartyId, ROW_NUMBER() OVER (ORDER BY ap.PartyIdName) AS rn FROM dbo.ActivityParty AS ap WHERE ap.ActivityId = pc.ActivityId AND ap.ParticipationTypeMask = 2 AND ap.IsPartyDeleted = 0) x INNER JOIN dbo.Contact AS c ON c.ContactId = x.PartyId WHERE x.rn = 14) AS Destinataire_Appel_HATVP_14,

    -- Destinataire 15
    (SELECT TRIM(ISNULL(c.FirstName,'') + ' ' + ISNULL(c.LastName,''))   FROM (SELECT ap.PartyId, ROW_NUMBER() OVER (ORDER BY ap.PartyIdName) AS rn FROM dbo.ActivityParty AS ap WHERE ap.ActivityId = pc.ActivityId AND ap.ParticipationTypeMask = 2 AND ap.IsPartyDeleted = 0) x INNER JOIN dbo.Contact AS c ON c.ContactId = x.PartyId WHERE x.rn = 15) AS Destinataire_Appel_Nom_15,
    (SELECT ISNULL(sm.Value,'-')         FROM (SELECT ap.PartyId, ROW_NUMBER() OVER (ORDER BY ap.PartyIdName) AS rn FROM dbo.ActivityParty AS ap WHERE ap.ActivityId = pc.ActivityId AND ap.ParticipationTypeMask = 2 AND ap.IsPartyDeleted = 0) x INNER JOIN dbo.Contact AS c ON c.ContactId = x.PartyId LEFT JOIN dbo.StringMap AS sm ON sm.ObjectTypeCode = 2 AND sm.AttributeName = 'grdf_fonction' AND sm.AttributeValue = c.grdf_fonction AND sm.LangId = 1036 WHERE x.rn = 15) AS Destinataire_Appel_Fonction_15,
    (SELECT CASE WHEN c.grdf_hatvp = 1 THEN 'Oui' ELSE 'Non' END        FROM (SELECT ap.PartyId, ROW_NUMBER() OVER (ORDER BY ap.PartyIdName) AS rn FROM dbo.ActivityParty AS ap WHERE ap.ActivityId = pc.ActivityId AND ap.ParticipationTypeMask = 2 AND ap.IsPartyDeleted = 0) x INNER JOIN dbo.Contact AS c ON c.ContactId = x.PartyId WHERE x.rn = 15) AS Destinataire_Appel_HATVP_15,

    -- ============================================================
    -- Nombre d'interlocuteurs HATVP
    -- ============================================================
    (
        SELECT COUNT(DISTINCT contact_hatvp.ContactId)
        FROM (
            SELECT c.ContactId
            FROM dbo.ActivityParty AS ap
            INNER JOIN dbo.Contact AS c ON c.ContactId = ap.PartyId AND c.grdf_hatvp = 1
            WHERE ap.ActivityId = pc.ActivityId AND ap.ParticipationTypeMask = 1 AND ap.IsPartyDeleted = 0
            UNION
            SELECT c.ContactId
            FROM dbo.ActivityParty AS ap
            INNER JOIN dbo.Contact AS c ON c.ContactId = ap.PartyId AND c.grdf_hatvp = 1
            WHERE ap.ActivityId = pc.ActivityId AND ap.ParticipationTypeMask = 2 AND ap.IsPartyDeleted = 0
            UNION
            SELECT c.ContactId
            FROM dbo.Contact AS c
            WHERE c.ContactId = pc.RegardingObjectId AND c.grdf_hatvp = 1 AND pc.RegardingObjectTypeCode = 2
        ) AS contact_hatvp
    )                                   AS NbInterlocuteursHATVP,

    -- Date planifiée (UTC → Europe/Paris)
    CONVERT(DATE,
        pc.ScheduledStart AT TIME ZONE 'UTC' AT TIME ZONE 'Romance Standard Time'
    )                                   AS Date_Appel,

    MAX(sm_stat.Value)                  AS Statut,
    MAX(sm_type.Value)                  AS grdf_Type,
    MAX(sm_prio.Value)                  AS Priorite,

    -- ============================================================
    -- Thématiques
    -- ============================================================
    (
        SELECT STRING_AGG(CAST(sm_them.Value AS NVARCHAR(MAX)), ', ')
            WITHIN GROUP (ORDER BY sm_them.Value)
        FROM dbo.StringMap AS sm_them
        WHERE sm_them.ObjectTypeCode = 4210
          AND sm_them.AttributeName  = 'grdf_thematique'
          AND CHARINDEX(CAST(sm_them.AttributeValue AS VARCHAR(20)), pc.grdf_thematique) > 0
          AND sm_them.LangId         = 1036
    )                                   AS Thematiques

FROM dbo.PhoneCall AS pc
LEFT JOIN OrigineAppel AS oa
    ON  oa.ActivityId = pc.ActivityId

LEFT JOIN dbo.StringMap AS sm_stat
    ON sm_stat.ObjectTypeCode = 4210 AND sm_stat.AttributeName = 'statecode'
    AND sm_stat.AttributeValue = pc.StateCode AND sm_stat.LangId = 1036
LEFT JOIN dbo.StringMap AS sm_type
    ON sm_type.ObjectTypeCode = 4210 AND sm_type.AttributeName = 'grdf_type'
    AND sm_type.AttributeValue = pc.grdf_type AND sm_type.LangId = 1036
LEFT JOIN dbo.StringMap AS sm_prio
    ON sm_prio.ObjectTypeCode = 4210 AND sm_prio.AttributeName = 'prioritycode'
    AND sm_prio.AttributeValue = pc.PriorityCode AND sm_prio.LangId = 1036

WHERE pc.CreatedOn >= '2023-01-01'

GROUP BY
    pc.ActivityId,
    pc.Subject,
    pc.OwnerIdName,
    pc.Description,
    pc.RegardingObjectId,
    pc.RegardingObjectTypeCode,
    pc.RegardingObjectIdName,
    pc.DirectionCode,
    pc.ScheduledStart,
    pc.grdf_thematique,
    pc.grdf_type;
