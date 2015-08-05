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
  organisationenhed_uuid uuid DEFAULT NULL
	)
  RETURNS uuid AS 
$$
DECLARE
  organisationenhed_registrering_id bigint;
  organisationenhed_attr_egenskaber_obj organisationenhedEgenskaberAttrType;
  
  organisationenhed_tils_gyldighed_obj organisationenhedGyldighedTilsType;
  
  organisationenhed_relationer OrganisationenhedRelationType;

BEGIN

IF organisationenhed_uuid IS NULL THEN
    LOOP
    organisationenhed_uuid:=uuid_generate_v4();
    EXIT WHEN NOT EXISTS (SELECT id from organisationenhed WHERE id=organisationenhed_uuid); 
    END LOOP;
END IF;


IF EXISTS (SELECT id from organisationenhed WHERE id=organisationenhed_uuid) THEN
  RAISE EXCEPTION 'Error creating or importing organisationenhed with uuid [%]. If you did not supply the uuid when invoking as_create_or_import_organisationenhed (i.e. create operation) please try to repeat the invocation/operation, that id collison with randomly generated uuids might in theory occur, albeit very very very rarely.',organisationenhed_uuid;
END IF;

IF  (organisationenhed_registrering.registrering).livscykluskode<>'Opstaaet'::Livscykluskode and (organisationenhed_registrering.registrering).livscykluskode<>'Importeret'::Livscykluskode THEN
  RAISE EXCEPTION 'Invalid livscykluskode[%] invoking as_create_or_import_organisationenhed.',(organisationenhed_registrering.registrering).livscykluskode;
END IF;



INSERT INTO 
      organisationenhed (ID)
SELECT
      organisationenhed_uuid
;


/*********************************/
--Insert new registrering

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
              ):: RegistreringBase
;

/*********************************/
--Insert attributes


/************/
--Verification
--For now all declared attributes are mandatory (the fields are all optional,though)

 
IF coalesce(array_length(organisationenhed_registrering.attrEgenskaber, 1),0)<1 THEN
  RAISE EXCEPTION 'Savner påkraevet attribut [egenskaber] for [organisationenhed]. Oprettelse afbrydes.';
END IF;



IF organisationenhed_registrering.attrEgenskaber IS NOT NULL THEN
  FOREACH organisationenhed_attr_egenskaber_obj IN ARRAY organisationenhed_registrering.attrEgenskaber
  LOOP

  IF
  ( organisationenhed_attr_egenskaber_obj.brugervendtnoegle IS NOT NULL AND organisationenhed_attr_egenskaber_obj.brugervendtnoegle<>'') 
   OR 
  ( organisationenhed_attr_egenskaber_obj.enhedsnavn IS NOT NULL AND organisationenhed_attr_egenskaber_obj.enhedsnavn<>'') 
   THEN

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
  END IF;

  END LOOP;
END IF;

/*********************************/
--Insert states (tilstande)


--Verification
--For now all declared states are mandatory.
IF coalesce(array_length(organisationenhed_registrering.tilsGyldighed, 1),0)<1  THEN
  RAISE EXCEPTION 'Savner påkraevet tilstand [gyldighed] for organisationenhed. Oprettelse afbrydes.';
END IF;

IF organisationenhed_registrering.tilsGyldighed IS NOT NULL THEN
  FOREACH organisationenhed_tils_gyldighed_obj IN ARRAY organisationenhed_registrering.tilsGyldighed
  LOOP

  IF organisationenhed_tils_gyldighed_obj.gyldighed IS NOT NULL AND organisationenhed_tils_gyldighed_obj.gyldighed<>''::OrganisationenhedGyldighedTils THEN

    INSERT INTO organisationenhed_tils_gyldighed (
      virkning,
      gyldighed,
      organisationenhed_registrering_id
    )
    SELECT
      organisationenhed_tils_gyldighed_obj.virkning,
      organisationenhed_tils_gyldighed_obj.gyldighed,
      organisationenhed_registrering_id;

  END IF;
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
      a.relMaalUuid,
      a.relMaalUrn,
      a.relType,
      a.objektType
    FROM unnest(organisationenhed_registrering.relationer) a
    WHERE (a.relMaalUuid IS NOT NULL OR (a.relMaalUrn IS NOT NULL AND a.relMaalUrn<>'') )
  ;

  PERFORM amqp.publish(1, 'mox.notifications', '', format('create %s', organisationenhed_uuid));

RETURN organisationenhed_uuid;

END;
$$ LANGUAGE plpgsql VOLATILE;


