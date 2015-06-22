-- Copyright (C) 2015 Magenta ApS, http://magenta.dk.
-- Contact: info@magenta.dk.
--
-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at http://mozilla.org/MPL/2.0/.

/*
NOTICE: This file is auto-generated using the script: apply-template.py klassifikation as_create_or_import.jinja.sql
*/

CREATE OR REPLACE FUNCTION as_create_or_import_klassifikation(
  klassifikation_registrering KlassifikationRegistreringType,
  klassifikation_uuid uuid DEFAULT NULL
	)
  RETURNS uuid AS 
$$
DECLARE
  klassifikation_registrering_id bigint;
  klassifikation_attr_egenskaber_obj klassifikationEgenskaberAttrType;
  
  klassifikation_tils_publiceret_obj klassifikationPubliceretTilsType;
  
  klassifikation_relationer KlassifikationRelationType;

BEGIN

IF klassifikation_uuid IS NULL THEN
    LOOP
    klassifikation_uuid:=uuid_generate_v4();
    EXIT WHEN NOT EXISTS (SELECT id from klassifikation WHERE id=klassifikation_uuid); 
    END LOOP;
END IF;


IF EXISTS (SELECT id from klassifikation WHERE id=klassifikation_uuid) THEN
  RAISE EXCEPTION 'Error creating or importing klassifikation with uuid [%]. If you did not supply the uuid when invoking as_create_or_import_klassifikation (i.e. create operation) please try to repeat the invocation/operation, that id collison with randomly generated uuids might in theory occur, albeit very very very rarely.',klassifikation_uuid;
END IF;

IF  (klassifikation_registrering.registrering).livscykluskode<>'Opstaaet'::Livscykluskode and (klassifikation_registrering.registrering).livscykluskode<>'Importeret'::Livscykluskode THEN
  RAISE EXCEPTION 'Invalid livscykluskode[%] invoking as_create_or_import_klassifikation.',(klassifikation_registrering.registrering).livscykluskode;
END IF;



INSERT INTO 
      klassifikation (ID)
SELECT
      klassifikation_uuid
;


/*********************************/
--Insert new registrering

klassifikation_registrering_id:=nextval('klassifikation_registrering_id_seq');

INSERT INTO klassifikation_registrering (
      id,
        klassifikation_id,
          registrering
        )
SELECT
      klassifikation_registrering_id,
        klassifikation_uuid,
          ROW (
            TSTZRANGE(clock_timestamp(),'infinity'::TIMESTAMPTZ,'[)' ),
            (klassifikation_registrering.registrering).livscykluskode,
            (klassifikation_registrering.registrering).brugerref,
            (klassifikation_registrering.registrering).note
              ):: RegistreringBase
;

/*********************************/
--Insert attributes


/************/
--Verification
--For now all declared attributes are mandatory (the fields are all optional,though)

 
IF coalesce(array_length(klassifikation_registrering.attrEgenskaber, 1),0)<1 THEN
  RAISE EXCEPTION 'Savner påkraevet attribut [egenskaber] for [klassifikation]. Oprettelse afbrydes.';
END IF;



IF klassifikation_registrering.attrEgenskaber IS NOT NULL THEN
  FOREACH klassifikation_attr_egenskaber_obj IN ARRAY klassifikation_registrering.attrEgenskaber
  LOOP

  IF
  ( klassifikation_attr_egenskaber_obj.brugervendtnoegle IS NOT NULL AND klassifikation_attr_egenskaber_obj.brugervendtnoegle<>'') 
   OR 
  ( klassifikation_attr_egenskaber_obj.beskrivelse IS NOT NULL AND klassifikation_attr_egenskaber_obj.beskrivelse<>'') 
   OR 
  ( klassifikation_attr_egenskaber_obj.kaldenavn IS NOT NULL AND klassifikation_attr_egenskaber_obj.kaldenavn<>'') 
   OR 
  ( klassifikation_attr_egenskaber_obj.ophavsret IS NOT NULL AND klassifikation_attr_egenskaber_obj.ophavsret<>'') 
   THEN

    INSERT INTO klassifikation_attr_egenskaber (
      brugervendtnoegle,
      beskrivelse,
      kaldenavn,
      ophavsret,
      virkning,
      klassifikation_registrering_id
    )
    SELECT
     klassifikation_attr_egenskaber_obj.brugervendtnoegle,
      klassifikation_attr_egenskaber_obj.beskrivelse,
      klassifikation_attr_egenskaber_obj.kaldenavn,
      klassifikation_attr_egenskaber_obj.ophavsret,
      klassifikation_attr_egenskaber_obj.virkning,
      klassifikation_registrering_id
    ;
  END IF;

  END LOOP;
END IF;

/*********************************/
--Insert states (tilstande)


--Verification
--For now all declared states are mandatory.
IF coalesce(array_length(klassifikation_registrering.tilsPubliceret, 1),0)<1  THEN
  RAISE EXCEPTION 'Savner påkraevet tilstand [publiceret] for klassifikation. Oprettelse afbrydes.';
END IF;

IF klassifikation_registrering.tilsPubliceret IS NOT NULL THEN
  FOREACH klassifikation_tils_publiceret_obj IN ARRAY klassifikation_registrering.tilsPubliceret
  LOOP

  IF klassifikation_tils_publiceret_obj.publiceret IS NOT NULL AND klassifikation_tils_publiceret_obj.publiceret<>''::KlassifikationPubliceretTils THEN

    INSERT INTO klassifikation_tils_publiceret (
      virkning,
      publiceret,
      klassifikation_registrering_id
    )
    SELECT
      klassifikation_tils_publiceret_obj.virkning,
      klassifikation_tils_publiceret_obj.publiceret,
      klassifikation_registrering_id;

  END IF;
  END LOOP;
END IF;

/*********************************/
--Insert relations

    INSERT INTO klassifikation_relation (
      klassifikation_registrering_id,
      virkning,
      rel_maal_uuid,
      rel_maal_urn,
      rel_type

    )
    SELECT
      klassifikation_registrering_id,
      a.virkning,
      a.relMaalUuid,
      a.relMaalUrn,
      a.relType
    FROM unnest(klassifikation_registrering.relationer) a
    WHERE (a.relMaalUuid IS NOT NULL OR (a.relMaalUrn IS NOT NULL AND a.relMaalUrn<>'') )
  ;


RETURN klassifikation_uuid;

END;
$$ LANGUAGE plpgsql VOLATILE;


