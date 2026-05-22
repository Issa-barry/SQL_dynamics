SELECT
    pc.ActivityId,
    pc.Subject                          AS Libelle,
    pc.OwnerIdName                      AS Proprietaire,
    pc.Description,

    -- Concernant : Nom | Prénom | Fonction
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
        (
            SELECT a.Name FROM dbo.Account AS a
            WHERE a.AccountId = pc.RegardingObjectId
        )
        WHEN pc.RegardingObjectTypeCode = 3 THEN
        (
            SELECT o.Name FROM dbo.Opportunity AS o
            WHERE o.OpportunityId = pc.RegardingObjectId
        )
        WHEN pc.RegardingObjectTypeCode = 4 THEN
        (
            SELECT l.Subject FROM dbo.Lead AS l
            WHERE l.LeadId = pc.RegardingObjectId
        )
        WHEN pc.RegardingObjectTypeCode = 4402 THEN
        (
            SELECT ca.Subject FROM dbo.CampaignActivity AS ca
            WHERE ca.ActivityId = pc.RegardingObjectId
        )
        WHEN pc.RegardingObjectTypeCode = 10118 THEN
        (
            SELECT ct.grdf_name FROM dbo.grdf_contrat AS ct
            WHERE ct.grdf_contratId = pc.RegardingObjectId
        )
        WHEN pc.RegardingObjectTypeCode = 10121 THEN
        (
            SELECT loc.grdf_nom FROM dbo.grdf_local AS loc
            WHERE loc.grdf_localid = pc.RegardingObjectId
        )
        ELSE pc.RegardingObjectIdName
    END                                 AS Concernant,

    -- Compte rattaché au concernant
    CASE
        WHEN pc.RegardingObjectTypeCode = 1 THEN NULL
        WHEN pc.RegardingObjectTypeCode = 2 THEN
        (
            SELECT a.Name FROM dbo.Contact AS c
            INNER JOIN dbo.Account AS a ON a.AccountId = c.AccountId
            WHERE c.ContactId = pc.RegardingObjectId
        )
        WHEN pc.RegardingObjectTypeCode = 3 THEN
        (
            SELECT a.Name FROM dbo.Opportunity AS o
            INNER JOIN dbo.Account AS a ON a.AccountId = o.AccountId
            WHERE o.OpportunityId = pc.RegardingObjectId
        )
        WHEN pc.RegardingObjectTypeCode = 4 THEN
        (
            SELECT a.Name FROM dbo.Lead AS l
            INNER JOIN dbo.Account AS a ON a.AccountId = l.ParentAccountId
            WHERE l.LeadId = pc.RegardingObjectId
        )
        WHEN pc.RegardingObjectTypeCode = 4402 THEN
        (
            SELECT c.Name FROM dbo.CampaignActivity AS ca
            INNER JOIN dbo.Campaign AS c ON c.CampaignId = ca.RegardingObjectId
            WHERE ca.ActivityId = pc.RegardingObjectId
        )
        WHEN pc.RegardingObjectTypeCode = 10118 THEN
        (
            SELECT a.Name FROM dbo.grdf_contrat AS ct
            INNER JOIN dbo.Account AS a ON a.AccountId = ct.grdf_Compte
            WHERE ct.grdf_contratId = pc.RegardingObjectId
        )
        WHEN pc.RegardingObjectTypeCode = 10121 THEN
        (
            SELECT a.Name FROM dbo.grdf_local AS loc
            INNER JOIN dbo.Account AS a ON a.AccountId = loc.grdf_compteid
            WHERE loc.grdf_localid = pc.RegardingObjectId
        )
        ELSE NULL
    END                                 AS CompteRattache,

    -- Type du concernant
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

    -- Référence compte (préfixe ' pour forcer texte dans Excel)
    CASE
        WHEN pc.RegardingObjectTypeCode = 1 THEN
            (SELECT '''' + ISNULL(CAST(a.grdf_reference AS NVARCHAR(50)), '') FROM dbo.Account AS a WHERE a.AccountId = pc.RegardingObjectId)
        WHEN pc.RegardingObjectTypeCode = 2 THEN
            (SELECT '''' + ISNULL(CAST(a.grdf_reference AS NVARCHAR(50)), '') FROM dbo.Contact AS c INNER JOIN dbo.Account AS a ON a.AccountId = c.AccountId WHERE c.ContactId = pc.RegardingObjectId)
        WHEN pc.RegardingObjectTypeCode = 3 THEN
            (SELECT '''' + ISNULL(CAST(a.grdf_reference AS NVARCHAR(50)), '') FROM dbo.Opportunity AS o INNER JOIN dbo.Account AS a ON a.AccountId = o.AccountId WHERE o.OpportunityId = pc.RegardingObjectId)
        WHEN pc.RegardingObjectTypeCode = 4 THEN
            (SELECT '''' + ISNULL(CAST(a.grdf_reference AS NVARCHAR(50)), '') FROM dbo.Lead AS l INNER JOIN dbo.Account AS a ON a.AccountId = l.ParentAccountId WHERE l.LeadId = pc.RegardingObjectId)
        WHEN pc.RegardingObjectTypeCode = 10118 THEN
            (SELECT '''' + ISNULL(CAST(a.grdf_reference AS NVARCHAR(50)), '') FROM dbo.grdf_contrat AS ct INNER JOIN dbo.Account AS a ON a.AccountId = ct.grdf_Compte WHERE ct.grdf_contratId = pc.RegardingObjectId)
        WHEN pc.RegardingObjectTypeCode = 10121 THEN
            (SELECT '''' + ISNULL(CAST(a.grdf_reference AS NVARCHAR(50)), '') FROM dbo.grdf_local AS loc INNER JOIN dbo.Account AS a ON a.AccountId = loc.grdf_compteid WHERE loc.grdf_localid = pc.RegardingObjectId)
        ELSE NULL
    END                                 AS RefCompte,

    -- Référence Atout Prisca
    CASE
        WHEN pc.RegardingObjectTypeCode = 1 THEN
            (SELECT a.grdf_reference_atoutprisca FROM dbo.Account AS a WHERE a.AccountId = pc.RegardingObjectId)
        WHEN pc.RegardingObjectTypeCode = 2 THEN
            (SELECT a.grdf_reference_atoutprisca FROM dbo.Contact AS c INNER JOIN dbo.Account AS a ON a.AccountId = c.AccountId WHERE c.ContactId = pc.RegardingObjectId)
        WHEN pc.RegardingObjectTypeCode = 3 THEN
            (SELECT a.grdf_reference_atoutprisca FROM dbo.Opportunity AS o INNER JOIN dbo.Account AS a ON a.AccountId = o.AccountId WHERE o.OpportunityId = pc.RegardingObjectId)
        WHEN pc.RegardingObjectTypeCode = 4 THEN
            (SELECT a.grdf_reference_atoutprisca FROM dbo.Lead AS l INNER JOIN dbo.Account AS a ON a.AccountId = l.ParentAccountId WHERE l.LeadId = pc.RegardingObjectId)
        WHEN pc.RegardingObjectTypeCode = 10118 THEN
            (SELECT a.grdf_reference_atoutprisca FROM dbo.grdf_contrat AS ct INNER JOIN dbo.Account AS a ON a.AccountId = ct.grdf_Compte WHERE ct.grdf_contratId = pc.RegardingObjectId)
        WHEN pc.RegardingObjectTypeCode = 10121 THEN
            (SELECT a.grdf_reference_atoutprisca FROM dbo.grdf_local AS loc INNER JOIN dbo.Account AS a ON a.AccountId = loc.grdf_compteid WHERE loc.grdf_localid = pc.RegardingObjectId)
        ELSE NULL
    END                                 AS RefAtoutPrisca,

    -- Code INSEE (préfixe ' pour forcer texte dans Excel)
    CASE
        WHEN pc.RegardingObjectTypeCode = 1 THEN
            (SELECT '''' + RIGHT('00000' + ISNULL(CAST(a.grdf_code_insee AS NVARCHAR(5)), ''), 5) FROM dbo.Account AS a WHERE a.AccountId = pc.RegardingObjectId)
        WHEN pc.RegardingObjectTypeCode = 2 THEN
            (SELECT '''' + RIGHT('00000' + ISNULL(CAST(a.grdf_code_insee AS NVARCHAR(5)), ''), 5) FROM dbo.Contact AS c INNER JOIN dbo.Account AS a ON a.AccountId = c.AccountId WHERE c.ContactId = pc.RegardingObjectId)
        WHEN pc.RegardingObjectTypeCode = 3 THEN
            (SELECT '''' + RIGHT('00000' + ISNULL(CAST(a.grdf_code_insee AS NVARCHAR(5)), ''), 5) FROM dbo.Opportunity AS o INNER JOIN dbo.Account AS a ON a.AccountId = o.AccountId WHERE o.OpportunityId = pc.RegardingObjectId)
        WHEN pc.RegardingObjectTypeCode = 4 THEN
            (SELECT '''' + RIGHT('00000' + ISNULL(CAST(a.grdf_code_insee AS NVARCHAR(5)), ''), 5) FROM dbo.Lead AS l INNER JOIN dbo.Account AS a ON a.AccountId = l.ParentAccountId WHERE l.LeadId = pc.RegardingObjectId)
        WHEN pc.RegardingObjectTypeCode = 10118 THEN
            (SELECT '''' + RIGHT('00000' + ISNULL(CAST(a.grdf_code_insee AS NVARCHAR(5)), ''), 5) FROM dbo.grdf_contrat AS ct INNER JOIN dbo.Account AS a ON a.AccountId = ct.grdf_Compte WHERE ct.grdf_contratId = pc.RegardingObjectId)
        WHEN pc.RegardingObjectTypeCode = 10121 THEN
            (SELECT '''' + RIGHT('00000' + ISNULL(CAST(a.grdf_code_insee AS NVARCHAR(5)), ''), 5) FROM dbo.grdf_local AS loc INNER JOIN dbo.Account AS a ON a.AccountId = loc.grdf_compteid WHERE loc.grdf_localid = pc.RegardingObjectId)
        ELSE NULL
    END                                 AS CodeINSEE,

    -- Code SIRET (préfixe ' pour forcer texte dans Excel)
    CASE
        WHEN pc.RegardingObjectTypeCode = 1 THEN
            (SELECT '''' + RIGHT('00000000000000' + ISNULL(CAST(a.grdf_siret AS NVARCHAR(14)), ''), 14) FROM dbo.Account AS a WHERE a.AccountId = pc.RegardingObjectId)
        WHEN pc.RegardingObjectTypeCode = 2 THEN
            (SELECT '''' + RIGHT('00000000000000' + ISNULL(CAST(a.grdf_siret AS NVARCHAR(14)), ''), 14) FROM dbo.Contact AS c INNER JOIN dbo.Account AS a ON a.AccountId = c.AccountId WHERE c.ContactId = pc.RegardingObjectId)
        WHEN pc.RegardingObjectTypeCode = 3 THEN
            (SELECT '''' + RIGHT('00000000000000' + ISNULL(CAST(a.grdf_siret AS NVARCHAR(14)), ''), 14) FROM dbo.Opportunity AS o INNER JOIN dbo.Account AS a ON a.AccountId = o.AccountId WHERE o.OpportunityId = pc.RegardingObjectId)
        WHEN pc.RegardingObjectTypeCode = 4 THEN
            (SELECT '''' + RIGHT('00000000000000' + ISNULL(CAST(a.grdf_siret AS NVARCHAR(14)), ''), 14) FROM dbo.Lead AS l INNER JOIN dbo.Account AS a ON a.AccountId = l.ParentAccountId WHERE l.LeadId = pc.RegardingObjectId)
        WHEN pc.RegardingObjectTypeCode = 10118 THEN
            (SELECT '''' + RIGHT('00000000000000' + ISNULL(CAST(a.grdf_siret AS NVARCHAR(14)), ''), 14) FROM dbo.grdf_contrat AS ct INNER JOIN dbo.Account AS a ON a.AccountId = ct.grdf_Compte WHERE ct.grdf_contratId = pc.RegardingObjectId)
        WHEN pc.RegardingObjectTypeCode = 10121 THEN
            (SELECT '''' + RIGHT('00000000000000' + ISNULL(CAST(a.grdf_siret AS NVARCHAR(14)), ''), 14) FROM dbo.grdf_local AS loc INNER JOIN dbo.Account AS a ON a.AccountId = loc.grdf_compteid WHERE loc.grdf_localid = pc.RegardingObjectId)
        ELSE NULL
    END                                 AS CodeSIRET,

    -- Code SIREN (préfixe ' pour forcer texte dans Excel)
    CASE
        WHEN pc.RegardingObjectTypeCode = 1 THEN
            (SELECT '''' + RIGHT('000000000' + ISNULL(LEFT(CAST(a.grdf_siret AS NVARCHAR(14)), 9), ''), 9) FROM dbo.Account AS a WHERE a.AccountId = pc.RegardingObjectId)
        WHEN pc.RegardingObjectTypeCode = 2 THEN
            (SELECT '''' + RIGHT('000000000' + ISNULL(LEFT(CAST(a.grdf_siret AS NVARCHAR(14)), 9), ''), 9) FROM dbo.Contact AS c INNER JOIN dbo.Account AS a ON a.AccountId = c.AccountId WHERE c.ContactId = pc.RegardingObjectId)
        WHEN pc.RegardingObjectTypeCode = 3 THEN
            (SELECT '''' + RIGHT('000000000' + ISNULL(LEFT(CAST(a.grdf_siret AS NVARCHAR(14)), 9), ''), 9) FROM dbo.Opportunity AS o INNER JOIN dbo.Account AS a ON a.AccountId = o.AccountId WHERE o.OpportunityId = pc.RegardingObjectId)
        WHEN pc.RegardingObjectTypeCode = 4 THEN
            (SELECT '''' + RIGHT('000000000' + ISNULL(LEFT(CAST(a.grdf_siret AS NVARCHAR(14)), 9), ''), 9) FROM dbo.Lead AS l INNER JOIN dbo.Account AS a ON a.AccountId = l.ParentAccountId WHERE l.LeadId = pc.RegardingObjectId)
        WHEN pc.RegardingObjectTypeCode = 10118 THEN
            (SELECT '''' + RIGHT('000000000' + ISNULL(LEFT(CAST(a.grdf_siret AS NVARCHAR(14)), 9), ''), 9) FROM dbo.grdf_contrat AS ct INNER JOIN dbo.Account AS a ON a.AccountId = ct.grdf_Compte WHERE ct.grdf_contratId = pc.RegardingObjectId)
        WHEN pc.RegardingObjectTypeCode = 10121 THEN
            (SELECT '''' + RIGHT('000000000' + ISNULL(LEFT(CAST(a.grdf_siret AS NVARCHAR(14)), 9), ''), 9) FROM dbo.grdf_local AS loc INNER JOIN dbo.Account AS a ON a.AccountId = loc.grdf_compteid WHERE loc.grdf_localid = pc.RegardingObjectId)
        ELSE NULL
    END                                 AS CodeSIREN,

    -- Direction (Entrant/Sortant)
    CASE WHEN pc.DirectionCode = 1
         THEN 'Sortant'
         ELSE 'Entrant'
    END                                 AS Direction,

    -- Origine de l'appel (mask = 1) — format : Nom | Prénom | Fonction | HATVP
    (
        SELECT STRING_AGG(
            CAST(
                ISNULL(c.LastName,  ap.PartyIdName) + ' | ' +
                ISNULL(c.FirstName, '-')             + ' | ' +
                ISNULL(sm_fonc.Value, '-')           + ' | ' +
                CASE WHEN c.grdf_hatvp = 1 THEN 'Oui' ELSE 'Non' END
            AS NVARCHAR(MAX)), ' ; ')
            WITHIN GROUP (ORDER BY ap.PartyIdName)
        FROM dbo.ActivityParty AS ap
        LEFT JOIN dbo.Contact AS c
            ON  c.ContactId            = ap.PartyId
        LEFT JOIN dbo.StringMap AS sm_fonc
            ON  sm_fonc.ObjectTypeCode = 2
            AND sm_fonc.AttributeName  = 'grdf_fonction'
            AND sm_fonc.AttributeValue = c.grdf_fonction
            AND sm_fonc.LangId         = 1036
        WHERE ap.ActivityId            = pc.ActivityId
          AND ap.ParticipationTypeMask = 1
          AND ap.IsPartyDeleted        = 0
    )                                   AS OrigineAppel,

    -- Destination de l'appel (mask = 2) — format : Nom | Prénom | Fonction | HATVP
    (
        SELECT STRING_AGG(
            CAST(
                ISNULL(c.LastName,  ap.PartyIdName) + ' | ' +
                ISNULL(c.FirstName, '-')             + ' | ' +
                ISNULL(sm_fonc.Value, '-')           + ' | ' +
                CASE WHEN c.grdf_hatvp = 1 THEN 'Oui' ELSE 'Non' END
            AS NVARCHAR(MAX)), ' ; ')
            WITHIN GROUP (ORDER BY ap.PartyIdName)
        FROM dbo.ActivityParty AS ap
        LEFT JOIN dbo.Contact AS c
            ON  c.ContactId            = ap.PartyId
        LEFT JOIN dbo.StringMap AS sm_fonc
            ON  sm_fonc.ObjectTypeCode = 2
            AND sm_fonc.AttributeName  = 'grdf_fonction'
            AND sm_fonc.AttributeValue = c.grdf_fonction
            AND sm_fonc.LangId         = 1036
        WHERE ap.ActivityId            = pc.ActivityId
          AND ap.ParticipationTypeMask = 2
          AND ap.IsPartyDeleted        = 0
    )                                   AS DestinationAppel,

    -- Nombre d'interlocuteurs HATVP
    (
        SELECT COUNT(DISTINCT contact_hatvp.ContactId)
        FROM (
            -- Contacts HATVP en origine (mask = 1)
            SELECT c.ContactId
            FROM dbo.ActivityParty AS ap
            INNER JOIN dbo.Contact AS c
                ON  c.ContactId            = ap.PartyId
                AND c.grdf_hatvp           = 1
            WHERE ap.ActivityId            = pc.ActivityId
              AND ap.ParticipationTypeMask = 1
              AND ap.IsPartyDeleted        = 0
            UNION
            -- Contacts HATVP en destination (mask = 2)
            SELECT c.ContactId
            FROM dbo.ActivityParty AS ap
            INNER JOIN dbo.Contact AS c
                ON  c.ContactId            = ap.PartyId
                AND c.grdf_hatvp           = 1
            WHERE ap.ActivityId            = pc.ActivityId
              AND ap.ParticipationTypeMask = 2
              AND ap.IsPartyDeleted        = 0
            UNION
            -- Concernant direct si contact HATVP
            SELECT c.ContactId
            FROM dbo.Contact AS c
            WHERE c.ContactId              = pc.RegardingObjectId
              AND c.grdf_hatvp             = 1
              AND pc.RegardingObjectTypeCode = 2
        ) AS contact_hatvp
    )                                   AS NbInterlocuteursHATV,

    -- Date planifiée (UTC → Europe/Paris)
    CONVERT(DATE,
        pc.ScheduledStart
            AT TIME ZONE 'UTC'
            AT TIME ZONE 'Romance Standard Time'
    )                                   AS Date_Appel,

    MAX(sm_stat.Value)                  AS Statut,
    MAX(sm_type.Value)                  AS grdf_Type,
    MAX(sm_prio.Value)                  AS Priorite,

    -- Thématiques (multi-valeur)
    (
        SELECT STRING_AGG(CAST(sm_them.Value AS NVARCHAR(MAX)), ', ')
            WITHIN GROUP (ORDER BY sm_them.Value)
        FROM dbo.StringMap AS sm_them
        WHERE sm_them.ObjectTypeCode    = 4210
          AND sm_them.AttributeName     = 'grdf_thematique'
          AND CHARINDEX(
                CAST(sm_them.AttributeValue AS VARCHAR(20)),
                pc.grdf_thematique
              ) > 0
          AND sm_them.LangId            = 1036
    )                                   AS Thematiques

FROM dbo.PhoneCall AS pc

LEFT JOIN dbo.StringMap AS sm_stat
    ON  sm_stat.ObjectTypeCode  = 4210
    AND sm_stat.AttributeName   = 'statecode'
    AND sm_stat.AttributeValue  = pc.StateCode
    AND sm_stat.LangId          = 1036
LEFT JOIN dbo.StringMap AS sm_type
    ON  sm_type.ObjectTypeCode  = 4210
    AND sm_type.AttributeName   = 'grdf_type'
    AND sm_type.AttributeValue  = pc.grdf_type
    AND sm_type.LangId          = 1036
LEFT JOIN dbo.StringMap AS sm_prio
    ON  sm_prio.ObjectTypeCode  = 4210
    AND sm_prio.AttributeName   = 'prioritycode'
    AND sm_prio.AttributeValue  = pc.PriorityCode
    AND sm_prio.LangId          = 1036

WHERE pc.CreatedOn >= '2023-01-01'
  AND (
        EXISTS (
            SELECT 1
            FROM dbo.ActivityParty AS ap
            INNER JOIN dbo.Contact AS c
                ON  c.ContactId            = ap.PartyId
                AND c.grdf_hatvp           = 1
            WHERE ap.ActivityId            = pc.ActivityId
              AND ap.ParticipationTypeMask = 1
              AND ap.IsPartyDeleted        = 0
        )
        OR
        EXISTS (
            SELECT 1
            FROM dbo.ActivityParty AS ap
            INNER JOIN dbo.Contact AS c
                ON  c.ContactId            = ap.PartyId
                AND c.grdf_hatvp           = 1
            WHERE ap.ActivityId            = pc.ActivityId
              AND ap.ParticipationTypeMask = 2
              AND ap.IsPartyDeleted        = 0
        )
      )
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
    pc.grdf_type
