-- Copyright (C) 2015 Magenta ApS, http://magenta.dk.
-- Contact: info@magenta.dk.
--
-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at http://mozilla.org/MPL/2.0/.

CREATE OR REPLACE FUNCTION actual_state_create_or_import_facet(
  facet_registrering FacetRegistreringType,
  facet_uuid uuid DEFAULT uuid_generate_v4() --This might genenerate a non unique value. Use uuid_generate_v5(). Consider using uuid_generate_v5() and namespace(s). Consider generating using sequences which generates input to hash, with a namespace part and a id part.
	)
  RETURNS uuid AS 
$$
DECLARE
  facet_registrering_id bigint;
  facet_attr_egenskab FacetAttrEgenskaberType;
  facet_tils_publiceret FacetTilsPubliceretType;
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
            (facet_registrering.registrering).timeperiod,
            (facet_registrering.registrering).livscykluskode,
            (facet_registrering.registrering).brugerref,
            (facet_registrering.registrering).note
              ):: RegistreringBase
;

/*********************************/
--Insert attributes


/************/
--Verification
IF array_length(facet_registrering.attrEgenskaber, 1)<1 THEN
  RAISE EXCEPTION 'Savner påkraevet attribut [egenskaber] for [facet]. Oprettelse afbrydes.';
END IF;




FOREACH facet_attr_egenskab IN ARRAY facet_registrering.attrEgenskaber
LOOP

INSERT INTO facet_attr_egenskaber (
  brugervendt_noegle,
    facetbeskrivelse,
      facetplan,
        facetopbygning,
          facetophavsret,
            facetsupplement,
              retskilde,
                virkning,
                  facet_registrering_id
)
SELECT
  facet_attr_egenskab.brugervendt_noegle,
    facet_attr_egenskab.facetbeskrivelse,
      facet_attr_egenskab.facetplan,
        facet_attr_egenskab.facetopbygning,
          facet_attr_egenskab.facetophavsret,
            facet_attr_egenskab.facetsupplement,
              facet_attr_egenskab.retskilde,
                facet_attr_egenskab.virkning,
                   facet_registrering_id
;

END LOOP;

/*********************************/
--Insert states (tilstande)


--Verification
IF array_length(facet_registrering.tilsPubliceretStatus, 1)<1 THEN
  RAISE EXCEPTION 'Savner påkraevet tilstand [publiceretStatus] for facet. Oprettelse afbrydes.';
END IF;


FOREACH facet_tils_publiceret IN ARRAY facet_registrering.tilsPubliceretStatus
LOOP

INSERT INTO facet_tils_publiceret (
  virkning,
    status,
      facet_registrering_id
)
SELECT
  facet_tils_publiceret.virkning,
    facet_tils_publiceret.status,
      facet_registrering_id;

END LOOP;

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
            a.rel_type
    FROM unnest(facet_registrering.relationer) a
  ;


RETURN facet_uuid;

END;
$$ LANGUAGE plpgsql VOLATILE;


