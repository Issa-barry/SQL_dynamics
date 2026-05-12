SELECT
    pc.ActivityId,
    pc.Subject                          AS Libelle,
    pc.OwnerIdName                      AS Proprietaire,
    pc.Description,
    pc.RegardingObjectIdName            AS Concernant,
    -- Direction (Entrant/Sortant)
    CASE WHEN pc.DirectionCode = 1
         THEN 'Sortant'
         ELSE 'Entrant'
    END                                 AS Direction,
    pc.OverriddenCreatedOn              AS Echeance,
    -- Origine de l'appel (mask = 1)
    (
        SELECT STRING_AGG(CAST(ap.PartyIdName AS NVARCHAR(MAX)), ', ')
            WITHIN GROUP (ORDER BY ap.PartyIdName)
        FROM dbo.ActivityParty AS ap
        WHERE ap.ActivityId             = pc.ActivityId
          AND ap.ParticipationTypeMask  = 1
          AND ap.IsPartyDeleted         = 0
    )                                   AS OrigineAppel,
    -- Destination de l'appel (mask = 2)
    (
        SELECT STRING_AGG(CAST(ap.PartyIdName AS NVARCHAR(MAX)), ', ')
            WITHIN GROUP (ORDER BY ap.PartyIdName)
        FROM dbo.ActivityParty AS ap
        WHERE ap.ActivityId             = pc.ActivityId
          AND ap.ParticipationTypeMask  = 2
          AND ap.IsPartyDeleted         = 0
    )                                   AS DestinationAppel,
    -- Date/Heure planifiée (UTC → Europe/Paris)
    CONVERT(DATE,
        pc.ScheduledStart
            AT TIME ZONE 'UTC'
            AT TIME ZONE 'Romance Standard Time'
    )                                   AS Date_Appel,
    CONVERT(TIME(0),
        pc.ScheduledStart
            AT TIME ZONE 'UTC'
            AT TIME ZONE 'Romance Standard Time'
    )                                   AS Heure_Appel,
    -- Durée
    CAST(
        COALESCE(
            pc.ActualDurationMinutes,
            DATEDIFF(MINUTE, pc.ScheduledStart, pc.ScheduledEnd)
        ) / 60.0
    AS DECIMAL(5,1))                    AS Duree_Heures,
    -- Statut principal
    MAX(sm_stat.Value)                  AS Statut,
    MAX(sm_reason.Value)                AS RaisonStatut,
    -- Type
    MAX(sm_type.Value)                  AS grdf_Type,
    -- Priorité
    MAX(sm_prio.Value)                  AS Priorite,
    -- Thématique
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
-- Jointure Statut principal
LEFT JOIN dbo.StringMap AS sm_stat
    ON  sm_stat.ObjectTypeCode  = 4210
    AND sm_stat.AttributeName   = 'statecode'
    AND sm_stat.AttributeValue  = pc.StateCode
    AND sm_stat.LangId          = 1036
-- Jointure Raison du statut
LEFT JOIN dbo.StringMap AS sm_reason
    ON  sm_reason.ObjectTypeCode = 4210
    AND sm_reason.AttributeName  = 'statuscode'
    AND sm_reason.AttributeValue = pc.StatusCode
    AND sm_reason.LangId         = 1036
-- Jointure Type
LEFT JOIN dbo.StringMap AS sm_type
    ON  sm_type.ObjectTypeCode  = 4210
    AND sm_type.AttributeName   = 'grdf_type'
    AND sm_type.AttributeValue  = pc.grdf_type
    AND sm_type.LangId          = 1036
-- Jointure Priorité
LEFT JOIN dbo.StringMap AS sm_prio
    ON  sm_prio.ObjectTypeCode  = 4210
    AND sm_prio.AttributeName   = 'prioritycode'
    AND sm_prio.AttributeValue  = pc.PriorityCode
    AND sm_prio.LangId          = 1036
WHERE pc.CreatedOn >= '2023-01-01'
  AND (
        -- Au moins un contact destination (mask = 2) est HATVP
        EXISTS (
            SELECT 1
            FROM dbo.ActivityParty AS ap
            INNER JOIN dbo.Contact AS c
                ON  c.ContactId                 = ap.PartyId
                AND c.grdf_hatvp                = 1
            WHERE ap.ActivityId                 = pc.ActivityId
              AND ap.ParticipationTypeMask       = 2
              AND ap.IsPartyDeleted              = 0
        )
        OR
        -- Ou contact origine (mask = 1) est HATVP
        EXISTS (
            SELECT 1
            FROM dbo.ActivityParty AS ap
            INNER JOIN dbo.Contact AS c
                ON  c.ContactId                 = ap.PartyId
                AND c.grdf_hatvp                = 1
            WHERE ap.ActivityId                 = pc.ActivityId
              AND ap.ParticipationTypeMask       = 1
              AND ap.IsPartyDeleted              = 0
        )
      )
GROUP BY
    pc.ActivityId,
    pc.Subject,
    pc.OwnerIdName,
    pc.Description,
    pc.RegardingObjectIdName,
    pc.DirectionCode,
    pc.OverriddenCreatedOn,
    pc.ScheduledStart,
    pc.ScheduledEnd,
    pc.ActualDurationMinutes,
    pc.grdf_thematique,
    pc.grdf_type
