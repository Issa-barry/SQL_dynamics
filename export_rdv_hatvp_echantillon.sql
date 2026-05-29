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
        (
            SELECT a.Name
            FROM dbo.Account AS a
            WHERE a.AccountId = app.RegardingObjectId
        )
        WHEN app.RegardingObjectTypeCode = 3 THEN
        (
            SELECT o.Name
            FROM dbo.Opportunity AS o
            WHERE o.OpportunityId = app.RegardingObjectId
        )
        WHEN app.RegardingObjectTypeCode = 4 THEN
        (
            SELECT l.Subject
            FROM dbo.Lead AS l
            WHERE l.LeadId = app.RegardingObjectId
        )
        WHEN app.RegardingObjectTypeCode = 4402 THEN
        (
            SELECT ca.Subject
            FROM dbo.CampaignActivity AS ca
            WHERE ca.ActivityId = app.RegardingObjectId
        )
        WHEN app.RegardingObjectTypeCode = 10118 THEN
        (
            SELECT ct.grdf_name
            FROM dbo.grdf_contrat AS ct
            WHERE ct.grdf_contratId = app.RegardingObjectId
        )
        WHEN app.RegardingObjectTypeCode = 10121 THEN
        (
            SELECT loc.grdf_nom
            FROM dbo.grdf_local AS loc
            WHERE loc.grdf_localid = app.RegardingObjectId
        )
        ELSE app.RegardingObjectIdName
    END                                 AS Concernant,
    -- Compte / Campagne rattaché(e)
    -- Si TypeConcernant = Compte => copier la valeur de Concernant
    CASE
        WHEN app.RegardingObjectTypeCode = 1 THEN
        (
            SELECT a.Name
            FROM dbo.Account AS a
            WHERE a.AccountId = app.RegardingObjectId
        )
        WHEN app.RegardingObjectTypeCode = 2 THEN
        (
            SELECT a.Name
            FROM dbo.Contact AS c
            INNER JOIN dbo.Account AS a ON a.AccountId = c.AccountId
            WHERE c.ContactId = app.RegardingObjectId
        )
        WHEN app.RegardingObjectTypeCode = 3 THEN
        (
            SELECT a.Name
            FROM dbo.Opportunity AS o
            INNER JOIN dbo.Account AS a ON a.AccountId = o.AccountId
            WHERE o.OpportunityId = app.RegardingObjectId
        )
        WHEN app.RegardingObjectTypeCode = 4 THEN
        (
            SELECT a.Name
            FROM dbo.Lead AS l
            INNER JOIN dbo.Account AS a ON a.AccountId = l.ParentAccountId
            WHERE l.LeadId = app.RegardingObjectId
        )
        WHEN app.RegardingObjectTypeCode = 4402 THEN
        (
            SELECT c.Name
            FROM dbo.CampaignActivity AS ca
            INNER JOIN dbo.Campaign AS c ON c.CampaignId = ca.RegardingObjectId
            WHERE ca.ActivityId = app.RegardingObjectId
        )
        WHEN app.RegardingObjectTypeCode = 10118 THEN
        (
            SELECT a.Name
            FROM dbo.grdf_contrat AS ct
            INNER JOIN dbo.Account AS a ON a.AccountId = ct.grdf_Compte
            WHERE ct.grdf_contratId = app.RegardingObjectId
        )
        WHEN app.RegardingObjectTypeCode = 10121 THEN
        (
            SELECT a.Name
            FROM dbo.grdf_local AS loc
            INNER JOIN dbo.Account AS a ON a.AccountId = loc.grdf_compteid
            WHERE loc.grdf_localid = app.RegardingObjectId
        )
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
    -- Référence compte (sans apostrophe)
    CASE
        WHEN app.RegardingObjectTypeCode = 1 THEN
            (SELECT ISNULL(CAST(a.grdf_reference AS NVARCHAR(50)), '') FROM dbo.Account AS a WHERE a.AccountId = app.RegardingObjectId)
        WHEN app.RegardingObjectTypeCode = 2 THEN
            (SELECT ISNULL(CAST(a.grdf_reference AS NVARCHAR(50)), '') FROM dbo.Contact AS c INNER JOIN dbo.Account AS a ON a.AccountId = c.AccountId WHERE c.ContactId = app.RegardingObjectId)
        WHEN app.RegardingObjectTypeCode = 3 THEN
            (SELECT ISNULL(CAST(a.grdf_reference AS NVARCHAR(50)), '') FROM dbo.Opportunity AS o INNER JOIN dbo.Account AS a ON a.AccountId = o.AccountId WHERE o.OpportunityId = app.RegardingObjectId)
        WHEN app.RegardingObjectTypeCode = 4 THEN
            (SELECT ISNULL(CAST(a.grdf_reference AS NVARCHAR(50)), '') FROM dbo.Lead AS l INNER JOIN dbo.Account AS a ON a.AccountId = l.ParentAccountId WHERE l.LeadId = app.RegardingObjectId)
        WHEN app.RegardingObjectTypeCode = 10118 THEN
            (SELECT ISNULL(CAST(a.grdf_reference AS NVARCHAR(50)), '') FROM dbo.grdf_contrat AS ct INNER JOIN dbo.Account AS a ON a.AccountId = ct.grdf_Compte WHERE ct.grdf_contratId = app.RegardingObjectId)
        WHEN app.RegardingObjectTypeCode = 10121 THEN
            (SELECT ISNULL(CAST(a.grdf_reference AS NVARCHAR(50)), '') FROM dbo.grdf_local AS loc INNER JOIN dbo.Account AS a ON a.AccountId = loc.grdf_compteid WHERE loc.grdf_localid = app.RegardingObjectId)
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
    -- Code INSEE (sans apostrophe)
    CASE
        WHEN app.RegardingObjectTypeCode = 1 THEN
            (SELECT RIGHT('00000' + ISNULL(CAST(a.grdf_code_insee AS NVARCHAR(5)), ''), 5) FROM dbo.Account AS a WHERE a.AccountId = app.RegardingObjectId)
        WHEN app.RegardingObjectTypeCode = 2 THEN
            (SELECT RIGHT('00000' + ISNULL(CAST(a.grdf_code_insee AS NVARCHAR(5)), ''), 5) FROM dbo.Contact AS c INNER JOIN dbo.Account AS a ON a.AccountId = c.AccountId WHERE c.ContactId = app.RegardingObjectId)
        WHEN app.RegardingObjectTypeCode = 3 THEN
            (SELECT RIGHT('00000' + ISNULL(CAST(a.grdf_code_insee AS NVARCHAR(5)), ''), 5) FROM dbo.Opportunity AS o INNER JOIN dbo.Account AS a ON a.AccountId = o.AccountId WHERE o.OpportunityId = app.RegardingObjectId)
        WHEN app.RegardingObjectTypeCode = 4 THEN
            (SELECT RIGHT('00000' + ISNULL(CAST(a.grdf_code_insee AS NVARCHAR(5)), ''), 5) FROM dbo.Lead AS l INNER JOIN dbo.Account AS a ON a.AccountId = l.ParentAccountId WHERE l.LeadId = app.RegardingObjectId)
        WHEN app.RegardingObjectTypeCode = 10118 THEN
            (SELECT RIGHT('00000' + ISNULL(CAST(a.grdf_code_insee AS NVARCHAR(5)), ''), 5) FROM dbo.grdf_contrat AS ct INNER JOIN dbo.Account AS a ON a.AccountId = ct.grdf_Compte WHERE ct.grdf_contratId = app.RegardingObjectId)
        WHEN app.RegardingObjectTypeCode = 10121 THEN
            (SELECT RIGHT('00000' + ISNULL(CAST(a.grdf_code_insee AS NVARCHAR(5)), ''), 5) FROM dbo.grdf_local AS loc INNER JOIN dbo.Account AS a ON a.AccountId = loc.grdf_compteid WHERE loc.grdf_localid = app.RegardingObjectId)
        ELSE NULL
    END                                 AS CodeINSEE,
    -- Code SIRET (sans apostrophe)
    CASE
        WHEN app.RegardingObjectTypeCode = 1 THEN
            (SELECT RIGHT('00000000000000' + ISNULL(CAST(a.grdf_siret AS NVARCHAR(14)), ''), 14) FROM dbo.Account AS a WHERE a.AccountId = app.RegardingObjectId)
        WHEN app.RegardingObjectTypeCode = 2 THEN
            (SELECT RIGHT('00000000000000' + ISNULL(CAST(a.grdf_siret AS NVARCHAR(14)), ''), 14) FROM dbo.Contact AS c INNER JOIN dbo.Account AS a ON a.AccountId = c.AccountId WHERE c.ContactId = app.RegardingObjectId)
        WHEN app.RegardingObjectTypeCode = 3 THEN
            (SELECT RIGHT('00000000000000' + ISNULL(CAST(a.grdf_siret AS NVARCHAR(14)), ''), 14) FROM dbo.Opportunity AS o INNER JOIN dbo.Account AS a ON a.AccountId = o.AccountId WHERE o.OpportunityId = app.RegardingObjectId)
        WHEN app.RegardingObjectTypeCode = 4 THEN
            (SELECT RIGHT('00000000000000' + ISNULL(CAST(a.grdf_siret AS NVARCHAR(14)), ''), 14) FROM dbo.Lead AS l INNER JOIN dbo.Account AS a ON a.AccountId = l.ParentAccountId WHERE l.LeadId = app.RegardingObjectId)
        WHEN app.RegardingObjectTypeCode = 10118 THEN
            (SELECT RIGHT('00000000000000' + ISNULL(CAST(a.grdf_siret AS NVARCHAR(14)), ''), 14) FROM dbo.grdf_contrat AS ct INNER JOIN dbo.Account AS a ON a.AccountId = ct.grdf_Compte WHERE ct.grdf_contratId = app.RegardingObjectId)
        WHEN app.RegardingObjectTypeCode = 10121 THEN
            (SELECT RIGHT('00000000000000' + ISNULL(CAST(a.grdf_siret AS NVARCHAR(14)), ''), 14) FROM dbo.grdf_local AS loc INNER JOIN dbo.Account AS a ON a.AccountId = loc.grdf_compteid WHERE loc.grdf_localid = app.RegardingObjectId)
        ELSE NULL
    END                                 AS CodeSIRET,
    -- Code SIREN (sans apostrophe)
    CASE
        WHEN app.RegardingObjectTypeCode = 1 THEN
            (SELECT RIGHT('000000000' + ISNULL(LEFT(CAST(a.grdf_siret AS NVARCHAR(14)), 9), ''), 9) FROM dbo.Account AS a WHERE a.AccountId = app.RegardingObjectId)
        WHEN app.RegardingObjectTypeCode = 2 THEN
            (SELECT RIGHT('000000000' + ISNULL(LEFT(CAST(a.grdf_siret AS NVARCHAR(14)), 9), ''), 9) FROM dbo.Contact AS c INNER JOIN dbo.Account AS a ON a.AccountId = c.AccountId WHERE c.ContactId = app.RegardingObjectId)
        WHEN app.RegardingObjectTypeCode = 3 THEN
            (SELECT RIGHT('000000000' + ISNULL(LEFT(CAST(a.grdf_siret AS NVARCHAR(14)), 9), ''), 9) FROM dbo.Opportunity AS o INNER JOIN dbo.Account AS a ON a.AccountId = o.AccountId WHERE o.OpportunityId = app.RegardingObjectId)
        WHEN app.RegardingObjectTypeCode = 4 THEN
            (SELECT RIGHT('000000000' + ISNULL(LEFT(CAST(a.grdf_siret AS NVARCHAR(14)), 9), ''), 9) FROM dbo.Lead AS l INNER JOIN dbo.Account AS a ON a.AccountId = l.ParentAccountId WHERE l.LeadId = app.RegardingObjectId)
        WHEN app.RegardingObjectTypeCode = 10118 THEN
            (SELECT RIGHT('000000000' + ISNULL(LEFT(CAST(a.grdf_siret AS NVARCHAR(14)), 9), ''), 9) FROM dbo.grdf_contrat AS ct INNER JOIN dbo.Account AS a ON a.AccountId = ct.grdf_Compte WHERE ct.grdf_contratId = app.RegardingObjectId)
        WHEN app.RegardingObjectTypeCode = 10121 THEN
            (SELECT RIGHT('000000000' + ISNULL(LEFT(CAST(a.grdf_siret AS NVARCHAR(14)), 9), ''), 9) FROM dbo.grdf_local AS loc INNER JOIN dbo.Account AS a ON a.AccountId = loc.grdf_compteid WHERE loc.grdf_localid = app.RegardingObjectId)
        ELSE NULL
    END                                 AS CodeSIREN,
    MAX(sm_empl.Value)                  AS grdf_emplacement,
    app.Location                        AS Lieu,
    MAX(sm_stat.Value)                  AS Statut,
    app.OwnerIdName                     AS Proprietaire,
    -- Participants internes GRDF
    (
        SELECT STRING_AGG(
            CAST(
                ISNULL(CASE WHEN ap.PartyObjectTypeCode = 8 THEN su.LastName  ELSE c.LastName  END, ap.PartyIdName) + ' | ' +
                ISNULL(CASE WHEN ap.PartyObjectTypeCode = 8 THEN su.FirstName ELSE c.FirstName END, '-') + ' | ' +
                ISNULL(sm_fonc.Value, '-')
            AS NVARCHAR(MAX)), ' ; ')
            WITHIN GROUP (ORDER BY
                CASE WHEN ap.PartyObjectTypeCode = 8 THEN su.LastName  ELSE c.LastName  END,
                CASE WHEN ap.PartyObjectTypeCode = 8 THEN su.FirstName ELSE c.FirstName END)
        FROM (
            SELECT TOP 5
                ap.PartyIdName, ap.ActivityId, ap.PartyId, ap.PartyObjectTypeCode
            FROM dbo.ActivityParty AS ap
            LEFT JOIN dbo.Contact    AS c2  ON c2.ContactId    = ap.PartyId AND ap.PartyObjectTypeCode = 2
            LEFT JOIN dbo.SystemUser AS su2 ON su2.SystemUserId = ap.PartyId AND ap.PartyObjectTypeCode = 8
            WHERE ap.ActivityId            = app.ActivityId
              AND ap.ParticipationTypeMask IN (5, 6)
              AND ap.IsPartyDeleted        = 0
              AND (ap.PartyObjectTypeCode  = 8
                   OR (ap.PartyObjectTypeCode = 2 AND c2.EMailAddress1 LIKE '%@grdf.fr'))
            ORDER BY
                CASE WHEN ap.PartyObjectTypeCode = 8 THEN su2.LastName  ELSE c2.LastName  END,
                CASE WHEN ap.PartyObjectTypeCode = 8 THEN su2.FirstName ELSE c2.FirstName END
        ) AS ap
        LEFT JOIN dbo.Contact    AS c     ON c.ContactId     = ap.PartyId AND ap.PartyObjectTypeCode = 2
        LEFT JOIN dbo.SystemUser AS su    ON su.SystemUserId  = ap.PartyId AND ap.PartyObjectTypeCode = 8
        LEFT JOIN dbo.StringMap  AS sm_fonc
            ON sm_fonc.ObjectTypeCode = 2
            AND sm_fonc.AttributeName  = 'grdf_fonction'
            AND sm_fonc.AttributeValue = c.grdf_fonction
            AND sm_fonc.LangId         = 1036
    )                                   AS Participants_Internes,
    -- Participants externes
    (
        SELECT STRING_AGG(
            CAST(
                ISNULL(c.LastName,  ap.PartyIdName) + ' | ' +
                ISNULL(c.FirstName, '-')             + ' | ' +
                ISNULL(sm_fonc.Value, '-')           + ' | ' +
                CASE WHEN c.grdf_hatvp = 1 THEN 'Oui' ELSE 'Non' END
            AS NVARCHAR(MAX)), ' ; ')
            WITHIN GROUP (ORDER BY c.LastName, c.FirstName)
        FROM (
            SELECT TOP 15
                ap.PartyIdName, ap.ActivityId, ap.PartyId, ap.PartyObjectTypeCode,
                c2.LastName, c2.FirstName, c2.grdf_fonction
            FROM dbo.ActivityParty AS ap
            LEFT JOIN dbo.Contact AS c2
                ON c2.ContactId = ap.PartyId AND ap.PartyObjectTypeCode = 2
            WHERE ap.ActivityId            = app.ActivityId
              AND ap.ParticipationTypeMask IN (5, 6)
              AND ap.IsPartyDeleted        = 0
              AND ap.PartyObjectTypeCode   = 2
              AND (c2.EMailAddress1 IS NULL OR c2.EMailAddress1 NOT LIKE '%@grdf.fr')
            ORDER BY c2.LastName, c2.FirstName
        ) AS ap
        LEFT JOIN dbo.Contact AS c      ON c.ContactId = ap.PartyId
        LEFT JOIN dbo.StringMap AS sm_fonc
            ON sm_fonc.ObjectTypeCode = 2
            AND sm_fonc.AttributeName  = 'grdf_fonction'
            AND sm_fonc.AttributeValue = ap.grdf_fonction
            AND sm_fonc.LangId         = 1036
    )                                   AS Participants_Externes,
    -- Nombre d'interlocuteurs HATVP (hors "Non concerné par l'HATVP")
    (
        SELECT COUNT(DISTINCT contact_hatvp.ContactId)
        FROM (
            SELECT c.ContactId FROM dbo.ActivityParty AS ap
            INNER JOIN dbo.Contact AS c ON c.ContactId = ap.PartyId
                AND c.grdf_hatvp        = 1
                AND c.grdf_valeur_hatvp <> 0   -- remplacer 0 par le code "Non concerné"
            WHERE ap.ActivityId              = app.ActivityId
              AND ap.ParticipationTypeMask   = 5
              AND ap.IsPartyDeleted          = 0
            UNION
            SELECT c.ContactId FROM dbo.ActivityParty AS ap
            INNER JOIN dbo.Contact AS c ON c.ContactId = ap.PartyId
                AND c.grdf_hatvp        = 1
                AND c.grdf_valeur_hatvp <> 0   -- remplacer 0 par le code "Non concerné"
            WHERE ap.ActivityId              = app.ActivityId
              AND ap.ParticipationTypeMask   = 6
              AND ap.IsPartyDeleted          = 0
            UNION
            SELECT c.ContactId FROM dbo.Contact AS c
            WHERE c.ContactId               = app.RegardingObjectId
              AND c.grdf_hatvp              = 1
              AND c.grdf_valeur_hatvp       <> 0   -- remplacer 0 par le code "Non concerné"
              AND app.RegardingObjectTypeCode = 2
        ) AS contact_hatvp
    )                                   AS NbInterlocuteursHATVP,
    -- Date de début (UTC → Europe/Paris)
    CONVERT(DATE,
        app.ScheduledStart AT TIME ZONE 'UTC' AT TIME ZONE 'Romance Standard Time'
    )                                   AS Date_Debut,
    MAX(sm_type.Value)                  AS grdf_Type,
    -- Thématiques
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
    -- Type de décision visée
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
    ON  sm_stat.ObjectTypeCode = 4201
    AND sm_stat.AttributeName  = 'statecode'
    AND sm_stat.AttributeValue = app.StateCode
    AND sm_stat.LangId         = 1036
LEFT JOIN dbo.StringMap AS sm_type
    ON  sm_type.ObjectTypeCode = 4201
    AND sm_type.AttributeName  = 'grdf_type'
    AND sm_type.AttributeValue = app.grdf_type
    AND sm_type.LangId         = 1036
LEFT JOIN dbo.StringMap AS sm_prio
    ON  sm_prio.ObjectTypeCode = 4201
    AND sm_prio.AttributeName  = 'prioritycode'
    AND sm_prio.AttributeValue = app.PriorityCode
    AND sm_prio.LangId         = 1036
LEFT JOIN dbo.StringMap AS sm_empl
    ON  sm_empl.ObjectTypeCode = 4201
    AND sm_empl.AttributeName  = 'grdf_emplacement'
    AND sm_empl.AttributeValue = app.grdf_emplacement
    AND sm_empl.LangId         = 1036
LEFT JOIN dbo.StringMap AS sm_act
    ON  sm_act.ObjectTypeCode  = 4201
    AND sm_act.AttributeName   = 'grdf_type_action'
    AND sm_act.AttributeValue  = TRY_CAST(app.grdf_type_action AS INT)
    AND sm_act.LangId          = 1036
LEFT JOIN dbo.StringMap AS sm_obj
    ON  sm_obj.ObjectTypeCode  = 4201
    AND sm_obj.AttributeName   = 'grdf_objet_decision'
    AND sm_obj.AttributeValue  = TRY_CAST(app.grdf_objet_decision AS INT)
    AND sm_obj.LangId          = 1036
LEFT JOIN dbo.StringMap AS sm_dom
    ON  sm_dom.ObjectTypeCode  = 4201
    AND sm_dom.AttributeName   = 'grdf_domaine_intervention'
    AND sm_dom.AttributeValue  = TRY_CAST(app.grdf_domaine_intervention AS INT)
    AND sm_dom.LangId          = 1036

WHERE app.CreatedOn >= '2023-01-01'
  AND (
        -- Cas 1 : le Concernant est un Contact HATVP avec valeur <> "Non concerné"
        (
            app.RegardingObjectTypeCode = 2
            AND EXISTS (
                SELECT 1 FROM dbo.Contact AS c
                WHERE c.ContactId          = app.RegardingObjectId
                  AND c.grdf_hatvp         = 1
                  AND c.grdf_valeur_hatvp  <> 0   -- remplacer 0 par le code "Non concerné"
            )
        )
        OR
        -- Cas 2 : au moins un participant (requis ou facultatif) Contact HATVP avec valeur <> "Non concerné"
        EXISTS (
            SELECT 1
            FROM dbo.ActivityParty AS ap
            INNER JOIN dbo.Contact AS c
                ON  c.ContactId          = ap.PartyId
                AND c.grdf_hatvp         = 1
                AND c.grdf_valeur_hatvp  <> 0   -- remplacer 0 par le code "Non concerné"
            WHERE ap.ActivityId           = app.ActivityId
              AND ap.ParticipationTypeMask IN (5, 6)
              AND ap.IsPartyDeleted       = 0
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
    sm_dom.Value
