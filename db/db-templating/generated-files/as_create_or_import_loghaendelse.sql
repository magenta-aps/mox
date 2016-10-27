-- Copyright (C) 2015 Magenta ApS, http://magenta.dk.
-- Contact: info@magenta.dk.
--
-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at http://mozilla.org/MPL/2.0/.

/*
NOTICE: This file is auto-generated using the script: apply-template.py loghaendelse as_create_or_import.jinja.sql
*/

CREATE OR REPLACE FUNCTION as_create_or_import_loghaendelse(
  loghaendelse_registrering LoghaendelseRegistreringType,
  loghaendelse_uuid uuid DEFAULT NULL,
  auth_criteria_arr LoghaendelseRegistreringType[] DEFAULT NULL
	)
  RETURNS uuid AS 
$$
DECLARE
  loghaendelse_registrering_id bigint;
  loghaendelse_attr_egenskaber_obj loghaendelseEgenskaberAttrType;
  
  loghaendelse_tils_gyldighed_obj loghaendelseGyldighedTilsType;
  
  loghaendelse_relationer LoghaendelseRelationType;
  auth_filtered_uuids uuid[];
BEGIN

IF loghaendelse_uuid IS NULL THEN
    LOOP
    loghaendelse_uuid:=uuid_generate_v4();
    EXIT WHEN NOT EXISTS (SELECT id from loghaendelse WHERE id=loghaendelse_uuid); 
    END LOOP;
END IF;


IF EXISTS (SELECT id from loghaendelse WHERE id=loghaendelse_uuid) THEN
  RAISE EXCEPTION 'Error creating or importing loghaendelse with uuid [%]. If you did not supply the uuid when invoking as_create_or_import_loghaendelse (i.e. create operation) please try to repeat the invocation/operation, that id collison with randomly generated uuids might in theory occur, albeit very very very rarely.',loghaendelse_uuid USING ERRCODE='MO500';
END IF;

IF  (loghaendelse_registrering.registrering).livscykluskode<>'Opstaaet'::Livscykluskode and (loghaendelse_registrering.registrering).livscykluskode<>'Importeret'::Livscykluskode THEN
  RAISE EXCEPTION 'Invalid livscykluskode[%] invoking as_create_or_import_loghaendelse.',(loghaendelse_registrering.registrering).livscykluskode USING ERRCODE='MO400';
END IF;



INSERT INTO 
      loghaendelse (ID)
SELECT
      loghaendelse_uuid
;


/*********************************/
--Insert new registrering

loghaendelse_registrering_id:=nextval('loghaendelse_registrering_id_seq');

INSERT INTO loghaendelse_registrering (
      id,
        loghaendelse_id,
          registrering
        )
SELECT
      loghaendelse_registrering_id,
        loghaendelse_uuid,
          ROW (
            TSTZRANGE(clock_timestamp(),'infinity'::TIMESTAMPTZ,'[)' ),
            (loghaendelse_registrering.registrering).livscykluskode,
            (loghaendelse_registrering.registrering).brugerref,
            (loghaendelse_registrering.registrering).note
              ):: RegistreringBase
;

/*********************************/
--Insert attributes


/************/
--Verification
--For now all declared attributes are mandatory (the fields are all optional,though)

 
IF coalesce(array_length(loghaendelse_registrering.attrEgenskaber, 1),0)<1 THEN
  RAISE EXCEPTION 'Savner påkraevet attribut [egenskaber] for [loghaendelse]. Oprettelse afbrydes.' USING ERRCODE='MO400';
END IF;



IF loghaendelse_registrering.attrEgenskaber IS NOT NULL and coalesce(array_length(loghaendelse_registrering.attrEgenskaber,1),0)>0 THEN
  FOREACH loghaendelse_attr_egenskaber_obj IN ARRAY loghaendelse_registrering.attrEgenskaber
  LOOP

    INSERT INTO loghaendelse_attr_egenskaber (
      service,
      klasse,
      tidspunkt,
      operation,
      objekttype,
      returkode,
      returtekst,
      note,
      virkning,
      loghaendelse_registrering_id
    )
    SELECT
     loghaendelse_attr_egenskaber_obj.service,
      loghaendelse_attr_egenskaber_obj.klasse,
      loghaendelse_attr_egenskaber_obj.tidspunkt,
      loghaendelse_attr_egenskaber_obj.operation,
      loghaendelse_attr_egenskaber_obj.objekttype,
      loghaendelse_attr_egenskaber_obj.returkode,
      loghaendelse_attr_egenskaber_obj.returtekst,
      loghaendelse_attr_egenskaber_obj.note,
      loghaendelse_attr_egenskaber_obj.virkning,
      loghaendelse_registrering_id
    ;
 

  END LOOP;
END IF;

/*********************************/
--Insert states (tilstande)


--Verification
--For now all declared states are mandatory.
IF coalesce(array_length(loghaendelse_registrering.tilsGyldighed, 1),0)<1  THEN
  RAISE EXCEPTION 'Savner påkraevet tilstand [gyldighed] for loghaendelse. Oprettelse afbrydes.' USING ERRCODE='MO400';
END IF;

IF loghaendelse_registrering.tilsGyldighed IS NOT NULL AND coalesce(array_length(loghaendelse_registrering.tilsGyldighed,1),0)>0 THEN
  FOREACH loghaendelse_tils_gyldighed_obj IN ARRAY loghaendelse_registrering.tilsGyldighed
  LOOP

    INSERT INTO loghaendelse_tils_gyldighed (
      virkning,
      gyldighed,
      loghaendelse_registrering_id
    )
    SELECT
      loghaendelse_tils_gyldighed_obj.virkning,
      loghaendelse_tils_gyldighed_obj.gyldighed,
      loghaendelse_registrering_id;

  END LOOP;
END IF;

/*********************************/
--Insert relations

    INSERT INTO loghaendelse_relation (
      loghaendelse_registrering_id,
      virkning,
      rel_maal_uuid,
      rel_maal_urn,
      rel_type,
      objekt_type
    )
    SELECT
      loghaendelse_registrering_id,
      a.virkning,
      a.uuid,
      a.urn,
      a.relType,
      a.objektType
    FROM unnest(loghaendelse_registrering.relationer) a
  ;


/*** Verify that the object meets the stipulated access allowed criteria  ***/
/*** NOTICE: We are doing this check *after* the insertion of data BUT *before* transaction commit, to reuse code / avoid fragmentation  ***/
auth_filtered_uuids:=_as_filter_unauth_loghaendelse(array[loghaendelse_uuid]::uuid[],auth_criteria_arr); 
IF NOT (coalesce(array_length(auth_filtered_uuids,1),0)=1 AND auth_filtered_uuids @>ARRAY[loghaendelse_uuid]) THEN
  RAISE EXCEPTION 'Unable to create/import loghaendelse with uuid [%]. Object does not met stipulated criteria:%',loghaendelse_uuid,to_json(auth_criteria_arr)  USING ERRCODE = 'MO401'; 
END IF;
/*********************/


  PERFORM actual_state._amqp_publish_notification('Loghaendelse', (loghaendelse_registrering.registrering).livscykluskode, loghaendelse_uuid);

RETURN loghaendelse_uuid;

END;
$$ LANGUAGE plpgsql VOLATILE;


