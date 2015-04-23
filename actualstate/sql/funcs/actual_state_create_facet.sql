-- Copyright (C) 2015 Magenta ApS, http://magenta.dk.
-- Contact: info@magenta.dk.
--
-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at http://mozilla.org/MPL/2.0/.

CREATE OR REPLACE FUNCTION actual_state_create_facet(
  registrering FacetRegistreringType
	)
  RETURNS uuid AS 
$$
DECLARE
  facet_uuid  uuid;
  facet_registrering_id bigint;
  facet_egenskab FacetEgenskaberType;
  facet_publiceret FacetPubliceretType;
  facet_relation_liste FacetRelationListeType;
  facet_relation_liste_id bigint;
  facet_relation FacetRelationerType;
BEGIN

--This might genenerate a non unique value. Use uuid_generate_v5() (see comment below)
facet_uuid := uuid_generate_v4(); --TODO Consider using uuid_generate_v5() and namespace(s). Consider generating using sequences which generates input to hash, with a namespace part and a id part


INSERT INTO 
      facet (ID)
SELECT
      facet_uuid
;

facet_registrering_id:=nextval('facet_registrering_id_seq');

INSERT INTO facet_registrering (
        id,
          facet_id,
            registrering
        )
SELECT
      facet_registrering_id,
        facet_uuid,
          registrering.registrering 
;


FOREACH facet_egenskab IN ARRAY registrering.egenskaber
LOOP

INSERT INTO facet_egenskaber (
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
  facet_egenskab.brugervendt_noegle,
    facet_egenskab.facetbeskrivelse,
      facet_egenskab.facetplan,
        facet_egenskab.facetopbygning,
          facet_egenskab.facetophavsret,
            facet_egenskab.facetsupplement,
              facet_egenskab.retskilde,
                facet_egenskab.virkning,
                   facet_registrering_id
;

END LOOP;

FOREACH facet_publiceret IN ARRAY registrering.publiceretStatuser
LOOP

INSERT INTO facet_publiceret (
  virkning,
    publiceret_status,
      facet_registrering_id
)
SELECT
  facet_publiceret.virkning,
    facet_publiceret.publiceret_status,
      facet_registrering_id;

END LOOP;


FOREACH facet_relation_liste IN ARRAY registrering.relationLister
LOOP

  facet_relation_liste_id:=nextval('facet_relation_liste_id_seq');

  INSERT INTO facet_relation_liste (
    id,
      facet_registrering_id,
        virkning
  ) 
  SELECT 
    facet_relation_liste_id,
      facet_registrering_id,
       facet_relation_liste.virkning
  ;

  FOREACH facet_relation IN ARRAY facet_relation_liste.relationer
  LOOP

    INSERT INTO facet_relationer (
    rel_type,
      rel_maal,
        facet_relation_liste_id
    )
    SELECT
      facet_relation.relType,
        facet_relation.relMaal,
          facet_relation_liste_id
  ;

  END LOOP;

END LOOP;


RETURN facet_uuid;

END;
$$ LANGUAGE plpgsql VOLATILE;


