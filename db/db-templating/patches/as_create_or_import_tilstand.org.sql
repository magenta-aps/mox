-- Copyright (C) 2015 Magenta ApS, http://magenta.dk.
-- Contact: info@magenta.dk.
--
-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at http://mozilla.org/MPL/2.0/.

/*
NOTICE: This file is auto-generated using the script: apply-template.py tilstand as_create_or_import.jinja.sql
*/

CREATE OR REPLACE FUNCTION as_create_or_import_tilstand(
  tilstand_registrering TilstandRegistreringType,
  tilstand_uuid uuid DEFAULT NULL,
  auth_criteria_arr TilstandRegistreringType[] DEFAULT NULL
	)
  RETURNS uuid AS 
$$
DECLARE
  tilstand_registrering_id bigint;
  tilstand_attr_egenskaber_obj tilstandEgenskaberAttrType;
  
  tilstand_tils_status_obj tilstandStatusTilsType;
  tilstand_tils_publiceret_obj tilstandPubliceretTilsType;
  
  tilstand_relationer TilstandRelationType;
  auth_filtered_uuids uuid[];
  tilstand_relation_kode tilstandRelationKode;
  tilstand_uuid_underscores text;
  tilstand_rel_seq_name text;
  tilstand_rel_type_cardinality_unlimited tilstandRelationKode[]:=ARRAY['tilstandsvaerdi'::TilstandRelationKode,'begrundelse'::TilstandRelationKode,'tilstandskvalitet'::TilstandRelationKode,'tilstandsvurdering'::TilstandRelationKode,'tilstandsaktoer'::TilstandRelationKode,'tilstandsudstyr'::TilstandRelationKode,'samtykke'::TilstandRelationKode,'tilstandsdokument'::TilstandRelationKode]::TilstandRelationKode[];
  tilstand_rel_type_cardinality_unlimited_present_in_argument tilstandRelationKode[];

BEGIN

IF tilstand_uuid IS NULL THEN
    LOOP
    tilstand_uuid:=uuid_generate_v4();
    EXIT WHEN NOT EXISTS (SELECT id from tilstand WHERE id=tilstand_uuid); 
    END LOOP;
END IF;


IF EXISTS (SELECT id from tilstand WHERE id=tilstand_uuid) THEN
  RAISE EXCEPTION 'Error creating or importing tilstand with uuid [%]. If you did not supply the uuid when invoking as_create_or_import_tilstand (i.e. create operation) please try to repeat the invocation/operation, that id collison with randomly generated uuids might in theory occur, albeit very very very rarely.',tilstand_uuid USING ERRCODE='MO500';
END IF;

IF  (tilstand_registrering.registrering).livscykluskode<>'Opstaaet'::Livscykluskode and (tilstand_registrering.registrering).livscykluskode<>'Importeret'::Livscykluskode THEN
  RAISE EXCEPTION 'Invalid livscykluskode[%] invoking as_create_or_import_tilstand.',(tilstand_registrering.registrering).livscykluskode USING ERRCODE='MO400';
END IF;



INSERT INTO 
      tilstand (ID)
SELECT
      tilstand_uuid
;


/*********************************/
--Insert new registrering

tilstand_registrering_id:=nextval('tilstand_registrering_id_seq');

INSERT INTO tilstand_registrering (
      id,
        tilstand_id,
          registrering
        )
SELECT
      tilstand_registrering_id,
        tilstand_uuid,
          ROW (
            TSTZRANGE(clock_timestamp(),'infinity'::TIMESTAMPTZ,'[)' ),
            (tilstand_registrering.registrering).livscykluskode,
            (tilstand_registrering.registrering).brugerref,
            (tilstand_registrering.registrering).note
              ):: RegistreringBase
;

/*********************************/
--Insert attributes


/************/
--Verification
--For now all declared attributes are mandatory (the fields are all optional,though)

 
IF coalesce(array_length(tilstand_registrering.attrEgenskaber, 1),0)<1 THEN
  RAISE EXCEPTION 'Savner påkraevet attribut [egenskaber] for [tilstand]. Oprettelse afbrydes.' USING ERRCODE='MO400';
END IF;



IF tilstand_registrering.attrEgenskaber IS NOT NULL and coalesce(array_length(tilstand_registrering.attrEgenskaber,1),0)>0 THEN
  FOREACH tilstand_attr_egenskaber_obj IN ARRAY tilstand_registrering.attrEgenskaber
  LOOP

    INSERT INTO tilstand_attr_egenskaber (
      brugervendtnoegle,
      beskrivelse,
      virkning,
      tilstand_registrering_id
    )
    SELECT
     tilstand_attr_egenskaber_obj.brugervendtnoegle,
      tilstand_attr_egenskaber_obj.beskrivelse,
      tilstand_attr_egenskaber_obj.virkning,
      tilstand_registrering_id
    ;
 

  END LOOP;
END IF;

/*********************************/
--Insert states (tilstande)


--Verification
--For now all declared states are mandatory.
IF coalesce(array_length(tilstand_registrering.tilsStatus, 1),0)<1  THEN
  RAISE EXCEPTION 'Savner påkraevet tilstand [status] for tilstand. Oprettelse afbrydes.' USING ERRCODE='MO400';
END IF;

IF tilstand_registrering.tilsStatus IS NOT NULL AND coalesce(array_length(tilstand_registrering.tilsStatus,1),0)>0 THEN
  FOREACH tilstand_tils_status_obj IN ARRAY tilstand_registrering.tilsStatus
  LOOP

    INSERT INTO tilstand_tils_status (
      virkning,
      status,
      tilstand_registrering_id
    )
    SELECT
      tilstand_tils_status_obj.virkning,
      tilstand_tils_status_obj.status,
      tilstand_registrering_id;

  END LOOP;
END IF;

--Verification
--For now all declared states are mandatory.
IF coalesce(array_length(tilstand_registrering.tilsPubliceret, 1),0)<1  THEN
  RAISE EXCEPTION 'Savner påkraevet tilstand [publiceret] for tilstand. Oprettelse afbrydes.' USING ERRCODE='MO400';
END IF;

IF tilstand_registrering.tilsPubliceret IS NOT NULL AND coalesce(array_length(tilstand_registrering.tilsPubliceret,1),0)>0 THEN
  FOREACH tilstand_tils_publiceret_obj IN ARRAY tilstand_registrering.tilsPubliceret
  LOOP

    INSERT INTO tilstand_tils_publiceret (
      virkning,
      publiceret,
      tilstand_registrering_id
    )
    SELECT
      tilstand_tils_publiceret_obj.virkning,
      tilstand_tils_publiceret_obj.publiceret,
      tilstand_registrering_id;

  END LOOP;
END IF;

/*********************************/
--Insert relations

IF coalesce(array_length(tilstand_registrering.relationer,1),0)>0 THEN

--Create temporary sequences
tilstand_uuid_underscores:=replace(tilstand_uuid::text, '-', '_');


SELECT array_agg( DISTINCT a.RelType) into tilstand_rel_type_cardinality_unlimited_present_in_argument FROM  unnest(tilstand_registrering.relationer) a WHERE a.RelType = any (tilstand_rel_type_cardinality_unlimited) ;
IF coalesce(array_length(tilstand_rel_type_cardinality_unlimited_present_in_argument,1),0)>0 THEN
FOREACH tilstand_relation_kode IN ARRAY (tilstand_rel_type_cardinality_unlimited_present_in_argument)
  LOOP
  tilstand_rel_seq_name := 'tilstand_' || tilstand_relation_kode::text || tilstand_uuid_underscores;

  EXECUTE 'CREATE TEMPORARY SEQUENCE ' || tilstand_rel_seq_name || '
  INCREMENT 1
  MINVALUE 1
  MAXVALUE 9223372036854775807
  START 1
  CACHE 1;';

END LOOP;
END IF;

    INSERT INTO tilstand_relation (
      tilstand_registrering_id,
      virkning,
      rel_maal_uuid,
      rel_maal_urn,
      rel_type,
      objekt_type,
      rel_index,
      tilstand_vaerdi_attr
    )
    SELECT
      tilstand_registrering_id,
      a.virkning,
      a.uuid,
      a.urn,
      a.relType,
      a.objektType,
        CASE WHEN a.relType = any (tilstand_rel_type_cardinality_unlimited) THEN --rel_index
        nextval('tilstand_' || a.relType::text || tilstand_uuid_underscores)
        ELSE 
        NULL
        END,
     CASE
        WHEN a.relType='tilstandsvaerdi' AND
          ( NOT (a.tilstandsVaerdiAttr IS NULL))
          AND 
          (
            (a.tilstandsVaerdiAttr).forventet IS NOT NULL
            OR
            (a.tilstandsVaerdiAttr).nominelVaerdi IS NOT NULL
          ) THEN a.tilstandsVaerdiAttr
        ELSE
        NULL
      END
    FROM unnest(tilstand_registrering.relationer) a
    ;


--Drop temporary sequences
IF coalesce(array_length(tilstand_rel_type_cardinality_unlimited_present_in_argument,1),0)>0 THEN
FOREACH tilstand_relation_kode IN ARRAY (tilstand_rel_type_cardinality_unlimited_present_in_argument)
  LOOP
  tilstand_rel_seq_name := 'tilstand_' || tilstand_relation_kode::text || tilstand_uuid_underscores;
  EXECUTE 'DROP  SEQUENCE ' || tilstand_rel_seq_name || ';';
END LOOP;
END IF;

END IF;

/*** Verify that the object meets the stipulated access allowed criteria  ***/
/*** NOTICE: We are doing this check *after* the insertion of data BUT *before* transaction commit, to reuse code / avoid fragmentation  ***/
auth_filtered_uuids:=_as_filter_unauth_tilstand(array[tilstand_uuid]::uuid[],auth_criteria_arr); 
IF NOT (coalesce(array_length(auth_filtered_uuids,1),0)=1 AND auth_filtered_uuids @>ARRAY[tilstand_uuid]) THEN
  RAISE EXCEPTION 'Unable to create/import tilstand with uuid [%]. Object does not met stipulated criteria:%',tilstand_uuid,to_json(auth_criteria_arr)  USING ERRCODE = 'MO401'; 
END IF;
/*********************/


  PERFORM actual_state._amqp_publish_notification('Tilstand', (tilstand_registrering.registrering).livscykluskode, tilstand_uuid);

RETURN tilstand_uuid;

END;
$$ LANGUAGE plpgsql VOLATILE;


