-- Copyright (C) 2015 Magenta ApS, http://magenta.dk.
-- Contact: info@magenta.dk.
--
-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at http://mozilla.org/MPL/2.0/.

/*
NOTICE: This file is auto-generated using the script: apply-template.py organisation as_create_or_import.jinja.sql
*/

CREATE OR REPLACE FUNCTION as_create_or_import_organisation(
  organisation_registrering OrganisationRegistreringType,
  organisation_uuid uuid DEFAULT NULL
	)
  RETURNS uuid AS 
$$
DECLARE
  organisation_registrering_id bigint;
  organisation_attr_egenskaber_obj organisationEgenskaberAttrType;
  
  organisation_tils_gyldighed_obj organisationGyldighedTilsType;
  
  organisation_relationer OrganisationRelationType;

BEGIN

IF organisation_uuid IS NULL THEN
    LOOP
    organisation_uuid:=uuid_generate_v4();
    EXIT WHEN NOT EXISTS (SELECT id from organisation WHERE id=organisation_uuid); 
    END LOOP;
END IF;


IF EXISTS (SELECT id from organisation WHERE id=organisation_uuid) THEN
  RAISE EXCEPTION 'Error creating or importing organisation with uuid [%]. If you did not supply the uuid when invoking as_create_or_import_organisation (i.e. create operation) please try to repeat the invocation/operation, that id collison with randomly generated uuids might in theory occur, albeit very very very rarely.',organisation_uuid;
END IF;

IF  (organisation_registrering.registrering).livscykluskode<>'Opstaaet'::Livscykluskode and (organisation_registrering.registrering).livscykluskode<>'Importeret'::Livscykluskode THEN
  RAISE EXCEPTION 'Invalid livscykluskode[%] invoking as_create_or_import_organisation.',(organisation_registrering.registrering).livscykluskode;
END IF;



INSERT INTO 
      organisation (ID)
SELECT
      organisation_uuid
;


/*********************************/
--Insert new registrering

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
              ):: RegistreringBase
;

/*********************************/
--Insert attributes


/************/
--Verification
--For now all declared attributes are mandatory (the fields are all optional,though)

 
IF coalesce(array_length(organisation_registrering.attrEgenskaber, 1),0)<1 THEN
  RAISE EXCEPTION 'Savner påkraevet attribut [egenskaber] for [organisation]. Oprettelse afbrydes.';
END IF;



IF organisation_registrering.attrEgenskaber IS NOT NULL THEN
  FOREACH organisation_attr_egenskaber_obj IN ARRAY organisation_registrering.attrEgenskaber
  LOOP

  IF
  ( organisation_attr_egenskaber_obj.brugervendtnoegle IS NOT NULL AND organisation_attr_egenskaber_obj.brugervendtnoegle<>'') 
   OR 
  ( organisation_attr_egenskaber_obj.organisationsnavn IS NOT NULL AND organisation_attr_egenskaber_obj.organisationsnavn<>'') 
   THEN

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
  END IF;

  END LOOP;
END IF;

/*********************************/
--Insert states (tilstande)


--Verification
--For now all declared states are mandatory.
IF coalesce(array_length(organisation_registrering.tilsGyldighed, 1),0)<1  THEN
  RAISE EXCEPTION 'Savner påkraevet tilstand [gyldighed] for organisation. Oprettelse afbrydes.';
END IF;

IF organisation_registrering.tilsGyldighed IS NOT NULL THEN
  FOREACH organisation_tils_gyldighed_obj IN ARRAY organisation_registrering.tilsGyldighed
  LOOP

  IF organisation_tils_gyldighed_obj.gyldighed IS NOT NULL AND organisation_tils_gyldighed_obj.gyldighed<>''::OrganisationGyldighedTils THEN

    INSERT INTO organisation_tils_gyldighed (
      virkning,
      gyldighed,
      organisation_registrering_id
    )
    SELECT
      organisation_tils_gyldighed_obj.virkning,
      organisation_tils_gyldighed_obj.gyldighed,
      organisation_registrering_id;

  END IF;
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
      a.relMaalUuid,
      a.relMaalUrn,
      a.relType,
      a.objektType
    FROM unnest(organisation_registrering.relationer) a
    WHERE (a.relMaalUuid IS NOT NULL OR (a.relMaalUrn IS NOT NULL AND a.relMaalUrn<>'') )
  ;

  PERFORM actual_state._amqp_publish_notification('Organisation', (organisation_registrering.registrering).livscykluskode, organisation_uuid);

RETURN organisation_uuid;

END;
$$ LANGUAGE plpgsql VOLATILE;


