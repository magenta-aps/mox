-- Copyright (C) 2015 Magenta ApS, http://magenta.dk.
-- Contact: info@magenta.dk.
--
-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at http://mozilla.org/MPL/2.0/.

/*
NOTICE: This file is auto-generated using the script: apply-template.py sag as_create_or_import.jinja.sql
*/

CREATE OR REPLACE FUNCTION as_create_or_import_sag(
  sag_registrering SagRegistreringType,
  sag_uuid uuid DEFAULT NULL
	)
  RETURNS uuid AS 
$$
DECLARE
  sag_registrering_id bigint;
  sag_attr_egenskaber_obj sagEgenskaberAttrType;
  
  sag_tils_fremdrift_obj sagFremdriftTilsType;
  
  sag_relationer SagRelationType;
  sag_relation_kode SagRelationKode;
  sag_uuid_underscores text;
  sag_rel_seq_name text;
  sag_rel_type_cardinality_unlimited SagRelationKode[]:=ARRAY['andetarkiv'::SagRelationKode,'andrebehandlere'::SagRelationKode,'sekundaerpart'::SagRelationKode,'andresager'::SagRelationKode,'byggeri'::SagRelationKode,'fredning'::SagRelationKode,'journalpost'::SagRelationKode]::SagRelationKode[];
BEGIN

IF sag_uuid IS NULL THEN
    LOOP
    sag_uuid:=uuid_generate_v4();
    EXIT WHEN NOT EXISTS (SELECT id from sag WHERE id=sag_uuid); 
    END LOOP;
END IF;


IF EXISTS (SELECT id from sag WHERE id=sag_uuid) THEN
  RAISE EXCEPTION 'Error creating or importing sag with uuid [%]. If you did not supply the uuid when invoking as_create_or_import_sag (i.e. create operation) please try to repeat the invocation/operation, that id collison with randomly generated uuids might in theory occur, albeit very very very rarely.',sag_uuid;
END IF;

IF  (sag_registrering.registrering).livscykluskode<>'Opstaaet'::Livscykluskode and (sag_registrering.registrering).livscykluskode<>'Importeret'::Livscykluskode THEN
  RAISE EXCEPTION 'Invalid livscykluskode[%] invoking as_create_or_import_sag.',(sag_registrering.registrering).livscykluskode;
END IF;



INSERT INTO 
      sag (ID)
SELECT
      sag_uuid
;


/*********************************/
--Insert new registrering

sag_registrering_id:=nextval('sag_registrering_id_seq');

INSERT INTO sag_registrering (
      id,
        sag_id,
          registrering
        )
SELECT
      sag_registrering_id,
        sag_uuid,
          ROW (
            TSTZRANGE(clock_timestamp(),'infinity'::TIMESTAMPTZ,'[)' ),
            (sag_registrering.registrering).livscykluskode,
            (sag_registrering.registrering).brugerref,
            (sag_registrering.registrering).note
              ):: RegistreringBase
;

/*********************************/
--Insert attributes


/************/
--Verification
--For now all declared attributes are mandatory (the fields are all optional,though)

 
IF coalesce(array_length(sag_registrering.attrEgenskaber, 1),0)<1 THEN
  RAISE EXCEPTION 'Savner påkraevet attribut [egenskaber] for [sag]. Oprettelse afbrydes.';
END IF;



IF sag_registrering.attrEgenskaber IS NOT NULL THEN
  FOREACH sag_attr_egenskaber_obj IN ARRAY sag_registrering.attrEgenskaber
  LOOP

  IF
  ( sag_attr_egenskaber_obj.brugervendtnoegle IS NOT NULL AND sag_attr_egenskaber_obj.brugervendtnoegle<>'') 
   OR 
  ( sag_attr_egenskaber_obj.afleveret IS NOT NULL) 
   OR 
  ( sag_attr_egenskaber_obj.beskrivelse IS NOT NULL AND sag_attr_egenskaber_obj.beskrivelse<>'') 
   OR 
  ( sag_attr_egenskaber_obj.hjemmel IS NOT NULL AND sag_attr_egenskaber_obj.hjemmel<>'') 
   OR 
  ( sag_attr_egenskaber_obj.kassationskode IS NOT NULL AND sag_attr_egenskaber_obj.kassationskode<>'') 
   OR 
  ( sag_attr_egenskaber_obj.offentlighedundtaget IS NOT NULL OR ((sag_attr_egenskaber_obj.offentlighedundtaget).AlternativTitel IS NOT NULL AND (sag_attr_egenskaber_obj.offentlighedundtaget).AlternativTitel<>'') OR ((sag_attr_egenskaber_obj.offentlighedundtaget).Hjemmel IS NOT NULL AND (sag_attr_egenskaber_obj.offentlighedundtaget).Hjemmel<>'')) 
   OR 
  ( sag_attr_egenskaber_obj.principiel IS NOT NULL) 
   OR 
  ( sag_attr_egenskaber_obj.sagsnummer IS NOT NULL AND sag_attr_egenskaber_obj.sagsnummer<>'') 
   OR 
  ( sag_attr_egenskaber_obj.titel IS NOT NULL AND sag_attr_egenskaber_obj.titel<>'') 
   THEN

    INSERT INTO sag_attr_egenskaber (
      brugervendtnoegle,
      afleveret,
      beskrivelse,
      hjemmel,
      kassationskode,
      offentlighedundtaget,
      principiel,
      sagsnummer,
      titel,
      virkning,
      sag_registrering_id
    )
    SELECT
     sag_attr_egenskaber_obj.brugervendtnoegle,
      sag_attr_egenskaber_obj.afleveret,
      sag_attr_egenskaber_obj.beskrivelse,
      sag_attr_egenskaber_obj.hjemmel,
      sag_attr_egenskaber_obj.kassationskode,
      sag_attr_egenskaber_obj.offentlighedundtaget,
      sag_attr_egenskaber_obj.principiel,
      sag_attr_egenskaber_obj.sagsnummer,
      sag_attr_egenskaber_obj.titel,
      sag_attr_egenskaber_obj.virkning,
      sag_registrering_id
    ;
  END IF;

  END LOOP;
END IF;

/*********************************/
--Insert states (tilstande)


--Verification
--For now all declared states are mandatory.
IF coalesce(array_length(sag_registrering.tilsFremdrift, 1),0)<1  THEN
  RAISE EXCEPTION 'Savner påkraevet tilstand [fremdrift] for sag. Oprettelse afbrydes.';
END IF;

IF sag_registrering.tilsFremdrift IS NOT NULL THEN
  FOREACH sag_tils_fremdrift_obj IN ARRAY sag_registrering.tilsFremdrift
  LOOP

  IF sag_tils_fremdrift_obj.fremdrift IS NOT NULL AND sag_tils_fremdrift_obj.fremdrift<>''::SagFremdriftTils THEN

    INSERT INTO sag_tils_fremdrift (
      virkning,
      fremdrift,
      sag_registrering_id
    )
    SELECT
      sag_tils_fremdrift_obj.virkning,
      sag_tils_fremdrift_obj.fremdrift,
      sag_registrering_id;

  END IF;
  END LOOP;
END IF;

/*********************************/
--Insert relations

IF coalesce(array_length(sag_registrering.relationer,1),0)>0 THEN

--Create temporary sequences
sag_uuid_underscores:=replace(sag_uuid::text, '-', '_');

FOREACH sag_relation_kode IN ARRAY (SELECT array_agg( DISTINCT a.RelType) FROM  unnest(sag_registrering.relationer) a WHERE a.RelType = any (sag_rel_type_cardinality_unlimited))
  LOOP
  sag_rel_seq_name := 'sag_rel_' || sag_relation_kode::text || sag_uuid_underscores;

  EXECUTE 'CREATE TEMPORARY SEQUENCE ' || sag_rel_seq_name || '
  INCREMENT 1
  MINVALUE 1
  MAXVALUE 9223372036854775807
  START 1
  CACHE 1;';

END LOOP;

    INSERT INTO sag_relation (
      sag_registrering_id,
      virkning,
      rel_maal_uuid,
      rel_maal_urn,
      rel_type,
      objekt_type,
      rel_index,
      rel_type_spec,
      journal_notat,
      journal_dokument_attr
    )
    SELECT
      sag_registrering_id,
      a.virkning,
      a.relMaalUuid,
      a.relMaalUrn,
      a.relType,
      a.objektType,
        CASE WHEN a.relType = any (sag_rel_type_cardinality_unlimited) THEN --rel_index
        nextval('sag_rel_' || a.relType::text || sag_uuid_underscores)
        ELSE 
        NULL
        END,
        CASE 
          WHEN a.relType='journalpost' THEN a.relTypeSpec  --rel_type_spec
          ELSE
          NULL
        END,
      a.journalNotat,
      a.journalDokumentAttr
    FROM unnest(sag_registrering.relationer) a
    WHERE 
          a.relMaalUuid IS NOT NULL 
      OR (a.relMaalUrn IS NOT NULL AND a.relMaalUrn<>'') 
      OR (  
          (NOT (a.journalNotat IS NULL)) 
          AND ( (a.journalNotat).titel <>'' OR (a.journalNotat).notat <>'' OR (a.journalNotat).format<>'' ) 
        )
  ;


--Drop temporary sequences
FOREACH sag_relation_kode IN ARRAY (SELECT array_agg( DISTINCT a.RelType) FROM  unnest(sag_registrering.relationer) a WHERE a.RelType = any (sag_rel_type_cardinality_unlimited))
  LOOP
  sag_rel_seq_name := 'sag_rel_' || sag_relation_kode::text || sag_uuid_underscores;
  EXECUTE 'DROP  SEQUENCE ' || sag_rel_seq_name || ';';
END LOOP;


END IF;

  PERFORM amqp.publish(1, 'mox.notifications', '', format('create %s', sag_uuid));

RETURN sag_uuid;

END;
$$ LANGUAGE plpgsql VOLATILE;


