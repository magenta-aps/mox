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
  does_exist boolean;
  new_indsats_registrering indsats_registrering;
  prev_indsats_registrering indsats_registrering;
BEGIN

IF indsats_uuid IS NULL THEN
    LOOP
    indsats_uuid:=uuid_generate_v4();
    EXIT WHEN NOT EXISTS (SELECT id from indsats WHERE id=indsats_uuid); 
    END LOOP;
END IF;


IF EXISTS (SELECT id from indsats WHERE id=indsats_uuid) THEN
    does_exist = True;
ELSE

    does_exist = False;
END IF;

IF  (indsats_registrering.registrering).livscykluskode<>'Opstaaet'::Livscykluskode and (indsats_registrering.registrering).livscykluskode<>'Importeret'::Livscykluskode  and (indsats_registrering.registrering).livscykluskode<>'Rettet'::Livscykluskode THEN
  RAISE EXCEPTION 'Invalid livscykluskode[%] invoking as_create_or_import_indsats.',(indsats_registrering.registrering).livscykluskode USING ERRCODE='MO400';
END IF;


IF NOT does_exist THEN

    INSERT INTO
          indsats (ID)
    SELECT
          indsats_uuid;
END IF;


/*********************************/
--Insert new registrering

IF NOT does_exist THEN
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
               ):: RegistreringBase ;
ELSE
    -- This is an update, not an import or create
        new_indsats_registrering := _as_create_indsats_registrering(
             indsats_uuid,
             (indsats_registrering.registrering).livscykluskode,
             (indsats_registrering.registrering).brugerref,
             (indsats_registrering.registrering).note);

        indsats_registrering_id := new_indsats_registrering.id;
END IF;


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

    INSERT INTO indsats_relation (
      indsats_registrering_id,
      virkning,
      rel_maal_uuid,
      rel_maal_urn,
      rel_type,
      objekt_type
    )
    SELECT
      indsats_registrering_id,
      a.virkning,
      a.uuid,
      a.urn,
      a.relType,
      a.objektType
    FROM unnest(indsats_registrering.relationer) a
  ;


/*** Verify that the object meets the stipulated access allowed criteria  ***/
/*** NOTICE: We are doing this check *after* the insertion of data BUT *before* transaction commit, to reuse code / avoid fragmentation  ***/
auth_filtered_uuids:=_as_filter_unauth_indsats(array[indsats_uuid]::uuid[],auth_criteria_arr); 
IF NOT (coalesce(array_length(auth_filtered_uuids,1),0)=1 AND auth_filtered_uuids @>ARRAY[indsats_uuid]) THEN
  RAISE EXCEPTION 'Unable to create/import indsats with uuid [%]. Object does not met stipulated criteria:%',indsats_uuid,to_json(auth_criteria_arr)  USING ERRCODE = 'MO401'; 
END IF;
/*********************/




RETURN indsats_uuid;

END;
$$ LANGUAGE plpgsql VOLATILE;


