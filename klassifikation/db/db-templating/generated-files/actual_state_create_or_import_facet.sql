-- Copyright (C) 2015 Magenta ApS, http://magenta.dk.
-- Contact: info@magenta.dk.
--
-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at http://mozilla.org/MPL/2.0/.

/*
NOTICE: This file is auto-generated using the script: apply-template.py facet actual_state_create_or_import.jinja.sql
*/

CREATE OR REPLACE FUNCTION actual_state_create_or_import_facet(
  facet_registrering FacetRegistreringType,
  facet_uuid uuid DEFAULT uuid_generate_v4() --This might genenerate a non unique value. Use uuid_generate_v5(). Consider using uuid_generate_v5() and namespace(s). Consider generating using sequences which generates input to hash, with a namespace part and a id part.
	)
  RETURNS uuid AS 
$$
DECLARE
  facet_registrering_id bigint;
  facet_attr_egenskaber_obj facetAttrEgenskaberType;
  
  facet_tils_publiceret_obj facetTilsPubliceretType;
  
  facet_relationer FacetRelationType;

BEGIN

IF EXISTS (SELECT id from facet WHERE id=facet_uuid) THEN
  RAISE EXCEPTION 'Error creating or importing facet with uuid [%]. If you did not supply the uuid when invoking actual_state_create_or_import_facet (i.e. create operation) please try to repeat the invocation/operation, that id collison with randomly generated uuids might occur, albeit very very rarely.',facet_uuid;
END IF;

IF  (facet_registrering.registrering).livscykluskode<>'Opstaaet'::Livscykluskode and (facet_registrering.registrering).livscykluskode<>'Importeret'::Livscykluskode THEN
  RAISE EXCEPTION 'Invalid livscykluskode[%] invoking actual_state_create_or_import_facet.',(facet_registrering.registrering).livscykluskode;
END IF;



INSERT INTO 
      facet (ID)
SELECT
      facet_uuid
;


/*********************************/
--Insert new registrering

facet_registrering_id:=nextval('facet_registrering_id_seq');

INSERT INTO facet_registrering (
      id,
        facet_id,
          registrering
        )
SELECT
      facet_registrering_id,
        facet_uuid,
          ROW (
            TSTZRANGE(clock_timestamp(),'infinity'::TIMESTAMPTZ,'[)' ),
            (facet_registrering.registrering).livscykluskode,
            (facet_registrering.registrering).brugerref,
            (facet_registrering.registrering).note
              ):: RegistreringBase
;

/*********************************/
--Insert attributes


/************/
--Verification
--For now all declared attributes are mandatory (the fields are all optional,though)

 
IF array_length(facet_registrering.attrEgenskaber, 1)<1 THEN
  RAISE EXCEPTION 'Savner påkraevet attribut [egenskaber] for [facet]. Oprettelse afbrydes.';
END IF;



IF facet_registrering.attrEgenskaber IS NOT NULL THEN
  FOREACH facet_attr_egenskaber_obj IN ARRAY facet_registrering.attrEgenskaber
  LOOP

  INSERT INTO facet_attr_egenskaber (
    brugervendtnoegle,
    beskrivelse,
    opbygning,
    ophavsret,
    plan,
    supplement,
    retskilde,
    virkning,
    facet_registrering_id
  )
  SELECT
   facet_attr_egenskaber_obj.brugervendtnoegle,
    facet_attr_egenskaber_obj.beskrivelse,
    facet_attr_egenskaber_obj.opbygning,
    facet_attr_egenskaber_obj.ophavsret,
    facet_attr_egenskaber_obj.plan,
    facet_attr_egenskaber_obj.supplement,
    facet_attr_egenskaber_obj.retskilde,
    facet_attr_egenskaber_obj.virkning,
    facet_registrering_id
  ;

  END LOOP;
END IF;

/*********************************/
--Insert states (tilstande)


--Verification
--For now all declared states are mandatory.
IF array_length(facet_registrering.tilsPubliceret, 1)<1 THEN
  RAISE EXCEPTION 'Savner påkraevet tilstand [publiceret] for facet. Oprettelse afbrydes.';
END IF;

IF facet_registrering.tilsPubliceret IS NOT NULL THEN
  FOREACH facet_tils_publiceret_obj IN ARRAY facet_registrering.tilsPubliceret
  LOOP

  INSERT INTO facet_tils_publiceret (
    virkning,
    publiceret,
    facet_registrering_id
  )
  SELECT
    facet_tils_publiceret_obj.virkning,
    facet_tils_publiceret_obj.publiceret,
    facet_registrering_id;

  END LOOP;
END IF;

/*********************************/
--Insert relations

    INSERT INTO facet_relation (
      facet_registrering_id,
      virkning,
      rel_maal,
      rel_type

    )
    SELECT
      facet_registrering_id,
      a.virkning,
      a.relMaal,
      a.relType
    FROM unnest(facet_registrering.relationer) a
  ;


RETURN facet_uuid;

END;
$$ LANGUAGE plpgsql VOLATILE;


