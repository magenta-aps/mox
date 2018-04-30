-- Copyright (C) 2015 Magenta ApS, http://magenta.dk.
-- Contact: info@magenta.dk.
--
-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at http://mozilla.org/MPL/2.0/.

/*
NOTICE: This file is auto-generated using the script: apply-template.py organisationenhed as_create_or_import.jinja.sql
*/

CREATE OR REPLACE FUNCTION as_create_or_import_organisationenhed(
  organisationenhed_registrering OrganisationenhedRegistreringType,
  organisationenhed_uuid uuid DEFAULT NULL,
  auth_criteria_arr OrganisationenhedRegistreringType[] DEFAULT NULL
	)
  RETURNS uuid AS 
$$
DECLARE
  organisationenhed_registrering_id bigint;
  organisationenhed_attr_egenskaber_obj organisationenhedEgenskaberAttrType;
  
  organisationenhed_tils_gyldighed_obj organisationenhedGyldighedTilsType;
  
  organisationenhed_relationer OrganisationenhedRelationType;
  auth_filtered_uuids uuid[];
  does_exist boolean;
  new_organisationenhed_registrering organisationenhed_registrering;
BEGIN

IF organisationenhed_uuid IS NULL THEN
    LOOP
    organisationenhed_uuid:=uuid_generate_v4();
    EXIT WHEN NOT EXISTS (SELECT id from organisationenhed WHERE id=organisationenhed_uuid); 
    END LOOP;
END IF;


IF EXISTS (SELECT id from organisationenhed WHERE id=organisationenhed_uuid) THEN
    does_exist = True;
ELSE

    does_exist = False;
END IF;

IF  (organisationenhed_registrering.registrering).livscykluskode<>'Opstaaet'::Livscykluskode and (organisationenhed_registrering.registrering).livscykluskode<>'Importeret'::Livscykluskode  and (organisationenhed_registrering.registrering).livscykluskode<>'Rettet'::Livscykluskode THEN
  RAISE EXCEPTION 'Invalid livscykluskode[%] invoking as_create_or_import_organisationenhed.',(organisationenhed_registrering.registrering).livscykluskode USING ERRCODE='MO400';
END IF;


IF NOT does_exist THEN

    INSERT INTO
          organisationenhed (ID)
    SELECT
          organisationenhed_uuid;
END IF;


/*********************************/
--Insert new registrering

IF NOT does_exist THEN
    organisationenhed_registrering_id:=nextval('organisationenhed_registrering_id_seq');

    INSERT INTO organisationenhed_registrering (
          id,
          organisationenhed_id,
          registrering
        )
    SELECT
          organisationenhed_registrering_id,
           organisationenhed_uuid,
           ROW (
             TSTZRANGE(clock_timestamp(),'infinity'::TIMESTAMPTZ,'[)' ),
             (organisationenhed_registrering.registrering).livscykluskode,
             (organisationenhed_registrering.registrering).brugerref,
             (organisationenhed_registrering.registrering).note
               ):: RegistreringBase ;
ELSE
    -- This is an update, not an import or create
        new_organisationenhed_registrering := _as_create_organisationenhed_registrering(
             organisationenhed_uuid,
             (organisationenhed_registrering.registrering).livscykluskode,
             (organisationenhed_registrering.registrering).brugerref,
             (organisationenhed_registrering.registrering).note);

        organisationenhed_registrering_id := new_organisationenhed_registrering.id;
END IF;


/*********************************/
--Insert attributes


/************/
--Verification
--For now all declared attributes are mandatory (the fields are all optional,though)

 
IF coalesce(array_length(organisationenhed_registrering.attrEgenskaber, 1),0)<1 THEN
  RAISE EXCEPTION 'Savner påkraevet attribut [egenskaber] for [organisationenhed]. Oprettelse afbrydes.' USING ERRCODE='MO400';
END IF;



IF organisationenhed_registrering.attrEgenskaber IS NOT NULL and coalesce(array_length(organisationenhed_registrering.attrEgenskaber,1),0)>0 THEN
  FOREACH organisationenhed_attr_egenskaber_obj IN ARRAY organisationenhed_registrering.attrEgenskaber
  LOOP

    INSERT INTO organisationenhed_attr_egenskaber (
      brugervendtnoegle,
      enhedsnavn,
      virkning,
      organisationenhed_registrering_id
    )
    SELECT
     organisationenhed_attr_egenskaber_obj.brugervendtnoegle,
      organisationenhed_attr_egenskaber_obj.enhedsnavn,
      organisationenhed_attr_egenskaber_obj.virkning,
      organisationenhed_registrering_id
    ;
 

  END LOOP;
END IF;

/*********************************/
--Insert states (tilstande)


--Verification
--For now all declared states are mandatory.
IF coalesce(array_length(organisationenhed_registrering.tilsGyldighed, 1),0)<1  THEN
  RAISE EXCEPTION 'Savner påkraevet tilstand [gyldighed] for organisationenhed. Oprettelse afbrydes.' USING ERRCODE='MO400';
END IF;

IF organisationenhed_registrering.tilsGyldighed IS NOT NULL AND coalesce(array_length(organisationenhed_registrering.tilsGyldighed,1),0)>0 THEN
  FOREACH organisationenhed_tils_gyldighed_obj IN ARRAY organisationenhed_registrering.tilsGyldighed
  LOOP

    INSERT INTO organisationenhed_tils_gyldighed (
      virkning,
      gyldighed,
      organisationenhed_registrering_id
    )
    SELECT
      organisationenhed_tils_gyldighed_obj.virkning,
      organisationenhed_tils_gyldighed_obj.gyldighed,
      organisationenhed_registrering_id;

  END LOOP;
END IF;

/*********************************/
--Insert relations

    INSERT INTO organisationenhed_relation (
      organisationenhed_registrering_id,
      virkning,
      rel_maal_uuid,
      rel_maal_urn,
      rel_type,
      objekt_type
    )
    SELECT
      organisationenhed_registrering_id,
      a.virkning,
      a.uuid,
      a.urn,
      a.relType,
      a.objektType
    FROM unnest(organisationenhed_registrering.relationer) a
  ;


/*** Verify that the object meets the stipulated access allowed criteria  ***/
/*** NOTICE: We are doing this check *after* the insertion of data BUT *before* transaction commit, to reuse code / avoid fragmentation  ***/
auth_filtered_uuids:=_as_filter_unauth_organisationenhed(array[organisationenhed_uuid]::uuid[],auth_criteria_arr); 
IF NOT (coalesce(array_length(auth_filtered_uuids,1),0)=1 AND auth_filtered_uuids @>ARRAY[organisationenhed_uuid]) THEN
  RAISE EXCEPTION 'Unable to create/import organisationenhed with uuid [%]. Object does not met stipulated criteria:%',organisationenhed_uuid,to_json(auth_criteria_arr)  USING ERRCODE = 'MO401'; 
END IF;
/*********************/


  PERFORM actual_state._amqp_publish_notification('Organisationenhed', (organisationenhed_registrering.registrering).livscykluskode, organisationenhed_uuid);

RETURN organisationenhed_uuid;

END;
$$ LANGUAGE plpgsql VOLATILE;


