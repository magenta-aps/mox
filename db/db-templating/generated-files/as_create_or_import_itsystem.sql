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
  itsystem_uuid uuid DEFAULT NULL
	)
  RETURNS uuid AS 
$$
DECLARE
  itsystem_registrering_id bigint;
  itsystem_attr_egenskaber_obj itsystemEgenskaberAttrType;
  
  itsystem_tils_gyldighed_obj itsystemGyldighedTilsType;
  
  itsystem_relationer ItsystemRelationType;

BEGIN

IF itsystem_uuid IS NULL THEN
    LOOP
    itsystem_uuid:=uuid_generate_v4();
    EXIT WHEN NOT EXISTS (SELECT id from itsystem WHERE id=itsystem_uuid); 
    END LOOP;
END IF;


IF EXISTS (SELECT id from itsystem WHERE id=itsystem_uuid) THEN
  RAISE EXCEPTION 'Error creating or importing itsystem with uuid [%]. If you did not supply the uuid when invoking as_create_or_import_itsystem (i.e. create operation) please try to repeat the invocation/operation, that id collison with randomly generated uuids might in theory occur, albeit very very very rarely.',itsystem_uuid;
END IF;

IF  (itsystem_registrering.registrering).livscykluskode<>'Opstaaet'::Livscykluskode and (itsystem_registrering.registrering).livscykluskode<>'Importeret'::Livscykluskode THEN
  RAISE EXCEPTION 'Invalid livscykluskode[%] invoking as_create_or_import_itsystem.',(itsystem_registrering.registrering).livscykluskode;
END IF;



INSERT INTO 
      itsystem (ID)
SELECT
      itsystem_uuid
;


/*********************************/
--Insert new registrering

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
              ):: RegistreringBase
;

/*********************************/
--Insert attributes


/************/
--Verification
--For now all declared attributes are mandatory (the fields are all optional,though)

 
IF coalesce(array_length(itsystem_registrering.attrEgenskaber, 1),0)<1 THEN
  RAISE EXCEPTION 'Savner påkraevet attribut [egenskaber] for [itsystem]. Oprettelse afbrydes.';
END IF;



IF itsystem_registrering.attrEgenskaber IS NOT NULL THEN
  FOREACH itsystem_attr_egenskaber_obj IN ARRAY itsystem_registrering.attrEgenskaber
  LOOP

  IF
  ( itsystem_attr_egenskaber_obj.brugervendtnoegle IS NOT NULL AND itsystem_attr_egenskaber_obj.brugervendtnoegle<>'') 
   OR 
  ( itsystem_attr_egenskaber_obj.itsystemnavn IS NOT NULL AND itsystem_attr_egenskaber_obj.itsystemnavn<>'') 
   OR 
  ( itsystem_attr_egenskaber_obj.itsystemtype IS NOT NULL AND itsystem_attr_egenskaber_obj.itsystemtype<>'') 
   OR 
  ( itsystem_attr_egenskaber_obj.konfigurationreference IS NOT NULL AND coalesce(array_length(itsystem_attr_egenskaber_obj.konfigurationreference,1),0)>0) 
   THEN

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
  END IF;

  END LOOP;
END IF;

/*********************************/
--Insert states (tilstande)


--Verification
--For now all declared states are mandatory.
IF coalesce(array_length(itsystem_registrering.tilsGyldighed, 1),0)<1  THEN
  RAISE EXCEPTION 'Savner påkraevet tilstand [gyldighed] for itsystem. Oprettelse afbrydes.';
END IF;

IF itsystem_registrering.tilsGyldighed IS NOT NULL THEN
  FOREACH itsystem_tils_gyldighed_obj IN ARRAY itsystem_registrering.tilsGyldighed
  LOOP

  IF itsystem_tils_gyldighed_obj.gyldighed IS NOT NULL AND itsystem_tils_gyldighed_obj.gyldighed<>''::ItsystemGyldighedTils THEN

    INSERT INTO itsystem_tils_gyldighed (
      virkning,
      gyldighed,
      itsystem_registrering_id
    )
    SELECT
      itsystem_tils_gyldighed_obj.virkning,
      itsystem_tils_gyldighed_obj.gyldighed,
      itsystem_registrering_id;

  END IF;
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
      a.relMaalUuid,
      a.relMaalUrn,
      a.relType,
      a.objektType
    FROM unnest(itsystem_registrering.relationer) a
    WHERE (a.relMaalUuid IS NOT NULL OR (a.relMaalUrn IS NOT NULL AND a.relMaalUrn<>'') )
  ;

  PERFORM actual_state._amqp_publish_notification('Itsystem', 'Opret', itsystem_uuid);

RETURN itsystem_uuid;

END;
$$ LANGUAGE plpgsql VOLATILE;


