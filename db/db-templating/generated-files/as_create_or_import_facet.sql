-- Copyright (C) 2015 Magenta ApS, http://magenta.dk.
-- Contact: info@magenta.dk.
--
-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at http://mozilla.org/MPL/2.0/.

/*
NOTICE: This file is auto-generated using the script: apply-template.py facet as_create_or_import.jinja.sql
*/

CREATE OR REPLACE FUNCTION as_create_or_import_facet(
  facet_registrering FacetRegistreringType,
  facet_uuid uuid DEFAULT NULL,
  auth_criteria_arr FacetRegistreringType[] DEFAULT NULL
	)
  RETURNS uuid AS 
$$
DECLARE
  facet_registrering_id bigint;
  facet_attr_egenskaber_obj facetEgenskaberAttrType;
  
  facet_tils_publiceret_obj facetPubliceretTilsType;
  
  facet_relationer FacetRelationType;
  auth_filtered_uuids uuid[];
BEGIN

IF facet_uuid IS NULL THEN
    LOOP
    facet_uuid:=uuid_generate_v4();
    EXIT WHEN NOT EXISTS (SELECT id from facet WHERE id=facet_uuid); 
    END LOOP;
END IF;


IF EXISTS (SELECT id from facet WHERE id=facet_uuid) THEN
  RAISE EXCEPTION 'Error creating or importing facet with uuid [%]. If you did not supply the uuid when invoking as_create_or_import_facet (i.e. create operation) please try to repeat the invocation/operation, that id collison with randomly generated uuids might in theory occur, albeit very very very rarely.',facet_uuid USING ERRCODE='MO500';
END IF;

IF  (facet_registrering.registrering).livscykluskode<>'Opstaaet'::Livscykluskode and (facet_registrering.registrering).livscykluskode<>'Importeret'::Livscykluskode THEN
  RAISE EXCEPTION 'Invalid livscykluskode[%] invoking as_create_or_import_facet.',(facet_registrering.registrering).livscykluskode USING ERRCODE='MO400';
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

 
IF coalesce(array_length(facet_registrering.attrEgenskaber, 1),0)<1 THEN
  RAISE EXCEPTION 'Savner påkraevet attribut [egenskaber] for [facet]. Oprettelse afbrydes.' USING ERRCODE='MO400';
END IF;



IF facet_registrering.attrEgenskaber IS NOT NULL and coalesce(array_length(facet_registrering.attrEgenskaber,1),0)>0 THEN
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
IF coalesce(array_length(facet_registrering.tilsPubliceret, 1),0)<1  THEN
  RAISE EXCEPTION 'Savner påkraevet tilstand [publiceret] for facet. Oprettelse afbrydes.' USING ERRCODE='MO400';
END IF;

IF facet_registrering.tilsPubliceret IS NOT NULL AND coalesce(array_length(facet_registrering.tilsPubliceret,1),0)>0 THEN
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
      rel_maal_uuid,
      rel_maal_urn,
      rel_type,
      objekt_type
    )
    SELECT
      facet_registrering_id,
      a.virkning,
      a.uuid,
      a.urn,
      a.relType,
      a.objektType
    FROM unnest(facet_registrering.relationer) a
  ;


/*** Verify that the object meets the stipulated access allowed criteria  ***/
/*** NOTICE: We are doing this check *after* the insertion of data BUT *before* transaction commit, to reuse code / avoid fragmentation  ***/
auth_filtered_uuids:=_as_filter_unauth_facet(array[facet_uuid]::uuid[],auth_criteria_arr); 
IF NOT (coalesce(array_length(auth_filtered_uuids,1),0)=1 AND auth_filtered_uuids @>ARRAY[facet_uuid]) THEN
  RAISE EXCEPTION 'Unable to create/import facet with uuid [%]. Object does not met stipulated criteria:%',facet_uuid,to_json(auth_criteria_arr)  USING ERRCODE = 'MO401'; 
END IF;
/*********************/


  PERFORM actual_state._amqp_publish_notification('Facet', (facet_registrering.registrering).livscykluskode, facet_uuid);

RETURN facet_uuid;

END;
$$ LANGUAGE plpgsql VOLATILE;


