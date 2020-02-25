{% extends "basis.jinja.sql" %}

-- SPDX-FileCopyrightText: 2018-2020 Magenta ApS
-- SPDX-License-Identifier: MPL-2.0


{% block body %}

-- Also notice, that the given arrays of {{oio_type|title}}Attr...Type
-- must be consistent regarding virkning (although the allowance of
-- null-values might make it possible to construct
-- 'logically consistent'-arrays of objects with overlapping virknings)
CREATE OR REPLACE FUNCTION as_update_{{oio_type}}(
    {{oio_type}}_uuid uuid,
    brugerref uuid,
    note text,
    livscykluskode Livscykluskode,

    {% for attribut, attribut_fields in attributter.items() %}
    attr{{attribut|title}} {{oio_type|title}}{{attribut|title}}AttrType[],
    {% endfor %}

    {% for tilstand, tilstand_values in tilstande.items() %}
    tils{{tilstand|title}} {{oio_type|title}}{{tilstand|title}}TilsType[],
    {% endfor %}

    relationer {{oio_type|title}}RelationType[],

    {% if oio_type == "dokument" %}
    varianter DokumentVariantType[],
    {% endif %}

    lostUpdatePreventionTZ TIMESTAMPTZ = null,
    auth_criteria_arr      {{oio_type|title}}RegistreringType[] = null
) RETURNS bigint AS $$
DECLARE
    read_new_{{oio_type}}          {{oio_type|title}}Type;
    read_prev_{{oio_type}}         {{oio_type|title}}Type;
    read_new_{{oio_type}}_reg      {{oio_type|title}}RegistreringType;
    read_prev_{{oio_type}}_reg     {{oio_type|title}}RegistreringType;
    new_{{oio_type}}_registrering  {{oio_type}}_registrering;
    prev_{{oio_type}}_registrering {{oio_type}}_registrering;
    {{oio_type}}_relation_navn     {{oio_type|title}}RelationKode;

    {% for attribut , attribut_fields in attributter.items() %}
    attr{{attribut|title}}Obj {{oio_type|title}}{{attribut|title}}AttrType;
    {% endfor %}

    {% if oio_type == "klasse" %}
    new_id_klasse_attr_egenskaber bigint;
    klasseSoegeordObj KlasseSoegeordType;
    {% endif %}

    auth_filtered_uuids uuid[];

    {% if oio_type == "aktivitet" %}
    rel_type_max_index_prev_rev int;
    rel_type_max_index_arr _aktivitetRelationMaxIndex[];
    aktivitet_rel_type_cardinality_unlimited aktivitetRelationKode[]:=ARRAY['udfoererklasse'::AktivitetRelationKode,'deltagerklasse'::AktivitetRelationKode,'objektklasse'::AktivitetRelationKode,'resultatklasse'::AktivitetRelationKode,'grundlagklasse'::AktivitetRelationKode,'facilitetklasse'::AktivitetRelationKode,'adresse'::AktivitetRelationKode,'geoobjekt'::AktivitetRelationKode,'position'::AktivitetRelationKode,'facilitet'::AktivitetRelationKode,'lokale'::AktivitetRelationKode,'aktivitetdokument'::AktivitetRelationKode,'aktivitetgrundlag'::AktivitetRelationKode,'aktivitetresultat'::AktivitetRelationKode,'udfoerer'::AktivitetRelationKode,'deltager'::AktivitetRelationKode]::aktivitetRelationKode[];
    aktivitet_uuid_underscores text;
    aktivitet_rel_seq_name text;
    aktivitet_rel_type_cardinality_unlimited_present_in_argument aktivitetRelationKode[];
    {% elif oio_type == "dokument" %}
    dokument_variant_obj DokumentVariantType;
    dokument_variant_egenskab_obj DokumentVariantEgenskaberType;
    dokument_del_obj DokumentDelType;
    dokument_del_egenskaber_obj DokumentDelEgenskaberType;
    dokument_del_relation_obj DokumentDelRelationType;
    dokument_variant_new_id bigint;
    dokument_del_new_id bigint;
    dokument_variant_egenskaber_expl_deleted text[]:=array[]::text[];
    dokument_variant_dele_all_expl_deleted text[]:=array[]::text[];
    dokument_variant_del_egenskaber_deleted _DokumentVariantDelKey[]:=array[]::_DokumentVariantDelKey[];
    dokument_variant_del_relationer_deleted _DokumentVariantDelKey[]:=array[]::_DokumentVariantDelKey[];
    dokument_variants_prev_reg_arr text[];
    dokument_variant_egenskaber_prev_reg_varianttekst text;
    dokument_variant_id bigint;
    dokument_variant_del_prev_reg_arr _DokumentVariantDelKey[];
    dokument_variant_del_prev_reg _DokumentVariantDelKey;
    dokument_del_id bigint;
    dokument_variant_del_prev_reg_rel_transfer _DokumentVariantDelKey[];
    {% elif oio_type == "indsats" %}
    rel_type_max_index_prev_rev int;
    rel_type_max_index_arr _indsatsRelationMaxIndex[];
    indsats_rel_type_cardinality_unlimited indsatsRelationKode[]:=ARRAY['indsatskvalitet'::IndsatsRelationKode,'indsatsaktoer'::IndsatsRelationKode,'samtykke'::IndsatsRelationKode,'indsatssag'::IndsatsRelationKode,'indsatsdokument'::IndsatsRelationKode];
    indsats_uuid_underscores text;
    indsats_rel_seq_name text;
    indsats_rel_type_cardinality_unlimited_present_in_argument IndsatsRelationKode[];
    {% elif oio_type == "sag" %}
    rel_type_max_index_prev_rev int;
    rel_type_max_index_arr _SagRelationMaxIndex[];
    sag_rel_type_cardinality_unlimited SagRelationKode[]:=ARRAY['andetarkiv'::SagRelationKode,'andrebehandlere'::SagRelationKode,'sekundaerpart'::SagRelationKode,'andresager'::SagRelationKode,'byggeri'::SagRelationKode,'fredning'::SagRelationKode,'journalpost'::SagRelationKode]::SagRelationKode[];
    sag_uuid_underscores text;
    sag_rel_seq_name text;
    sag_rel_type_cardinality_unlimited_present_in_argument sagRelationKode[];
    {% elif oio_type == "tilstand" %}
    rel_type_max_index_prev_rev int;
    rel_type_max_index_arr _tilstandRelationMaxIndex[];
    tilstand_rel_type_cardinality_unlimited tilstandRelationKode[]:=ARRAY['tilstandsvaerdi'::TilstandRelationKode,'begrundelse'::TilstandRelationKode,'tilstandskvalitet'::TilstandRelationKode,'tilstandsvurdering'::TilstandRelationKode,'tilstandsaktoer'::TilstandRelationKode,'tilstandsudstyr'::TilstandRelationKode,'samtykke'::TilstandRelationKode,'tilstandsdokument'::TilstandRelationKode]::TilstandRelationKode[];
    tilstand_uuid_underscores text;
    tilstand_rel_seq_name text;
    tilstand_rel_type_cardinality_unlimited_present_in_argument tilstandRelationKode[];
    {% endif %}
BEGIN
    -- Create a new registrering
    IF NOT EXISTS (select a.id from {{oio_type}} a join {{oio_type}}_registrering b ON b.{{oio_type}}_id=a.id WHERE a.id={{oio_type}}_uuid) THEN
        RAISE EXCEPTION 'Unable to update {{oio_type}} with uuid [%], being unable to find any previous registrations.',{{oio_type}}_uuid USING ERRCODE = 'MO400';
    END IF;

    -- We synchronize concurrent invocations of as_updates of this particular
    -- object on a exclusive row lock. This lock will be held by the current
    -- transaction until it terminates.
    PERFORM a.id FROM {{oio_type}} a WHERE a.id={{oio_type}}_uuid FOR UPDATE;

    -- Verify that the object meets the stipulated access allowed criteria
    auth_filtered_uuids := _as_filter_unauth_{{oio_type}}(array[{{oio_type}}_uuid]::uuid[], auth_criteria_arr);
    IF NOT (coalesce(array_length(auth_filtered_uuids, 1), 0) = 1 AND auth_filtered_uuids @>ARRAY[{{oio_type}}_uuid]) THEN
      RAISE EXCEPTION 'Unable to update {{oio_type}} with uuid [%]. Object does not met stipulated criteria:%', {{oio_type}}_uuid, to_json(auth_criteria_arr) USING ERRCODE = 'MO401';
    END IF;

    new_{{oio_type}}_registrering := _as_create_{{oio_type}}_registrering({{oio_type}}_uuid, livscykluskode, brugerref, note);
    prev_{{oio_type}}_registrering := _as_get_prev_{{oio_type}}_registrering(new_{{oio_type}}_registrering);

    IF lostUpdatePreventionTZ IS NOT NULL THEN
      IF NOT (LOWER((prev_{{oio_type}}_registrering.registrering).timeperiod) = lostUpdatePreventionTZ) THEN
        RAISE EXCEPTION 'Unable to update {{oio_type}} with uuid [%], as the {{oio_type}} seems to have been updated since latest read by client (the given lostUpdatePreventionTZ [%] does not match the timesamp of latest registration [%]).', {{oio_type}}_uuid, lostUpdatePreventionTZ, LOWER((prev_{{oio_type}}_registrering.registrering).timeperiod) USING ERRCODE = 'MO409';
      END IF;
    END IF;

    -- Handle relationer (relations)
    IF relationer IS NOT NULL AND coalesce(array_length(relationer, 1), 0) = 0 THEN
        -- raise notice 'Skipping relations, as it is explicit set to empty array. Update note [%]', note;
    ELSE

    -- 1) Insert relations given as part of this update
    -- 2) for aktivitet: Insert relations of previous registration, with index
    --      values not included in this update. Please notice that for the
    --      logic to work, it is very important that the index sequences
    --      start with the max value for index of the same type in the
    --      previous registration
    -- 2) for everything else: Insert relations of previous registration,
    --      taking overlapping virknings into consideration
    --      (using function subtract_tstzrange)

    --Ad 1)
    {% if oio_type in ("aktivitet", "indsats", "sag", "tilstand") %}
    -- Build array with the max index values of the different types of
    -- relations of the previous registration
    {% if oio_type == "sag" %}
    SELECT array_agg(rel_type_max_index)::_{{oio_type|title}}RelationMaxIndex[] into rel_type_max_index_arr
    {% else %}
    SELECT array_agg(rel_type_max_index)::_{{oio_type}}RelationMaxIndex[] into rel_type_max_index_arr
    {% endif %}
    FROM
    (
        SELECT
        {% if oio_type == "sag" %}
        (ROW(rel_type,coalesce(max(rel_index),0))::_{{oio_type|title}}RelationMaxIndex) rel_type_max_index
        {% else %}
        (ROW(rel_type,coalesce(max(rel_index),0))::_{{oio_type}}RelationMaxIndex) rel_type_max_index
        {% endif %}
            FROM {{oio_type}}_relation a
           WHERE a.{{oio_type}}_registrering_id=prev_{{oio_type}}_registrering.id
             AND a.rel_type = ANY ({{oio_type}}_rel_type_cardinality_unlimited)
        GROUP BY rel_type
    ) AS a;

 
    ---Create temporary sequences
    {% if oio_type != "tilstand" %}
    {{oio_type}}_uuid_underscores:=replace({{oio_type}}_uuid::text, '-', '_');
    {% endif %}

    SELECT array_agg(DISTINCT a.RelType) INTO {{oio_type}}_rel_type_cardinality_unlimited_present_in_argument FROM unnest(relationer) a WHERE a.RelType = ANY ({{oio_type}}_rel_type_cardinality_unlimited);
    {% if oio_type == "tilstand" %}
    {{oio_type}}_uuid_underscores := replace({{oio_type}}_uuid::text, '-', '_');
    {% endif %}

    IF coalesce(array_length({{oio_type}}_rel_type_cardinality_unlimited_present_in_argument, 1), 0) > 0 THEN
        FOREACH {{oio_type}}_relation_navn IN ARRAY ({{oio_type}}_rel_type_cardinality_unlimited_present_in_argument) LOOP
            {{oio_type}}_rel_seq_name := '{{oio_type}}_' || {{oio_type}}_relation_navn::text || {{oio_type}}_uuid_underscores;

            rel_type_max_index_prev_rev := null;

            SELECT a.indeks into rel_type_max_index_prev_rev
              FROM unnest(rel_type_max_index_arr) a(relType,indeks)
             WHERE a.relType={{oio_type}}_relation_navn;

            IF rel_type_max_index_prev_rev IS NULL THEN
              rel_type_max_index_prev_rev := 0;
            END IF;

            EXECUTE 'CREATE TEMPORARY SEQUENCE ' || {{oio_type}}_rel_seq_name || '
            INCREMENT 1
            MINVALUE 1
            MAXVALUE 9223372036854775807
            START ' ||  (rel_type_max_index_prev_rev+1)::text ||'
            CACHE 1;';

        END LOOP;
    END IF;
    {% endif %}

    INSERT INTO {{oio_type}}_relation ({{oio_type}}_registrering_id, virkning, rel_maal_uuid, rel_maal_urn, rel_type, objekt_type {% if oio_type == "aktivitet" %}, rel_index, aktoer_attr {% elif oio_type == "indsats" %}, rel_index {% elif oio_type == "sag" %}, rel_index, rel_type_spec, journal_notat, journal_dokument_attr {% elif oio_type == "tilstand" %}, rel_index, tilstand_vaerdi_attr {% endif %})
    SELECT
        new_{{oio_type}}_registrering.id,
        a.virkning,
        a.uuid,
        a.urn,
        a.relType,
        a.objektType {% if oio_type == "aktivitet" %},
            CASE WHEN a.relType = ANY (aktivitet_rel_type_cardinality_unlimited) THEN
                CASE WHEN a.indeks IS NULL
                    OR b.id IS NULL THEN
                    -- For new relations and relations with index given that
                    -- is not found in prev registrering, we'll assign new
                    -- index values.
                    nextval('aktivitet_' || a.relType::text || aktivitet_uuid_underscores)
                ELSE
                    a.indeks
                END
            ELSE
                NULL
            END,
            CASE WHEN a.relType = ('udfoerer'::AktivitetRelationKode)
                OR rel_type = ('deltager'::AktivitetRelationKode)
                OR rel_type = ('ansvarlig'::AktivitetRelationKode)
                AND NOT (a.aktoerAttr IS NULL)
                AND ((a.aktoerAttr).obligatorisk IS NOT NULL
                    OR (a.aktoerAttr).accepteret IS NOT NULL
                    OR ((a.aktoerAttr).repraesentation_uuid IS NOT NULL
                        OR ((a.aktoerAttr).repraesentation_urn IS NOT NULL
                            AND (a.aktoerAttr).repraesentation_urn <> ''))) THEN
                a.aktoerAttr
            ELSE
                NULL
            END {% elif oio_type == "indsats" %},
            CASE WHEN a.relType = ANY (indsats_rel_type_cardinality_unlimited) THEN
                CASE WHEN a.indeks IS NULL
                    OR b.id IS NULL THEN
                    -- For new relations and relations with index given that
                    -- is not found in prev registrering, we'll assign new
                    -- index values.
                    nextval('indsats_' || a.relType::text || indsats_uuid_underscores)
                ELSE
                    a.indeks
                END
            ELSE
                NULL
            END {% elif oio_type == "sag" %},
            CASE WHEN a.relType = ANY (sag_rel_type_cardinality_unlimited) THEN
                CASE WHEN a.indeks IS NULL
                    OR b.id IS NULL THEN
                    -- For new relations and relations with index given that
                    -- is not found in prev registrering, we'll assign new
                    -- index values.
                    nextval('sag_' || a.relType::text || sag_uuid_underscores)
                ELSE
                    a.indeks
                END
            ELSE
                NULL
            END,
            CASE WHEN a.relType = 'journalpost' THEN
                a.relTypeSpec
            ELSE
                NULL
            END,
            CASE WHEN (NOT (a.journalNotat IS NULL))
                AND ((a.journalNotat).titel IS NOT NULL
                    OR (a.journalNotat).notat IS NOT NULL
                    OR (a.journalNotat).format IS NOT NULL) THEN
                a.journalNotat
            ELSE
                NULL
            END,
            CASE WHEN ((NOT a.journalDokumentAttr IS NULL)
                    AND ((a.journalDokumentAttr).dokumenttitel IS NOT NULL
                        OR (NOT ((a.journalDokumentAttr).offentlighedUndtaget IS NULL)
                            AND (((a.journalDokumentAttr).offentlighedUndtaget).AlternativTitel IS NOT NULL
                                OR ((a.journalDokumentAttr).offentlighedUndtaget).Hjemmel IS NOT NULL)))) THEN
                a.journalDokumentAttr
            ELSE
                NULL
            END {% elif oio_type == "tilstand" %},
            CASE WHEN a.relType = ANY (tilstand_rel_type_cardinality_unlimited) THEN
                CASE WHEN a.indeks IS NULL
                    OR b.id IS NULL THEN
                    -- For new relations and relations with index given that
                    -- is not found in prev registrering, we'll assign new
                    -- index values.
                    nextval('tilstand_' || a.relType::text || tilstand_uuid_underscores)
                ELSE
                    a.indeks
                END
            ELSE
                NULL
            END,
            CASE WHEN a.relType = 'tilstandsvaerdi'
                AND (NOT ((a.tilstandsVaerdiAttr)
                        IS NULL))
                AND ((a.tilstandsVaerdiAttr).forventet IS NOT NULL
                    OR (a.tilstandsVaerdiAttr).nominelVaerdi IS NOT NULL) THEN
                (a.tilstandsVaerdiAttr)
            ELSE
                NULL
            END {% endif %}
        FROM
            unnest(relationer) AS a {% if oio_type in ("aktivitet", "indsats", "sag", "tilstand") %}
        LEFT JOIN {{oio_type}}_relation b ON a.relType = ANY ({{oio_type}}_rel_type_cardinality_unlimited) AND b.{{oio_type}}_registrering_id = prev_{{oio_type}}_registrering.id AND a.relType = b.rel_type AND a.indeks = b.rel_index {% endif %};

    {% if oio_type in ("aktivitet", "indsats", "sag", "tilstand") %}
    -- Drop temporary sequences
    IF coalesce(array_length({{oio_type}}_rel_type_cardinality_unlimited_present_in_argument, 1), 0) > 0 THEN
        {% if oio_type == "tilstand" %}
        FOREACH tilstand_relation_navn IN ARRAY (SELECT array_agg(DISTINCT a.RelType) FROM unnest(relationer) a WHERE a.RelType = ANY (tilstand_rel_type_cardinality_unlimited))
        {% else %}
        FOREACH {{oio_type}}_relation_navn IN ARRAY ({{oio_type}}_rel_type_cardinality_unlimited_present_in_argument)
        {% endif %}
        LOOP
          {{oio_type}}_rel_seq_name := '{{oio_type}}_' || {{oio_type}}_relation_navn::text || {{oio_type}}_uuid_underscores;
          EXECUTE 'DROP SEQUENCE ' || {{oio_type}}_rel_seq_name || ';';
        END LOOP;
    END IF;
    {% endif %}


    -- Ad 2)
    -- 0..1 relations

    {% if oio_type in ("aktivitet", "indsats", "sag", "tilstand") %}
    -- Please notice, that for 0..1 relations for aktivitet, we're ignoring index
    -- here, and handling it the same way, that is done for other object types (like
    -- Facet, Klasse etc). That is, you only make changes for the
    -- virkningsperiod that you explicitly specify (unless you delete all relations)
    {% endif %}
    {% if oio_type == "indsats" %}
    FOREACH indsats_relation_navn IN ARRAY ARRAY['indsatstype'::IndsatsRelationKode, 'indsatsmodtager'::IndsatsRelationKode]::IndsatsRelationKode[]
    {% else %}
    FOREACH {{oio_type}}_relation_navn IN ARRAY ARRAY[{% for relkode in relationer_nul_til_en %}'{{relkode}}'::{{oio_type|title}}RelationKode {% if not loop.last %}, {% endif %} {% endfor %}]::{{oio_type|title}}RelationKode[] {% endif %} LOOP
        INSERT INTO {{oio_type}}_relation ({{oio_type}}_registrering_id, virkning, rel_maal_uuid, rel_maal_urn, rel_type, objekt_type {% if oio_type == "aktivitet" %}, rel_index, aktoer_attr {% elif oio_type == "indsats" %}, rel_index {% elif oio_type == "sag" %}, rel_index, rel_type_spec, journal_notat, journal_dokument_attr {% elif oio_type == "tilstand" %}, rel_index, tilstand_vaerdi_attr {% endif %})
        SELECT
            new_{{oio_type}}_registrering.id,
            ROW (c.tz_range_leftover,
                (a.virkning).AktoerRef,
                (a.virkning).AktoerTypeKode,
                (a.virkning).NoteTekst)::virkning,
            a.rel_maal_uuid,
            a.rel_maal_urn,
            a.rel_type,
            a.objekt_type {% if oio_type == "aktivitet" %},
                NULL, -- a.rel_index, rel_index is not to be used for 0..1 relations
                a.aktoer_attr {% elif oio_type == "indsats" %},
                NULL -- a.rel_index, rel_index is not to be used for 0..1 relations
                {% elif oio_type == "sag" %},
                NULL, -- a.rel_index, rel_index is not to be used for 0..1 relations
                a.rel_type_spec,
                a.journal_notat,
                a.journal_dokument_attr {% elif oio_type == "tilstand" %},
                NULL, -- a.rel_index, rel_index is not to be used for 0..1 relations
                a.tilstand_vaerdi_attr {% endif %}
            FROM (
                -- Build an array of the timeperiod of the virkning of the
                -- relations of the new registrering to pass to
                -- _subtract_tstzrange_arr on the relations of the previous
                -- registrering.
                SELECT coalesce(array_agg((b.virkning).TimePeriod), ARRAY[]::TSTZRANGE[]) tzranges_of_new_reg
                  FROM {{oio_type}}_relation b
                 WHERE b.{{oio_type}}_registrering_id = new_{{oio_type}}_registrering.id AND b.rel_type = {{oio_type}}_relation_navn) d
            JOIN {{oio_type}}_relation a ON TRUE
            JOIN unnest(_subtract_tstzrange_arr ((a.virkning).TimePeriod, tzranges_of_new_reg)) AS c (tz_range_leftover) ON TRUE
        WHERE
            a.{{oio_type}}_registrering_id = prev_{{oio_type}}_registrering.id AND a.rel_type = {{oio_type}}_relation_navn;
    END LOOP;

    -- 0..n relations
    -- We only have to check if there are any of the relations with the
    -- given name present in the new registration, otherwise copy the ones
    -- from the previous registration.

    {% if oio_type not in ("aktivitet", "indsats", "sag", "tilstand") %}
    FOREACH {{oio_type}}_relation_navn IN ARRAY ARRAY[{% for relkode in relationer_nul_til_mange %}'{{relkode}}'::{{oio_type|title}}RelationKode{% if not loop.last %}, {% endif %}{% endfor %}]::{{oio_type|title}}RelationKode[] LOOP
        IF NOT EXISTS (
                    SELECT 1
                      FROM {{oio_type}}_relation
                     WHERE {{oio_type}}_registrering_id = new_{{oio_type}}_registrering.id AND rel_type = {{oio_type}}_relation_navn) THEN
                    {% endif %}
                    INSERT INTO {{oio_type}}_relation ({{oio_type}}_registrering_id, virkning, rel_maal_uuid, rel_maal_urn, rel_type, objekt_type {% if oio_type == "aktivitet" %}, rel_index, aktoer_attr {% elif oio_type == "indsats" %}, rel_index {% elif oio_type == "sag" %}, rel_index, rel_type_spec, journal_notat, journal_dokument_attr {% elif oio_type == "tilstand" %}, rel_index, tilstand_vaerdi_attr {% endif %})
                    SELECT
                        new_{{oio_type}}_registrering.id, {% if oio_type == "aktivitet" %} a.virkning, a.rel_maal_uuid, a.rel_maal_urn, a.rel_type, a.objekt_type, a.rel_index, a.aktoer_attr
                        FROM aktivitet_relation a
                        LEFT JOIN aktivitet_relation b ON b.aktivitet_registrering_id = new_aktivitet_registrering.id AND b.rel_type = a.rel_type AND b.rel_index = a.rel_index
                    WHERE
                        a.aktivitet_registrering_id = prev_aktivitet_registrering.id AND a.rel_type = ANY (aktivitet_rel_type_cardinality_unlimited) AND b.id IS NULL
                        -- Don't transfer relations of prev. registrering, if
                        -- the index was specified in data given to the/this
                        -- update-function
                        {% elif oio_type == "indsats" %} a.virkning, a.rel_maal_uuid, a.rel_maal_urn, a.rel_type, a.objekt_type, a.rel_index
                    FROM indsats_relation a
                    LEFT JOIN indsats_relation b ON b.indsats_registrering_id = new_indsats_registrering.id AND b.rel_type = a.rel_type AND b.rel_index = a.rel_index
                WHERE
                    a.indsats_registrering_id = prev_indsats_registrering.id AND a.rel_type = ANY (indsats_rel_type_cardinality_unlimited) AND b.id IS NULL
                    -- Don't transfer relations of prev. registrering,
                    -- if the index was specified in data given to the/this
                    -- update-function
                    {% elif oio_type == "sag" %} a.virkning, a.rel_maal_uuid, a.rel_maal_urn, a.rel_type, a.objekt_type, a.rel_index, a.rel_type_spec, a.journal_notat, a.journal_dokument_attr
                FROM sag_relation a
                LEFT JOIN sag_relation b ON b.sag_registrering_id = new_sag_registrering.id AND b.rel_type = a.rel_type AND b.rel_index = a.rel_index
            WHERE
                a.sag_registrering_id = prev_sag_registrering.id AND a.rel_type = ANY (sag_rel_type_cardinality_unlimited) AND b.id IS NULL
                -- Don't transfer relations of prev. registrering, if the
                -- index was specified in data given to the/this
                -- update-function
                {% elif oio_type == "tilstand" %} a.virkning, a.rel_maal_uuid, a.rel_maal_urn, a.rel_type, a.objekt_type, a.rel_index, a.tilstand_vaerdi_attr
            FROM tilstand_relation a
            LEFT JOIN tilstand_relation b ON b.tilstand_registrering_id = new_tilstand_registrering.id AND b.rel_type = a.rel_type AND b.rel_index = a.rel_index
        WHERE
            a.tilstand_registrering_id = prev_tilstand_registrering.id AND a.rel_type = ANY (tilstand_rel_type_cardinality_unlimited) AND b.id IS NULL
            -- Don't transfer relations of prev. registrering, if the index
            -- was specified in data given to the/this update-function
            {% else %} virkning, rel_maal_uuid, rel_maal_urn, rel_type, objekt_type
        FROM {{oio_type}}_relation
        WHERE
            {{oio_type}}_registrering_id = prev_{{oio_type}}_registrering.id AND rel_type = {{oio_type}}_relation_navn {% endif %};

    {% if oio_type not in ("aktivitet", "indsats", "sag", "tilstand") %}
        END IF;
    END LOOP;
    {% endif %}
    END IF;


    -- Handle tilstande (states)
    {% for tilstand, tilstand_values in tilstande.items() %}
    IF tils{{tilstand|title}} IS NOT NULL AND coalesce(array_length(tils{{tilstand|title}}, 1), 0) = 0 THEN
        -- raise debug 'Skipping [{{tilstand|title}}] as it is explicit set to empty array';
    ELSE
        -- 1) Insert tilstande/states given as part of this update
        -- 2) Insert tilstande/states of previous registration, taking
        --      overlapping virknings into consideration (using function
        --      subtract_tstzrange)

        -- {{oio_type}}_tils_{{tilstand}}

        -- Ad 1)
        INSERT INTO {{oio_type}}_tils_{{tilstand}}(virkning, {{tilstand}}, {{oio_type}}_registrering_id)
             SELECT a.virkning, a.{{tilstand}}, new_{{oio_type}}_registrering.id
               FROM unnest(tils{{tilstand|title}}) AS a;

        -- Ad 2
        INSERT INTO {{oio_type}}_tils_{{tilstand}}(virkning, {{tilstand}}, {{oio_type}}_registrering_id)
        SELECT
            ROW (c.tz_range_leftover,
                (a.virkning).AktoerRef,
                (a.virkning).AktoerTypeKode,
                (a.virkning).NoteTekst)::virkning,
            a.{{tilstand}},
            new_{{oio_type}}_registrering.id
        FROM (
            -- Build an array of the timeperiod of the virkning of the
            -- {{oio_type}}_tils_{{tilstand}} of the new registrering to
            -- pass to _subtract_tstzrange_arr on the
            -- {{oio_type}}_tils_{{tilstand}} of the previous registrering
            SELECT coalesce(array_agg((b.virkning).TimePeriod), ARRAY[]::TSTZRANGE[]) tzranges_of_new_reg
              FROM {{oio_type}}_tils_{{tilstand}} b
             WHERE b.{{oio_type}}_registrering_id = new_{{oio_type}}_registrering.id) d
              JOIN {{oio_type}}_tils_{{tilstand}} a ON TRUE
              JOIN unnest(_subtract_tstzrange_arr ((a.virkning).TimePeriod, tzranges_of_new_reg)) AS c (tz_range_leftover) ON TRUE
        WHERE a.{{oio_type}}_registrering_id = prev_{{oio_type}}_registrering.id;
    END IF;
    {% endfor %}


    -- Handle attributter (attributes)
    {% for attribut, attribut_fields in attributter.items() %}
    -- {{oio_type}}_attr_{{attribut}}

    -- Generate and insert any merged objects, if any fields are null
    -- in attr{{oio_type|title}}Obj
    IF attr{{attribut|title}} IS NOT NULL THEN
        --Input validation:
        --Verify that there is no overlap in virkning in the array given
        IF EXISTS (
                SELECT a.* FROM
                    unnest(attr{{attribut|title}}) a
                    JOIN unnest(attr{{attribut|title}}) b ON (a.virkning).TimePeriod && (b.virkning).TimePeriod
                GROUP BY
                    a.{{attribut_fields|join(',a.')}},
                    a.virkning
                    {% if oio_type == "klasse" %},
                        a.soegeord
                    {% endif %}
                    HAVING COUNT(*) > 1) THEN
                    RAISE EXCEPTION 'Unable to update {{oio_type}} with uuid [%], as the {{oio_type}} have overlapping virknings in the given {{attribut}} array :%', {{oio_type}}_uuid, to_json(attr{{attribut|title}}) USING ERRCODE = 'MO400';
    END IF;

    FOREACH attr{{attribut|title}}Obj IN ARRAY attr{{attribut|title}} LOOP
        -- To avoid needless fragmentation we'll check for presence of
        -- null values in the fields - and if none are present, we'll skip
        -- the merging operations
        IF {% for field in attribut_fields %} (attr{{attribut|title}}Obj).{{field}} IS NULL {% if not loop.last %} OR {% endif %}{% endfor %} THEN
            {% if oio_type == "klasse" %} WITH inserted_merged_attr_egenskaber AS ({% endif %}
            INSERT INTO {{oio_type}}_attr_{{attribut}} ({% if oio_type == "klasse" %} id, {% endif %} {{attribut_fields|join(',')}}, virkning, {{oio_type}}_registrering_id)
                SELECT
                    {% for fieldname in attribut_fields %}
                        {% if oio_type == "klasse" and loop.first %} nextval('klasse_attr_egenskaber_id_seq'), {% endif %}
                        {% if (attributter_metadata[attribut][fieldname]['type'] in ("int", "date", "timestamptz", "boolean", "interval(0)")) %}
                            CASE WHEN ((attr{{attribut|title}}Obj.{{fieldname}}).cleared) THEN
                                NULL
                            ELSE
                                coalesce((attr{{attribut|title}}Obj.{{fieldname}}).value, a.{{fieldname}})
                            END,
                        {% else %}
                            coalesce(attr{{attribut|title}}Obj.{{fieldname}}, a.{{fieldname}}),{% endif %}
                    {% endfor %}
                    ROW ((a.virkning).TimePeriod * (attr{{attribut|title}}Obj.virkning).TimePeriod,
                            (attr{{attribut|title}}Obj.virkning).AktoerRef,
                            (attr{{attribut|title}}Obj.virkning).AktoerTypeKode,
                            (attr{{attribut|title}}Obj.virkning).NoteTekst)::Virkning,
                            new_{{oio_type}}_registrering.id
                        FROM {{oio_type}}_attr_{{attribut}} a
                    WHERE
                        a.{{oio_type}}_registrering_id = prev_{{oio_type}}_registrering.id
                        AND (a.virkning).TimePeriod && (attr{{attribut|title}}Obj.virkning).TimePeriod
                        {% if oio_type == "klasse" %}
                        RETURNING
                            id new_id,
                            (virkning).TimePeriod merged_timeperiod
                        ) INSERT INTO klasse_attr_egenskaber_soegeord (soegeordidentifikator, beskrivelse, soegeordskategori, klasse_attr_egenskaber_id)
                        SELECT
                            coalesce(b.soegeordidentifikator, c.soegeordidentifikator), --please notice that this is not a merge - one of the joins on b or c will fail.
                            coalesce(b.beskrivelse, c.beskrivelse), --please notice that this is not a merge - one of the joins on b or c will fail.
                            coalesce(b.soegeordskategori, c.soegeordskategori), --please notice that this is not a merge - one of the joins on b or c will fail.
                            a.new_id
                        FROM
                            inserted_merged_attr_egenskaber a
                            LEFT JOIN unnest(attrEgenskaberObj.soegeord) AS b (soegeordidentifikator,
                                beskrivelse,
                                soegeordskategori) ON attrEgenskaberObj.soegeord IS NOT NULL
                            LEFT JOIN klasse_attr_egenskaber AS b2 ON attrEgenskaberObj.soegeord IS NULL AND b2.klasse_registrering_id = prev_klasse_registrering.id AND (b2.virkning).TimePeriod @> a.merged_timeperiod --Please notice, that this will max hit exactly one row - the row that the new id was merged with
                            LEFT JOIN klasse_attr_egenskaber_soegeord AS c ON attrEgenskaberObj.soegeord IS NULL AND c.klasse_attr_egenskaber_id = b2.id
                        WHERE ((attrEgenskaberObj.soegeord IS NULL AND c.id IS NOT NULL) --there is sogeord of merged egenskab
                            OR coalesce(array_length(attrEgenskaberObj.soegeord, 1), 0) > 0 --soegeord is defined in array
                        ) AND (NOT (attrEgenskaberObj.soegeord IS NOT NULL AND array_length(attrEgenskaberObj.soegeord, 1) = 0)) --if the array is empty, no sogeord should be inserted
                        {% endif %};

        -- For any periods within the virkning of the attr{{attribut|title}}Obj,
        -- that is NOT covered by any "merged" rows inserted above, generate
        -- and insert rows.
        {% if oio_type == "klasse" %}
        WITH inserted_attr_egenskaber AS (
        {% endif %}
            INSERT INTO {{oio_type}}_attr_{{attribut}} ({% if oio_type == "klasse" %} id, {% endif %} {{attribut_fields|join(',')}}, virkning, {{oio_type}}_registrering_id)
                SELECT
                    {% for fieldname in attribut_fields %}
                    {% if oio_type == "klasse" and loop.first %} nextval('klasse_attr_egenskaber_id_seq'),{% endif %} attr{{attribut|title}}Obj.{{fieldname}},
                    {% endfor %}
                    ROW (b.tz_range_leftover,
                        (attr{{attribut|title}}Obj.virkning).AktoerRef,
                        (attr{{attribut|title}}Obj.virkning).AktoerTypeKode,
                        (attr{{attribut|title}}Obj.virkning).NoteTekst)::Virkning,
                        new_{{oio_type}}_registrering.id
                    FROM (
                        -- Build an array of the timeperiod of the virkning
                        -- of the {{oio_type}}_attr_{{attribut}} of the new
                        -- registrering to pass to _subtract_tstzrange_arr.
                        SELECT
                            coalesce(array_agg((b.virkning).TimePeriod), ARRAY[]::TSTZRANGE[]) tzranges_of_new_reg
                        FROM {{oio_type}}_attr_{{attribut}} b
                    WHERE b.{{oio_type}}_registrering_id = new_{{oio_type}}_registrering.id) AS a
                    JOIN unnest(_subtract_tstzrange_arr ((attr{{attribut|title}}Obj.virkning).TimePeriod, a.tzranges_of_new_reg)) AS b (tz_range_leftover) ON TRUE {% if oio_type == "klasse" %}
                    RETURNING id
        ) INSERT INTO klasse_attr_egenskaber_soegeord(soegeordidentifikator, beskrivelse, soegeordskategori, klasse_attr_egenskaber_id)
        SELECT
            a.soegeordidentifikator,
            a.beskrivelse,
            a.soegeordskategori,
            b.id
        FROM
            unnest(attrEgenskaberObj.soegeord) AS a (soegeordidentifikator,
                beskrivelse,
                soegeordskategori)
            JOIN inserted_attr_egenskaber b ON TRUE {% endif %};

        ELSE
            -- Insert attr{{attribut|title}}Obj raw (if there were no null-valued fields)
            {% if oio_type == "klasse" %}
            new_id_klasse_attr_egenskaber := nextval('klasse_attr_egenskaber_id_seq');
            {% endif %}

            INSERT INTO {{oio_type}}_attr_{{attribut}} ({% if oio_type == "klasse" %} id, {% endif %} {{attribut_fields|join(',')}}, virkning, {{oio_type}}_registrering_id)
                VALUES ({% if oio_type == "klasse" %} new_id_klasse_attr_egenskaber, {% endif %} {% for fieldname in attribut_fields %} attr{{attribut|title}}Obj.{{fieldname}}, {% endfor %}attr{{attribut|title}}Obj.virkning, new_{{oio_type}}_registrering.id {% if oio_type == "klasse" %});
        IF attrEgenskaberObj.soegeord IS NOT NULL THEN
            INSERT INTO klasse_attr_egenskaber_soegeord (soegeordidentifikator, beskrivelse, soegeordskategori, klasse_attr_egenskaber_id)
            SELECT
                a.soegeordidentifikator,
                a.beskrivelse,
                a.soegeordskategori,
                new_id_klasse_attr_egenskaber
            FROM
                unnest(attrEgenskaberObj.soegeord) AS a (soegeordidentifikator, beskrivelse, soegeordskategori);
        END IF;

        {% else %});{% endif %}
        END IF;

        END LOOP;

        END IF;

        IF attr{{attribut|title}} IS NOT NULL AND coalesce(array_length(attr{{attribut|title}}, 1), 0) = 0 THEN
            -- raise debug 'Skipping handling of {{attribut}} of previous registration as an empty array was explicit given.';
        ELSE



-- Handle {{attribut}} of previous registration, taking overlapping
-- virknings into consideration (using function subtract_tstzrange)
{% if oio_type == "klasse" %}
WITH copied_attr_egenskaber AS (
{% endif %}
    INSERT INTO {{oio_type}}_attr_{{attribut}} ({% if oio_type == "klasse" and loop.first %} id, {% endif %} {{attribut_fields|join(',')}}, virkning, {{oio_type}}_registrering_id)
    SELECT
        {% if oio_type == "klasse" %} nextval('klasse_attr_egenskaber_id_seq'), {% endif %}
        {% for fieldname in attribut_fields %}
            a.{{fieldname}},
        {% endfor %}
        ROW (c.tz_range_leftover,
            (a.virkning).AktoerRef,
            (a.virkning).AktoerTypeKode,
            (a.virkning).NoteTekst)::virkning,
            new_{{oio_type}}_registrering.id
        FROM (
            -- Build an array of the timeperiod of the virkning of the
            -- {{oio_type}}_attr_{{attribut}} of the new registrering to
            -- pass to _subtract_tstzrange_arr on the
            -- {{oio_type}}_attr_{{attribut}} of the previous registrering.
            SELECT
                coalesce(array_agg((b.virkning).TimePeriod), ARRAY[]::TSTZRANGE[]) tzranges_of_new_reg
            FROM
                {{oio_type}}_attr_{{attribut}} b
            WHERE
                b.{{oio_type}}_registrering_id = new_{{oio_type}}_registrering.id) d
            JOIN {{oio_type}}_attr_{{attribut}} a ON TRUE
            JOIN unnest(_subtract_tstzrange_arr ((a.virkning).TimePeriod, tzranges_of_new_reg)) AS c (tz_range_leftover) ON TRUE
        WHERE
            a.{{oio_type}}_registrering_id = prev_{{oio_type}}_registrering.id {% if oio_type == "klasse" %}
            RETURNING id new_id, (virkning).TimePeriod
    ) INSERT INTO klasse_attr_egenskaber_soegeord (soegeordidentifikator, beskrivelse, soegeordskategori, klasse_attr_egenskaber_id)
    SELECT
        b.soegeordidentifikator, b.beskrivelse, b.soegeordskategori, a.new_id
    FROM
        copied_attr_egenskaber a
        JOIN klasse_attr_egenskaber a2 ON a2.klasse_registrering_id = prev_klasse_registrering.id AND (a2.virkning).TimePeriod @> a.TimePeriod
        -- This will hit exactly one row - that is, the row that we copied.
        JOIN klasse_attr_egenskaber_soegeord b ON a2.id = b.klasse_attr_egenskaber_id
        {% endif %};

END IF;
{% endfor %}


{% if oio_type == "dokument" %}
/******************************************************************/
--Handling document variants and document parts

--check if the update explicitly clears all the doc variants (and parts) by explicitly giving an empty array, if so - no variant will be included in the new reg. 
IF varianter IS NOT NULL AND coalesce(array_length(varianter,1),0)=0 THEN
  --raise notice 'Skipping insertion of doc variants (and parts), as an empty array was given explicitly';
ELSE

--Check if any variants was given in the new update - otherwise we'll skip ahead to transfering the old variants
IF varianter IS NOT NULL AND coalesce(array_length(varianter,1),0)>0 THEN
  
FOREACH dokument_variant_obj IN ARRAY varianter
LOOP

dokument_variant_new_id:=_ensure_document_variant_exists_and_get(new_dokument_registrering.id,dokument_variant_obj.varianttekst);

--handle variant egenskaber
IF dokument_variant_obj.egenskaber IS NOT NULL AND coalesce(array_length(dokument_variant_obj.egenskaber,1),0)=0 THEN
dokument_variant_egenskaber_expl_deleted:=array_append(dokument_variant_egenskaber_expl_deleted, dokument_variant_obj.varianttekst);
ELSE 


IF dokument_variant_obj.egenskaber IS NOT NULL AND coalesce(array_length(dokument_variant_obj.egenskaber,1),0)>0 THEN

  --Input validation: 
  --Verify that there is no overlap in virkning in the array given

  IF EXISTS (
  SELECT
  a.*
  FROM unnest(dokument_variant_obj.egenskaber) a
  JOIN unnest(dokument_variant_obj.egenskaber) b on (a.virkning).TimePeriod && (b.virkning).TimePeriod
  GROUP BY a.arkivering,a.delvisscannet,a.offentliggoerelse,a.produktion, a.virkning
  HAVING COUNT(*)>1
  ) THEN
  RAISE EXCEPTION 'Unable to update dokument with uuid [%], as the given dokument variant [%] have overlapping virknings in the given egenskaber array :%',dokument_uuid,dokument_variant_obj.varianttekst,to_json(dokument_variant_obj.egenskaber)  USING ERRCODE = 22000;

  END IF;


FOREACH dokument_variant_egenskab_obj IN ARRAY dokument_variant_obj.egenskaber
  LOOP

   IF (dokument_variant_egenskab_obj).arkivering is null OR 
   (dokument_variant_egenskab_obj).delvisscannet is null OR 
   (dokument_variant_egenskab_obj).offentliggoerelse is null OR 
   (dokument_variant_egenskab_obj).produktion is null 
  THEN


  INSERT INTO dokument_variant_egenskaber(
    variant_id,
        arkivering, 
          delvisscannet, 
            offentliggoerelse, 
              produktion,
                virkning
      )
  SELECT
    dokument_variant_new_id, 
        CASE WHEN (dokument_variant_egenskab_obj.arkivering).cleared THEN NULL 
        ELSE coalesce((dokument_variant_egenskab_obj.arkivering).value,a.arkivering)
        END, 
          CASE WHEN (dokument_variant_egenskab_obj.delvisscannet).cleared THEN NULL 
          ELSE coalesce((dokument_variant_egenskab_obj.delvisscannet).value,a.delvisscannet)
          END,
            CASE WHEN (dokument_variant_egenskab_obj.offentliggoerelse).cleared THEN NULL 
            ELSE coalesce((dokument_variant_egenskab_obj.offentliggoerelse).value,a.offentliggoerelse)
            END,
              CASE WHEN (dokument_variant_egenskab_obj.produktion).cleared THEN NULL 
              ELSE coalesce((dokument_variant_egenskab_obj.produktion).value,a.produktion)
              END,
                ROW (
                  (a.virkning).TimePeriod * (dokument_variant_egenskab_obj.virkning).TimePeriod,
                  (dokument_variant_egenskab_obj.virkning).AktoerRef,
                  (dokument_variant_egenskab_obj.virkning).AktoerTypeKode,
                  (dokument_variant_egenskab_obj.virkning).NoteTekst
                )::Virkning
  FROM dokument_variant_egenskaber a
  JOIN dokument_variant b on a.variant_id=b.id
  WHERE
    b.dokument_registrering_id=prev_dokument_registrering.id 
    and b.varianttekst=dokument_variant_obj.varianttekst
    and (a.virkning).TimePeriod && (dokument_variant_egenskab_obj.virkning).TimePeriod
  ;


  --For any periods within the virkning of the dokument_variant_egenskab_obj, that is NOT covered by any "merged" rows inserted above, generate and insert rows

  INSERT INTO
  dokument_variant_egenskaber
  (
    variant_id,
      arkivering, 
        delvisscannet, 
          offentliggoerelse, 
            produktion,
              virkning
  )
  SELECT 
    dokument_variant_new_id,
      dokument_variant_egenskab_obj.arkivering, 
        dokument_variant_egenskab_obj.delvisscannet, 
          dokument_variant_egenskab_obj.offentliggoerelse, 
            dokument_variant_egenskab_obj.produktion,
              ROW (
                   b.tz_range_leftover,
                  (dokument_variant_egenskab_obj.virkning).AktoerRef,
                  (dokument_variant_egenskab_obj.virkning).AktoerTypeKode,
                  (dokument_variant_egenskab_obj.virkning).NoteTekst
              )::Virkning
  FROM
  (
  --build an array of the timeperiod of the virkning of the dokument variant egenskaber of the new registrering to pass to _subtract_tstzrange_arr 
      SELECT coalesce(array_agg((b.virkning).TimePeriod),array[]::TSTZRANGE[]) tzranges_of_new_reg
      FROM dokument_variant_egenskaber b
      WHERE 
       b.variant_id=dokument_variant_new_id
  ) as a
  JOIN unnest(_subtract_tstzrange_arr((dokument_variant_egenskab_obj.virkning).TimePeriod,a.tzranges_of_new_reg)) as b(tz_range_leftover) on true
  ;
  ELSE 

   --insert attrEgenskaberObj raw (if there were no null-valued fields) 

   INSERT INTO
    dokument_variant_egenskaber (
      variant_id,
        arkivering, 
          delvisscannet, 
            offentliggoerelse, 
              produktion,
                virkning
    )
    VALUES (
      dokument_variant_new_id,
        dokument_variant_egenskab_obj.arkivering, 
          dokument_variant_egenskab_obj.delvisscannet, 
            dokument_variant_egenskab_obj.offentliggoerelse, 
              dokument_variant_egenskab_obj.produktion,
                dokument_variant_egenskab_obj.virkning
    );

  END IF; --else block: null elements present in -dokument_variant_obj.egenskab obj

  END LOOP; --dokument_variant_obj.egenskaber


END IF; --variant egenskaber given.

END IF; --else block: explicit empty array of variant egenskaber given


--handle variant dele
IF dokument_variant_obj.dele IS NOT NULL AND coalesce(array_length(dokument_variant_obj.dele,1),0)=0 THEN

dokument_variant_dele_all_expl_deleted :=array_append(dokument_variant_dele_all_expl_deleted, dokument_variant_obj.varianttekst);

ELSE

IF dokument_variant_obj.dele IS NOT NULL AND coalesce(array_length(dokument_variant_obj.dele,1),0)>0 THEN


FOREACH dokument_del_obj IN ARRAY dokument_variant_obj.dele
    LOOP

    dokument_del_new_id:=_ensure_document_del_exists_and_get(new_dokument_registrering.id, dokument_variant_new_id, dokument_del_obj.deltekst);

    IF dokument_del_obj.egenskaber IS NOT NULL AND coalesce(array_length(dokument_del_obj.egenskaber,1),0)=0 THEN
    dokument_variant_del_egenskaber_deleted:=array_append(dokument_variant_del_egenskaber_deleted,ROW(dokument_variant_obj.varianttekst, dokument_del_obj.deltekst)::_DokumentVariantDelKey);
    ELSE

    IF dokument_del_obj.egenskaber IS NOT NULL AND coalesce(array_length(dokument_del_obj.egenskaber,1),0)>0 THEN  

    --Input validation: 
    --Verify that there is no overlap in virkning in the array given
    IF EXISTS (
      SELECT
      a.*
      FROM unnest(dokument_del_obj.egenskaber) a
      JOIN unnest(dokument_del_obj.egenskaber) b on (a.virkning).TimePeriod && (b.virkning).TimePeriod
      GROUP BY a.indeks,a.indhold,a.lokation,a.mimetype, a.virkning
      HAVING COUNT(*)>1
    ) THEN
    RAISE EXCEPTION 'Unable to update dokument with uuid [%], as the dokument variant [%] have del [%] with overlapping virknings in the given egenskaber array :%',dokument_uuid,dokument_variant_obj.varianttekst,dokument_del_obj.deltekst,to_json(dokument_del_obj.egenskaber)  USING ERRCODE = 22000;
    END IF;



  FOREACH dokument_del_egenskaber_obj in array dokument_del_obj.egenskaber
  LOOP

  --To avoid needless fragmentation we'll check for presence of null values in the fields - and if none are present, we'll skip the merging operations
  IF (dokument_del_egenskaber_obj).indeks is null OR 
   (dokument_del_egenskaber_obj).indhold is null OR 
   (dokument_del_egenskaber_obj).lokation is null OR 
   (dokument_del_egenskaber_obj).mimetype is null 
  THEN

  INSERT INTO
  dokument_del_egenskaber
  (
    del_id,
      indeks,
        indhold,
          lokation,
            mimetype,
              virkning
  )
  SELECT 
    dokument_del_new_id, 
      CASE WHEN (dokument_del_egenskaber_obj.indeks).cleared THEN NULL 
      ELSE coalesce((dokument_del_egenskaber_obj.indeks).value,a.indeks)
      END, 
        coalesce(dokument_del_egenskaber_obj.indhold,a.indhold), 
          coalesce(dokument_del_egenskaber_obj.lokation,a.lokation), 
            coalesce(dokument_del_egenskaber_obj.mimetype,a.mimetype),
              ROW (
                (a.virkning).TimePeriod * (dokument_del_egenskaber_obj.virkning).TimePeriod,
                (dokument_del_egenskaber_obj.virkning).AktoerRef,
                (dokument_del_egenskaber_obj.virkning).AktoerTypeKode,
                (dokument_del_egenskaber_obj.virkning).NoteTekst
              )::Virkning
  FROM dokument_del_egenskaber a
  JOIN dokument_del b on a.del_id=b.id
  JOIN dokument_variant c on b.variant_id=c.id
  WHERE
    c.dokument_registrering_id=prev_dokument_registrering.id 
    and c.varianttekst=dokument_variant_obj.varianttekst
    and b.deltekst=dokument_del_obj.deltekst
    and (a.virkning).TimePeriod && (dokument_del_egenskaber_obj.virkning).TimePeriod
  ;

  --For any periods within the virkning of the dokument_del_egenskaber_obj, that is NOT covered by any "merged" rows inserted above, generate and insert rows

  INSERT INTO
  dokument_del_egenskaber
  (
    del_id,
      indeks,
        indhold,
          lokation,
            mimetype,
              virkning
  )
  SELECT 
    dokument_del_new_id,
      dokument_del_egenskaber_obj.indeks, 
        dokument_del_egenskaber_obj.indhold, 
          dokument_del_egenskaber_obj.lokation, 
            dokument_del_egenskaber_obj.mimetype,
              ROW (
                   b.tz_range_leftover,
                  (dokument_del_egenskaber_obj.virkning).AktoerRef,
                  (dokument_del_egenskaber_obj.virkning).AktoerTypeKode,
                  (dokument_del_egenskaber_obj.virkning).NoteTekst
              )::Virkning
  FROM
  (
  --build an array of the timeperiod of the virkning of the relevant dokument_del_egenskaber of the new registrering to pass to _subtract_tstzrange_arr 
      SELECT coalesce(array_agg((b.virkning).TimePeriod),array[]::TSTZRANGE[]) tzranges_of_new_reg
      FROM dokument_del_egenskaber b
      JOIN dokument_del c on b.del_id=c.id
      JOIN dokument_variant d on c.variant_id=d.id
      WHERE 
      d.dokument_registrering_id=new_dokument_registrering.id
      and d.varianttekst=dokument_variant_obj.varianttekst
      and c.deltekst=dokument_del_obj.deltekst
  ) as a
  JOIN unnest(_subtract_tstzrange_arr((dokument_del_egenskaber_obj.virkning).TimePeriod,a.tzranges_of_new_reg)) as b(tz_range_leftover) on true
  ;
  ELSE
     --insert dokument_del_egenskaber_obj raw (if there were no null-valued fields)

  INSERT INTO
  dokument_del_egenskaber
  (
    del_id,
      indeks,
        indhold,
          lokation,
            mimetype,
              virkning
  )
  SELECT 
    dokument_del_new_id,
      dokument_del_egenskaber_obj.indeks, 
        dokument_del_egenskaber_obj.indhold, 
          dokument_del_egenskaber_obj.lokation, 
            dokument_del_egenskaber_obj.mimetype,
              dokument_del_egenskaber_obj.virkning
  ;

  END IF; --else block: null field in del egenskaber obj pesent

  END LOOP;
    END IF; --del obj has egenskaber given.

    END IF; --else block: explicit empty array of variant del egenskaber given

     IF dokument_del_obj.relationer IS NOT NULL AND coalesce(array_length(dokument_del_obj.relationer,1),0)=0 THEN
     dokument_variant_del_relationer_deleted:=array_append(dokument_variant_del_relationer_deleted,ROW(dokument_variant_obj.varianttekst, dokument_del_obj.deltekst)::_DokumentVariantDelKey);
    
    ELSE


    INSERT INTO dokument_del_relation(
        del_id, 
          virkning, 
            rel_maal_uuid, 
              rel_maal_urn, 
                rel_type, 
                  objekt_type
        )
    SELECT
        dokument_del_new_id,
          a.virkning,
            a.uuid,
              a.urn,
                a.relType,
                  a.objektType
    FROM unnest(dokument_del_obj.relationer) a(relType,virkning,uuid,urn,objektType)
    ;

    END IF; --explicit empty array of variant del relationer given

    END LOOP; --dokument_variant_obj.dele


END IF; --dokument dele present



END IF; --else block: explicit empty array of variant dele given





END LOOP;

END IF; --variants given with this update.


/****************************************************/
--carry over any variant egenskaber of the prev. registration, unless explicitly deleted - where there is room acording to virkning


SELECT array_agg(varianttekst) into dokument_variants_prev_reg_arr
FROM
dokument_variant a
WHERE a.dokument_registrering_id=prev_dokument_registrering.id
and a.varianttekst not in (select varianttekst from unnest(dokument_variant_egenskaber_expl_deleted) b(varianttekst) )
;

IF dokument_variants_prev_reg_arr IS NOT NULL AND coalesce(array_length(dokument_variants_prev_reg_arr,1),0)>0 THEN

FOREACH dokument_variant_egenskaber_prev_reg_varianttekst IN ARRAY dokument_variants_prev_reg_arr
LOOP 


dokument_variant_id:=_ensure_document_variant_exists_and_get(new_dokument_registrering.id,dokument_variant_egenskaber_prev_reg_varianttekst);

INSERT INTO
    dokument_variant_egenskaber (
      variant_id,
        arkivering, 
          delvisscannet, 
            offentliggoerelse, 
              produktion,
                virkning 
    )
SELECT
      dokument_variant_id,
        a.arkivering,
          a.delvisscannet,
            a.offentliggoerelse,
              a.produktion,               
                ROW(
                  c.tz_range_leftover,
              (a.virkning).AktoerRef,
              (a.virkning).AktoerTypeKode,
              (a.virkning).NoteTekst
                ) :: virkning
FROM
(
 --build an array of the timeperiod of the virkning of the dokument_variant_egenskaber of the new registrering to pass to _subtract_tstzrange_arr on the dokumentvariant_attr_egenskaber of the previous registrering 
    SELECT coalesce(array_agg((b.virkning).TimePeriod),array[]::TSTZRANGE[]) tzranges_of_new_reg
    FROM dokument_variant_egenskaber b
    WHERE 
    b.variant_id=dokument_variant_id

) d
  JOIN dokument_variant_egenskaber a ON true  
  JOIN dokument_variant e ON a.variant_id = e.id
  JOIN unnest(_subtract_tstzrange_arr((a.virkning).TimePeriod,tzranges_of_new_reg)) as c(tz_range_leftover) on true
  WHERE e.dokument_registrering_id=prev_dokument_registrering.id    
  and e.varianttekst=dokument_variant_egenskaber_prev_reg_varianttekst 
;

END LOOP; --loop dokument_variant_egenskaber_prev_reg_varianttekst
END IF;-- not null dokument_variants_prev_reg_arr


/****************************************************/
--carry over any variant del egenskaber of the prev. registration, unless explicitly deleted -  where there is room acording to virkning

  SELECT array_agg(row(a.varianttekst,a.deltekst)::_DokumentVariantDelKey) into dokument_variant_del_prev_reg_arr
  FROM
  (
  SELECT a.varianttekst,b.deltekst
  FROM
  dokument_variant a
  join dokument_del b on b.variant_id=a.id
  LEFT join unnest(dokument_variant_del_egenskaber_deleted) c(varianttekst,deltekst) on a.varianttekst=c.varianttekst and b.deltekst=c.deltekst
  LEFT JOIN unnest(dokument_variant_dele_all_expl_deleted) d(varianttekst) on d.varianttekst = a.varianttekst
  WHERE a.dokument_registrering_id=prev_dokument_registrering.id
  and d.varianttekst is null
  and (c.varianttekst is null and c.deltekst is null)
  group by a.varianttekst,b.deltekst
 ) as a
;
 

if dokument_variant_del_prev_reg_arr IS NOT NULL and coalesce(array_length(dokument_variant_del_prev_reg_arr,1),0)>0 THEN

  FOREACH dokument_variant_del_prev_reg in ARRAY dokument_variant_del_prev_reg_arr
  LOOP

  dokument_del_id:=_ensure_document_variant_and_del_exists_and_get_del(new_dokument_registrering.id,dokument_variant_del_prev_reg.varianttekst,dokument_variant_del_prev_reg.deltekst);

  INSERT INTO dokument_del_egenskaber (
      del_id,
        indeks,
          indhold,
            lokation,
              mimetype,
                virkning
    )
  SELECT
      dokument_del_id,
        a.indeks,
          a.indhold,
            a.lokation,
              a.mimetype,
                ROW(
                  c.tz_range_leftover,
                    (a.virkning).AktoerRef,
                    (a.virkning).AktoerTypeKode,
                    (a.virkning).NoteTekst
                ) :: virkning
  FROM
  (
   --build an array of the timeperiod of the virkning of the dokument_del_egenskaber of the new registrering to pass to _subtract_tstzrange_arr on the relevant dokument_del_egenskaber of the previous registrering 
      SELECT coalesce(array_agg((b.virkning).TimePeriod),array[]::TSTZRANGE[]) tzranges_of_new_reg
      FROM dokument_del_egenskaber b
      JOIN dokument_del c on b.del_id=c.id
      JOIN dokument_variant d on c.variant_id=d.id
      WHERE 
            d.dokument_registrering_id=new_dokument_registrering.id
            AND d.varianttekst=dokument_variant_del_prev_reg.varianttekst
            AND c.deltekst=dokument_variant_del_prev_reg.deltekst
  ) d
    JOIN dokument_del_egenskaber a ON true  
    JOIN dokument_del b on a.del_id=b.id
    JOIN dokument_variant e on b.variant_id=e.id
    JOIN unnest(_subtract_tstzrange_arr((a.virkning).TimePeriod,tzranges_of_new_reg)) as c(tz_range_leftover) on true
    WHERE e.dokument_registrering_id=prev_dokument_registrering.id    
    AND e.varianttekst=dokument_variant_del_prev_reg.varianttekst
    AND b.deltekst=dokument_variant_del_prev_reg.deltekst
  ;

  END LOOP;


END IF; --dokument_variant_del_prev_reg_arr not empty




/****************************************************/
--carry over any document part relations of the prev. relation if a) they were not explicitly cleared and b)no document part relations is already present for the variant del.



--3) Transfer relations of prev reg.

--Identify the variant + del combos that should have relations carried over
SELECT array_agg(ROW(e.varianttekst,e.deltekst)::_DokumentVariantDelKey) into dokument_variant_del_prev_reg_rel_transfer
FROM
(
  SELECT
  c.varianttekst,b.deltekst
  FROM dokument_del_relation a 
  JOIN dokument_del b on a.del_id=b.id
  JOIN dokument_variant c on b.variant_id=c.id
  LEFT JOIN unnest(dokument_variant_del_relationer_deleted) d(varianttekst,deltekst) on d.varianttekst=c.varianttekst and d.deltekst=b.deltekst
  WHERE c.dokument_registrering_id=prev_dokument_registrering.id
  AND (d.varianttekst IS NULL AND d.deltekst IS NULL) 
  EXCEPT
  SELECT
  c.varianttekst,b.deltekst
  FROM dokument_del_relation a 
  JOIN dokument_del b on a.del_id=b.id
  JOIN dokument_variant c on b.variant_id=c.id
  WHERE c.dokument_registrering_id=new_dokument_registrering.id
) as e
;




-- Make sure that part + variants are in place 
IF dokument_variant_del_prev_reg_rel_transfer IS NOT NULL AND coalesce(array_length(dokument_variant_del_prev_reg_rel_transfer,1),0)>0 THEN
  FOREACH dokument_variant_del_prev_reg IN array dokument_variant_del_prev_reg_rel_transfer
  LOOP
     dokument_del_id:=_ensure_document_variant_and_del_exists_and_get_del(new_dokument_registrering.id,dokument_variant_del_prev_reg.varianttekst , dokument_variant_del_prev_reg.deltekst);

--transfer relations of prev reg.
INSERT INTO dokument_del_relation(
    del_id, 
      virkning, 
        rel_maal_uuid, 
          rel_maal_urn, 
            rel_type, 
              objekt_type
    )
SELECT
    dokument_del_id,
      a.virkning,
        a.rel_maal_uuid,
          a.rel_maal_urn,
            a.rel_type,
              a.objekt_type
FROM dokument_del_relation a 
JOIN dokument_del b on a.del_id=b.id
JOIN dokument_variant c on b.variant_id=c.id
WHERE c.dokument_registrering_id=prev_dokument_registrering.id
AND c.varianttekst=dokument_variant_del_prev_reg.varianttekst
AND b.deltekst=dokument_variant_del_prev_reg.deltekst
;

END LOOP;

END IF; --block: there are relations to transfer
END IF; --else block for skip on empty array for variants.
{% endif %}


    /******************************************************************/
    -- If the new registrering is identical to the previous one, we need
    -- to throw an exception to abort the transaction.

    read_new_{{oio_type}} := as_read_{{oio_type}}({{oio_type}}_uuid, (new_{{oio_type}}_registrering.registrering).timeperiod, null);
    read_prev_{{oio_type}} := as_read_{{oio_type}}({{oio_type}}_uuid, (prev_{{oio_type}}_registrering.registrering).timeperiod, null);

    -- The ordering in as_list (called by as_read) ensures that the latest
    -- registration is returned at index pos 1.

    IF NOT (lower((read_new_{{oio_type}}.registrering[1].registrering).TimePeriod) = lower((new_{{oio_type}}_registrering.registrering).TimePeriod) and lower((read_prev_{{oio_type}}.registrering[1].registrering).TimePeriod)=lower((prev_{{oio_type}}_registrering.registrering).TimePeriod)) THEN
      RAISE EXCEPTION 'Error updating {{oio_type}} with id [%]: The ordering of as_list_{{oio_type}} should ensure that the latest registrering can be found at index 1. Expected new reg: [%]. Actual new reg at index 1: [%]. Expected prev reg: [%]. Actual prev reg at index 1: [%].', {{oio_type}}_uuid, to_json(new_{{oio_type}}_registrering), to_json(read_new_{{oio_type}}.registrering[1].registrering), to_json(prev_{{oio_type}}_registrering), to_json(prev_new_{{oio_type}}.registrering[1].registrering) USING ERRCODE = 'MO500';
    END IF;
     
    -- We'll ignore the registreringBase part in the comparrison - except
    -- for the livcykluskode
    read_new_{{oio_type}}_reg := ROW(
        ROW (null, (read_new_{{oio_type}}.registrering[1].registrering).livscykluskode, null, null)::registreringBase,
        {% for tilstand, tilstand_values in tilstande.items() %}
        (read_new_{{oio_type}}.registrering[1]).tils{{tilstand|title}} ,{% endfor %}
        {% for attribut, attribut_fields in attributter.items() %}
        (read_new_{{oio_type}}.registrering[1]).attr{{attribut|title}} ,{% endfor %}
        (read_new_{{oio_type}}.registrering[1]).relationer{% if oio_type == "dokument" %},
        (read_new_dokument.registrering[1]).varianter{% endif %}
    )::{{oio_type}}RegistreringType;

    read_prev_{{oio_type}}_reg := ROW(
        ROW(null, (read_prev_{{oio_type}}.registrering[1].registrering).livscykluskode, null, null)::registreringBase,
        {% for tilstand, tilstand_values in tilstande.items() %}
        (read_prev_{{oio_type}}.registrering[1]).tils{{tilstand|title}} ,{% endfor %}
        {% for attribut, attribut_fields in attributter.items() %}
        (read_prev_{{oio_type}}.registrering[1]).attr{{attribut|title}} ,{% endfor %}
        (read_prev_{{oio_type}}.registrering[1]).relationer{% if oio_type == "dokument" %},
        (read_prev_dokument.registrering[1]).varianter{% endif %}
    )::{{oio_type}}RegistreringType;


    IF read_prev_{{oio_type}}_reg = read_new_{{oio_type}}_reg THEN
      --RAISE NOTICE 'Note[%]. Aborted reg:%',note,to_json(read_new_{{oio_type}}_reg);
      --RAISE NOTICE 'Note[%]. Previous reg:%',note,to_json(read_prev_{{oio_type}}_reg);
      RAISE EXCEPTION 'Aborted updating {{oio_type}} with id [%] as the given data, does not give raise to a new registration. Aborted reg:[%], previous reg:[%]', {{oio_type}}_uuid, to_json(read_new_{{oio_type}}_reg), to_json(read_prev_{{oio_type}}_reg) USING ERRCODE = 'MO400';
    END IF;


    return new_{{oio_type}}_registrering.id;
END; $$ LANGUAGE plpgsql VOLATILE;



{% endblock %}
