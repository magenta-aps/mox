-- Copyright (C) 2015 Magenta ApS, http://magenta.dk.
-- Contact: info@magenta.dk.
--
-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at http://mozilla.org/MPL/2.0/.

/*
NOTICE: This file is auto-generated using the script: apply-template.py dokument as_create_or_import.jinja.sql
*/

CREATE OR REPLACE FUNCTION as_create_or_import_dokument(
  dokument_registrering DokumentRegistreringType,
  dokument_uuid uuid DEFAULT NULL,
  auth_criteria_arr DokumentRegistreringType[] DEFAULT NULL
	)
  RETURNS uuid AS 
$$
DECLARE
  dokument_registrering_id bigint;
  dokument_attr_egenskaber_obj dokumentEgenskaberAttrType;
  
  dokument_tils_fremdrift_obj dokumentFremdriftTilsType;
  
  dokument_relationer DokumentRelationType;
  auth_filtered_uuids uuid[];
  does_exist boolean;
  new_dokument_registrering dokument_registrering;
  prev_dokument_registrering dokument_registrering;
BEGIN

IF dokument_uuid IS NULL THEN
    LOOP
    dokument_uuid:=uuid_generate_v4();
    EXIT WHEN NOT EXISTS (SELECT id from dokument WHERE id=dokument_uuid); 
    END LOOP;
END IF;


IF EXISTS (SELECT id from dokument WHERE id=dokument_uuid) THEN
    does_exist = True;
ELSE

    does_exist = False;
END IF;

IF  (dokument_registrering.registrering).livscykluskode<>'Opstaaet'::Livscykluskode and (dokument_registrering.registrering).livscykluskode<>'Importeret'::Livscykluskode  and (dokument_registrering.registrering).livscykluskode<>'Rettet'::Livscykluskode THEN
  RAISE EXCEPTION 'Invalid livscykluskode[%] invoking as_create_or_import_dokument.',(dokument_registrering.registrering).livscykluskode USING ERRCODE='MO400';
END IF;


IF NOT does_exist THEN

    INSERT INTO
          dokument (ID)
    SELECT
          dokument_uuid;
END IF;


/*********************************/
--Insert new registrering

IF NOT does_exist THEN
    dokument_registrering_id:=nextval('dokument_registrering_id_seq');

    INSERT INTO dokument_registrering (
          id,
          dokument_id,
          registrering
        )
    SELECT
          dokument_registrering_id,
           dokument_uuid,
           ROW (
             TSTZRANGE(clock_timestamp(),'infinity'::TIMESTAMPTZ,'[)' ),
             (dokument_registrering.registrering).livscykluskode,
             (dokument_registrering.registrering).brugerref,
             (dokument_registrering.registrering).note
               ):: RegistreringBase ;
ELSE
    -- This is an update, not an import or create
        new_dokument_registrering := _as_create_dokument_registrering(
             dokument_uuid,
             (dokument_registrering.registrering).livscykluskode,
             (dokument_registrering.registrering).brugerref,
             (dokument_registrering.registrering).note);

        dokument_registrering_id := new_dokument_registrering.id;
END IF;


/*********************************/
--Insert attributes


/************/
--Verification
--For now all declared attributes are mandatory (the fields are all optional,though)

 
IF coalesce(array_length(dokument_registrering.attrEgenskaber, 1),0)<1 THEN
  RAISE EXCEPTION 'Savner påkraevet attribut [egenskaber] for [dokument]. Oprettelse afbrydes.' USING ERRCODE='MO400';
END IF;



IF dokument_registrering.attrEgenskaber IS NOT NULL and coalesce(array_length(dokument_registrering.attrEgenskaber,1),0)>0 THEN
  FOREACH dokument_attr_egenskaber_obj IN ARRAY dokument_registrering.attrEgenskaber
  LOOP

    INSERT INTO dokument_attr_egenskaber (
      brugervendtnoegle,
      beskrivelse,
      brevdato,
      kassationskode,
      major,
      minor,
      offentlighedundtaget,
      titel,
      dokumenttype,
      virkning,
      dokument_registrering_id
    )
    SELECT
     dokument_attr_egenskaber_obj.brugervendtnoegle,
      dokument_attr_egenskaber_obj.beskrivelse,
      dokument_attr_egenskaber_obj.brevdato,
      dokument_attr_egenskaber_obj.kassationskode,
      dokument_attr_egenskaber_obj.major,
      dokument_attr_egenskaber_obj.minor,
      dokument_attr_egenskaber_obj.offentlighedundtaget,
      dokument_attr_egenskaber_obj.titel,
      dokument_attr_egenskaber_obj.dokumenttype,
      dokument_attr_egenskaber_obj.virkning,
      dokument_registrering_id
    ;
 

  END LOOP;
END IF;

/*********************************/
--Insert states (tilstande)


--Verification
--For now all declared states are mandatory.
IF coalesce(array_length(dokument_registrering.tilsFremdrift, 1),0)<1  THEN
  RAISE EXCEPTION 'Savner påkraevet tilstand [fremdrift] for dokument. Oprettelse afbrydes.' USING ERRCODE='MO400';
END IF;

IF dokument_registrering.tilsFremdrift IS NOT NULL AND coalesce(array_length(dokument_registrering.tilsFremdrift,1),0)>0 THEN
  FOREACH dokument_tils_fremdrift_obj IN ARRAY dokument_registrering.tilsFremdrift
  LOOP

    INSERT INTO dokument_tils_fremdrift (
      virkning,
      fremdrift,
      dokument_registrering_id
    )
    SELECT
      dokument_tils_fremdrift_obj.virkning,
      dokument_tils_fremdrift_obj.fremdrift,
      dokument_registrering_id;

  END LOOP;
END IF;

/*********************************/
--Insert relations

    INSERT INTO dokument_relation (
      dokument_registrering_id,
      virkning,
      rel_maal_uuid,
      rel_maal_urn,
      rel_type,
      objekt_type
    )
    SELECT
      dokument_registrering_id,
      a.virkning,
      a.uuid,
      a.urn,
      a.relType,
      a.objektType
    FROM unnest(dokument_registrering.relationer) a
  ;


/*** Verify that the object meets the stipulated access allowed criteria  ***/
/*** NOTICE: We are doing this check *after* the insertion of data BUT *before* transaction commit, to reuse code / avoid fragmentation  ***/
auth_filtered_uuids:=_as_filter_unauth_dokument(array[dokument_uuid]::uuid[],auth_criteria_arr); 
IF NOT (coalesce(array_length(auth_filtered_uuids,1),0)=1 AND auth_filtered_uuids @>ARRAY[dokument_uuid]) THEN
  RAISE EXCEPTION 'Unable to create/import dokument with uuid [%]. Object does not met stipulated criteria:%',dokument_uuid,to_json(auth_criteria_arr)  USING ERRCODE = 'MO401'; 
END IF;
/*********************/




RETURN dokument_uuid;

END;
$$ LANGUAGE plpgsql VOLATILE;


