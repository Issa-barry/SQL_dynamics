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
            SELECT a.Name
            FROM dbo.Account AS a
            WHERE a.AccountId = pc.RegardingObjectId
        )
        ELSE pc.RegardingObjectIdName
    END                                 AS Concernant,

    -- Type du concernant
    CASE
        WHEN pc.RegardingObjectTypeCode = 2 THEN 'Contact'
        WHEN pc.RegardingObjectTypeCode = 1 THEN 'Compte'
        WHEN pc.RegardingObjectTypeCode = 4 THEN 'Opportunité'
        ELSE CAST(pc.RegardingObjectTypeCode AS NVARCHAR(50))
    END                                 AS TypeConcernant,

    -- Direction (Entrant/Sortant)
    CASE WHEN pc.DirectionCode = 1
         THEN 'Sortant'
         ELSE 'Entrant'
    END                                 AS Direction,

    -- Origine de l'appel (mask = 1)
    (
        SELECT STRING_AGG(
            CAST(
                ISNULL(c.LastName,  ap.PartyIdName) + ' | ' +
                ISNULL(c.FirstName, '-')             + ' | ' +
                ISNULL(sm_fonc.Value, '-')
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

    -- Destination de l'appel (mask = 2)
    (
        SELECT STRING_AGG(
            CAST(
                ISNULL(c.LastName,  ap.PartyIdName) + ' | ' +
                ISNULL(c.FirstName, '-')             + ' | ' +
                ISNULL(sm_fonc.Value, '-')
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
  AND pc.ActivityId IN (
    '427FF4DB-A795-F011-8134-005056BE5B03'
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
    pc.ScheduledEnd,
    pc.ActualDurationMinutes,
    pc.grdf_thematique,
    pc.grdf_type
