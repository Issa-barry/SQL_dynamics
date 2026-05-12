SELECT TOP 10
    app.ActivityId,
    app.grdf_hatvp,
    app.Subject                         AS Libelle,
    app.OwnerIdName                     AS Proprietaire,
    app.Description,
    app.RegardingObjectIdName           AS Concernant,
    app.grdf_emplacement,
    app.Location                        AS Lieu,
    MAX(sm_stat.Value)                  AS Statut,
    MAX(sm_reason.Value)                AS RaisonStatut,
    -- Participants obligatoires (ParticipationTypeMask = 5)
    (
        SELECT STRING_AGG(ap.PartyIdName, ', ')
            WITHIN GROUP (ORDER BY ap.PartyIdName)
        FROM dbo.ActivityParty AS ap
        WHERE ap.ActivityId             = app.ActivityId
          AND ap.ParticipationTypeMask  = 5
          AND ap.IsPartyDeleted         = 0
    )                                   AS Participants,
    -- Participants facultatifs (ParticipationTypeMask = 6)
    (
        SELECT STRING_AGG(ap.PartyIdName, ', ')
            WITHIN GROUP (ORDER BY ap.PartyIdName)
        FROM dbo.ActivityParty AS ap
        WHERE ap.ActivityId             = app.ActivityId
          AND ap.ParticipationTypeMask  = 6
          AND ap.IsPartyDeleted         = 0
    )                                   AS Facultatifs,
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
        SELECT STRING_AGG(sm_them.Value, ', ')
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
        SELECT STRING_AGG(sm_dec.Value, ', ')
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
    -- Comptes rendus (Titre + Description)
    (
        SELECT STRING_AGG(
            ISNULL(cr.grdf_titre, '') 
                + CASE WHEN cr.grdf_description IS NOT NULL 
                       THEN ' | ' + cr.grdf_description 
                       ELSE '' 
                  END,
            ' ;; '
        ) WITHIN GROUP (ORDER BY cr.grdf_titre)
        FROM dbo.grdf_compte_rendu AS cr
        WHERE cr.grdf_rendez_vousid = app.ActivityId
    )                                   AS ComptesRendus
FROM dbo.Appointment AS app
-- Jointure Statut principal
LEFT JOIN dbo.StringMap AS sm_stat
    ON  sm_stat.ObjectTypeCode  = 4201
    AND sm_stat.AttributeName   = 'statecode'
    AND sm_stat.AttributeValue  = app.StateCode
    AND sm_stat.LangId          = 1036
-- Jointure Raison du statut
LEFT JOIN dbo.StringMap AS sm_reason
    ON  sm_reason.ObjectTypeCode = 4201
    AND sm_reason.AttributeName  = 'statuscode'
    AND sm_reason.AttributeValue = app.StatusCode
    AND sm_reason.LangId         = 1036
-- Jointure Type
LEFT JOIN dbo.StringMap AS sm_type
    ON  sm_type.ObjectTypeCode  = 4201
    AND sm_type.AttributeName   = 'grdf_type'
    AND sm_type.AttributeValue  = app.grdf_type
    AND sm_type.LangId          = 1036
-- Jointure Priorité
LEFT JOIN dbo.StringMap AS sm_prio
    ON  sm_prio.ObjectTypeCode  = 4201
    AND sm_prio.AttributeName   = 'prioritycode'
    AND sm_prio.AttributeValue  = app.PriorityCode
    AND sm_prio.LangId          = 1036
WHERE app.ActivityId IN (
    '93e62a73-0143-f111-8141-005056be5b03',
    '3b2803ca-c72d-f111-8144-005056be1732',
    '92512192-4aed-f011-813d-005056beef00',
	'93140e6c-322f-f111-813f-005056be7218'
)
GROUP BY
    app.ActivityId,
    app.grdf_hatvp,
    app.Subject,
    app.OwnerIdName,
    app.Description,
    app.RegardingObjectIdName,
    app.grdf_emplacement,
    app.Location,
    app.ScheduledStart,
    app.ScheduledEnd,
    app.IsAllDayEvent,
    app.ActualDurationMinutes,
    app.grdf_thematique,
    app.grdf_type_decision_vise

