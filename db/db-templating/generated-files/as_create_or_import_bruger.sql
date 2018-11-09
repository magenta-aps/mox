-- Copyright (C) 2015 Magenta ApS, http://magenta.dk.
-- Contact: info@magenta.dk.
--
-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at http://mozilla.org/MPL/2.0/.

/*
NOTICE: This file is auto-generated using the script: apply-template.py bruger as_create_or_import.jinja.sql
*/

CREATE OR REPLACE FUNCTION as_create_or_import_bruger(
  bruger_registrering BrugerRegistreringType,
  bruger_uuid uuid DEFAULT NULL,
  auth_criteria_arr BrugerRegistreringType[] DEFAULT NULL
	)
  RETURNS uuid AS 
$$
DECLARE
  bruger_registrering_id bigint;
  bruger_attr_egenskaber_obj brugerEgenskaberAttrType;
  
  bruger_tils_gyldighed_obj brugerGyldighedTilsType;
  
  bruger_relationer BrugerRelationType;
  auth_filtered_uuids uuid[];
  does_exist boolean;
  new_bruger_registrering bruger_registrering;
BEGIN

IF bruger_uuid IS NULL THEN
    LOOP
    bruger_uuid:=uuid_generate_v4();
    EXIT WHEN NOT EXISTS (SELECT id from bruger WHERE id=bruger_uuid); 
    END LOOP;
END IF;


IF EXISTS (SELECT id from bruger WHERE id=bruger_uuid) THEN
    does_exist = True;
ELSE

    does_exist = False;
END IF;

IF  (bruger_registrering.registrering).livscykluskode<>'Opstaaet'::Livscykluskode and (bruger_registrering.registrering).livscykluskode<>'Importeret'::Livscykluskode  and (bruger_registrering.registrering).livscykluskode<>'Rettet'::Livscykluskode THEN
  RAISE EXCEPTION 'Invalid livscykluskode[%] invoking as_create_or_import_bruger.',(bruger_registrering.registrering).livscykluskode USING ERRCODE='MO400';
END IF;


IF NOT does_exist THEN

    INSERT INTO
          bruger (ID)
    SELECT
          bruger_uuid;
END IF;


/*********************************/
--Insert new registrering

IF NOT does_exist THEN
    bruger_registrering_id:=nextval('bruger_registrering_id_seq');

    INSERT INTO bruger_registrering (
          id,
          bruger_id,
          registrering
        )
    SELECT
          bruger_registrering_id,
           bruger_uuid,
           ROW (
             TSTZRANGE(clock_timestamp(),'infinity'::TIMESTAMPTZ,'[)' ),
             (bruger_registrering.registrering).livscykluskode,
             (bruger_registrering.registrering).brugerref,
             (bruger_registrering.registrering).note
               ):: RegistreringBase ;
ELSE
    -- This is an update, not an import or create
        new_bruger_registrering := _as_create_bruger_registrering(
             bruger_uuid,
             (bruger_registrering.registrering).livscykluskode,
             (bruger_registrering.registrering).brugerref,
             (bruger_registrering.registrering).note);

        bruger_registrering_id := new_bruger_registrering.id;
END IF;


/*********************************/
--Insert attributes


/************/
--Verification
--For now all declared attributes are mandatory (the fields are all optional,though)

 
IF coalesce(array_length(bruger_registrering.attrEgenskaber, 1),0)<1 THEN
  RAISE EXCEPTION 'Savner påkraevet attribut [egenskaber] for [bruger]. Oprettelse afbrydes.' USING ERRCODE='MO400';
END IF;



IF bruger_registrering.attrEgenskaber IS NOT NULL and coalesce(array_length(bruger_registrering.attrEgenskaber,1),0)>0 THEN
  FOREACH bruger_attr_egenskaber_obj IN ARRAY bruger_registrering.attrEgenskaber
  LOOP

    INSERT INTO bruger_attr_egenskaber (
      brugervendtnoegle,
      brugernavn,
      brugertype,
      virkning,
      bruger_registrering_id
    )
    SELECT
     bruger_attr_egenskaber_obj.brugervendtnoegle,
      bruger_attr_egenskaber_obj.brugernavn,
      bruger_attr_egenskaber_obj.brugertype,
      bruger_attr_egenskaber_obj.virkning,
      bruger_registrering_id
    ;
 

  END LOOP;
END IF;

/*********************************/
--Insert states (tilstande)


--Verification
--For now all declared states are mandatory.
IF coalesce(array_length(bruger_registrering.tilsGyldighed, 1),0)<1  THEN
  RAISE EXCEPTION 'Savner påkraevet tilstand [gyldighed] for bruger. Oprettelse afbrydes.' USING ERRCODE='MO400';
END IF;

IF bruger_registrering.tilsGyldighed IS NOT NULL AND coalesce(array_length(bruger_registrering.tilsGyldighed,1),0)>0 THEN
  FOREACH bruger_tils_gyldighed_obj IN ARRAY bruger_registrering.tilsGyldighed
  LOOP

    INSERT INTO bruger_tils_gyldighed (
      virkning,
      gyldighed,
      bruger_registrering_id
    )
    SELECT
      bruger_tils_gyldighed_obj.virkning,
      bruger_tils_gyldighed_obj.gyldighed,
      bruger_registrering_id;

  END LOOP;
END IF;

/*********************************/
--Insert relations

    INSERT INTO bruger_relation (
      bruger_registrering_id,
      virkning,
      rel_maal_uuid,
      rel_maal_urn,
      rel_type,
      objekt_type
    )
    SELECT
      bruger_registrering_id,
      a.virkning,
      a.uuid,
      a.urn,
      a.relType,
      a.objektType
    FROM unnest(bruger_registrering.relationer) a
  ;


/*** Verify that the object meets the stipulated access allowed criteria  ***/
/*** NOTICE: We are doing this check *after* the insertion of data BUT *before* transaction commit, to reuse code / avoid fragmentation  ***/
auth_filtered_uuids:=_as_filter_unauth_bruger(array[bruger_uuid]::uuid[],auth_criteria_arr); 
IF NOT (coalesce(array_length(auth_filtered_uuids,1),0)=1 AND auth_filtered_uuids @>ARRAY[bruger_uuid]) THEN
  RAISE EXCEPTION 'Unable to create/import bruger with uuid [%]. Object does not met stipulated criteria:%',bruger_uuid,to_json(auth_criteria_arr)  USING ERRCODE = 'MO401'; 
END IF;
/*********************/




RETURN bruger_uuid;

END;
$$ LANGUAGE plpgsql VOLATILE;


