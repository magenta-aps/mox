{% extends "basis.jinja.sql" %}

-- SPDX-FileCopyrightText: 2018-2020 Magenta ApS
-- SPDX-License-Identifier: MPL-2.0


{% block body %}

CREATE OR REPLACE FUNCTION as_create_or_import_{{oio_type}} (
    {{oio_type}}_registrering {{oio_type|title}}RegistreringType,
    {{oio_type}}_uuid uuid DEFAULT NULL, auth_criteria_arr
    {{oio_type|title}}RegistreringType[] DEFAULT NULL) RETURNS uuid AS
$$ DECLARE {{oio_type}}_registrering_id bigint;

    {%for attribut , attribut_fields in attributter.items() %}
    {{oio_type}}_attr_{{attribut}}_obj {{oio_type}}{{attribut|title}}AttrType;
    {% endfor %}

    {% for tilstand, tilstand_values in tilstande.items() %}
    {{oio_type}}_tils_{{tilstand}}_obj {{oio_type}}{{tilstand|title}}TilsType;
    {% endfor %}

    {{oio_type}}_relationer {{oio_type|title}}RelationType;

    {% if oio_type == "dokument" %}
    dokument_variant_obj DokumentVariantType;
    dokument_variant_egenskab_obj DokumentVariantEgenskaberType;
    dokument_del_obj DokumentDelType;
    dokument_del_egenskaber_obj DokumentDelEgenskaberType;
    dokument_del_relation_obj DokumentDelRelationType;
    dokument_variant_new_id bigint;
    dokument_del_new_id bigint;
    {% elif oio_type == "klasse" %}
    klasse_attr_egenskaber_id bigint;
    klasse_attr_egenskaber_soegeord_obj KlasseSoegeordType;
    {% elif oio_type == "sag" %}
    sag_relation_kode SagRelationKode;
    sag_uuid_underscores text;
    sag_rel_seq_name text;
    sag_rel_type_cardinality_unlimited SagRelationKode[]:=ARRAY['andetarkiv'::SagRelationKode,'andrebehandlere'::SagRelationKode,'sekundaerpart'::SagRelationKode,'andresager'::SagRelationKode,'byggeri'::SagRelationKode,'fredning'::SagRelationKode,'journalpost'::SagRelationKode]::SagRelationKode[];
    {% endif %}

    auth_filtered_uuids uuid[];

    {% if oio_type == "aktivitet" %}
    aktivitet_relation_kode aktivitetRelationKode;
    aktivitet_uuid_underscores text;
    aktivitet_rel_seq_name text;
    aktivitet_rel_type_cardinality_unlimited aktivitetRelationKode[]:=ARRAY['udfoererklasse'::AktivitetRelationKode,'deltagerklasse'::AktivitetRelationKode,'objektklasse'::AktivitetRelationKode,'resultatklasse'::AktivitetRelationKode,'grundlagklasse'::AktivitetRelationKode,'facilitetklasse'::AktivitetRelationKode,'adresse'::AktivitetRelationKode,'geoobjekt'::AktivitetRelationKode,'position'::AktivitetRelationKode,'facilitet'::AktivitetRelationKode,'lokale'::AktivitetRelationKode,'aktivitetdokument'::AktivitetRelationKode,'aktivitetgrundlag'::AktivitetRelationKode,'aktivitetresultat'::AktivitetRelationKode,'udfoerer'::AktivitetRelationKode,'deltager'::AktivitetRelationKode]::aktivitetRelationKode[];
    aktivitet_rel_type_cardinality_unlimited_present_in_argument aktivitetRelationKode[];
    {% elif oio_type == "indsats" %}
    indsats_relation_kode indsatsRelationKode;
    indsats_uuid_underscores text;
    indsats_rel_seq_name text;
    indsats_rel_type_cardinality_unlimited indsatsRelationKode[]:=ARRAY['indsatskvalitet'::IndsatsRelationKode,'indsatsaktoer'::IndsatsRelationKode,'samtykke'::IndsatsRelationKode,'indsatssag'::IndsatsRelationKode,'indsatsdokument'::IndsatsRelationKode]::indsatsRelationKode[];
    indsats_rel_type_cardinality_unlimited_present_in_argument indsatsRelationKode[];
    {% elif oio_type == "sag" %}
    sag_rel_type_cardinality_unlimited_present_in_argument sagRelationKode[];
    {% elif oio_type == "tilstand" %}
    tilstand_relation_kode tilstandRelationKode;
    tilstand_uuid_underscores text;
    tilstand_rel_seq_name text;
    tilstand_rel_type_cardinality_unlimited tilstandRelationKode[]:=ARRAY['tilstandsvaerdi'::TilstandRelationKode,'begrundelse'::TilstandRelationKode,'tilstandskvalitet'::TilstandRelationKode,'tilstandsvurdering'::TilstandRelationKode,'tilstandsaktoer'::TilstandRelationKode,'tilstandsudstyr'::TilstandRelationKode,'samtykke'::TilstandRelationKode,'tilstandsdokument'::TilstandRelationKode]::TilstandRelationKode[];
    tilstand_rel_type_cardinality_unlimited_present_in_argument tilstandRelationKode[];
    {% endif %}

    does_exist boolean;
    new_{{oio_type}}_registrering {{oio_type}}_registrering;
BEGIN
    IF {{oio_type}}_uuid IS NULL THEN LOOP
        {{oio_type}}_uuid:=uuid_generate_v4(); EXIT WHEN NOT EXISTS (SELECT id
            from {{oio_type}} WHERE id={{oio_type}}_uuid); END LOOP; END IF;

    IF EXISTS (SELECT id from {{oio_type}} WHERE id={{oio_type}}_uuid) THEN
        does_exist = True; ELSE

        does_exist = False; END IF;

    IF
        ({{oio_type}}_registrering.registrering).livscykluskode<>'Opstaaet'::Livscykluskode
        and
        ({{oio_type}}_registrering.registrering).livscykluskode<>'Importeret'::Livscykluskode
        and
        ({{oio_type}}_registrering.registrering).livscykluskode<>'Rettet'::Livscykluskode
        THEN RAISE EXCEPTION 'Invalid livscykluskode[%] invoking
        as_create_or_import_{{oio_type}}.',({{oio_type}}_registrering.registrering).livscykluskode
        USING ERRCODE='MO400'; END IF;

    IF NOT does_exist THEN INSERT INTO {{oio_type}} (ID) SELECT
        {{oio_type}}_uuid; END IF;

    /*********************************/
    --Insert new registrering

    IF NOT does_exist THEN
        {{oio_type}}_registrering_id:=nextval('{{oio_type}}_registrering_id_seq');

        INSERT INTO {{oio_type}}_registrering (id, {{oio_type}}_id,
            registrering) SELECT {{oio_type}}_registrering_id,
        {{oio_type}}_uuid, ROW (
            TSTZRANGE(clock_timestamp(),'infinity'::TIMESTAMPTZ,'[)' ),
        ({{oio_type}}_registrering.registrering).livscykluskode,
        ({{oio_type}}_registrering.registrering).brugerref,
        ({{oio_type}}_registrering.registrering).note):: RegistreringBase ;
    ELSE
        -- This is an update, not an import or create
            new_{{oio_type}}_registrering :=
            _as_create_{{oio_type}}_registrering({{oio_type}}_uuid,
                ({{oio_type}}_registrering.registrering).livscykluskode,
                ({{oio_type}}_registrering.registrering).brugerref,
                ({{oio_type}}_registrering.registrering).note);

            {{oio_type}}_registrering_id := new_{{oio_type}}_registrering.id;
    END IF;


/*********************************/
--Insert attributes


/************/
--Verification
--For now all declared attributes are mandatory (the fields are all optional,though)

{% for attribut , attribut_fields in attributter.items() %}
{%- if attributter_mandatory[attribut] -%}
IF coalesce(array_length({{oio_type}}_registrering.attr{{attribut|title}},
    1),0)<1 THEN RAISE EXCEPTION 'Savner påkrævet attribut [{{attribut}}] for
    [{{oio_type}}]. Oprettelse afbrydes.' USING ERRCODE='MO400'; END IF;
{%- endif %}

IF {{oio_type}}_registrering.attr{{attribut|title}} IS NOT NULL and coalesce(array_length({{oio_type}}_registrering.attr{{attribut|title}},1),0)>0 THEN
  FOREACH {{oio_type}}_attr_{{attribut}}_obj IN ARRAY {{oio_type}}_registrering.attr{{attribut|title}}
  LOOP

  {% if oio_type == "klasse" %}
  klasse_attr_egenskaber_id:=nextval('klasse_attr_egenskaber_id_seq');
  {% endif %}
    INSERT INTO {{oio_type}}_attr_{{attribut}} (
      {% if oio_type == "klasse" %}id,{% endif %}
      {% for field in attribut_fields %}{{field}},
      {% endfor %}virkning,
      {{oio_type}}_registrering_id
    )
    SELECT
     {% if oio_type == "klasse" %}klasse_attr_egenskaber_id,{% endif %}
     {% for field in attribut_fields %}{{oio_type}}_attr_{{attribut}}_obj.{{field}},
      {% endfor %}{{oio_type}}_attr_{{attribut}}_obj.virkning,
      {{oio_type}}_registrering_id
    ;
  
    {% if oio_type == "klasse" %}
 /************/
 --Insert Soegeord
  IF klasse_attr_egenskaber_obj.soegeord IS NOT NULL AND coalesce(array_length(klasse_attr_egenskaber_obj.soegeord,1),0)>1 THEN
    FOREACH klasse_attr_egenskaber_soegeord_obj IN ARRAY klasse_attr_egenskaber_obj.soegeord
      LOOP

      IF (klasse_attr_egenskaber_soegeord_obj.soegeordidentifikator IS NOT NULL AND klasse_attr_egenskaber_soegeord_obj.soegeordidentifikator<>'') 
      OR (klasse_attr_egenskaber_soegeord_obj.beskrivelse IS NOT NULL AND klasse_attr_egenskaber_soegeord_obj.beskrivelse<>'' )
      OR (klasse_attr_egenskaber_soegeord_obj.soegeordskategori IS NOT NULL AND klasse_attr_egenskaber_soegeord_obj.soegeordskategori<>'') THEN

      INSERT INTO klasse_attr_egenskaber_soegeord (
        soegeordidentifikator,
        beskrivelse,
        soegeordskategori,
        klasse_attr_egenskaber_id
      )
      SELECT
        klasse_attr_egenskaber_soegeord_obj.soegeordidentifikator,
        klasse_attr_egenskaber_soegeord_obj.beskrivelse,
        klasse_attr_egenskaber_soegeord_obj.soegeordskategori,
        klasse_attr_egenskaber_id
      ;
      END IF;
 
     END LOOP;
    END IF;
    {% endif %}
  END LOOP;
END IF;
{% endfor %}
/*********************************/
--Insert states (tilstande)

{% for tilstand, tilstand_values in tilstande.items() %}
--Verification
--For now all declared states are mandatory.
IF coalesce(array_length({{oio_type}}_registrering.tils{{tilstand|title}}, 1),0)<1 THEN
  RAISE EXCEPTION 'Savner påkraevet tilstand [{{tilstand}}] for {{oio_type}}. Oprettelse afbrydes.' USING ERRCODE='MO400';
END IF;

IF {{oio_type}}_registrering.tils{{tilstand|title}} IS NOT NULL AND coalesce(array_length({{oio_type}}_registrering.tils{{tilstand|title}},1),0)>0 THEN
  FOREACH {{oio_type}}_tils_{{tilstand}}_obj IN ARRAY {{oio_type}}_registrering.tils{{tilstand|title}}
  LOOP

    INSERT INTO {{oio_type}}_tils_{{tilstand}} (
      virkning,
      {{tilstand}},
      {{oio_type}}_registrering_id
    )
    SELECT
      {{oio_type}}_tils_{{tilstand}}_obj.virkning,
      {{oio_type}}_tils_{{tilstand}}_obj.{{tilstand}},
      {{oio_type}}_registrering_id;

  END LOOP;
END IF;
{% endfor %}
/*********************************/
--Insert relations

{% if oio_type in ("aktivitet", "indsats", "sag", "tilstand") %}
IF coalesce(array_length({{oio_type}}_registrering.relationer,1),0)>0 THEN

--Create temporary sequences
{{oio_type}}_uuid_underscores:=replace({{oio_type}}_uuid::text, '-', '_');

SELECT array_agg(DISTINCT a.RelType) into {{oio_type}}_rel_type_cardinality_unlimited_present_in_argument FROM unnest({{oio_type}}_registrering.relationer) a WHERE a.RelType = any ({{oio_type}}_rel_type_cardinality_unlimited) ;
IF coalesce(array_length({{oio_type}}_rel_type_cardinality_unlimited_present_in_argument,1),0)>0 THEN

FOREACH {{oio_type}}_relation_kode IN ARRAY ({{oio_type}}_rel_type_cardinality_unlimited_present_in_argument)
  LOOP
  {{oio_type}}_rel_seq_name := '{{oio_type}}_' || {{oio_type}}_relation_kode::text || {{oio_type}}_uuid_underscores;

  EXECUTE 'CREATE TEMPORARY SEQUENCE ' || {{oio_type}}_rel_seq_name || '
  INCREMENT 1
  MINVALUE 1
  MAXVALUE 9223372036854775807
  START 1
  CACHE 1;';

END LOOP;
END IF;
{% endif %}

    INSERT INTO {{oio_type}}_relation (
      {{oio_type}}_registrering_id,
      virkning,
      rel_maal_uuid,
      rel_maal_urn,
      rel_type,
      objekt_type{% if oio_type == "aktivitet" %},
      rel_index,
      aktoer_attr{% elif oio_type == "indsats" %},
      rel_index{% elif oio_type == "sag" %},
      rel_index,
      rel_type_spec,
      journal_notat,
      journal_dokument_attr{% elif oio_type == "tilstand" %},
      rel_index,
      tilstand_vaerdi_attr{% endif %}
    )
    SELECT
      {{oio_type}}_registrering_id,
      a.virkning,
      a.uuid,
      a.urn,
      a.relType,
      a.objektType{% if oio_type in ("aktivitet", "indsats", "tilstand") %},
      CASE WHEN a.relType = any ({{oio_type}}_rel_type_cardinality_unlimited) THEN --rel_index
      nextval('{{oio_type}}_' || a.relType::text || {{oio_type}}_uuid_underscores)
      ELSE 
      NULL
      END{% endif %}{% if oio_type == "aktivitet" %},
      CASE 
        WHEN a.relType =('udfoerer'::AktivitetRelationKode)  OR a.relType=('deltager'::AktivitetRelationKode) OR a.relType=('ansvarlig'::AktivitetRelationKode) 
        AND NOT (a.aktoerAttr IS NULL)
        AND (
          (a.aktoerAttr).obligatorisk IS NOT NULL
          OR
          (a.aktoerAttr).accepteret IS NOT NULL
          OR
            (
              (a.aktoerAttr).repraesentation_uuid IS NOT NULL
              OR
              ((a.aktoerAttr).repraesentation_urn IS NOT NULL AND (a.aktoerAttr).repraesentation_urn<>'')
            )
          ) 
        THEN a.aktoerAttr
        ELSE
        NULL
      END
      {% elif oio_type == "sag" %},
      CASE WHEN a.relType = any (sag_rel_type_cardinality_unlimited) THEN --rel_index
      nextval('sag_' || a.relType::text || sag_uuid_underscores)
      ELSE 
      NULL
      END,
      CASE 
        WHEN a.relType='journalpost' THEN a.relTypeSpec  --rel_type_spec
        ELSE
        NULL
      END,
    CASE 
        WHEN  
          (NOT (a.journalNotat IS NULL)) 
          AND
          (
            (a.journalNotat).titel IS NOT NULL
            OR
            (a.journalNotat).notat IS NOT NULL
            OR
            (a.journalNotat).format IS NOT NULL
          )
         THEN a.journalNotat
         ELSE
         NULL
    END
    ,CASE 
      WHEN (
              (NOT a.journalDokumentAttr IS NULL)
              AND
              (
                (a.journalDokumentAttr).dokumenttitel IS NOT NULL
                OR
                (
                  NOT ((a.journalDokumentAttr).offentlighedUndtaget IS NULL)
                  AND
                  (
                    ((a.journalDokumentAttr).offentlighedUndtaget).AlternativTitel IS NOT NULL
                     OR
                     ((a.journalDokumentAttr).offentlighedUndtaget).Hjemmel IS NOT NULL
                   )
                 )
              )
            ) THEN a.journalDokumentAttr
       ELSE
       NULL
      END
      {% elif oio_type == "tilstand" %},
      CASE
        WHEN a.relType='tilstandsvaerdi' AND
          (NOT (a.tilstandsVaerdiAttr IS NULL))
          AND 
          (
            (a.tilstandsVaerdiAttr).forventet IS NOT NULL
            OR
            (a.tilstandsVaerdiAttr).nominelVaerdi IS NOT NULL
          ) THEN a.tilstandsVaerdiAttr
        ELSE
        NULL
      END
    {% endif %}
    FROM unnest({{oio_type}}_registrering.relationer) a
  ;


{% if oio_type in ("aktivitet", "indsats", "sag", "tilstand") %}
--Drop temporary sequences
IF coalesce(array_length({{oio_type}}_rel_type_cardinality_unlimited_present_in_argument,1),0)>0 THEN
FOREACH {{oio_type}}_relation_kode IN ARRAY ({{oio_type}}_rel_type_cardinality_unlimited_present_in_argument)
  LOOP
  {{oio_type}}_rel_seq_name := '{{oio_type}}_' || {{oio_type}}_relation_kode::text || {{oio_type}}_uuid_underscores;
  EXECUTE 'DROP SEQUENCE ' || {{oio_type}}_rel_seq_name || ';';
END LOOP;
END IF;


END IF;
{% elif oio_type == "dokument" %}
--/*********************************/
--Insert document variants (and parts)

IF dokument_registrering.varianter IS NOT NULL AND coalesce(array_length(dokument_registrering.varianter,1),0)>0 THEN
  

FOREACH dokument_variant_obj IN ARRAY dokument_registrering.varianter
LOOP

dokument_variant_new_id:=nextval('dokument_variant_id_seq'::regclass);

  INSERT INTO dokument_variant (
      id,
        varianttekst,
          dokument_registrering_id
  )
  VALUES
  (
      dokument_variant_new_id,
        dokument_variant_obj.varianttekst,
          dokument_registrering_id
  ); 


  IF dokument_variant_obj.egenskaber IS NOT NULL AND coalesce(array_length(dokument_variant_obj.egenskaber,1),0)>0 THEN

    FOREACH dokument_variant_egenskab_obj IN ARRAY dokument_variant_obj.egenskaber
    LOOP

     INSERT INTO dokument_variant_egenskaber (
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
                dokument_variant_egenskab_obj.virkning
      ;

    END LOOP; --variant_egenskaber
  END IF; --variant_egenskaber


  IF dokument_variant_obj.dele IS NOT NULL AND coalesce(array_length(dokument_variant_obj.dele,1),0)>0 THEN

    FOREACH dokument_del_obj IN ARRAY dokument_variant_obj.dele
    LOOP

    dokument_del_new_id:=nextval('dokument_del_id_seq'::regclass);

  INSERT INTO dokument_del (
    id,
      deltekst,
        variant_id
    )
    VALUES
    (
    dokument_del_new_id,
        dokument_del_obj.deltekst,
          dokument_variant_new_id
    )
    ;

    IF dokument_del_obj.egenskaber IS NOT NULL AND coalesce(array_length(dokument_del_obj.egenskaber,1),0)>0 THEN

    FOREACH dokument_del_egenskaber_obj IN ARRAY dokument_del_obj.egenskaber
    LOOP

    INSERT INTO
    dokument_del_egenskaber (
      del_id,
        indeks, 
          indhold, 
            lokation, 
              mimetype, 
                virkning
    )
    VALUES
    (
      dokument_del_new_id, 
        dokument_del_egenskaber_obj.indeks,
          dokument_del_egenskaber_obj.indhold,
            dokument_del_egenskaber_obj.lokation,
              dokument_del_egenskaber_obj.mimetype,
                dokument_del_egenskaber_obj.virkning
    )
    ;                

    END LOOP;--del_egenskaber
    END IF; --del_egenskaber

    IF dokument_del_obj.relationer IS NOT NULL AND coalesce(array_length(dokument_del_obj.relationer,1),0)>0 THEN

    FOREACH dokument_del_relation_obj IN ARRAY dokument_del_obj.relationer
    LOOP

      INSERT INTO dokument_del_relation (
        del_id,
          virkning,
            rel_maal_uuid, 
              rel_maal_urn,
                rel_type,
                  objekt_type
      )
      VALUES
      (
        dokument_del_new_id,
          dokument_del_relation_obj.virkning,
            dokument_del_relation_obj.uuid,
              dokument_del_relation_obj.urn,
                dokument_del_relation_obj.relType,
                  dokument_del_relation_obj.objektType
      )
      ;

    END LOOP;--del_relationer

    END IF; --dokument_del_obj.relationer

    END LOOP; --variant_dele
  END IF; 

 END LOOP; --varianter


END IF; --varianter

{% endif %}

/*** Verify that the object meets the stipulated access allowed criteria  ***/
/*** NOTICE: We are doing this check *after* the insertion of data BUT *before* transaction commit, to reuse code / avoid fragmentation  ***/
auth_filtered_uuids:=_as_filter_unauth_{{oio_type}}(array[{{oio_type}}_uuid]::uuid[],auth_criteria_arr); 
IF NOT (coalesce(array_length(auth_filtered_uuids,1),0)=1 AND auth_filtered_uuids @>ARRAY[{{oio_type}}_uuid]) THEN
  RAISE EXCEPTION 'Unable to create/import {{oio_type}} with uuid [%]. Object does not met stipulated criteria:%',{{oio_type}}_uuid,to_json(auth_criteria_arr)  USING ERRCODE = 'MO401'; 
END IF;
/*********************/




RETURN {{oio_type}}_uuid;

END;
$$ LANGUAGE plpgsql VOLATILE;
{% endblock %}

