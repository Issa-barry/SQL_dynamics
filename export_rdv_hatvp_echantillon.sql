SELECT
    app.ActivityId,
    app.grdf_hatvp                      AS RDV_hatvp,
    app.Subject                         AS Libelle,
    app.Description,
    -- Concernant : Nom | Prénom | Fonction
    CASE
        WHEN app.RegardingObjectTypeCode = 2 THEN
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
            WHERE c.ContactId = app.RegardingObjectId
        )
        WHEN app.RegardingObjectTypeCode = 1 THEN
            (SELECT a.Name FROM dbo.Account AS a WHERE a.AccountId = app.RegardingObjectId)
        WHEN app.RegardingObjectTypeCode = 3 THEN
            (SELECT o.Name FROM dbo.Opportunity AS o WHERE o.OpportunityId = app.RegardingObjectId)
        WHEN app.RegardingObjectTypeCode = 4 THEN
            (SELECT l.Subject FROM dbo.Lead AS l WHERE l.LeadId = app.RegardingObjectId)
        WHEN app.RegardingObjectTypeCode = 4402 THEN
            (SELECT ca.Subject FROM dbo.CampaignActivity AS ca WHERE ca.ActivityId = app.RegardingObjectId)
        WHEN app.RegardingObjectTypeCode = 10118 THEN
            (SELECT ct.grdf_name FROM dbo.grdf_contrat AS ct WHERE ct.grdf_contratId = app.RegardingObjectId)
        WHEN app.RegardingObjectTypeCode = 10121 THEN
            (SELECT loc.grdf_nom FROM dbo.grdf_local AS loc WHERE loc.grdf_localid = app.RegardingObjectId)
        ELSE app.RegardingObjectIdName
    END                                 AS Concernant,
    -- Compte / Campagne rattaché(e)
    CASE
        WHEN app.RegardingObjectTypeCode = 1 THEN
            (SELECT a.Name FROM dbo.Account AS a WHERE a.AccountId = app.RegardingObjectId)
        WHEN app.RegardingObjectTypeCode = 2 THEN
            (SELECT a.Name FROM dbo.Contact AS c INNER JOIN dbo.Account AS a ON a.AccountId = c.AccountId WHERE c.ContactId = app.RegardingObjectId)
        WHEN app.RegardingObjectTypeCode = 3 THEN
            (SELECT a.Name FROM dbo.Opportunity AS o INNER JOIN dbo.Account AS a ON a.AccountId = o.AccountId WHERE o.OpportunityId = app.RegardingObjectId)
        WHEN app.RegardingObjectTypeCode = 4 THEN
            (SELECT a.Name FROM dbo.Lead AS l INNER JOIN dbo.Account AS a ON a.AccountId = l.ParentAccountId WHERE l.LeadId = app.RegardingObjectId)
        WHEN app.RegardingObjectTypeCode = 4402 THEN
            (SELECT c.Name FROM dbo.CampaignActivity AS ca INNER JOIN dbo.Campaign AS c ON c.CampaignId = ca.RegardingObjectId WHERE ca.ActivityId = app.RegardingObjectId)
        WHEN app.RegardingObjectTypeCode = 10118 THEN
            (SELECT a.Name FROM dbo.grdf_contrat AS ct INNER JOIN dbo.Account AS a ON a.AccountId = ct.grdf_Compte WHERE ct.grdf_contratId = app.RegardingObjectId)
        WHEN app.RegardingObjectTypeCode = 10121 THEN
            (SELECT a.Name FROM dbo.grdf_local AS loc INNER JOIN dbo.Account AS a ON a.AccountId = loc.grdf_compteid WHERE loc.grdf_localid = app.RegardingObjectId)
        ELSE NULL
    END                                 AS [Compte / Campagne rattaché(e)],
    -- Type du concernant
    CASE
        WHEN app.RegardingObjectTypeCode = 2     THEN 'Contact'
        WHEN app.RegardingObjectTypeCode = 1     THEN 'Compte'
        WHEN app.RegardingObjectTypeCode = 3     THEN 'Projet'
        WHEN app.RegardingObjectTypeCode = 4     THEN 'Lead'
        WHEN app.RegardingObjectTypeCode = 4400  THEN 'Campagne'
        WHEN app.RegardingObjectTypeCode = 4402  THEN 'Activité de campagne'
        WHEN app.RegardingObjectTypeCode = 10118 THEN 'Contrat'
        WHEN app.RegardingObjectTypeCode = 10121 THEN 'Local'
        ELSE CAST(app.RegardingObjectTypeCode AS NVARCHAR(50))
    END                                 AS TypeConcernant,
    -- Référence compte
    CASE
        WHEN app.RegardingObjectTypeCode = 1 THEN
            (SELECT '''' + ISNULL(CAST(a.grdf_reference AS NVARCHAR(50)), '') FROM dbo.Account AS a WHERE a.AccountId = app.RegardingObjectId)
        WHEN app.RegardingObjectTypeCode = 2 THEN
            (SELECT '''' + ISNULL(CAST(a.grdf_reference AS NVARCHAR(50)), '') FROM dbo.Contact AS c INNER JOIN dbo.Account AS a ON a.AccountId = c.AccountId WHERE c.ContactId = app.RegardingObjectId)
        WHEN app.RegardingObjectTypeCode = 3 THEN
            (SELECT '''' + ISNULL(CAST(a.grdf_reference AS NVARCHAR(50)), '') FROM dbo.Opportunity AS o INNER JOIN dbo.Account AS a ON a.AccountId = o.AccountId WHERE o.OpportunityId = app.RegardingObjectId)
        WHEN app.RegardingObjectTypeCode = 4 THEN
            (SELECT '''' + ISNULL(CAST(a.grdf_reference AS NVARCHAR(50)), '') FROM dbo.Lead AS l INNER JOIN dbo.Account AS a ON a.AccountId = l.ParentAccountId WHERE l.LeadId = app.RegardingObjectId)
        WHEN app.RegardingObjectTypeCode = 10118 THEN
            (SELECT '''' + ISNULL(CAST(a.grdf_reference AS NVARCHAR(50)), '') FROM dbo.grdf_contrat AS ct INNER JOIN dbo.Account AS a ON a.AccountId = ct.grdf_Compte WHERE ct.grdf_contratId = app.RegardingObjectId)
        WHEN app.RegardingObjectTypeCode = 10121 THEN
            (SELECT '''' + ISNULL(CAST(a.grdf_reference AS NVARCHAR(50)), '') FROM dbo.grdf_local AS loc INNER JOIN dbo.Account AS a ON a.AccountId = loc.grdf_compteid WHERE loc.grdf_localid = app.RegardingObjectId)
        ELSE NULL
    END                                 AS RefCompte,
    -- Référence Atout Prisca
    CASE
        WHEN app.RegardingObjectTypeCode = 1 THEN
            (SELECT a.grdf_reference_atoutprisca FROM dbo.Account AS a WHERE a.AccountId = app.RegardingObjectId)
        WHEN app.RegardingObjectTypeCode = 2 THEN
            (SELECT a.grdf_reference_atoutprisca FROM dbo.Contact AS c INNER JOIN dbo.Account AS a ON a.AccountId = c.AccountId WHERE c.ContactId = app.RegardingObjectId)
        WHEN app.RegardingObjectTypeCode = 3 THEN
            (SELECT a.grdf_reference_atoutprisca FROM dbo.Opportunity AS o INNER JOIN dbo.Account AS a ON a.AccountId = o.AccountId WHERE o.OpportunityId = app.RegardingObjectId)
        WHEN app.RegardingObjectTypeCode = 4 THEN
            (SELECT a.grdf_reference_atoutprisca FROM dbo.Lead AS l INNER JOIN dbo.Account AS a ON a.AccountId = l.ParentAccountId WHERE l.LeadId = app.RegardingObjectId)
        WHEN app.RegardingObjectTypeCode = 10118 THEN
            (SELECT a.grdf_reference_atoutprisca FROM dbo.grdf_contrat AS ct INNER JOIN dbo.Account AS a ON a.AccountId = ct.grdf_Compte WHERE ct.grdf_contratId = app.RegardingObjectId)
        WHEN app.RegardingObjectTypeCode = 10121 THEN
            (SELECT a.grdf_reference_atoutprisca FROM dbo.grdf_local AS loc INNER JOIN dbo.Account AS a ON a.AccountId = loc.grdf_compteid WHERE loc.grdf_localid = app.RegardingObjectId)
        ELSE NULL
    END                                 AS RefAtoutPrisca,
    -- Code INSEE
    CASE
        WHEN app.RegardingObjectTypeCode = 1 THEN
            (SELECT '''' + RIGHT('00000' + ISNULL(CAST(a.grdf_code_insee AS NVARCHAR(5)), ''), 5) FROM dbo.Account AS a WHERE a.AccountId = app.RegardingObjectId)
        WHEN app.RegardingObjectTypeCode = 2 THEN
            (SELECT '''' + RIGHT('00000' + ISNULL(CAST(a.grdf_code_insee AS NVARCHAR(5)), ''), 5) FROM dbo.Contact AS c INNER JOIN dbo.Account AS a ON a.AccountId = c.AccountId WHERE c.ContactId = app.RegardingObjectId)
        WHEN app.RegardingObjectTypeCode = 3 THEN
            (SELECT '''' + RIGHT('00000' + ISNULL(CAST(a.grdf_code_insee AS NVARCHAR(5)), ''), 5) FROM dbo.Opportunity AS o INNER JOIN dbo.Account AS a ON a.AccountId = o.AccountId WHERE o.OpportunityId = app.RegardingObjectId)
        WHEN app.RegardingObjectTypeCode = 4 THEN
            (SELECT '''' + RIGHT('00000' + ISNULL(CAST(a.grdf_code_insee AS NVARCHAR(5)), ''), 5) FROM dbo.Lead AS l INNER JOIN dbo.Account AS a ON a.AccountId = l.ParentAccountId WHERE l.LeadId = app.RegardingObjectId)
        WHEN app.RegardingObjectTypeCode = 10118 THEN
            (SELECT '''' + RIGHT('00000' + ISNULL(CAST(a.grdf_code_insee AS NVARCHAR(5)), ''), 5) FROM dbo.grdf_contrat AS ct INNER JOIN dbo.Account AS a ON a.AccountId = ct.grdf_Compte WHERE ct.grdf_contratId = app.RegardingObjectId)
        WHEN app.RegardingObjectTypeCode = 10121 THEN
            (SELECT '''' + RIGHT('00000' + ISNULL(CAST(a.grdf_code_insee AS NVARCHAR(5)), ''), 5) FROM dbo.grdf_local AS loc INNER JOIN dbo.Account AS a ON a.AccountId = loc.grdf_compteid WHERE loc.grdf_localid = app.RegardingObjectId)
        ELSE NULL
    END                                 AS CodeINSEE,
    -- Code SIRET
    CASE
        WHEN app.RegardingObjectTypeCode = 1 THEN
            (SELECT '''' + RIGHT('00000000000000' + ISNULL(CAST(a.grdf_siret AS NVARCHAR(14)), ''), 14) FROM dbo.Account AS a WHERE a.AccountId = app.RegardingObjectId)
        WHEN app.RegardingObjectTypeCode = 2 THEN
            (SELECT '''' + RIGHT('00000000000000' + ISNULL(CAST(a.grdf_siret AS NVARCHAR(14)), ''), 14) FROM dbo.Contact AS c INNER JOIN dbo.Account AS a ON a.AccountId = c.AccountId WHERE c.ContactId = app.RegardingObjectId)
        WHEN app.RegardingObjectTypeCode = 3 THEN
            (SELECT '''' + RIGHT('00000000000000' + ISNULL(CAST(a.grdf_siret AS NVARCHAR(14)), ''), 14) FROM dbo.Opportunity AS o INNER JOIN dbo.Account AS a ON a.AccountId = o.AccountId WHERE o.OpportunityId = app.RegardingObjectId)
        WHEN app.RegardingObjectTypeCode = 4 THEN
            (SELECT '''' + RIGHT('00000000000000' + ISNULL(CAST(a.grdf_siret AS NVARCHAR(14)), ''), 14) FROM dbo.Lead AS l INNER JOIN dbo.Account AS a ON a.AccountId = l.ParentAccountId WHERE l.LeadId = app.RegardingObjectId)
        WHEN app.RegardingObjectTypeCode = 10118 THEN
            (SELECT '''' + RIGHT('00000000000000' + ISNULL(CAST(a.grdf_siret AS NVARCHAR(14)), ''), 14) FROM dbo.grdf_contrat AS ct INNER JOIN dbo.Account AS a ON a.AccountId = ct.grdf_Compte WHERE ct.grdf_contratId = app.RegardingObjectId)
        WHEN app.RegardingObjectTypeCode = 10121 THEN
            (SELECT '''' + RIGHT('00000000000000' + ISNULL(CAST(a.grdf_siret AS NVARCHAR(14)), ''), 14) FROM dbo.grdf_local AS loc INNER JOIN dbo.Account AS a ON a.AccountId = loc.grdf_compteid WHERE loc.grdf_localid = app.RegardingObjectId)
        ELSE NULL
    END                                 AS CodeSIRET,
    -- Code SIREN
    CASE
        WHEN app.RegardingObjectTypeCode = 1 THEN
            (SELECT '''' + RIGHT('000000000' + ISNULL(LEFT(CAST(a.grdf_siret AS NVARCHAR(14)), 9), ''), 9) FROM dbo.Account AS a WHERE a.AccountId = app.RegardingObjectId)
        WHEN app.RegardingObjectTypeCode = 2 THEN
            (SELECT '''' + RIGHT('000000000' + ISNULL(LEFT(CAST(a.grdf_siret AS NVARCHAR(14)), 9), ''), 9) FROM dbo.Contact AS c INNER JOIN dbo.Account AS a ON a.AccountId = c.AccountId WHERE c.ContactId = app.RegardingObjectId)
        WHEN app.RegardingObjectTypeCode = 3 THEN
            (SELECT '''' + RIGHT('000000000' + ISNULL(LEFT(CAST(a.grdf_siret AS NVARCHAR(14)), 9), ''), 9) FROM dbo.Opportunity AS o INNER JOIN dbo.Account AS a ON a.AccountId = o.AccountId WHERE o.OpportunityId = app.RegardingObjectId)
        WHEN app.RegardingObjectTypeCode = 4 THEN
            (SELECT '''' + RIGHT('000000000' + ISNULL(LEFT(CAST(a.grdf_siret AS NVARCHAR(14)), 9), ''), 9) FROM dbo.Lead AS l INNER JOIN dbo.Account AS a ON a.AccountId = l.ParentAccountId WHERE l.LeadId = app.RegardingObjectId)
        WHEN app.RegardingObjectTypeCode = 10118 THEN
            (SELECT '''' + RIGHT('000000000' + ISNULL(LEFT(CAST(a.grdf_siret AS NVARCHAR(14)), 9), ''), 9) FROM dbo.grdf_contrat AS ct INNER JOIN dbo.Account AS a ON a.AccountId = ct.grdf_Compte WHERE ct.grdf_contratId = app.RegardingObjectId)
        WHEN app.RegardingObjectTypeCode = 10121 THEN
            (SELECT '''' + RIGHT('000000000' + ISNULL(LEFT(CAST(a.grdf_siret AS NVARCHAR(14)), 9), ''), 9) FROM dbo.grdf_local AS loc INNER JOIN dbo.Account AS a ON a.AccountId = loc.grdf_compteid WHERE loc.grdf_localid = app.RegardingObjectId)
        ELSE NULL
    END                                 AS CodeSIREN,
    MAX(sm_empl.Value)                  AS grdf_emplacement,
    app.Location                        AS Lieu,
    MAX(sm_stat.Value)                  AS Statut,
    app.OwnerIdName                     AS Proprietaire,

    -- =========================================================
    -- Participants internes : 5 colonnes Nom + 5 colonnes MAIA
    -- =========================================================

    -- Participant_Interne_1
    (
        SELECT ISNULL(pi.FirstName, '') + ' ' + ISNULL(pi.LastName, '')
        FROM (
            SELECT
                CASE WHEN ap.PartyObjectTypeCode = 8 THEN su.FirstName ELSE c.FirstName END AS FirstName,
                CASE WHEN ap.PartyObjectTypeCode = 8 THEN su.LastName  ELSE c.LastName  END AS LastName,
                ROW_NUMBER() OVER (ORDER BY
                    CASE WHEN ap.PartyObjectTypeCode = 8 THEN su.LastName  ELSE c.LastName  END,
                    CASE WHEN ap.PartyObjectTypeCode = 8 THEN su.FirstName ELSE c.FirstName END) AS rn
            FROM dbo.ActivityParty AS ap
            LEFT JOIN dbo.Contact    AS c  ON c.ContactId    = ap.PartyId AND ap.PartyObjectTypeCode = 2
            LEFT JOIN dbo.SystemUser AS su ON su.SystemUserId = ap.PartyId AND ap.PartyObjectTypeCode = 8
            WHERE ap.ActivityId = app.ActivityId AND ap.ParticipationTypeMask IN (5,6) AND ap.IsPartyDeleted = 0
              AND (ap.PartyObjectTypeCode = 8 OR (ap.PartyObjectTypeCode = 2 AND c.EMailAddress1 LIKE '%@grdf.fr'))
        ) AS pi WHERE pi.rn = 1
    ) AS Participant_Interne_1,
    (
        SELECT ISNULL(RIGHT(su.DomainName, LEN(su.DomainName) - CHARINDEX('\', su.DomainName)), NULL)
        FROM (
            SELECT ap.PartyId, ap.PartyObjectTypeCode,
                ROW_NUMBER() OVER (ORDER BY
                    CASE WHEN ap.PartyObjectTypeCode = 8 THEN su2.LastName  ELSE c2.LastName  END,
                    CASE WHEN ap.PartyObjectTypeCode = 8 THEN su2.FirstName ELSE c2.FirstName END) AS rn
            FROM dbo.ActivityParty AS ap
            LEFT JOIN dbo.Contact    AS c2  ON c2.ContactId    = ap.PartyId AND ap.PartyObjectTypeCode = 2
            LEFT JOIN dbo.SystemUser AS su2 ON su2.SystemUserId = ap.PartyId AND ap.PartyObjectTypeCode = 8
            WHERE ap.ActivityId = app.ActivityId AND ap.ParticipationTypeMask IN (5,6) AND ap.IsPartyDeleted = 0
              AND (ap.PartyObjectTypeCode = 8 OR (ap.PartyObjectTypeCode = 2 AND c2.EMailAddress1 LIKE '%@grdf.fr'))
        ) AS ap
        INNER JOIN dbo.SystemUser AS su ON su.SystemUserId = ap.PartyId AND ap.PartyObjectTypeCode = 8
        WHERE ap.rn = 1
    ) AS MAIA_Participant_Interne_1,

    -- Participant_Interne_2
    (
        SELECT ISNULL(pi.FirstName, '') + ' ' + ISNULL(pi.LastName, '')
        FROM (
            SELECT
                CASE WHEN ap.PartyObjectTypeCode = 8 THEN su.FirstName ELSE c.FirstName END AS FirstName,
                CASE WHEN ap.PartyObjectTypeCode = 8 THEN su.LastName  ELSE c.LastName  END AS LastName,
                ROW_NUMBER() OVER (ORDER BY
                    CASE WHEN ap.PartyObjectTypeCode = 8 THEN su.LastName  ELSE c.LastName  END,
                    CASE WHEN ap.PartyObjectTypeCode = 8 THEN su.FirstName ELSE c.FirstName END) AS rn
            FROM dbo.ActivityParty AS ap
            LEFT JOIN dbo.Contact    AS c  ON c.ContactId    = ap.PartyId AND ap.PartyObjectTypeCode = 2
            LEFT JOIN dbo.SystemUser AS su ON su.SystemUserId = ap.PartyId AND ap.PartyObjectTypeCode = 8
            WHERE ap.ActivityId = app.ActivityId AND ap.ParticipationTypeMask IN (5,6) AND ap.IsPartyDeleted = 0
              AND (ap.PartyObjectTypeCode = 8 OR (ap.PartyObjectTypeCode = 2 AND c.EMailAddress1 LIKE '%@grdf.fr'))
        ) AS pi WHERE pi.rn = 2
    ) AS Participant_Interne_2,
    (
        SELECT ISNULL(RIGHT(su.DomainName, LEN(su.DomainName) - CHARINDEX('\', su.DomainName)), NULL)
        FROM (
            SELECT ap.PartyId, ap.PartyObjectTypeCode,
                ROW_NUMBER() OVER (ORDER BY
                    CASE WHEN ap.PartyObjectTypeCode = 8 THEN su2.LastName  ELSE c2.LastName  END,
                    CASE WHEN ap.PartyObjectTypeCode = 8 THEN su2.FirstName ELSE c2.FirstName END) AS rn
            FROM dbo.ActivityParty AS ap
            LEFT JOIN dbo.Contact    AS c2  ON c2.ContactId    = ap.PartyId AND ap.PartyObjectTypeCode = 2
            LEFT JOIN dbo.SystemUser AS su2 ON su2.SystemUserId = ap.PartyId AND ap.PartyObjectTypeCode = 8
            WHERE ap.ActivityId = app.ActivityId AND ap.ParticipationTypeMask IN (5,6) AND ap.IsPartyDeleted = 0
              AND (ap.PartyObjectTypeCode = 8 OR (ap.PartyObjectTypeCode = 2 AND c2.EMailAddress1 LIKE '%@grdf.fr'))
        ) AS ap
        INNER JOIN dbo.SystemUser AS su ON su.SystemUserId = ap.PartyId AND ap.PartyObjectTypeCode = 8
        WHERE ap.rn = 2
    ) AS MAIA_Participant_Interne_2,

    -- Participant_Interne_3
    (
        SELECT ISNULL(pi.FirstName, '') + ' ' + ISNULL(pi.LastName, '')
        FROM (
            SELECT
                CASE WHEN ap.PartyObjectTypeCode = 8 THEN su.FirstName ELSE c.FirstName END AS FirstName,
                CASE WHEN ap.PartyObjectTypeCode = 8 THEN su.LastName  ELSE c.LastName  END AS LastName,
                ROW_NUMBER() OVER (ORDER BY
                    CASE WHEN ap.PartyObjectTypeCode = 8 THEN su.LastName  ELSE c.LastName  END,
                    CASE WHEN ap.PartyObjectTypeCode = 8 THEN su.FirstName ELSE c.FirstName END) AS rn
            FROM dbo.ActivityParty AS ap
            LEFT JOIN dbo.Contact    AS c  ON c.ContactId    = ap.PartyId AND ap.PartyObjectTypeCode = 2
            LEFT JOIN dbo.SystemUser AS su ON su.SystemUserId = ap.PartyId AND ap.PartyObjectTypeCode = 8
            WHERE ap.ActivityId = app.ActivityId AND ap.ParticipationTypeMask IN (5,6) AND ap.IsPartyDeleted = 0
              AND (ap.PartyObjectTypeCode = 8 OR (ap.PartyObjectTypeCode = 2 AND c.EMailAddress1 LIKE '%@grdf.fr'))
        ) AS pi WHERE pi.rn = 3
    ) AS Participant_Interne_3,
    (
        SELECT ISNULL(RIGHT(su.DomainName, LEN(su.DomainName) - CHARINDEX('\', su.DomainName)), NULL)
        FROM (
            SELECT ap.PartyId, ap.PartyObjectTypeCode,
                ROW_NUMBER() OVER (ORDER BY
                    CASE WHEN ap.PartyObjectTypeCode = 8 THEN su2.LastName  ELSE c2.LastName  END,
                    CASE WHEN ap.PartyObjectTypeCode = 8 THEN su2.FirstName ELSE c2.FirstName END) AS rn
            FROM dbo.ActivityParty AS ap
            LEFT JOIN dbo.Contact    AS c2  ON c2.ContactId    = ap.PartyId AND ap.PartyObjectTypeCode = 2
            LEFT JOIN dbo.SystemUser AS su2 ON su2.SystemUserId = ap.PartyId AND ap.PartyObjectTypeCode = 8
            WHERE ap.ActivityId = app.ActivityId AND ap.ParticipationTypeMask IN (5,6) AND ap.IsPartyDeleted = 0
              AND (ap.PartyObjectTypeCode = 8 OR (ap.PartyObjectTypeCode = 2 AND c2.EMailAddress1 LIKE '%@grdf.fr'))
        ) AS ap
        INNER JOIN dbo.SystemUser AS su ON su.SystemUserId = ap.PartyId AND ap.PartyObjectTypeCode = 8
        WHERE ap.rn = 3
    ) AS MAIA_Participant_Interne_3,

    -- Participant_Interne_4
    (
        SELECT ISNULL(pi.FirstName, '') + ' ' + ISNULL(pi.LastName, '')
        FROM (
            SELECT
                CASE WHEN ap.PartyObjectTypeCode = 8 THEN su.FirstName ELSE c.FirstName END AS FirstName,
                CASE WHEN ap.PartyObjectTypeCode = 8 THEN su.LastName  ELSE c.LastName  END AS LastName,
                ROW_NUMBER() OVER (ORDER BY
                    CASE WHEN ap.PartyObjectTypeCode = 8 THEN su.LastName  ELSE c.LastName  END,
                    CASE WHEN ap.PartyObjectTypeCode = 8 THEN su.FirstName ELSE c.FirstName END) AS rn
            FROM dbo.ActivityParty AS ap
            LEFT JOIN dbo.Contact    AS c  ON c.ContactId    = ap.PartyId AND ap.PartyObjectTypeCode = 2
            LEFT JOIN dbo.SystemUser AS su ON su.SystemUserId = ap.PartyId AND ap.PartyObjectTypeCode = 8
            WHERE ap.ActivityId = app.ActivityId AND ap.ParticipationTypeMask IN (5,6) AND ap.IsPartyDeleted = 0
              AND (ap.PartyObjectTypeCode = 8 OR (ap.PartyObjectTypeCode = 2 AND c.EMailAddress1 LIKE '%@grdf.fr'))
        ) AS pi WHERE pi.rn = 4
    ) AS Participant_Interne_4,
    (
        SELECT ISNULL(RIGHT(su.DomainName, LEN(su.DomainName) - CHARINDEX('\', su.DomainName)), NULL)
        FROM (
            SELECT ap.PartyId, ap.PartyObjectTypeCode,
                ROW_NUMBER() OVER (ORDER BY
                    CASE WHEN ap.PartyObjectTypeCode = 8 THEN su2.LastName  ELSE c2.LastName  END,
                    CASE WHEN ap.PartyObjectTypeCode = 8 THEN su2.FirstName ELSE c2.FirstName END) AS rn
            FROM dbo.ActivityParty AS ap
            LEFT JOIN dbo.Contact    AS c2  ON c2.ContactId    = ap.PartyId AND ap.PartyObjectTypeCode = 2
            LEFT JOIN dbo.SystemUser AS su2 ON su2.SystemUserId = ap.PartyId AND ap.PartyObjectTypeCode = 8
            WHERE ap.ActivityId = app.ActivityId AND ap.ParticipationTypeMask IN (5,6) AND ap.IsPartyDeleted = 0
              AND (ap.PartyObjectTypeCode = 8 OR (ap.PartyObjectTypeCode = 2 AND c2.EMailAddress1 LIKE '%@grdf.fr'))
        ) AS ap
        INNER JOIN dbo.SystemUser AS su ON su.SystemUserId = ap.PartyId AND ap.PartyObjectTypeCode = 8
        WHERE ap.rn = 4
    ) AS MAIA_Participant_Interne_4,

    -- Participant_Interne_5
    (
        SELECT ISNULL(pi.FirstName, '') + ' ' + ISNULL(pi.LastName, '')
        FROM (
            SELECT
                CASE WHEN ap.PartyObjectTypeCode = 8 THEN su.FirstName ELSE c.FirstName END AS FirstName,
                CASE WHEN ap.PartyObjectTypeCode = 8 THEN su.LastName  ELSE c.LastName  END AS LastName,
                ROW_NUMBER() OVER (ORDER BY
                    CASE WHEN ap.PartyObjectTypeCode = 8 THEN su.LastName  ELSE c.LastName  END,
                    CASE WHEN ap.PartyObjectTypeCode = 8 THEN su.FirstName ELSE c.FirstName END) AS rn
            FROM dbo.ActivityParty AS ap
            LEFT JOIN dbo.Contact    AS c  ON c.ContactId    = ap.PartyId AND ap.PartyObjectTypeCode = 2
            LEFT JOIN dbo.SystemUser AS su ON su.SystemUserId = ap.PartyId AND ap.PartyObjectTypeCode = 8
            WHERE ap.ActivityId = app.ActivityId AND ap.ParticipationTypeMask IN (5,6) AND ap.IsPartyDeleted = 0
              AND (ap.PartyObjectTypeCode = 8 OR (ap.PartyObjectTypeCode = 2 AND c.EMailAddress1 LIKE '%@grdf.fr'))
        ) AS pi WHERE pi.rn = 5
    ) AS Participant_Interne_5,
    (
        SELECT ISNULL(RIGHT(su.DomainName, LEN(su.DomainName) - CHARINDEX('\', su.DomainName)), NULL)
        FROM (
            SELECT ap.PartyId, ap.PartyObjectTypeCode,
                ROW_NUMBER() OVER (ORDER BY
                    CASE WHEN ap.PartyObjectTypeCode = 8 THEN su2.LastName  ELSE c2.LastName  END,
                    CASE WHEN ap.PartyObjectTypeCode = 8 THEN su2.FirstName ELSE c2.FirstName END) AS rn
            FROM dbo.ActivityParty AS ap
            LEFT JOIN dbo.Contact    AS c2  ON c2.ContactId    = ap.PartyId AND ap.PartyObjectTypeCode = 2
            LEFT JOIN dbo.SystemUser AS su2 ON su2.SystemUserId = ap.PartyId AND ap.PartyObjectTypeCode = 8
            WHERE ap.ActivityId = app.ActivityId AND ap.ParticipationTypeMask IN (5,6) AND ap.IsPartyDeleted = 0
              AND (ap.PartyObjectTypeCode = 8 OR (ap.PartyObjectTypeCode = 2 AND c2.EMailAddress1 LIKE '%@grdf.fr'))
        ) AS ap
        INNER JOIN dbo.SystemUser AS su ON su.SystemUserId = ap.PartyId AND ap.PartyObjectTypeCode = 8
        WHERE ap.rn = 5
    ) AS MAIA_Participant_Interne_5,

    -- =========================================================
    -- Participants externes : 15 × (Nom, Fonction, HATVP)
    -- =========================================================

    -- Externe 1
    (SELECT ISNULL(pe.FirstName,'') + ' ' + ISNULL(pe.LastName,'') FROM (
        SELECT c.FirstName, c.LastName, ROW_NUMBER() OVER (ORDER BY c.LastName, c.FirstName) AS rn
        FROM dbo.ActivityParty AS ap LEFT JOIN dbo.Contact AS c ON c.ContactId = ap.PartyId AND ap.PartyObjectTypeCode = 2
        WHERE ap.ActivityId = app.ActivityId AND ap.ParticipationTypeMask IN (5,6) AND ap.IsPartyDeleted = 0
          AND ap.PartyObjectTypeCode = 2 AND (c.EMailAddress1 IS NULL OR c.EMailAddress1 NOT LIKE '%@grdf.fr')
    ) AS pe WHERE pe.rn = 1) AS Participant_Externe_Nom_1,
    (SELECT sm.Value FROM (
        SELECT c.grdf_fonction, ROW_NUMBER() OVER (ORDER BY c.LastName, c.FirstName) AS rn
        FROM dbo.ActivityParty AS ap LEFT JOIN dbo.Contact AS c ON c.ContactId = ap.PartyId AND ap.PartyObjectTypeCode = 2
        WHERE ap.ActivityId = app.ActivityId AND ap.ParticipationTypeMask IN (5,6) AND ap.IsPartyDeleted = 0
          AND ap.PartyObjectTypeCode = 2 AND (c.EMailAddress1 IS NULL OR c.EMailAddress1 NOT LIKE '%@grdf.fr')
    ) AS pe LEFT JOIN dbo.StringMap AS sm ON sm.ObjectTypeCode = 2 AND sm.AttributeName = 'grdf_fonction'
        AND sm.AttributeValue = pe.grdf_fonction AND sm.LangId = 1036
    WHERE pe.rn = 1) AS Participant_Externe_Fonction_1,
    (SELECT CASE WHEN pe.grdf_hatvp = 1 THEN 'Oui' ELSE 'Non' END FROM (
        SELECT c.grdf_hatvp, ROW_NUMBER() OVER (ORDER BY c.LastName, c.FirstName) AS rn
        FROM dbo.ActivityParty AS ap LEFT JOIN dbo.Contact AS c ON c.ContactId = ap.PartyId AND ap.PartyObjectTypeCode = 2
        WHERE ap.ActivityId = app.ActivityId AND ap.ParticipationTypeMask IN (5,6) AND ap.IsPartyDeleted = 0
          AND ap.PartyObjectTypeCode = 2 AND (c.EMailAddress1 IS NULL OR c.EMailAddress1 NOT LIKE '%@grdf.fr')
    ) AS pe WHERE pe.rn = 1) AS Participant_Externe_HATVP_1,

    -- Externe 2
    (SELECT ISNULL(pe.FirstName,'') + ' ' + ISNULL(pe.LastName,'') FROM (
        SELECT c.FirstName, c.LastName, ROW_NUMBER() OVER (ORDER BY c.LastName, c.FirstName) AS rn
        FROM dbo.ActivityParty AS ap LEFT JOIN dbo.Contact AS c ON c.ContactId = ap.PartyId AND ap.PartyObjectTypeCode = 2
        WHERE ap.ActivityId = app.ActivityId AND ap.ParticipationTypeMask IN (5,6) AND ap.IsPartyDeleted = 0
          AND ap.PartyObjectTypeCode = 2 AND (c.EMailAddress1 IS NULL OR c.EMailAddress1 NOT LIKE '%@grdf.fr')
    ) AS pe WHERE pe.rn = 2) AS Participant_Externe_Nom_2,
    (SELECT sm.Value FROM (
        SELECT c.grdf_fonction, ROW_NUMBER() OVER (ORDER BY c.LastName, c.FirstName) AS rn
        FROM dbo.ActivityParty AS ap LEFT JOIN dbo.Contact AS c ON c.ContactId = ap.PartyId AND ap.PartyObjectTypeCode = 2
        WHERE ap.ActivityId = app.ActivityId AND ap.ParticipationTypeMask IN (5,6) AND ap.IsPartyDeleted = 0
          AND ap.PartyObjectTypeCode = 2 AND (c.EMailAddress1 IS NULL OR c.EMailAddress1 NOT LIKE '%@grdf.fr')
    ) AS pe LEFT JOIN dbo.StringMap AS sm ON sm.ObjectTypeCode = 2 AND sm.AttributeName = 'grdf_fonction'
        AND sm.AttributeValue = pe.grdf_fonction AND sm.LangId = 1036
    WHERE pe.rn = 2) AS Participant_Externe_Fonction_2,
    (SELECT CASE WHEN pe.grdf_hatvp = 1 THEN 'Oui' ELSE 'Non' END FROM (
        SELECT c.grdf_hatvp, ROW_NUMBER() OVER (ORDER BY c.LastName, c.FirstName) AS rn
        FROM dbo.ActivityParty AS ap LEFT JOIN dbo.Contact AS c ON c.ContactId = ap.PartyId AND ap.PartyObjectTypeCode = 2
        WHERE ap.ActivityId = app.ActivityId AND ap.ParticipationTypeMask IN (5,6) AND ap.IsPartyDeleted = 0
          AND ap.PartyObjectTypeCode = 2 AND (c.EMailAddress1 IS NULL OR c.EMailAddress1 NOT LIKE '%@grdf.fr')
    ) AS pe WHERE pe.rn = 2) AS Participant_Externe_HATVP_2,

    -- Externe 3
    (SELECT ISNULL(pe.FirstName,'') + ' ' + ISNULL(pe.LastName,'') FROM (
        SELECT c.FirstName, c.LastName, ROW_NUMBER() OVER (ORDER BY c.LastName, c.FirstName) AS rn
        FROM dbo.ActivityParty AS ap LEFT JOIN dbo.Contact AS c ON c.ContactId = ap.PartyId AND ap.PartyObjectTypeCode = 2
        WHERE ap.ActivityId = app.ActivityId AND ap.ParticipationTypeMask IN (5,6) AND ap.IsPartyDeleted = 0
          AND ap.PartyObjectTypeCode = 2 AND (c.EMailAddress1 IS NULL OR c.EMailAddress1 NOT LIKE '%@grdf.fr')
    ) AS pe WHERE pe.rn = 3) AS Participant_Externe_Nom_3,
    (SELECT sm.Value FROM (
        SELECT c.grdf_fonction, ROW_NUMBER() OVER (ORDER BY c.LastName, c.FirstName) AS rn
        FROM dbo.ActivityParty AS ap LEFT JOIN dbo.Contact AS c ON c.ContactId = ap.PartyId AND ap.PartyObjectTypeCode = 2
        WHERE ap.ActivityId = app.ActivityId AND ap.ParticipationTypeMask IN (5,6) AND ap.IsPartyDeleted = 0
          AND ap.PartyObjectTypeCode = 2 AND (c.EMailAddress1 IS NULL OR c.EMailAddress1 NOT LIKE '%@grdf.fr')
    ) AS pe LEFT JOIN dbo.StringMap AS sm ON sm.ObjectTypeCode = 2 AND sm.AttributeName = 'grdf_fonction'
        AND sm.AttributeValue = pe.grdf_fonction AND sm.LangId = 1036
    WHERE pe.rn = 3) AS Participant_Externe_Fonction_3,
    (SELECT CASE WHEN pe.grdf_hatvp = 1 THEN 'Oui' ELSE 'Non' END FROM (
        SELECT c.grdf_hatvp, ROW_NUMBER() OVER (ORDER BY c.LastName, c.FirstName) AS rn
        FROM dbo.ActivityParty AS ap LEFT JOIN dbo.Contact AS c ON c.ContactId = ap.PartyId AND ap.PartyObjectTypeCode = 2
        WHERE ap.ActivityId = app.ActivityId AND ap.ParticipationTypeMask IN (5,6) AND ap.IsPartyDeleted = 0
          AND ap.PartyObjectTypeCode = 2 AND (c.EMailAddress1 IS NULL OR c.EMailAddress1 NOT LIKE '%@grdf.fr')
    ) AS pe WHERE pe.rn = 3) AS Participant_Externe_HATVP_3,

    -- Externe 4
    (SELECT ISNULL(pe.FirstName,'') + ' ' + ISNULL(pe.LastName,'') FROM (
        SELECT c.FirstName, c.LastName, ROW_NUMBER() OVER (ORDER BY c.LastName, c.FirstName) AS rn
        FROM dbo.ActivityParty AS ap LEFT JOIN dbo.Contact AS c ON c.ContactId = ap.PartyId AND ap.PartyObjectTypeCode = 2
        WHERE ap.ActivityId = app.ActivityId AND ap.ParticipationTypeMask IN (5,6) AND ap.IsPartyDeleted = 0
          AND ap.PartyObjectTypeCode = 2 AND (c.EMailAddress1 IS NULL OR c.EMailAddress1 NOT LIKE '%@grdf.fr')
    ) AS pe WHERE pe.rn = 4) AS Participant_Externe_Nom_4,
    (SELECT sm.Value FROM (
        SELECT c.grdf_fonction, ROW_NUMBER() OVER (ORDER BY c.LastName, c.FirstName) AS rn
        FROM dbo.ActivityParty AS ap LEFT JOIN dbo.Contact AS c ON c.ContactId = ap.PartyId AND ap.PartyObjectTypeCode = 2
        WHERE ap.ActivityId = app.ActivityId AND ap.ParticipationTypeMask IN (5,6) AND ap.IsPartyDeleted = 0
          AND ap.PartyObjectTypeCode = 2 AND (c.EMailAddress1 IS NULL OR c.EMailAddress1 NOT LIKE '%@grdf.fr')
    ) AS pe LEFT JOIN dbo.StringMap AS sm ON sm.ObjectTypeCode = 2 AND sm.AttributeName = 'grdf_fonction'
        AND sm.AttributeValue = pe.grdf_fonction AND sm.LangId = 1036
    WHERE pe.rn = 4) AS Participant_Externe_Fonction_4,
    (SELECT CASE WHEN pe.grdf_hatvp = 1 THEN 'Oui' ELSE 'Non' END FROM (
        SELECT c.grdf_hatvp, ROW_NUMBER() OVER (ORDER BY c.LastName, c.FirstName) AS rn
        FROM dbo.ActivityParty AS ap LEFT JOIN dbo.Contact AS c ON c.ContactId = ap.PartyId AND ap.PartyObjectTypeCode = 2
        WHERE ap.ActivityId = app.ActivityId AND ap.ParticipationTypeMask IN (5,6) AND ap.IsPartyDeleted = 0
          AND ap.PartyObjectTypeCode = 2 AND (c.EMailAddress1 IS NULL OR c.EMailAddress1 NOT LIKE '%@grdf.fr')
    ) AS pe WHERE pe.rn = 4) AS Participant_Externe_HATVP_4,

    -- Externe 5
    (SELECT ISNULL(pe.FirstName,'') + ' ' + ISNULL(pe.LastName,'') FROM (
        SELECT c.FirstName, c.LastName, ROW_NUMBER() OVER (ORDER BY c.LastName, c.FirstName) AS rn
        FROM dbo.ActivityParty AS ap LEFT JOIN dbo.Contact AS c ON c.ContactId = ap.PartyId AND ap.PartyObjectTypeCode = 2
        WHERE ap.ActivityId = app.ActivityId AND ap.ParticipationTypeMask IN (5,6) AND ap.IsPartyDeleted = 0
          AND ap.PartyObjectTypeCode = 2 AND (c.EMailAddress1 IS NULL OR c.EMailAddress1 NOT LIKE '%@grdf.fr')
    ) AS pe WHERE pe.rn = 5) AS Participant_Externe_Nom_5,
    (SELECT sm.Value FROM (
        SELECT c.grdf_fonction, ROW_NUMBER() OVER (ORDER BY c.LastName, c.FirstName) AS rn
        FROM dbo.ActivityParty AS ap LEFT JOIN dbo.Contact AS c ON c.ContactId = ap.PartyId AND ap.PartyObjectTypeCode = 2
        WHERE ap.ActivityId = app.ActivityId AND ap.ParticipationTypeMask IN (5,6) AND ap.IsPartyDeleted = 0
          AND ap.PartyObjectTypeCode = 2 AND (c.EMailAddress1 IS NULL OR c.EMailAddress1 NOT LIKE '%@grdf.fr')
    ) AS pe LEFT JOIN dbo.StringMap AS sm ON sm.ObjectTypeCode = 2 AND sm.AttributeName = 'grdf_fonction'
        AND sm.AttributeValue = pe.grdf_fonction AND sm.LangId = 1036
    WHERE pe.rn = 5) AS Participant_Externe_Fonction_5,
    (SELECT CASE WHEN pe.grdf_hatvp = 1 THEN 'Oui' ELSE 'Non' END FROM (
        SELECT c.grdf_hatvp, ROW_NUMBER() OVER (ORDER BY c.LastName, c.FirstName) AS rn
        FROM dbo.ActivityParty AS ap LEFT JOIN dbo.Contact AS c ON c.ContactId = ap.PartyId AND ap.PartyObjectTypeCode = 2
        WHERE ap.ActivityId = app.ActivityId AND ap.ParticipationTypeMask IN (5,6) AND ap.IsPartyDeleted = 0
          AND ap.PartyObjectTypeCode = 2 AND (c.EMailAddress1 IS NULL OR c.EMailAddress1 NOT LIKE '%@grdf.fr')
    ) AS pe WHERE pe.rn = 5) AS Participant_Externe_HATVP_5,

    -- Externe 6
    (SELECT ISNULL(pe.FirstName,'') + ' ' + ISNULL(pe.LastName,'') FROM (
        SELECT c.FirstName, c.LastName, ROW_NUMBER() OVER (ORDER BY c.LastName, c.FirstName) AS rn
        FROM dbo.ActivityParty AS ap LEFT JOIN dbo.Contact AS c ON c.ContactId = ap.PartyId AND ap.PartyObjectTypeCode = 2
        WHERE ap.ActivityId = app.ActivityId AND ap.ParticipationTypeMask IN (5,6) AND ap.IsPartyDeleted = 0
          AND ap.PartyObjectTypeCode = 2 AND (c.EMailAddress1 IS NULL OR c.EMailAddress1 NOT LIKE '%@grdf.fr')
    ) AS pe WHERE pe.rn = 6) AS Participant_Externe_Nom_6,
    (SELECT sm.Value FROM (
        SELECT c.grdf_fonction, ROW_NUMBER() OVER (ORDER BY c.LastName, c.FirstName) AS rn
        FROM dbo.ActivityParty AS ap LEFT JOIN dbo.Contact AS c ON c.ContactId = ap.PartyId AND ap.PartyObjectTypeCode = 2
        WHERE ap.ActivityId = app.ActivityId AND ap.ParticipationTypeMask IN (5,6) AND ap.IsPartyDeleted = 0
          AND ap.PartyObjectTypeCode = 2 AND (c.EMailAddress1 IS NULL OR c.EMailAddress1 NOT LIKE '%@grdf.fr')
    ) AS pe LEFT JOIN dbo.StringMap AS sm ON sm.ObjectTypeCode = 2 AND sm.AttributeName = 'grdf_fonction'
        AND sm.AttributeValue = pe.grdf_fonction AND sm.LangId = 1036
    WHERE pe.rn = 6) AS Participant_Externe_Fonction_6,
    (SELECT CASE WHEN pe.grdf_hatvp = 1 THEN 'Oui' ELSE 'Non' END FROM (
        SELECT c.grdf_hatvp, ROW_NUMBER() OVER (ORDER BY c.LastName, c.FirstName) AS rn
        FROM dbo.ActivityParty AS ap LEFT JOIN dbo.Contact AS c ON c.ContactId = ap.PartyId AND ap.PartyObjectTypeCode = 2
        WHERE ap.ActivityId = app.ActivityId AND ap.ParticipationTypeMask IN (5,6) AND ap.IsPartyDeleted = 0
          AND ap.PartyObjectTypeCode = 2 AND (c.EMailAddress1 IS NULL OR c.EMailAddress1 NOT LIKE '%@grdf.fr')
    ) AS pe WHERE pe.rn = 6) AS Participant_Externe_HATVP_6,

    -- Externe 7
    (SELECT ISNULL(pe.FirstName,'') + ' ' + ISNULL(pe.LastName,'') FROM (
        SELECT c.FirstName, c.LastName, ROW_NUMBER() OVER (ORDER BY c.LastName, c.FirstName) AS rn
        FROM dbo.ActivityParty AS ap LEFT JOIN dbo.Contact AS c ON c.ContactId = ap.PartyId AND ap.PartyObjectTypeCode = 2
        WHERE ap.ActivityId = app.ActivityId AND ap.ParticipationTypeMask IN (5,6) AND ap.IsPartyDeleted = 0
          AND ap.PartyObjectTypeCode = 2 AND (c.EMailAddress1 IS NULL OR c.EMailAddress1 NOT LIKE '%@grdf.fr')
    ) AS pe WHERE pe.rn = 7) AS Participant_Externe_Nom_7,
    (SELECT sm.Value FROM (
        SELECT c.grdf_fonction, ROW_NUMBER() OVER (ORDER BY c.LastName, c.FirstName) AS rn
        FROM dbo.ActivityParty AS ap LEFT JOIN dbo.Contact AS c ON c.ContactId = ap.PartyId AND ap.PartyObjectTypeCode = 2
        WHERE ap.ActivityId = app.ActivityId AND ap.ParticipationTypeMask IN (5,6) AND ap.IsPartyDeleted = 0
          AND ap.PartyObjectTypeCode = 2 AND (c.EMailAddress1 IS NULL OR c.EMailAddress1 NOT LIKE '%@grdf.fr')
    ) AS pe LEFT JOIN dbo.StringMap AS sm ON sm.ObjectTypeCode = 2 AND sm.AttributeName = 'grdf_fonction'
        AND sm.AttributeValue = pe.grdf_fonction AND sm.LangId = 1036
    WHERE pe.rn = 7) AS Participant_Externe_Fonction_7,
    (SELECT CASE WHEN pe.grdf_hatvp = 1 THEN 'Oui' ELSE 'Non' END FROM (
        SELECT c.grdf_hatvp, ROW_NUMBER() OVER (ORDER BY c.LastName, c.FirstName) AS rn
        FROM dbo.ActivityParty AS ap LEFT JOIN dbo.Contact AS c ON c.ContactId = ap.PartyId AND ap.PartyObjectTypeCode = 2
        WHERE ap.ActivityId = app.ActivityId AND ap.ParticipationTypeMask IN (5,6) AND ap.IsPartyDeleted = 0
          AND ap.PartyObjectTypeCode = 2 AND (c.EMailAddress1 IS NULL OR c.EMailAddress1 NOT LIKE '%@grdf.fr')
    ) AS pe WHERE pe.rn = 7) AS Participant_Externe_HATVP_7,

    -- Externe 8
    (SELECT ISNULL(pe.FirstName,'') + ' ' + ISNULL(pe.LastName,'') FROM (
        SELECT c.FirstName, c.LastName, ROW_NUMBER() OVER (ORDER BY c.LastName, c.FirstName) AS rn
        FROM dbo.ActivityParty AS ap LEFT JOIN dbo.Contact AS c ON c.ContactId = ap.PartyId AND ap.PartyObjectTypeCode = 2
        WHERE ap.ActivityId = app.ActivityId AND ap.ParticipationTypeMask IN (5,6) AND ap.IsPartyDeleted = 0
          AND ap.PartyObjectTypeCode = 2 AND (c.EMailAddress1 IS NULL OR c.EMailAddress1 NOT LIKE '%@grdf.fr')
    ) AS pe WHERE pe.rn = 8) AS Participant_Externe_Nom_8,
    (SELECT sm.Value FROM (
        SELECT c.grdf_fonction, ROW_NUMBER() OVER (ORDER BY c.LastName, c.FirstName) AS rn
        FROM dbo.ActivityParty AS ap LEFT JOIN dbo.Contact AS c ON c.ContactId = ap.PartyId AND ap.PartyObjectTypeCode = 2
        WHERE ap.ActivityId = app.ActivityId AND ap.ParticipationTypeMask IN (5,6) AND ap.IsPartyDeleted = 0
          AND ap.PartyObjectTypeCode = 2 AND (c.EMailAddress1 IS NULL OR c.EMailAddress1 NOT LIKE '%@grdf.fr')
    ) AS pe LEFT JOIN dbo.StringMap AS sm ON sm.ObjectTypeCode = 2 AND sm.AttributeName = 'grdf_fonction'
        AND sm.AttributeValue = pe.grdf_fonction AND sm.LangId = 1036
    WHERE pe.rn = 8) AS Participant_Externe_Fonction_8,
    (SELECT CASE WHEN pe.grdf_hatvp = 1 THEN 'Oui' ELSE 'Non' END FROM (
        SELECT c.grdf_hatvp, ROW_NUMBER() OVER (ORDER BY c.LastName, c.FirstName) AS rn
        FROM dbo.ActivityParty AS ap LEFT JOIN dbo.Contact AS c ON c.ContactId = ap.PartyId AND ap.PartyObjectTypeCode = 2
        WHERE ap.ActivityId = app.ActivityId AND ap.ParticipationTypeMask IN (5,6) AND ap.IsPartyDeleted = 0
          AND ap.PartyObjectTypeCode = 2 AND (c.EMailAddress1 IS NULL OR c.EMailAddress1 NOT LIKE '%@grdf.fr')
    ) AS pe WHERE pe.rn = 8) AS Participant_Externe_HATVP_8,

    -- Externe 9
    (SELECT ISNULL(pe.FirstName,'') + ' ' + ISNULL(pe.LastName,'') FROM (
        SELECT c.FirstName, c.LastName, ROW_NUMBER() OVER (ORDER BY c.LastName, c.FirstName) AS rn
        FROM dbo.ActivityParty AS ap LEFT JOIN dbo.Contact AS c ON c.ContactId = ap.PartyId AND ap.PartyObjectTypeCode = 2
        WHERE ap.ActivityId = app.ActivityId AND ap.ParticipationTypeMask IN (5,6) AND ap.IsPartyDeleted = 0
          AND ap.PartyObjectTypeCode = 2 AND (c.EMailAddress1 IS NULL OR c.EMailAddress1 NOT LIKE '%@grdf.fr')
    ) AS pe WHERE pe.rn = 9) AS Participant_Externe_Nom_9,
    (SELECT sm.Value FROM (
        SELECT c.grdf_fonction, ROW_NUMBER() OVER (ORDER BY c.LastName, c.FirstName) AS rn
        FROM dbo.ActivityParty AS ap LEFT JOIN dbo.Contact AS c ON c.ContactId = ap.PartyId AND ap.PartyObjectTypeCode = 2
        WHERE ap.ActivityId = app.ActivityId AND ap.ParticipationTypeMask IN (5,6) AND ap.IsPartyDeleted = 0
          AND ap.PartyObjectTypeCode = 2 AND (c.EMailAddress1 IS NULL OR c.EMailAddress1 NOT LIKE '%@grdf.fr')
    ) AS pe LEFT JOIN dbo.StringMap AS sm ON sm.ObjectTypeCode = 2 AND sm.AttributeName = 'grdf_fonction'
        AND sm.AttributeValue = pe.grdf_fonction AND sm.LangId = 1036
    WHERE pe.rn = 9) AS Participant_Externe_Fonction_9,
    (SELECT CASE WHEN pe.grdf_hatvp = 1 THEN 'Oui' ELSE 'Non' END FROM (
        SELECT c.grdf_hatvp, ROW_NUMBER() OVER (ORDER BY c.LastName, c.FirstName) AS rn
        FROM dbo.ActivityParty AS ap LEFT JOIN dbo.Contact AS c ON c.ContactId = ap.PartyId AND ap.PartyObjectTypeCode = 2
        WHERE ap.ActivityId = app.ActivityId AND ap.ParticipationTypeMask IN (5,6) AND ap.IsPartyDeleted = 0
          AND ap.PartyObjectTypeCode = 2 AND (c.EMailAddress1 IS NULL OR c.EMailAddress1 NOT LIKE '%@grdf.fr')
    ) AS pe WHERE pe.rn = 9) AS Participant_Externe_HATVP_9,

    -- Externe 10
    (SELECT ISNULL(pe.FirstName,'') + ' ' + ISNULL(pe.LastName,'') FROM (
        SELECT c.FirstName, c.LastName, ROW_NUMBER() OVER (ORDER BY c.LastName, c.FirstName) AS rn
        FROM dbo.ActivityParty AS ap LEFT JOIN dbo.Contact AS c ON c.ContactId = ap.PartyId AND ap.PartyObjectTypeCode = 2
        WHERE ap.ActivityId = app.ActivityId AND ap.ParticipationTypeMask IN (5,6) AND ap.IsPartyDeleted = 0
          AND ap.PartyObjectTypeCode = 2 AND (c.EMailAddress1 IS NULL OR c.EMailAddress1 NOT LIKE '%@grdf.fr')
    ) AS pe WHERE pe.rn = 10) AS Participant_Externe_Nom_10,
    (SELECT sm.Value FROM (
        SELECT c.grdf_fonction, ROW_NUMBER() OVER (ORDER BY c.LastName, c.FirstName) AS rn
        FROM dbo.ActivityParty AS ap LEFT JOIN dbo.Contact AS c ON c.ContactId = ap.PartyId AND ap.PartyObjectTypeCode = 2
        WHERE ap.ActivityId = app.ActivityId AND ap.ParticipationTypeMask IN (5,6) AND ap.IsPartyDeleted = 0
          AND ap.PartyObjectTypeCode = 2 AND (c.EMailAddress1 IS NULL OR c.EMailAddress1 NOT LIKE '%@grdf.fr')
    ) AS pe LEFT JOIN dbo.StringMap AS sm ON sm.ObjectTypeCode = 2 AND sm.AttributeName = 'grdf_fonction'
        AND sm.AttributeValue = pe.grdf_fonction AND sm.LangId = 1036
    WHERE pe.rn = 10) AS Participant_Externe_Fonction_10,
    (SELECT CASE WHEN pe.grdf_hatvp = 1 THEN 'Oui' ELSE 'Non' END FROM (
        SELECT c.grdf_hatvp, ROW_NUMBER() OVER (ORDER BY c.LastName, c.FirstName) AS rn
        FROM dbo.ActivityParty AS ap LEFT JOIN dbo.Contact AS c ON c.ContactId = ap.PartyId AND ap.PartyObjectTypeCode = 2
        WHERE ap.ActivityId = app.ActivityId AND ap.ParticipationTypeMask IN (5,6) AND ap.IsPartyDeleted = 0
          AND ap.PartyObjectTypeCode = 2 AND (c.EMailAddress1 IS NULL OR c.EMailAddress1 NOT LIKE '%@grdf.fr')
    ) AS pe WHERE pe.rn = 10) AS Participant_Externe_HATVP_10,

    -- Externe 11
    (SELECT ISNULL(pe.FirstName,'') + ' ' + ISNULL(pe.LastName,'') FROM (
        SELECT c.FirstName, c.LastName, ROW_NUMBER() OVER (ORDER BY c.LastName, c.FirstName) AS rn
        FROM dbo.ActivityParty AS ap LEFT JOIN dbo.Contact AS c ON c.ContactId = ap.PartyId AND ap.PartyObjectTypeCode = 2
        WHERE ap.ActivityId = app.ActivityId AND ap.ParticipationTypeMask IN (5,6) AND ap.IsPartyDeleted = 0
          AND ap.PartyObjectTypeCode = 2 AND (c.EMailAddress1 IS NULL OR c.EMailAddress1 NOT LIKE '%@grdf.fr')
    ) AS pe WHERE pe.rn = 11) AS Participant_Externe_Nom_11,
    (SELECT sm.Value FROM (
        SELECT c.grdf_fonction, ROW_NUMBER() OVER (ORDER BY c.LastName, c.FirstName) AS rn
        FROM dbo.ActivityParty AS ap LEFT JOIN dbo.Contact AS c ON c.ContactId = ap.PartyId AND ap.PartyObjectTypeCode = 2
        WHERE ap.ActivityId = app.ActivityId AND ap.ParticipationTypeMask IN (5,6) AND ap.IsPartyDeleted = 0
          AND ap.PartyObjectTypeCode = 2 AND (c.EMailAddress1 IS NULL OR c.EMailAddress1 NOT LIKE '%@grdf.fr')
    ) AS pe LEFT JOIN dbo.StringMap AS sm ON sm.ObjectTypeCode = 2 AND sm.AttributeName = 'grdf_fonction'
        AND sm.AttributeValue = pe.grdf_fonction AND sm.LangId = 1036
    WHERE pe.rn = 11) AS Participant_Externe_Fonction_11,
    (SELECT CASE WHEN pe.grdf_hatvp = 1 THEN 'Oui' ELSE 'Non' END FROM (
        SELECT c.grdf_hatvp, ROW_NUMBER() OVER (ORDER BY c.LastName, c.FirstName) AS rn
        FROM dbo.ActivityParty AS ap LEFT JOIN dbo.Contact AS c ON c.ContactId = ap.PartyId AND ap.PartyObjectTypeCode = 2
        WHERE ap.ActivityId = app.ActivityId AND ap.ParticipationTypeMask IN (5,6) AND ap.IsPartyDeleted = 0
          AND ap.PartyObjectTypeCode = 2 AND (c.EMailAddress1 IS NULL OR c.EMailAddress1 NOT LIKE '%@grdf.fr')
    ) AS pe WHERE pe.rn = 11) AS Participant_Externe_HATVP_11,

    -- Externe 12
    (SELECT ISNULL(pe.FirstName,'') + ' ' + ISNULL(pe.LastName,'') FROM (
        SELECT c.FirstName, c.LastName, ROW_NUMBER() OVER (ORDER BY c.LastName, c.FirstName) AS rn
        FROM dbo.ActivityParty AS ap LEFT JOIN dbo.Contact AS c ON c.ContactId = ap.PartyId AND ap.PartyObjectTypeCode = 2
        WHERE ap.ActivityId = app.ActivityId AND ap.ParticipationTypeMask IN (5,6) AND ap.IsPartyDeleted = 0
          AND ap.PartyObjectTypeCode = 2 AND (c.EMailAddress1 IS NULL OR c.EMailAddress1 NOT LIKE '%@grdf.fr')
    ) AS pe WHERE pe.rn = 12) AS Participant_Externe_Nom_12,
    (SELECT sm.Value FROM (
        SELECT c.grdf_fonction, ROW_NUMBER() OVER (ORDER BY c.LastName, c.FirstName) AS rn
        FROM dbo.ActivityParty AS ap LEFT JOIN dbo.Contact AS c ON c.ContactId = ap.PartyId AND ap.PartyObjectTypeCode = 2
        WHERE ap.ActivityId = app.ActivityId AND ap.ParticipationTypeMask IN (5,6) AND ap.IsPartyDeleted = 0
          AND ap.PartyObjectTypeCode = 2 AND (c.EMailAddress1 IS NULL OR c.EMailAddress1 NOT LIKE '%@grdf.fr')
    ) AS pe LEFT JOIN dbo.StringMap AS sm ON sm.ObjectTypeCode = 2 AND sm.AttributeName = 'grdf_fonction'
        AND sm.AttributeValue = pe.grdf_fonction AND sm.LangId = 1036
    WHERE pe.rn = 12) AS Participant_Externe_Fonction_12,
    (SELECT CASE WHEN pe.grdf_hatvp = 1 THEN 'Oui' ELSE 'Non' END FROM (
        SELECT c.grdf_hatvp, ROW_NUMBER() OVER (ORDER BY c.LastName, c.FirstName) AS rn
        FROM dbo.ActivityParty AS ap LEFT JOIN dbo.Contact AS c ON c.ContactId = ap.PartyId AND ap.PartyObjectTypeCode = 2
        WHERE ap.ActivityId = app.ActivityId AND ap.ParticipationTypeMask IN (5,6) AND ap.IsPartyDeleted = 0
          AND ap.PartyObjectTypeCode = 2 AND (c.EMailAddress1 IS NULL OR c.EMailAddress1 NOT LIKE '%@grdf.fr')
    ) AS pe WHERE pe.rn = 12) AS Participant_Externe_HATVP_12,

    -- Externe 13
    (SELECT ISNULL(pe.FirstName,'') + ' ' + ISNULL(pe.LastName,'') FROM (
        SELECT c.FirstName, c.LastName, ROW_NUMBER() OVER (ORDER BY c.LastName, c.FirstName) AS rn
        FROM dbo.ActivityParty AS ap LEFT JOIN dbo.Contact AS c ON c.ContactId = ap.PartyId AND ap.PartyObjectTypeCode = 2
        WHERE ap.ActivityId = app.ActivityId AND ap.ParticipationTypeMask IN (5,6) AND ap.IsPartyDeleted = 0
          AND ap.PartyObjectTypeCode = 2 AND (c.EMailAddress1 IS NULL OR c.EMailAddress1 NOT LIKE '%@grdf.fr')
    ) AS pe WHERE pe.rn = 13) AS Participant_Externe_Nom_13,
    (SELECT sm.Value FROM (
        SELECT c.grdf_fonction, ROW_NUMBER() OVER (ORDER BY c.LastName, c.FirstName) AS rn
        FROM dbo.ActivityParty AS ap LEFT JOIN dbo.Contact AS c ON c.ContactId = ap.PartyId AND ap.PartyObjectTypeCode = 2
        WHERE ap.ActivityId = app.ActivityId AND ap.ParticipationTypeMask IN (5,6) AND ap.IsPartyDeleted = 0
          AND ap.PartyObjectTypeCode = 2 AND (c.EMailAddress1 IS NULL OR c.EMailAddress1 NOT LIKE '%@grdf.fr')
    ) AS pe LEFT JOIN dbo.StringMap AS sm ON sm.ObjectTypeCode = 2 AND sm.AttributeName = 'grdf_fonction'
        AND sm.AttributeValue = pe.grdf_fonction AND sm.LangId = 1036
    WHERE pe.rn = 13) AS Participant_Externe_Fonction_13,
    (SELECT CASE WHEN pe.grdf_hatvp = 1 THEN 'Oui' ELSE 'Non' END FROM (
        SELECT c.grdf_hatvp, ROW_NUMBER() OVER (ORDER BY c.LastName, c.FirstName) AS rn
        FROM dbo.ActivityParty AS ap LEFT JOIN dbo.Contact AS c ON c.ContactId = ap.PartyId AND ap.PartyObjectTypeCode = 2
        WHERE ap.ActivityId = app.ActivityId AND ap.ParticipationTypeMask IN (5,6) AND ap.IsPartyDeleted = 0
          AND ap.PartyObjectTypeCode = 2 AND (c.EMailAddress1 IS NULL OR c.EMailAddress1 NOT LIKE '%@grdf.fr')
    ) AS pe WHERE pe.rn = 13) AS Participant_Externe_HATVP_13,

    -- Externe 14
    (SELECT ISNULL(pe.FirstName,'') + ' ' + ISNULL(pe.LastName,'') FROM (
        SELECT c.FirstName, c.LastName, ROW_NUMBER() OVER (ORDER BY c.LastName, c.FirstName) AS rn
        FROM dbo.ActivityParty AS ap LEFT JOIN dbo.Contact AS c ON c.ContactId = ap.PartyId AND ap.PartyObjectTypeCode = 2
        WHERE ap.ActivityId = app.ActivityId AND ap.ParticipationTypeMask IN (5,6) AND ap.IsPartyDeleted = 0
          AND ap.PartyObjectTypeCode = 2 AND (c.EMailAddress1 IS NULL OR c.EMailAddress1 NOT LIKE '%@grdf.fr')
    ) AS pe WHERE pe.rn = 14) AS Participant_Externe_Nom_14,
    (SELECT sm.Value FROM (
        SELECT c.grdf_fonction, ROW_NUMBER() OVER (ORDER BY c.LastName, c.FirstName) AS rn
        FROM dbo.ActivityParty AS ap LEFT JOIN dbo.Contact AS c ON c.ContactId = ap.PartyId AND ap.PartyObjectTypeCode = 2
        WHERE ap.ActivityId = app.ActivityId AND ap.ParticipationTypeMask IN (5,6) AND ap.IsPartyDeleted = 0
          AND ap.PartyObjectTypeCode = 2 AND (c.EMailAddress1 IS NULL OR c.EMailAddress1 NOT LIKE '%@grdf.fr')
    ) AS pe LEFT JOIN dbo.StringMap AS sm ON sm.ObjectTypeCode = 2 AND sm.AttributeName = 'grdf_fonction'
        AND sm.AttributeValue = pe.grdf_fonction AND sm.LangId = 1036
    WHERE pe.rn = 14) AS Participant_Externe_Fonction_14,
    (SELECT CASE WHEN pe.grdf_hatvp = 1 THEN 'Oui' ELSE 'Non' END FROM (
        SELECT c.grdf_hatvp, ROW_NUMBER() OVER (ORDER BY c.LastName, c.FirstName) AS rn
        FROM dbo.ActivityParty AS ap LEFT JOIN dbo.Contact AS c ON c.ContactId = ap.PartyId AND ap.PartyObjectTypeCode = 2
        WHERE ap.ActivityId = app.ActivityId AND ap.ParticipationTypeMask IN (5,6) AND ap.IsPartyDeleted = 0
          AND ap.PartyObjectTypeCode = 2 AND (c.EMailAddress1 IS NULL OR c.EMailAddress1 NOT LIKE '%@grdf.fr')
    ) AS pe WHERE pe.rn = 14) AS Participant_Externe_HATVP_14,

    -- Externe 15
    (SELECT ISNULL(pe.FirstName,'') + ' ' + ISNULL(pe.LastName,'') FROM (
        SELECT c.FirstName, c.LastName, ROW_NUMBER() OVER (ORDER BY c.LastName, c.FirstName) AS rn
        FROM dbo.ActivityParty AS ap LEFT JOIN dbo.Contact AS c ON c.ContactId = ap.PartyId AND ap.PartyObjectTypeCode = 2
        WHERE ap.ActivityId = app.ActivityId AND ap.ParticipationTypeMask IN (5,6) AND ap.IsPartyDeleted = 0
          AND ap.PartyObjectTypeCode = 2 AND (c.EMailAddress1 IS NULL OR c.EMailAddress1 NOT LIKE '%@grdf.fr')
    ) AS pe WHERE pe.rn = 15) AS Participant_Externe_Nom_15,
    (SELECT sm.Value FROM (
        SELECT c.grdf_fonction, ROW_NUMBER() OVER (ORDER BY c.LastName, c.FirstName) AS rn
        FROM dbo.ActivityParty AS ap LEFT JOIN dbo.Contact AS c ON c.ContactId = ap.PartyId AND ap.PartyObjectTypeCode = 2
        WHERE ap.ActivityId = app.ActivityId AND ap.ParticipationTypeMask IN (5,6) AND ap.IsPartyDeleted = 0
          AND ap.PartyObjectTypeCode = 2 AND (c.EMailAddress1 IS NULL OR c.EMailAddress1 NOT LIKE '%@grdf.fr')
    ) AS pe LEFT JOIN dbo.StringMap AS sm ON sm.ObjectTypeCode = 2 AND sm.AttributeName = 'grdf_fonction'
        AND sm.AttributeValue = pe.grdf_fonction AND sm.LangId = 1036
    WHERE pe.rn = 15) AS Participant_Externe_Fonction_15,
    (SELECT CASE WHEN pe.grdf_hatvp = 1 THEN 'Oui' ELSE 'Non' END FROM (
        SELECT c.grdf_hatvp, ROW_NUMBER() OVER (ORDER BY c.LastName, c.FirstName) AS rn
        FROM dbo.ActivityParty AS ap LEFT JOIN dbo.Contact AS c ON c.ContactId = ap.PartyId AND ap.PartyObjectTypeCode = 2
        WHERE ap.ActivityId = app.ActivityId AND ap.ParticipationTypeMask IN (5,6) AND ap.IsPartyDeleted = 0
          AND ap.PartyObjectTypeCode = 2 AND (c.EMailAddress1 IS NULL OR c.EMailAddress1 NOT LIKE '%@grdf.fr')
    ) AS pe WHERE pe.rn = 15) AS Participant_Externe_HATVP_15,

    -- =========================================================
    -- Reste des colonnes
    -- =========================================================
    (
        SELECT COUNT(DISTINCT contact_hatvp.ContactId)
        FROM (
            SELECT c.ContactId FROM dbo.ActivityParty AS ap
            INNER JOIN dbo.Contact AS c ON c.ContactId = ap.PartyId AND c.grdf_hatvp = 1
            WHERE ap.ActivityId = app.ActivityId AND ap.ParticipationTypeMask = 5 AND ap.IsPartyDeleted = 0
            UNION
            SELECT c.ContactId FROM dbo.ActivityParty AS ap
            INNER JOIN dbo.Contact AS c ON c.ContactId = ap.PartyId AND c.grdf_hatvp = 1
            WHERE ap.ActivityId = app.ActivityId AND ap.ParticipationTypeMask = 6 AND ap.IsPartyDeleted = 0
            UNION
            SELECT c.ContactId FROM dbo.Contact AS c
            WHERE c.ContactId = app.RegardingObjectId
              AND c.grdf_hatvp = 1
              AND app.RegardingObjectTypeCode = 2
        ) AS contact_hatvp
    )                                   AS NbInterlocuteursHATVP,

    -- Député = 996270020, Sénateur = 996270072, Préfet = 996270055
    CASE
        WHEN EXISTS (
            SELECT 1 FROM dbo.ActivityParty AS ap
            INNER JOIN dbo.Contact AS c ON c.ContactId = ap.PartyId
                AND c.grdf_fonction IN (996270020, 996270072, 996270055)
            WHERE ap.ActivityId = app.ActivityId AND ap.ParticipationTypeMask IN (5,6) AND ap.IsPartyDeleted = 0
        )
        OR EXISTS (
            SELECT 1 FROM dbo.Contact AS c
            WHERE c.ContactId = app.RegardingObjectId
              AND app.RegardingObjectTypeCode = 2
              AND c.grdf_fonction IN (996270020, 996270072, 996270055)
        )
        THEN 'Oui' ELSE 'Non'
    END                                 AS ContientDeputeOuSenateurOuPrefet,

    CONVERT(DATE,
        app.ScheduledStart AT TIME ZONE 'UTC' AT TIME ZONE 'Romance Standard Time'
    )                                   AS Date_Debut,
    MAX(sm_type.Value)                  AS grdf_Type,
    (
        SELECT STRING_AGG(CAST(sm_them.Value AS NVARCHAR(MAX)), ', ')
            WITHIN GROUP (ORDER BY sm_them.Value)
        FROM dbo.StringMap AS sm_them
        WHERE sm_them.ObjectTypeCode = 4201
          AND sm_them.AttributeName  = 'grdf_thematique'
          AND CHARINDEX(CAST(sm_them.AttributeValue AS VARCHAR(20)), app.grdf_thematique) > 0
          AND sm_them.LangId         = 1036
    )                                   AS Thematiques,
    MAX(sm_prio.Value)                  AS Priorite,
    (
        SELECT STRING_AGG(CAST(sm_dec.Value AS NVARCHAR(MAX)), ', ')
            WITHIN GROUP (ORDER BY sm_dec.Value)
        FROM dbo.StringMap AS sm_dec
        WHERE sm_dec.ObjectTypeCode = 4201
          AND sm_dec.AttributeName  = 'grdf_type_decision_vise'
          AND CHARINDEX(CAST(sm_dec.AttributeValue AS VARCHAR(20)), app.grdf_type_decision_vise) > 0
          AND sm_dec.LangId         = 1036
    )                                   AS HATVP_TypeDecisionVisee,
    sm_act.Value                        AS HATVP_TypeAction,
    sm_obj.Value                        AS HATVP_ObjetDecision,
    sm_dom.Value                        AS HATVP_DomaineIntervention,
    app.grdf_decision_visee             AS HATVP_DecisionVisee

FROM dbo.Appointment AS app

LEFT JOIN dbo.StringMap AS sm_stat
    ON sm_stat.ObjectTypeCode = 4201 AND sm_stat.AttributeName = 'statecode'
    AND sm_stat.AttributeValue = app.StateCode AND sm_stat.LangId = 1036
LEFT JOIN dbo.StringMap AS sm_type
    ON sm_type.ObjectTypeCode = 4201 AND sm_type.AttributeName = 'grdf_type'
    AND sm_type.AttributeValue = app.grdf_type AND sm_type.LangId = 1036
LEFT JOIN dbo.StringMap AS sm_prio
    ON sm_prio.ObjectTypeCode = 4201 AND sm_prio.AttributeName = 'prioritycode'
    AND sm_prio.AttributeValue = app.PriorityCode AND sm_prio.LangId = 1036
LEFT JOIN dbo.StringMap AS sm_empl
    ON sm_empl.ObjectTypeCode = 4201 AND sm_empl.AttributeName = 'grdf_emplacement'
    AND sm_empl.AttributeValue = app.grdf_emplacement AND sm_empl.LangId = 1036
LEFT JOIN dbo.StringMap AS sm_act
    ON sm_act.ObjectTypeCode = 4201 AND sm_act.AttributeName = 'grdf_type_action'
    AND sm_act.AttributeValue = TRY_CAST(app.grdf_type_action AS INT) AND sm_act.LangId = 1036
LEFT JOIN dbo.StringMap AS sm_obj
    ON sm_obj.ObjectTypeCode = 4201 AND sm_obj.AttributeName = 'grdf_objet_decision'
    AND sm_obj.AttributeValue = TRY_CAST(app.grdf_objet_decision AS INT) AND sm_obj.LangId = 1036
LEFT JOIN dbo.StringMap AS sm_dom
    ON sm_dom.ObjectTypeCode = 4201 AND sm_dom.AttributeName = 'grdf_domaine_intervention'
    AND sm_dom.AttributeValue = TRY_CAST(app.grdf_domaine_intervention AS INT) AND sm_dom.LangId = 1036

WHERE app.CreatedOn >= '2023-01-01'
  AND (
        -- Cas 1 : Concernant = Contact avec grdf_hatvp = 1
        (
            app.RegardingObjectTypeCode = 2
            AND EXISTS (
                SELECT 1 FROM dbo.Contact AS c
                WHERE c.ContactId = app.RegardingObjectId
                  AND c.grdf_hatvp = 1
            )
        )
        OR
        -- Cas 2 : au moins un participant Contact avec grdf_hatvp = 1
        EXISTS (
            SELECT 1
            FROM dbo.ActivityParty AS ap
            INNER JOIN dbo.Contact AS c ON c.ContactId = ap.PartyId AND c.grdf_hatvp = 1
            WHERE ap.ActivityId = app.ActivityId
              AND ap.ParticipationTypeMask IN (5,6) AND ap.IsPartyDeleted = 0
        )
        OR
        -- Cas 3 : au moins un participant dont fonction = Député, Sénateur ou Préfet
        EXISTS (
            SELECT 1
            FROM dbo.ActivityParty AS ap
            INNER JOIN dbo.Contact AS c ON c.ContactId = ap.PartyId
                AND c.grdf_fonction IN (996270020, 996270072, 996270055)
            WHERE ap.ActivityId = app.ActivityId
              AND ap.ParticipationTypeMask IN (5,6) AND ap.IsPartyDeleted = 0
        )
        OR
        -- Cas 4 : Concernant = Contact dont fonction = Député, Sénateur ou Préfet
        (
            app.RegardingObjectTypeCode = 2
            AND EXISTS (
                SELECT 1 FROM dbo.Contact AS c
                WHERE c.ContactId = app.RegardingObjectId
                  AND c.grdf_fonction IN (996270020, 996270072, 996270055)
            )
        )
      )
  AND app.ActivityId IN (
    '93e62a73-0143-f111-8141-005056be5b03',
    '3b2803ca-c72d-f111-8144-005056be1732',
    '92512192-4aed-f011-813d-005056beef00',
    'e7eeaaca-5aed-f011-8140-005056be8b27',
    '6331C265-60F0-F011-813A-005056BE5B03',
    'D5AA6FF8-3D2C-F111-8144-005056BE8B27',
    '2BF36B3E-E7A5-F011-813A-005056BE8B27',
    'DCF70AB8-A995-F011-8139-005056BE1732',
    'b4821a8e-b4bb-f011-8139-005056beef00',
    'd8856fe4-b2ce-f011-813d-005056be1732',
    'B0D25693-69F0-F011-813D-005056BEEF00',
    'CBE8D6FC-1785-F011-8133-005056BE5B03'
  )

GROUP BY
    app.ActivityId,
    app.grdf_hatvp,
    app.Subject,
    app.OwnerIdName,
    app.Description,
    app.RegardingObjectId,
    app.RegardingObjectTypeCode,
    app.RegardingObjectIdName,
    app.Location,
    app.ScheduledStart,
    app.ScheduledEnd,
    app.IsAllDayEvent,
    app.ActualDurationMinutes,
    app.grdf_thematique,
    app.grdf_type_decision_vise,
    app.grdf_type_action,
    app.grdf_objet_decision,
    app.grdf_domaine_intervention,
    app.grdf_decision_visee,
    sm_act.Value,
    sm_obj.Value,
    sm_dom.Value;
