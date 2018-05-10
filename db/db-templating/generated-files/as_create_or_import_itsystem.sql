-- Copyright (C) 2015 Magenta ApS, http://magenta.dk.
-- Contact: info@magenta.dk.
--
-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at http://mozilla.org/MPL/2.0/.

/*
NOTICE: This file is auto-generated using the script: apply-template.py itsystem as_create_or_import.jinja.sql
*/

CREATE OR REPLACE FUNCTION as_create_or_import_itsystem(
  itsystem_registrering ItsystemRegistreringType,
  itsystem_uuid uuid DEFAULT NULL,
  auth_criteria_arr ItsystemRegistreringType[] DEFAULT NULL
	)
  RETURNS uuid AS 
$$
DECLARE
  itsystem_registrering_id bigint;
  itsystem_attr_egenskaber_obj itsystemEgenskaberAttrType;
  
  itsystem_tils_gyldighed_obj itsystemGyldighedTilsType;
  
  itsystem_relationer ItsystemRelationType;
  auth_filtered_uuids uuid[];
  does_exist boolean;
  new_itsystem_registrering itsystem_registrering;
BEGIN

IF itsystem_uuid IS NULL THEN
    LOOP
    itsystem_uuid:=uuid_generate_v4();
    EXIT WHEN NOT EXISTS (SELECT id from itsystem WHERE id=itsystem_uuid); 
    END LOOP;
END IF;


IF EXISTS (SELECT id from itsystem WHERE id=itsystem_uuid) THEN
    does_exist = True;
ELSE

    does_exist = False;
END IF;

IF  (itsystem_registrering.registrering).livscykluskode<>'Opstaaet'::Livscykluskode and (itsystem_registrering.registrering).livscykluskode<>'Importeret'::Livscykluskode  and (itsystem_registrering.registrering).livscykluskode<>'Rettet'::Livscykluskode THEN
  RAISE EXCEPTION 'Invalid livscykluskode[%] invoking as_create_or_import_itsystem.',(itsystem_registrering.registrering).livscykluskode USING ERRCODE='MO400';
END IF;


IF NOT does_exist THEN

    INSERT INTO
          itsystem (ID)
    SELECT
          itsystem_uuid;
END IF;


/*********************************/
--Insert new registrering

IF NOT does_exist THEN
    itsystem_registrering_id:=nextval('itsystem_registrering_id_seq');

    INSERT INTO itsystem_registrering (
          id,
          itsystem_id,
          registrering
        )
    SELECT
          itsystem_registrering_id,
           itsystem_uuid,
           ROW (
             TSTZRANGE(clock_timestamp(),'infinity'::TIMESTAMPTZ,'[)' ),
             (itsystem_registrering.registrering).livscykluskode,
             (itsystem_registrering.registrering).brugerref,
             (itsystem_registrering.registrering).note
               ):: RegistreringBase ;
ELSE
    -- This is an update, not an import or create
        new_itsystem_registrering := _as_create_itsystem_registrering(
             itsystem_uuid,
             (itsystem_registrering.registrering).livscykluskode,
             (itsystem_registrering.registrering).brugerref,
             (itsystem_registrering.registrering).note);

        itsystem_registrering_id := new_itsystem_registrering.id;
END IF;


/*********************************/
--Insert attributes


/************/
--Verification
--For now all declared attributes are mandatory (the fields are all optional,though)

 
IF coalesce(array_length(itsystem_registrering.attrEgenskaber, 1),0)<1 THEN
  RAISE EXCEPTION 'Savner påkraevet attribut [egenskaber] for [itsystem]. Oprettelse afbrydes.' USING ERRCODE='MO400';
END IF;



IF itsystem_registrering.attrEgenskaber IS NOT NULL and coalesce(array_length(itsystem_registrering.attrEgenskaber,1),0)>0 THEN
  FOREACH itsystem_attr_egenskaber_obj IN ARRAY itsystem_registrering.attrEgenskaber
  LOOP

    INSERT INTO itsystem_attr_egenskaber (
      brugervendtnoegle,
      itsystemnavn,
      itsystemtype,
      konfigurationreference,
      virkning,
      itsystem_registrering_id
    )
    SELECT
     itsystem_attr_egenskaber_obj.brugervendtnoegle,
      itsystem_attr_egenskaber_obj.itsystemnavn,
      itsystem_attr_egenskaber_obj.itsystemtype,
      itsystem_attr_egenskaber_obj.konfigurationreference,
      itsystem_attr_egenskaber_obj.virkning,
      itsystem_registrering_id
    ;
 

  END LOOP;
END IF;

/*********************************/
--Insert states (tilstande)


--Verification
--For now all declared states are mandatory.
IF coalesce(array_length(itsystem_registrering.tilsGyldighed, 1),0)<1  THEN
  RAISE EXCEPTION 'Savner påkraevet tilstand [gyldighed] for itsystem. Oprettelse afbrydes.' USING ERRCODE='MO400';
END IF;

IF itsystem_registrering.tilsGyldighed IS NOT NULL AND coalesce(array_length(itsystem_registrering.tilsGyldighed,1),0)>0 THEN
  FOREACH itsystem_tils_gyldighed_obj IN ARRAY itsystem_registrering.tilsGyldighed
  LOOP

    INSERT INTO itsystem_tils_gyldighed (
      virkning,
      gyldighed,
      itsystem_registrering_id
    )
    SELECT
      itsystem_tils_gyldighed_obj.virkning,
      itsystem_tils_gyldighed_obj.gyldighed,
      itsystem_registrering_id;

  END LOOP;
END IF;

/*********************************/
--Insert relations

    INSERT INTO itsystem_relation (
      itsystem_registrering_id,
      virkning,
      rel_maal_uuid,
      rel_maal_urn,
      rel_type,
      objekt_type
    )
    SELECT
      itsystem_registrering_id,
      a.virkning,
      a.uuid,
      a.urn,
      a.relType,
      a.objektType
    FROM unnest(itsystem_registrering.relationer) a
  ;


/*** Verify that the object meets the stipulated access allowed criteria  ***/
/*** NOTICE: We are doing this check *after* the insertion of data BUT *before* transaction commit, to reuse code / avoid fragmentation  ***/
auth_filtered_uuids:=_as_filter_unauth_itsystem(array[itsystem_uuid]::uuid[],auth_criteria_arr); 
IF NOT (coalesce(array_length(auth_filtered_uuids,1),0)=1 AND auth_filtered_uuids @>ARRAY[itsystem_uuid]) THEN
  RAISE EXCEPTION 'Unable to create/import itsystem with uuid [%]. Object does not met stipulated criteria:%',itsystem_uuid,to_json(auth_criteria_arr)  USING ERRCODE = 'MO401'; 
END IF;
/*********************/


  PERFORM actual_state._amqp_publish_notification('Itsystem', (itsystem_registrering.registrering).livscykluskode, itsystem_uuid);

RETURN itsystem_uuid;

END;
$$ LANGUAGE plpgsql VOLATILE;


