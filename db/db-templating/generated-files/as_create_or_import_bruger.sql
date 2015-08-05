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
  bruger_uuid uuid DEFAULT NULL
	)
  RETURNS uuid AS 
$$
DECLARE
  bruger_registrering_id bigint;
  bruger_attr_egenskaber_obj brugerEgenskaberAttrType;
  
  bruger_tils_gyldighed_obj brugerGyldighedTilsType;
  
  bruger_relationer BrugerRelationType;

BEGIN

IF bruger_uuid IS NULL THEN
    LOOP
    bruger_uuid:=uuid_generate_v4();
    EXIT WHEN NOT EXISTS (SELECT id from bruger WHERE id=bruger_uuid); 
    END LOOP;
END IF;


IF EXISTS (SELECT id from bruger WHERE id=bruger_uuid) THEN
  RAISE EXCEPTION 'Error creating or importing bruger with uuid [%]. If you did not supply the uuid when invoking as_create_or_import_bruger (i.e. create operation) please try to repeat the invocation/operation, that id collison with randomly generated uuids might in theory occur, albeit very very very rarely.',bruger_uuid;
END IF;

IF  (bruger_registrering.registrering).livscykluskode<>'Opstaaet'::Livscykluskode and (bruger_registrering.registrering).livscykluskode<>'Importeret'::Livscykluskode THEN
  RAISE EXCEPTION 'Invalid livscykluskode[%] invoking as_create_or_import_bruger.',(bruger_registrering.registrering).livscykluskode;
END IF;



INSERT INTO 
      bruger (ID)
SELECT
      bruger_uuid
;


/*********************************/
--Insert new registrering

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
              ):: RegistreringBase
;

/*********************************/
--Insert attributes


/************/
--Verification
--For now all declared attributes are mandatory (the fields are all optional,though)

 
IF coalesce(array_length(bruger_registrering.attrEgenskaber, 1),0)<1 THEN
  RAISE EXCEPTION 'Savner påkraevet attribut [egenskaber] for [bruger]. Oprettelse afbrydes.';
END IF;



IF bruger_registrering.attrEgenskaber IS NOT NULL THEN
  FOREACH bruger_attr_egenskaber_obj IN ARRAY bruger_registrering.attrEgenskaber
  LOOP

  IF
  ( bruger_attr_egenskaber_obj.brugervendtnoegle IS NOT NULL AND bruger_attr_egenskaber_obj.brugervendtnoegle<>'') 
   OR 
  ( bruger_attr_egenskaber_obj.brugernavn IS NOT NULL AND bruger_attr_egenskaber_obj.brugernavn<>'') 
   OR 
  ( bruger_attr_egenskaber_obj.brugertype IS NOT NULL AND bruger_attr_egenskaber_obj.brugertype<>'') 
   THEN

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
  END IF;

  END LOOP;
END IF;

/*********************************/
--Insert states (tilstande)


--Verification
--For now all declared states are mandatory.
IF coalesce(array_length(bruger_registrering.tilsGyldighed, 1),0)<1  THEN
  RAISE EXCEPTION 'Savner påkraevet tilstand [gyldighed] for bruger. Oprettelse afbrydes.';
END IF;

IF bruger_registrering.tilsGyldighed IS NOT NULL THEN
  FOREACH bruger_tils_gyldighed_obj IN ARRAY bruger_registrering.tilsGyldighed
  LOOP

  IF bruger_tils_gyldighed_obj.gyldighed IS NOT NULL AND bruger_tils_gyldighed_obj.gyldighed<>''::BrugerGyldighedTils THEN

    INSERT INTO bruger_tils_gyldighed (
      virkning,
      gyldighed,
      bruger_registrering_id
    )
    SELECT
      bruger_tils_gyldighed_obj.virkning,
      bruger_tils_gyldighed_obj.gyldighed,
      bruger_registrering_id;

  END IF;
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
      a.relMaalUuid,
      a.relMaalUrn,
      a.relType,
      a.objektType
    FROM unnest(bruger_registrering.relationer) a
    WHERE (a.relMaalUuid IS NOT NULL OR (a.relMaalUrn IS NOT NULL AND a.relMaalUrn<>'') )
  ;

  PERFORM amqp.publish(1, 'mox.notifications', '', format('create %s', bruger_uuid));

RETURN bruger_uuid;

END;
$$ LANGUAGE plpgsql VOLATILE;


