-- Copyright (C) 2015 Magenta ApS, http://magenta.dk.
-- Contact: info@magenta.dk.
--
-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at http://mozilla.org/MPL/2.0/.

/*
NOTICE: This file is auto-generated using the script: apply-template.py klasse as_create_or_import.jinja.sql AND applying a patch (as_create_or_import_klasse.sql.diff)
*/

CREATE OR REPLACE FUNCTION as_create_or_import_klasse(
  klasse_registrering KlasseRegistreringType,
  klasse_uuid uuid DEFAULT NULL,
  auth_criteria_arr KlasseRegistreringType[] DEFAULT NULL
	)
  RETURNS uuid AS 
$$
DECLARE
  klasse_registrering_id bigint;
  klasse_attr_egenskaber_obj klasseEgenskaberAttrType;
  
  klasse_tils_publiceret_obj klassePubliceretTilsType;
  
  klasse_relationer KlasseRelationType;
  klasse_attr_egenskaber_id bigint;
  klasse_attr_egenskaber_soegeord_obj KlasseSoegeordType;
  auth_filtered_uuids uuid[];
BEGIN

IF klasse_uuid IS NULL THEN
    LOOP
    klasse_uuid:=uuid_generate_v4();
    EXIT WHEN NOT EXISTS (SELECT id from klasse WHERE id=klasse_uuid); 
    END LOOP;
END IF;


IF EXISTS (SELECT id from klasse WHERE id=klasse_uuid) THEN
  RAISE EXCEPTION 'Error creating or importing klasse with uuid [%]. If you did not supply the uuid when invoking as_create_or_import_klasse (i.e. create operation) please try to repeat the invocation/operation, that id collison with randomly generated uuids might in theory occur, albeit very very very rarely.',klasse_uuid;
END IF;

IF  (klasse_registrering.registrering).livscykluskode<>'Opstaaet'::Livscykluskode and (klasse_registrering.registrering).livscykluskode<>'Importeret'::Livscykluskode THEN
  RAISE EXCEPTION 'Invalid livscykluskode[%] invoking as_create_or_import_klasse.',(klasse_registrering.registrering).livscykluskode;
END IF;



INSERT INTO 
      klasse (ID)
SELECT
      klasse_uuid
;


/*********************************/
--Insert new registrering

klasse_registrering_id:=nextval('klasse_registrering_id_seq');

INSERT INTO klasse_registrering (
      id,
        klasse_id,
          registrering
        )
SELECT
      klasse_registrering_id,
        klasse_uuid,
          ROW (
            TSTZRANGE(clock_timestamp(),'infinity'::TIMESTAMPTZ,'[)' ),
            (klasse_registrering.registrering).livscykluskode,
            (klasse_registrering.registrering).brugerref,
            (klasse_registrering.registrering).note
              ):: RegistreringBase
;

/*********************************/
--Insert attributes


/************/
--Verification
--For now all declared attributes are mandatory (the fields are all optional,though)

 
IF coalesce(array_length(klasse_registrering.attrEgenskaber, 1),0)<1 THEN
  RAISE EXCEPTION 'Savner påkraevet attribut [egenskaber] for [klasse]. Oprettelse afbrydes.';
END IF;



IF klasse_registrering.attrEgenskaber IS NOT NULL and coalesce(array_length(klasse_registrering.attrEgenskaber,1),0)>0 THEN
  FOREACH klasse_attr_egenskaber_obj IN ARRAY klasse_registrering.attrEgenskaber
  LOOP

klasse_attr_egenskaber_id:=nextval('klasse_attr_egenskaber_id_seq');
  INSERT INTO klasse_attr_egenskaber (
    id,
    brugervendtnoegle,
    beskrivelse,
    eksempel,
    omfang,
    titel,
    retskilde,
    aendringsnotat,
    virkning,
    klasse_registrering_id
  )
  SELECT
    klasse_attr_egenskaber_id,
   klasse_attr_egenskaber_obj.brugervendtnoegle,
    klasse_attr_egenskaber_obj.beskrivelse,
    klasse_attr_egenskaber_obj.eksempel,
    klasse_attr_egenskaber_obj.omfang,
    klasse_attr_egenskaber_obj.titel,
    klasse_attr_egenskaber_obj.retskilde,
    klasse_attr_egenskaber_obj.aendringsnotat,
    klasse_attr_egenskaber_obj.virkning,
    klasse_registrering_id
  ;

/************/
--Insert Soegeord
  IF klasse_attr_egenskaber_obj.soegeord IS NOT NULL AND coalesce(array_length(klasse_attr_egenskaber_obj.soegeord,1),0)>1  THEN
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
  END LOOP;
END IF;

/*********************************/
--Insert states (tilstande)


--Verification
--For now all declared states are mandatory.
IF coalesce(array_length(klasse_registrering.tilsPubliceret, 1),0)<1  THEN
  RAISE EXCEPTION 'Savner påkraevet tilstand [publiceret] for klasse. Oprettelse afbrydes.';
END IF;

IF klasse_registrering.tilsPubliceret IS NOT NULL AND coalesce(array_length(klasse_registrering.tilsPubliceret,1),0)>0 THEN
  FOREACH klasse_tils_publiceret_obj IN ARRAY klasse_registrering.tilsPubliceret
  LOOP

    INSERT INTO klasse_tils_publiceret (
      virkning,
      publiceret,
      klasse_registrering_id
    )
    SELECT
      klasse_tils_publiceret_obj.virkning,
      klasse_tils_publiceret_obj.publiceret,
      klasse_registrering_id;

  END LOOP;
END IF;

/*********************************/
--Insert relations

    INSERT INTO klasse_relation (
      klasse_registrering_id,
      virkning,
      rel_maal_uuid,
      rel_maal_urn,
      rel_type,
      objekt_type
    )
    SELECT
      klasse_registrering_id,
      a.virkning,
      a.relMaalUuid,
      a.relMaalUrn,
      a.relType,
      a.objektType
    FROM unnest(klasse_registrering.relationer) a
  ;


/*** Verify that the object meets the stipulated access allowed criteria  ***/
/*** NOTICE: We are doing this check *after* the insertion of data BUT *before* transaction commit, to reuse code / avoid fragmentation  ***/
auth_filtered_uuids:=_as_filter_unauth_klasse(array[klasse_uuid]::uuid[],auth_criteria_arr); 
IF NOT (coalesce(array_length(auth_filtered_uuids,1),0)=1 AND auth_filtered_uuids @>ARRAY[klasse_uuid]) THEN
  RAISE EXCEPTION 'Unable to create/import klasse with uuid [%]. Object does not met stipulated criteria:%',klasse_uuid,to_json(auth_criteria_arr)  USING ERRCODE = 'MO401'; 
END IF;
/*********************/


  PERFORM actual_state._amqp_publish_notification('Klasse', (klasse_registrering.registrering).livscykluskode, klasse_uuid);

RETURN klasse_uuid;

END;
$$ LANGUAGE plpgsql VOLATILE;


