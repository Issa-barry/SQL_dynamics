SELECT
    app.ActivityId,
    app.grdf_hatvp,
    app.Subject                         AS Libelle,
    app.OwnerIdName                     AS Proprietaire,
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
        ELSE app.RegardingObjectIdName
    END                                 AS Concernant,
    -- Type du concernant
    CASE
        WHEN app.RegardingObjectTypeCode = 2 THEN 'Contact'
        WHEN app.RegardingObjectTypeCode = 1 THEN 'Compte'
        WHEN app.RegardingObjectTypeCode = 4 THEN 'Opportunité'
        ELSE CAST(app.RegardingObjectTypeCode AS NVARCHAR(50))
    END                                 AS TypeConcernant,
    MAX(sm_empl.Value)                  AS grdf_emplacement,
    app.Location                        AS Lieu,
    MAX(sm_stat.Value)                  AS Statut,
    MAX(sm_reason.Value)                AS RaisonStatut,
    -- Participants obligatoires (ParticipationTypeMask = 5)
    (
        SELECT STRING_AGG(
            CAST(
                ISNULL(c.LastName,  ap.PartyIdName) + ' | ' +
                ISNULL(c.FirstName, '-')             + ' | ' +
                ISNULL(sm_fonc.Value, '-')
            AS NVARCHAR(MAX)), ' ; ')
            WITHIN GROUP (ORDER BY c.LastName, c.FirstName)
        FROM dbo.ActivityParty AS ap
        LEFT JOIN dbo.Contact AS c
            ON  c.ContactId            = ap.PartyId
        LEFT JOIN dbo.StringMap AS sm_fonc
            ON  sm_fonc.ObjectTypeCode = 2
            AND sm_fonc.AttributeName  = 'grdf_fonction'
            AND sm_fonc.AttributeValue = c.grdf_fonction
            AND sm_fonc.LangId         = 1036
        WHERE ap.ActivityId            = app.ActivityId
          AND ap.ParticipationTypeMask = 5
          AND ap.IsPartyDeleted        = 0
    )                                   AS Participants,
    -- Participants facultatifs (ParticipationTypeMask = 6)
    (
        SELECT STRING_AGG(
            CAST(
                ISNULL(c.LastName,  ap.PartyIdName) + ' | ' +
                ISNULL(c.FirstName, '-')             + ' | ' +
                ISNULL(sm_fonc.Value, '-')
            AS NVARCHAR(MAX)), ' ; ')
            WITHIN GROUP (ORDER BY c.LastName, c.FirstName)
        FROM dbo.ActivityParty AS ap
        LEFT JOIN dbo.Contact AS c
            ON  c.ContactId            = ap.PartyId
        LEFT JOIN dbo.StringMap AS sm_fonc
            ON  sm_fonc.ObjectTypeCode = 2
            AND sm_fonc.AttributeName  = 'grdf_fonction'
            AND sm_fonc.AttributeValue = c.grdf_fonction
            AND sm_fonc.LangId         = 1036
        WHERE ap.ActivityId            = app.ActivityId
          AND ap.ParticipationTypeMask = 6
          AND ap.IsPartyDeleted        = 0
    )                                   AS Facultatifs,
    -- Nombre d'interlocuteurs HATVP
    (
        SELECT COUNT(DISTINCT contact_hatvp.ContactId)
        FROM
        (
            SELECT c.ContactId
            FROM dbo.ActivityParty AS ap
            INNER JOIN dbo.Contact AS c
                ON  c.ContactId            = ap.PartyId
                AND c.grdf_hatvp           = 1
            WHERE ap.ActivityId            = app.ActivityId
              AND ap.ParticipationTypeMask = 5
              AND ap.IsPartyDeleted        = 0
            UNION
            SELECT c.ContactId
            FROM dbo.ActivityParty AS ap
            INNER JOIN dbo.Contact AS c
                ON  c.ContactId            = ap.PartyId
                AND c.grdf_hatvp           = 1
            WHERE ap.ActivityId            = app.ActivityId
              AND ap.ParticipationTypeMask = 6
              AND ap.IsPartyDeleted        = 0
            UNION
            SELECT c.ContactId
            FROM dbo.Contact AS c
            WHERE c.ContactId              = app.RegardingObjectId
              AND c.grdf_hatvp             = 1
              AND app.RegardingObjectTypeCode = 2
        ) AS contact_hatvp
    )                                   AS NbInterlocuteursHATV,
    -- Heure de début (UTC → Europe/Paris)
    CONVERT(DATE,
        app.ScheduledStart
            AT TIME ZONE 'UTC'
            AT TIME ZONE 'Romance Standard Time'
    )                                   AS HeureDebut_Date,
    CONVERT(TIME(0),
        app.ScheduledStart
            AT TIME ZONE 'UTC'
            AT TIME ZONE 'Romance Standard Time'
    )                                   AS HeureDebut_Heure,
    -- Heure de fin (UTC → Europe/Paris)
    CONVERT(DATE,
        app.ScheduledEnd
            AT TIME ZONE 'UTC'
            AT TIME ZONE 'Romance Standard Time'
    )                                   AS HeureFin_Date,
    CONVERT(TIME(0),
        app.ScheduledEnd
            AT TIME ZONE 'UTC'
            AT TIME ZONE 'Romance Standard Time'
    )                                   AS HeureFin_Heure,
    -- Journée
    CASE WHEN app.IsAllDayEvent = 1
         THEN 'Oui'
         ELSE 'Non'
    END                                 AS Journee,
    -- Durée
    CAST(
        COALESCE(
            app.ActualDurationMinutes,
            DATEDIFF(MINUTE, app.ScheduledStart, app.ScheduledEnd)
        ) / 60.0
    AS DECIMAL(5,1))                    AS Duree_Heures,
    MAX(sm_type.Value)                  AS grdf_Type,
    MAX(sm_prio.Value)                  AS Priorite,
    -- Thématiques
    (
        SELECT STRING_AGG(CAST(sm_them.Value AS NVARCHAR(MAX)), ', ')
            WITHIN GROUP (ORDER BY sm_them.Value)
        FROM dbo.StringMap AS sm_them
        WHERE sm_them.ObjectTypeCode    = 4201
          AND sm_them.AttributeName     = 'grdf_thematique'
          AND CHARINDEX(
                CAST(sm_them.AttributeValue AS VARCHAR(20)),
                app.grdf_thematique
              ) > 0
          AND sm_them.LangId            = 1036
    )                                   AS Thematiques,
    -- HATVP Type de décision visée
    (
        SELECT STRING_AGG(CAST(sm_dec.Value AS NVARCHAR(MAX)), ', ')
            WITHIN GROUP (ORDER BY sm_dec.Value)
        FROM dbo.StringMap AS sm_dec
        WHERE sm_dec.ObjectTypeCode     = 4201
          AND sm_dec.AttributeName      = 'grdf_type_decision_vise'
          AND CHARINDEX(
                CAST(sm_dec.AttributeValue AS VARCHAR(20)),
                app.grdf_type_decision_vise
              ) > 0
          AND sm_dec.LangId             = 1036
    )                                   AS HATVP_TypeDecisionVisee,
    -- Comptes rendus
    (
        SELECT STRING_AGG(
            CAST(
                ISNULL(cr.grdf_titre, '')
                    + CASE WHEN cr.grdf_description IS NOT NULL
                           THEN ' | ' + cr.grdf_description
                           ELSE ''
                      END
            AS NVARCHAR(MAX)),
            ' ;; '
        ) WITHIN GROUP (ORDER BY cr.grdf_titre)
        FROM dbo.grdf_compte_rendu AS cr
        WHERE cr.grdf_rendez_vousid = app.ActivityId
    )                                   AS ComptesRendus
FROM dbo.Appointment AS app
LEFT JOIN dbo.StringMap AS sm_stat
    ON  sm_stat.ObjectTypeCode  = 4201
    AND sm_stat.AttributeName   = 'statecode'
    AND sm_stat.AttributeValue  = app.StateCode
    AND sm_stat.LangId          = 1036
LEFT JOIN dbo.StringMap AS sm_reason
    ON  sm_reason.ObjectTypeCode = 4201
    AND sm_reason.AttributeName  = 'statuscode'
    AND sm_reason.AttributeValue = app.StatusCode
    AND sm_reason.LangId         = 1036
LEFT JOIN dbo.StringMap AS sm_type
    ON  sm_type.ObjectTypeCode  = 4201
    AND sm_type.AttributeName   = 'grdf_type'
    AND sm_type.AttributeValue  = app.grdf_type
    AND sm_type.LangId          = 1036
LEFT JOIN dbo.StringMap AS sm_prio
    ON  sm_prio.ObjectTypeCode  = 4201
    AND sm_prio.AttributeName   = 'prioritycode'
    AND sm_prio.AttributeValue  = app.PriorityCode
    AND sm_prio.LangId          = 1036
LEFT JOIN dbo.StringMap AS sm_empl
    ON  sm_empl.ObjectTypeCode  = 4201
    AND sm_empl.AttributeName   = 'grdf_emplacement'
    AND sm_empl.AttributeValue  = app.grdf_emplacement
    AND sm_empl.LangId          = 1036
WHERE app.CreatedOn >= '2023-01-01'
  AND (
        app.grdf_hatvp = 1
        OR
        EXISTS (
            SELECT 1
            FROM dbo.ActivityParty AS ap
            INNER JOIN dbo.Contact AS c
                ON  c.ContactId         = ap.PartyId
                AND c.grdf_hatvp        = 1
            WHERE ap.ActivityId         = app.ActivityId
              AND ap.ParticipationTypeMask IN (5, 6)
              AND ap.IsPartyDeleted      = 0
        )
      )
  AND app.ActivityId IN (
    '93e62a73-0143-f111-8141-005056be5b03',
    '3b2803ca-c72d-f111-8144-005056be1732',
    '92512192-4aed-f011-813d-005056beef00'
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
    app.grdf_type_decision_vise;
