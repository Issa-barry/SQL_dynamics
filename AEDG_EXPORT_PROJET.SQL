
SELECT TOP 10
    o.OpportunityId,
    o.grdf_reference                        AS [Référence],
    o.Name                                  AS [Désignation du projet],

    -- Localisation
    o.grdf_adresse                          AS [Adresse],
    o.grdf_code_postal                      AS [Code postal],
    o.grdf_ville                            AS [Ville],

    -- Agence
    o.grdf_agenceidName                     AS [Agence],

    -- Maître d'ouvrage
    o.AccountIdName                         AS [MOA],
    o.grdf_sci_sccv_sdc_exploitant_chauffageidName AS [SCI/SCCV/SDC],

    -- Qualification
    o.grdf_segment_marche                   AS [Segment marché],
    o.grdf_segment_dev                      AS [Segment dev],
    o.grdf_sous_segment_developpement       AS [Sous-segment],
    o.grdf_existant_neuf                    AS [Existant/Neuf],
    o.grdf_fidelisation                     AS [Fidélisation],

    -- Intervenants
    o.OwnerIdName                           AS [Propriétaire],
    o.grdf_responsableidName                AS [Responsable],
    o.grdf_utilisateuridName                AS [Utilisateur],

    -- Statut (StateCode)
    CASE o.StateCode
        WHEN 0 THEN 'Ouvert'
        WHEN 1 THEN 'Clôturé Gagné'
        WHEN 2 THEN 'Clôturé'
    END                                     AS [Statut],

    -- ✅ Raison du statut — codes standards + codes GRDF
    CASE o.StatusCode
        -- Codes standards Dynamics (1, 2, 3, 4...)
        WHEN 1  THEN 'Projet Avéré'
        WHEN 2  THEN 'Etude Technique'
        WHEN 3  THEN 'Proposé'
        WHEN 4  THEN 'Clôturé Gagné'
        WHEN 5  THEN 'Accepté'
        -- Codes GRDF custom (996270xxx)
        WHEN 996270000 THEN 'Projet Avéré'
        WHEN 996270001 THEN 'Etude Technique'
        WHEN 996270004 THEN 'Projet Avancé'
        WHEN 996270009 THEN 'Proposé'
        WHEN 996270012 THEN 'Accepté'
        WHEN 996270003 THEN 'Clôturé Gagné'
        WHEN 996270002 THEN 'Doublon'
        WHEN 996270010 THEN 'Supérieur'
        WHEN 996270011 THEN 'Monox'
        WHEN 996270013 THEN 'En cours'
        WHEN 996270020 THEN 'Supprimé'
        WHEN 996270021 THEN 'Perdu'
        WHEN 996270023 THEN 'Abandonné'
        WHEN 996270036 THEN 'Autre clôture'
        WHEN 996270043 THEN 'Non abouti'
        ELSE CAST(o.StatusCode AS VARCHAR)
    END                                     AS [Raison du statut],

    -- Dates clés
    o.CreatedOn                             AS [Créé le],
    o.grdf_date_jalon_projet_avere          AS [Date projet avéré],
    o.grdf_date_etape_etude_technique       AS [Date étude technique],
    o.grdf_date_etape_propose               AS [Date proposé],
    o.grdf_date_etape_accepte               AS [Date accepté],
    o.grdf_date_etape_cloture_gagne         AS [Date clôture gagné],

    -- Données techniques
    o.grdf_puissance_totale_installee       AS [Puissance totale (kW)],
    o.grdf_surface_concernee_m2             AS [Surface (m²)],
    o.grdf_nombre_logements                 AS [Nb logements],
    o.grdf_nombre_locaux_commerciaux        AS [Nb locaux commerciaux],
    o.grdf_chiffre_affaire                  AS [Chiffre d'affaires],
    o.grdf_conso_ref_mwh                    AS [Conso ref (MWh)],

    -- Liens
    o.grdf_lien_eracco                      AS [Lien ERACCO],
    o.grdf_lien_omer                        AS [Lien OMER]

FROM Opportunity o
ORDER BY o.CreatedOn DESC
