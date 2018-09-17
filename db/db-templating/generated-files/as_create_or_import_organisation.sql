-- Copyright (C) 2015 Magenta ApS, http://magenta.dk.
-- Contact: info@magenta.dk.
--
-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at http://mozilla.org/MPL/2.0/.

/*
NOTICE: This file is auto-generated using the script: oio_rest/apply-templates.py
*/

CREATE OR REPLACE FUNCTION as_create_or_import_organisation(
  organisation_registrering OrganisationRegistreringType,
  organisation_uuid uuid DEFAULT NULL,
  auth_criteria_arr OrganisationRegistreringType[] DEFAULT NULL
	)
  RETURNS uuid AS 
$$
DECLARE
  organisation_registrering_id bigint;
  organisation_attr_egenskaber_obj organisationEgenskaberAttrType;
  
  organisation_tils_gyldighed_obj organisationGyldighedTilsType;
  
  organisation_relationer OrganisationRelationType;
  
  auth_filtered_uuids uuid[];
  
  does_exist boolean;
  new_organisation_registrering organisation_registrering;
BEGIN

IF organisation_uuid IS NULL THEN
    LOOP
    organisation_uuid:=uuid_generate_v4();
    EXIT WHEN NOT EXISTS (SELECT id from organisation WHERE id=organisation_uuid); 
    END LOOP;
END IF;


IF EXISTS (SELECT id from organisation WHERE id=organisation_uuid) THEN
    does_exist = True;
ELSE

    does_exist = False;
END IF;

IF  (organisation_registrering.registrering).livscykluskode<>'Opstaaet'::Livscykluskode and (organisation_registrering.registrering).livscykluskode<>'Importeret'::Livscykluskode  and (organisation_registrering.registrering).livscykluskode<>'Rettet'::Livscykluskode THEN
  RAISE EXCEPTION 'Invalid livscykluskode[%] invoking as_create_or_import_organisation.',(organisation_registrering.registrering).livscykluskode USING ERRCODE='MO400';
END IF;


IF NOT does_exist THEN

    INSERT INTO
          organisation (ID)
    SELECT
          organisation_uuid;
END IF;


/*********************************/
--Insert new registrering

IF NOT does_exist THEN
    organisation_registrering_id:=nextval('organisation_registrering_id_seq');

    INSERT INTO organisation_registrering (
          id,
          organisation_id,
          registrering
        )
    SELECT
          organisation_registrering_id,
           organisation_uuid,
           ROW (
             TSTZRANGE(clock_timestamp(),'infinity'::TIMESTAMPTZ,'[)' ),
             (organisation_registrering.registrering).livscykluskode,
             (organisation_registrering.registrering).brugerref,
             (organisation_registrering.registrering).note
               ):: RegistreringBase ;
ELSE
    -- This is an update, not an import or create
        new_organisation_registrering := _as_create_organisation_registrering(
             organisation_uuid,
             (organisation_registrering.registrering).livscykluskode,
             (organisation_registrering.registrering).brugerref,
             (organisation_registrering.registrering).note);

        organisation_registrering_id := new_organisation_registrering.id;
END IF;


/*********************************/
--Insert attributes


/************/
--Verification
--For now all declared attributes are mandatory (the fields are all optional,though)

 
IF coalesce(array_length(organisation_registrering.attrEgenskaber, 1),0)<1 THEN
  RAISE EXCEPTION 'Savner påkraevet attribut [egenskaber] for [organisation]. Oprettelse afbrydes.' USING ERRCODE='MO400';
END IF;



IF organisation_registrering.attrEgenskaber IS NOT NULL and coalesce(array_length(organisation_registrering.attrEgenskaber,1),0)>0 THEN
  FOREACH organisation_attr_egenskaber_obj IN ARRAY organisation_registrering.attrEgenskaber
  LOOP

  
    INSERT INTO organisation_attr_egenskaber (
      
      brugervendtnoegle,
      organisationsnavn,
      virkning,
      organisation_registrering_id
    )
    SELECT
     
     organisation_attr_egenskaber_obj.brugervendtnoegle,
      organisation_attr_egenskaber_obj.organisationsnavn,
      organisation_attr_egenskaber_obj.virkning,
      organisation_registrering_id
    ;
  
    
  END LOOP;
END IF;

/*********************************/
--Insert states (tilstande)


--Verification
--For now all declared states are mandatory.
IF coalesce(array_length(organisation_registrering.tilsGyldighed, 1),0)<1  THEN
  RAISE EXCEPTION 'Savner påkraevet tilstand [gyldighed] for organisation. Oprettelse afbrydes.' USING ERRCODE='MO400';
END IF;

IF organisation_registrering.tilsGyldighed IS NOT NULL AND coalesce(array_length(organisation_registrering.tilsGyldighed,1),0)>0 THEN
  FOREACH organisation_tils_gyldighed_obj IN ARRAY organisation_registrering.tilsGyldighed
  LOOP

    INSERT INTO organisation_tils_gyldighed (
      virkning,
      gyldighed,
      organisation_registrering_id
    )
    SELECT
      organisation_tils_gyldighed_obj.virkning,
      organisation_tils_gyldighed_obj.gyldighed,
      organisation_registrering_id;

  END LOOP;
END IF;

/*********************************/
--Insert relations



    INSERT INTO organisation_relation (
      organisation_registrering_id,
      virkning,
      rel_maal_uuid,
      rel_maal_urn,
      rel_type,
      objekt_type
    )
    SELECT
      organisation_registrering_id,
      a.virkning,
      a.uuid,
      a.urn,
      a.relType,
      a.objektType
    FROM unnest(organisation_registrering.relationer) a
  ;




/*** Verify that the object meets the stipulated access allowed criteria  ***/
/*** NOTICE: We are doing this check *after* the insertion of data BUT *before* transaction commit, to reuse code / avoid fragmentation  ***/
auth_filtered_uuids:=_as_filter_unauth_organisation(array[organisation_uuid]::uuid[],auth_criteria_arr); 
IF NOT (coalesce(array_length(auth_filtered_uuids,1),0)=1 AND auth_filtered_uuids @>ARRAY[organisation_uuid]) THEN
  RAISE EXCEPTION 'Unable to create/import organisation with uuid [%]. Object does not met stipulated criteria:%',organisation_uuid,to_json(auth_criteria_arr)  USING ERRCODE = 'MO401'; 
END IF;
/*********************/


  PERFORM actual_state._amqp_publish_notification('Organisation', (organisation_registrering.registrering).livscykluskode, organisation_uuid);

RETURN organisation_uuid;

END;
$$ LANGUAGE plpgsql VOLATILE;


