
-- Copyright (C) 2015 Magenta ApS, http://magenta.dk.
-- Contact: info@magenta.dk.
--
-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at http://mozilla.org/MPL/2.0/.


--Please notice that is it the responsibility of the invoker of this function to compare the resulting facet_registration (including the entire hierarchy)
--to the previous one, and abort the transaction if the two registrations are identical. (This is to comply with the stipulated behavior in 'Specifikation_af_generelle_egenskaber - til OIOkomiteen.pdf')



CREATE OR REPLACE FUNCTION actual_state_update_facet(
  facet_uuid uuid,
  brugerref uuid,
  note text,
  livscykluskode Livscykluskode,          
  attrEgenskaber FacetAttrEgenskaberType[],
  tilsPubliceretStatus FacetTilsPubliceretType[],
  relAnsvarlig FacetRelAnsvarligType[],
  relEjer FacetRelEjerType[],
  relFacettilhoer FacetRelFacettilhoerType[],
  relRedaktoerer FacetRelRedaktoererType[]
	)
  RETURNS uuid AS --TODO
$$
DECLARE
  new_facet_registrering facet_registrering;
  prev_facet_registrering facet_registrering;
  facet_rel_ansvarlig FacetRelAnsvarligType;
BEGIN

--create a new registrering

new_facet_registrering := _actual_state_create_facet_registrering(facet_uuid,livscykluskode, brugerref, note);
prev_facet_registrering := _actual_state_get_prev_facet_registrering(new_facet_registrering);

--handle relationer (relations)

-- 0..1 relations 

--ansvarlig

--1) Insert relations given as part of this update
--2) Merge relations of previous relations, taking overlapping virknings into consideration (using function subtract_tstzrange)

--Ad 1)

  FOREACH facet_rel_ansvarlig IN ARRAY relAnsvarlig
  LOOP

    INSERT INTO facet_rel_ansvarlig (
      facet_registrering_id,
       virkning,
        rel_maal
    )
    SELECT
      new_facet_registrering.id,
        facet_rel_ansvarlig.virkning,
          facet_rel_ansvarlig.relMaal
  ;

  END LOOP;


--Ad 2)

  INSERT INTO facet_rel_ansvarlig (
      facet_registrering_id,
        virkning,
          rel_maal
    )
  SELECT 
      new_facet_registrering.id, 
        ROW(
          c.tz_range_leftover,
          (a.virkning).AktoerRef,
          (a.virkning).AktoerTypeKode,
          (a.virkning).NoteTekst
          ) :: virkning,
          a.rel_maal
  FROM
  (
    --build an array of the timeperiod of the virkning of the relations of the new registrering to pass to subtract_tstzrange_arr on the relations of the previous registrering 
    SELECT coalesce(array_agg((b.virkning).TimePeriod),array[]::TSTZRANGE[]) tzranges_of_new_reg
    FROM facet_rel_ansvarlig b
    WHERE b.facet_registrering_id=new_facet_registrering.id
  ) d
  JOIN facet_rel_ansvarlig a ON true
  JOIN unnest(subtract_tstzrange_arr((a.virkning).TimePeriod,tzranges_of_new_reg)) as c(tz_range_leftover) on true
  WHERE a.facet_registrering_id=prev_facet_registrering.id 
  ;

--TODO: Do the other relations


--TODO: handle tilstande (states)

--TODO: handle attributter (attributes)











END;
$$ LANGUAGE plpgsql VOLATILE;