-- Copyright (C) 2015 Magenta ApS, http://magenta.dk.
-- Contact: info@magenta.dk.
--
-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at http://mozilla.org/MPL/2.0/.

/*
NOTICE: This file is auto-generated using the script: apply-template.py organisationfunktion as_create_or_import.jinja.sql
*/

CREATE OR REPLACE FUNCTION as_create_or_import_organisationfunktion(
  organisationfunktion_registrering OrganisationfunktionRegistreringType,
  organisationfunktion_uuid uuid DEFAULT NULL,
  auth_criteria_arr OrganisationfunktionRegistreringType[] DEFAULT NULL
	)
  RETURNS uuid AS 
$$
DECLARE
  organisationfunktion_registrering_id bigint;
  organisationfunktion_attr_egenskaber_obj organisationfunktionEgenskaberAttrType;
  
  organisationfunktion_tils_gyldighed_obj organisationfunktionGyldighedTilsType;
  
  organisationfunktion_relationer OrganisationfunktionRelationType;
  auth_filtered_uuids uuid[];
  does_exist boolean;
  new_organisationfunktion_registrering organisationfunktion_registrering;
BEGIN

IF organisationfunktion_uuid IS NULL THEN
    LOOP
    organisationfunktion_uuid:=uuid_generate_v4();
    EXIT WHEN NOT EXISTS (SELECT id from organisationfunktion WHERE id=organisationfunktion_uuid); 
    END LOOP;
END IF;


IF EXISTS (SELECT id from organisationfunktion WHERE id=organisationfunktion_uuid) THEN
    does_exist = True;
ELSE

    does_exist = False;
END IF;

IF  (organisationfunktion_registrering.registrering).livscykluskode<>'Opstaaet'::Livscykluskode and (organisationfunktion_registrering.registrering).livscykluskode<>'Importeret'::Livscykluskode  and (organisationfunktion_registrering.registrering).livscykluskode<>'Rettet'::Livscykluskode THEN
  RAISE EXCEPTION 'Invalid livscykluskode[%] invoking as_create_or_import_organisationfunktion.',(organisationfunktion_registrering.registrering).livscykluskode USING ERRCODE='MO400';
END IF;


IF NOT does_exist THEN

    INSERT INTO
          organisationfunktion (ID)
    SELECT
          organisationfunktion_uuid;
END IF;


/*********************************/
--Insert new registrering

IF NOT does_exist THEN
    organisationfunktion_registrering_id:=nextval('organisationfunktion_registrering_id_seq');

    INSERT INTO organisationfunktion_registrering (
          id,
          organisationfunktion_id,
          registrering
        )
    SELECT
          organisationfunktion_registrering_id,
           organisationfunktion_uuid,
           ROW (
             TSTZRANGE(clock_timestamp(),'infinity'::TIMESTAMPTZ,'[)' ),
             (organisationfunktion_registrering.registrering).livscykluskode,
             (organisationfunktion_registrering.registrering).brugerref,
             (organisationfunktion_registrering.registrering).note
               ):: RegistreringBase ;
ELSE
    -- This is an update, not an import or create
        new_organisationfunktion_registrering := _as_create_organisationfunktion_registrering(
             organisationfunktion_uuid,
             (organisationfunktion_registrering.registrering).livscykluskode,
             (organisationfunktion_registrering.registrering).brugerref,
             (organisationfunktion_registrering.registrering).note);

        organisationfunktion_registrering_id := new_organisationfunktion_registrering.id;
END IF;


/*********************************/
--Insert attributes


/************/
--Verification
--For now all declared attributes are mandatory (the fields are all optional,though)

 
IF coalesce(array_length(organisationfunktion_registrering.attrEgenskaber, 1),0)<1 THEN
  RAISE EXCEPTION 'Savner påkraevet attribut [egenskaber] for [organisationfunktion]. Oprettelse afbrydes.' USING ERRCODE='MO400';
END IF;



IF organisationfunktion_registrering.attrEgenskaber IS NOT NULL and coalesce(array_length(organisationfunktion_registrering.attrEgenskaber,1),0)>0 THEN
  FOREACH organisationfunktion_attr_egenskaber_obj IN ARRAY organisationfunktion_registrering.attrEgenskaber
  LOOP

    INSERT INTO organisationfunktion_attr_egenskaber (
      brugervendtnoegle,
      funktionsnavn,
      virkning,
      organisationfunktion_registrering_id
    )
    SELECT
     organisationfunktion_attr_egenskaber_obj.brugervendtnoegle,
      organisationfunktion_attr_egenskaber_obj.funktionsnavn,
      organisationfunktion_attr_egenskaber_obj.virkning,
      organisationfunktion_registrering_id
    ;
 

  END LOOP;
END IF;

/*********************************/
--Insert states (tilstande)


--Verification
--For now all declared states are mandatory.
IF coalesce(array_length(organisationfunktion_registrering.tilsGyldighed, 1),0)<1  THEN
  RAISE EXCEPTION 'Savner påkraevet tilstand [gyldighed] for organisationfunktion. Oprettelse afbrydes.' USING ERRCODE='MO400';
END IF;

IF organisationfunktion_registrering.tilsGyldighed IS NOT NULL AND coalesce(array_length(organisationfunktion_registrering.tilsGyldighed,1),0)>0 THEN
  FOREACH organisationfunktion_tils_gyldighed_obj IN ARRAY organisationfunktion_registrering.tilsGyldighed
  LOOP

    INSERT INTO organisationfunktion_tils_gyldighed (
      virkning,
      gyldighed,
      organisationfunktion_registrering_id
    )
    SELECT
      organisationfunktion_tils_gyldighed_obj.virkning,
      organisationfunktion_tils_gyldighed_obj.gyldighed,
      organisationfunktion_registrering_id;

  END LOOP;
END IF;

/*********************************/
--Insert relations

    INSERT INTO organisationfunktion_relation (
      organisationfunktion_registrering_id,
      virkning,
      rel_maal_uuid,
      rel_maal_urn,
      rel_type,
      objekt_type
    )
    SELECT
      organisationfunktion_registrering_id,
      a.virkning,
      a.uuid,
      a.urn,
      a.relType,
      a.objektType
    FROM unnest(organisationfunktion_registrering.relationer) a
  ;


/*** Verify that the object meets the stipulated access allowed criteria  ***/
/*** NOTICE: We are doing this check *after* the insertion of data BUT *before* transaction commit, to reuse code / avoid fragmentation  ***/
auth_filtered_uuids:=_as_filter_unauth_organisationfunktion(array[organisationfunktion_uuid]::uuid[],auth_criteria_arr); 
IF NOT (coalesce(array_length(auth_filtered_uuids,1),0)=1 AND auth_filtered_uuids @>ARRAY[organisationfunktion_uuid]) THEN
  RAISE EXCEPTION 'Unable to create/import organisationfunktion with uuid [%]. Object does not met stipulated criteria:%',organisationfunktion_uuid,to_json(auth_criteria_arr)  USING ERRCODE = 'MO401'; 
END IF;
/*********************/


  PERFORM actual_state._amqp_publish_notification('Organisationfunktion', (organisationfunktion_registrering.registrering).livscykluskode, organisationfunktion_uuid);

RETURN organisationfunktion_uuid;

END;
$$ LANGUAGE plpgsql VOLATILE;


