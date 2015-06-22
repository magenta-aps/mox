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
  organisationfunktion_uuid uuid DEFAULT NULL
	)
  RETURNS uuid AS 
$$
DECLARE
  organisationfunktion_registrering_id bigint;
  organisationfunktion_attr_egenskaber_obj organisationfunktionEgenskaberAttrType;
  
  organisationfunktion_tils_gyldighed_obj organisationfunktionGyldighedTilsType;
  
  organisationfunktion_relationer OrganisationfunktionRelationType;

BEGIN

IF organisationfunktion_uuid IS NULL THEN
    LOOP
    organisationfunktion_uuid:=uuid_generate_v4();
    EXIT WHEN NOT EXISTS (SELECT id from organisationfunktion WHERE id=organisationfunktion_uuid); 
    END LOOP;
END IF;


IF EXISTS (SELECT id from organisationfunktion WHERE id=organisationfunktion_uuid) THEN
  RAISE EXCEPTION 'Error creating or importing organisationfunktion with uuid [%]. If you did not supply the uuid when invoking as_create_or_import_organisationfunktion (i.e. create operation) please try to repeat the invocation/operation, that id collison with randomly generated uuids might in theory occur, albeit very very very rarely.',organisationfunktion_uuid;
END IF;

IF  (organisationfunktion_registrering.registrering).livscykluskode<>'Opstaaet'::Livscykluskode and (organisationfunktion_registrering.registrering).livscykluskode<>'Importeret'::Livscykluskode THEN
  RAISE EXCEPTION 'Invalid livscykluskode[%] invoking as_create_or_import_organisationfunktion.',(organisationfunktion_registrering.registrering).livscykluskode;
END IF;



INSERT INTO 
      organisationfunktion (ID)
SELECT
      organisationfunktion_uuid
;


/*********************************/
--Insert new registrering

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
              ):: RegistreringBase
;

/*********************************/
--Insert attributes


/************/
--Verification
--For now all declared attributes are mandatory (the fields are all optional,though)

 
IF coalesce(array_length(organisationfunktion_registrering.attrEgenskaber, 1),0)<1 THEN
  RAISE EXCEPTION 'Savner påkraevet attribut [egenskaber] for [organisationfunktion]. Oprettelse afbrydes.';
END IF;



IF organisationfunktion_registrering.attrEgenskaber IS NOT NULL THEN
  FOREACH organisationfunktion_attr_egenskaber_obj IN ARRAY organisationfunktion_registrering.attrEgenskaber
  LOOP

  IF
  ( organisationfunktion_attr_egenskaber_obj.brugervendtnoegle IS NOT NULL AND organisationfunktion_attr_egenskaber_obj.brugervendtnoegle<>'') 
   OR 
  ( organisationfunktion_attr_egenskaber_obj.funktionsnavn IS NOT NULL AND organisationfunktion_attr_egenskaber_obj.funktionsnavn<>'') 
   THEN

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
  END IF;

  END LOOP;
END IF;

/*********************************/
--Insert states (tilstande)


--Verification
--For now all declared states are mandatory.
IF coalesce(array_length(organisationfunktion_registrering.tilsGyldighed, 1),0)<1  THEN
  RAISE EXCEPTION 'Savner påkraevet tilstand [gyldighed] for organisationfunktion. Oprettelse afbrydes.';
END IF;

IF organisationfunktion_registrering.tilsGyldighed IS NOT NULL THEN
  FOREACH organisationfunktion_tils_gyldighed_obj IN ARRAY organisationfunktion_registrering.tilsGyldighed
  LOOP

  IF organisationfunktion_tils_gyldighed_obj.gyldighed IS NOT NULL AND organisationfunktion_tils_gyldighed_obj.gyldighed<>''::OrganisationfunktionGyldighedTils THEN

    INSERT INTO organisationfunktion_tils_gyldighed (
      virkning,
      gyldighed,
      organisationfunktion_registrering_id
    )
    SELECT
      organisationfunktion_tils_gyldighed_obj.virkning,
      organisationfunktion_tils_gyldighed_obj.gyldighed,
      organisationfunktion_registrering_id;

  END IF;
  END LOOP;
END IF;

/*********************************/
--Insert relations

    INSERT INTO organisationfunktion_relation (
      organisationfunktion_registrering_id,
      virkning,
      rel_maal_uuid,
      rel_maal_urn,
      rel_type

    )
    SELECT
      organisationfunktion_registrering_id,
      a.virkning,
      a.relMaalUuid,
      a.relMaalUrn,
      a.relType
    FROM unnest(organisationfunktion_registrering.relationer) a
    WHERE (a.relMaalUuid IS NOT NULL OR (a.relMaalUrn IS NOT NULL AND a.relMaalUrn<>'') )
  ;


RETURN organisationfunktion_uuid;

END;
$$ LANGUAGE plpgsql VOLATILE;


