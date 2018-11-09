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
  sag_uuid uuid DEFAULT NULL,
  auth_criteria_arr SagRegistreringType[] DEFAULT NULL
	)
  RETURNS uuid AS 
$$
DECLARE
  sag_registrering_id bigint;
  sag_attr_egenskaber_obj sagEgenskaberAttrType;
  
  sag_tils_fremdrift_obj sagFremdriftTilsType;
  
  sag_relationer SagRelationType;
  auth_filtered_uuids uuid[];
  does_exist boolean;
  new_sag_registrering sag_registrering;
  prev_sag_registrering sag_registrering;
BEGIN

IF sag_uuid IS NULL THEN
    LOOP
    sag_uuid:=uuid_generate_v4();
    EXIT WHEN NOT EXISTS (SELECT id from sag WHERE id=sag_uuid); 
    END LOOP;
END IF;


IF EXISTS (SELECT id from sag WHERE id=sag_uuid) THEN
    does_exist = True;
ELSE

    does_exist = False;
END IF;

IF  (sag_registrering.registrering).livscykluskode<>'Opstaaet'::Livscykluskode and (sag_registrering.registrering).livscykluskode<>'Importeret'::Livscykluskode  and (sag_registrering.registrering).livscykluskode<>'Rettet'::Livscykluskode THEN
  RAISE EXCEPTION 'Invalid livscykluskode[%] invoking as_create_or_import_sag.',(sag_registrering.registrering).livscykluskode USING ERRCODE='MO400';
END IF;


IF NOT does_exist THEN

    INSERT INTO
          sag (ID)
    SELECT
          sag_uuid;
END IF;


/*********************************/
--Insert new registrering

IF NOT does_exist THEN
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
               ):: RegistreringBase ;
ELSE
    -- This is an update, not an import or create
        new_sag_registrering := _as_create_sag_registrering(
             sag_uuid,
             (sag_registrering.registrering).livscykluskode,
             (sag_registrering.registrering).brugerref,
             (sag_registrering.registrering).note);

        sag_registrering_id := new_sag_registrering.id;
END IF;


/*********************************/
--Insert attributes


/************/
--Verification
--For now all declared attributes are mandatory (the fields are all optional,though)

 
IF coalesce(array_length(sag_registrering.attrEgenskaber, 1),0)<1 THEN
  RAISE EXCEPTION 'Savner påkraevet attribut [egenskaber] for [sag]. Oprettelse afbrydes.' USING ERRCODE='MO400';
END IF;



IF sag_registrering.attrEgenskaber IS NOT NULL and coalesce(array_length(sag_registrering.attrEgenskaber,1),0)>0 THEN
  FOREACH sag_attr_egenskaber_obj IN ARRAY sag_registrering.attrEgenskaber
  LOOP

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
 

  END LOOP;
END IF;

/*********************************/
--Insert states (tilstande)


--Verification
--For now all declared states are mandatory.
IF coalesce(array_length(sag_registrering.tilsFremdrift, 1),0)<1  THEN
  RAISE EXCEPTION 'Savner påkraevet tilstand [fremdrift] for sag. Oprettelse afbrydes.' USING ERRCODE='MO400';
END IF;

IF sag_registrering.tilsFremdrift IS NOT NULL AND coalesce(array_length(sag_registrering.tilsFremdrift,1),0)>0 THEN
  FOREACH sag_tils_fremdrift_obj IN ARRAY sag_registrering.tilsFremdrift
  LOOP

    INSERT INTO sag_tils_fremdrift (
      virkning,
      fremdrift,
      sag_registrering_id
    )
    SELECT
      sag_tils_fremdrift_obj.virkning,
      sag_tils_fremdrift_obj.fremdrift,
      sag_registrering_id;

  END LOOP;
END IF;

/*********************************/
--Insert relations

    INSERT INTO sag_relation (
      sag_registrering_id,
      virkning,
      rel_maal_uuid,
      rel_maal_urn,
      rel_type,
      objekt_type
    )
    SELECT
      sag_registrering_id,
      a.virkning,
      a.uuid,
      a.urn,
      a.relType,
      a.objektType
    FROM unnest(sag_registrering.relationer) a
  ;


/*** Verify that the object meets the stipulated access allowed criteria  ***/
/*** NOTICE: We are doing this check *after* the insertion of data BUT *before* transaction commit, to reuse code / avoid fragmentation  ***/
auth_filtered_uuids:=_as_filter_unauth_sag(array[sag_uuid]::uuid[],auth_criteria_arr); 
IF NOT (coalesce(array_length(auth_filtered_uuids,1),0)=1 AND auth_filtered_uuids @>ARRAY[sag_uuid]) THEN
  RAISE EXCEPTION 'Unable to create/import sag with uuid [%]. Object does not met stipulated criteria:%',sag_uuid,to_json(auth_criteria_arr)  USING ERRCODE = 'MO401'; 
END IF;
/*********************/




RETURN sag_uuid;

END;
$$ LANGUAGE plpgsql VOLATILE;


