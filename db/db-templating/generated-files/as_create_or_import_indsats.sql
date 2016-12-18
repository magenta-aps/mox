-- Copyright (C) 2015 Magenta ApS, http://magenta.dk.
-- Contact: info@magenta.dk.
--
-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at http://mozilla.org/MPL/2.0/.

/*
NOTICE: This file is auto-generated using the script: apply-template.py indsats as_create_or_import.jinja.sql
*/

CREATE OR REPLACE FUNCTION as_create_or_import_indsats(
  indsats_registrering IndsatsRegistreringType,
  indsats_uuid uuid DEFAULT NULL,
  auth_criteria_arr IndsatsRegistreringType[] DEFAULT NULL
	)
  RETURNS uuid AS 
$$
DECLARE
  indsats_registrering_id bigint;
  indsats_attr_egenskaber_obj indsatsEgenskaberAttrType;
  
  indsats_tils_publiceret_obj indsatsPubliceretTilsType;
  indsats_tils_fremdrift_obj indsatsFremdriftTilsType;
  
  indsats_relationer IndsatsRelationType;
  auth_filtered_uuids uuid[];
  indsats_relation_kode indsatsRelationKode;
  indsats_uuid_underscores text;
  indsats_rel_seq_name text;
  indsats_rel_type_cardinality_unlimited indsatsRelationKode[]:=ARRAY['indsatskvalitet'::IndsatsRelationKode,'indsatsaktoer'::IndsatsRelationKode,'samtykke'::IndsatsRelationKode,'indsatssag'::IndsatsRelationKode,'indsatsdokument'::IndsatsRelationKode]::indsatsRelationKode[];
  indsats_rel_type_cardinality_unlimited_present_in_argument indsatsRelationKode[];
BEGIN

IF indsats_uuid IS NULL THEN
    LOOP
    indsats_uuid:=uuid_generate_v4();
    EXIT WHEN NOT EXISTS (SELECT id from indsats WHERE id=indsats_uuid); 
    END LOOP;
END IF;


IF EXISTS (SELECT id from indsats WHERE id=indsats_uuid) THEN
  RAISE EXCEPTION 'Error creating or importing indsats with uuid [%]. If you did not supply the uuid when invoking as_create_or_import_indsats (i.e. create operation) please try to repeat the invocation/operation, that id collison with randomly generated uuids might in theory occur, albeit very very very rarely.',indsats_uuid USING ERRCODE='MO500';
END IF;

IF  (indsats_registrering.registrering).livscykluskode<>'Opstaaet'::Livscykluskode and (indsats_registrering.registrering).livscykluskode<>'Importeret'::Livscykluskode THEN
  RAISE EXCEPTION 'Invalid livscykluskode[%] invoking as_create_or_import_indsats.',(indsats_registrering.registrering).livscykluskode USING ERRCODE='MO400';
END IF;



INSERT INTO 
      indsats (ID)
SELECT
      indsats_uuid
;


/*********************************/
--Insert new registrering

indsats_registrering_id:=nextval('indsats_registrering_id_seq');

INSERT INTO indsats_registrering (
      id,
        indsats_id,
          registrering
        )
SELECT
      indsats_registrering_id,
        indsats_uuid,
          ROW (
            TSTZRANGE(clock_timestamp(),'infinity'::TIMESTAMPTZ,'[)' ),
            (indsats_registrering.registrering).livscykluskode,
            (indsats_registrering.registrering).brugerref,
            (indsats_registrering.registrering).note
              ):: RegistreringBase
;

/*********************************/
--Insert attributes


/************/
--Verification
--For now all declared attributes are mandatory (the fields are all optional,though)

 
IF coalesce(array_length(indsats_registrering.attrEgenskaber, 1),0)<1 THEN
  RAISE EXCEPTION 'Savner påkraevet attribut [egenskaber] for [indsats]. Oprettelse afbrydes.' USING ERRCODE='MO400';
END IF;



IF indsats_registrering.attrEgenskaber IS NOT NULL and coalesce(array_length(indsats_registrering.attrEgenskaber,1),0)>0 THEN
  FOREACH indsats_attr_egenskaber_obj IN ARRAY indsats_registrering.attrEgenskaber
  LOOP

    INSERT INTO indsats_attr_egenskaber (
      brugervendtnoegle,
      beskrivelse,
      starttidspunkt,
      sluttidspunkt,
      virkning,
      indsats_registrering_id
    )
    SELECT
     indsats_attr_egenskaber_obj.brugervendtnoegle,
      indsats_attr_egenskaber_obj.beskrivelse,
      indsats_attr_egenskaber_obj.starttidspunkt,
      indsats_attr_egenskaber_obj.sluttidspunkt,
      indsats_attr_egenskaber_obj.virkning,
      indsats_registrering_id
    ;
 

  END LOOP;
END IF;

/*********************************/
--Insert states (tilstande)


--Verification
--For now all declared states are mandatory.
IF coalesce(array_length(indsats_registrering.tilsPubliceret, 1),0)<1  THEN
  RAISE EXCEPTION 'Savner påkraevet tilstand [publiceret] for indsats. Oprettelse afbrydes.' USING ERRCODE='MO400';
END IF;

IF indsats_registrering.tilsPubliceret IS NOT NULL AND coalesce(array_length(indsats_registrering.tilsPubliceret,1),0)>0 THEN
  FOREACH indsats_tils_publiceret_obj IN ARRAY indsats_registrering.tilsPubliceret
  LOOP

    INSERT INTO indsats_tils_publiceret (
      virkning,
      publiceret,
      indsats_registrering_id
    )
    SELECT
      indsats_tils_publiceret_obj.virkning,
      indsats_tils_publiceret_obj.publiceret,
      indsats_registrering_id;

  END LOOP;
END IF;

--Verification
--For now all declared states are mandatory.
IF coalesce(array_length(indsats_registrering.tilsFremdrift, 1),0)<1  THEN
  RAISE EXCEPTION 'Savner påkraevet tilstand [fremdrift] for indsats. Oprettelse afbrydes.' USING ERRCODE='MO400';
END IF;

IF indsats_registrering.tilsFremdrift IS NOT NULL AND coalesce(array_length(indsats_registrering.tilsFremdrift,1),0)>0 THEN
  FOREACH indsats_tils_fremdrift_obj IN ARRAY indsats_registrering.tilsFremdrift
  LOOP

    INSERT INTO indsats_tils_fremdrift (
      virkning,
      fremdrift,
      indsats_registrering_id
    )
    SELECT
      indsats_tils_fremdrift_obj.virkning,
      indsats_tils_fremdrift_obj.fremdrift,
      indsats_registrering_id;

  END LOOP;
END IF;

/*********************************/
--Insert relations

IF coalesce(array_length(indsats_registrering.relationer,1),0)>0 THEN

--Create temporary sequences
indsats_uuid_underscores:=replace(indsats_uuid::text, '-', '_');

SELECT array_agg( DISTINCT a.RelType) into indsats_rel_type_cardinality_unlimited_present_in_argument FROM  unnest(indsats_registrering.relationer) a WHERE a.RelType = any (indsats_rel_type_cardinality_unlimited) ;
IF coalesce(array_length(indsats_rel_type_cardinality_unlimited_present_in_argument,1),0)>0 THEN
FOREACH indsats_relation_kode IN ARRAY (indsats_rel_type_cardinality_unlimited_present_in_argument)
  LOOP
  indsats_rel_seq_name := 'indsats_' || indsats_relation_kode::text || indsats_uuid_underscores;

  EXECUTE 'CREATE TEMPORARY SEQUENCE ' || indsats_rel_seq_name || '
  INCREMENT 1
  MINVALUE 1
  MAXVALUE 9223372036854775807
  START 1
  CACHE 1;';

END LOOP;
END IF;

    INSERT INTO indsats_relation (
      indsats_registrering_id,
      virkning,
      rel_maal_uuid,
      rel_maal_urn,
      rel_type,
      objekt_type,
      rel_index
    )
    SELECT
      indsats_registrering_id,
      a.virkning,
      a.uuid,
      a.urn,
      a.relType,
      a.objektType,
        CASE WHEN a.relType = any (indsats_rel_type_cardinality_unlimited) THEN --rel_index
        nextval('indsats_' || a.relType::text || indsats_uuid_underscores)
        ELSE 
        NULL
        END
    FROM unnest(indsats_registrering.relationer) a
    ;


--Drop temporary sequences
IF coalesce(array_length(indsats_rel_type_cardinality_unlimited_present_in_argument,1),0)>0 THEN
FOREACH indsats_relation_kode IN ARRAY (indsats_rel_type_cardinality_unlimited_present_in_argument)
  LOOP
  indsats_rel_seq_name := 'indsats_' || indsats_relation_kode::text || indsats_uuid_underscores;
  EXECUTE 'DROP  SEQUENCE ' || indsats_rel_seq_name || ';';
END LOOP;
END IF;

END IF;

/*** Verify that the object meets the stipulated access allowed criteria  ***/
/*** NOTICE: We are doing this check *after* the insertion of data BUT *before* transaction commit, to reuse code / avoid fragmentation  ***/
auth_filtered_uuids:=_as_filter_unauth_indsats(array[indsats_uuid]::uuid[],auth_criteria_arr); 
IF NOT (coalesce(array_length(auth_filtered_uuids,1),0)=1 AND auth_filtered_uuids @>ARRAY[indsats_uuid]) THEN
  RAISE EXCEPTION 'Unable to create/import indsats with uuid [%]. Object does not met stipulated criteria:%',indsats_uuid,to_json(auth_criteria_arr)  USING ERRCODE = 'MO401'; 
END IF;
/*********************/


  PERFORM actual_state._amqp_publish_notification('Indsats', (indsats_registrering.registrering).livscykluskode, indsats_uuid);

RETURN indsats_uuid;

END;
$$ LANGUAGE plpgsql VOLATILE;


