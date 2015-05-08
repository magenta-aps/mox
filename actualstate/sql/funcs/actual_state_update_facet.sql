
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
  relationer FacetRelationType[]
	)
  RETURNS bigint AS --TODO
$$
DECLARE
  new_facet_registrering facet_registrering;
  prev_facet_registrering facet_registrering;
  facet_relation_obj FacetRelationType;
  facet_relation_navn text;
BEGIN

--create a new registrering

new_facet_registrering := _actual_state_create_facet_registrering(facet_uuid,livscykluskode, brugerref, note);
prev_facet_registrering := _actual_state_get_prev_facet_registrering(new_facet_registrering);

--handle relationer (relations)


--1) Insert relations given as part of this update
--2) Insert relations of previous registration, taking overlapping virknings into consideration (using function subtract_tstzrange)

--Ad 1)

    INSERT INTO facet_relation (
      facet_registrering_id,
        virkning,
          rel_maal,
            rel_type
    )
    SELECT
      new_facet_registrering.id,
        a.facet_relation_obj.virkning,
          a.facet_relation_obj.relMaal,
            a.facet_relation_obj.relation_navn
    FROM unnest(relationer) as a(facet_relation_obj) 
  ;


--Ad 2)

/**********************/
-- 0..1 relations 

FOREACH facet_relation_navn in array ARRAY['Ejer'::FacetRelationKode, 'Ansvarlig'::FacetRelationKode,'Facettilhoer'::FacetRelationKode]
LOOP

  INSERT INTO facet_relation (
      facet_registrering_id,
        virkning,
          rel_maal,
            rel_type
    )
  SELECT 
      new_facet_registrering.id, 
        ROW(
          c.tz_range_leftover,
            (a.virkning).AktoerRef,
            (a.virkning).AktoerTypeKode,
            (a.virkning).NoteTekst
        ) :: virkning,
          a.rel_maal,
            a.rel_type
  FROM
  (
    --build an array of the timeperiod of the virkning of the relations of the new registrering to pass to subtract_tstzrange_arr on the relations of the previous registrering 
    SELECT coalesce(array_agg((b.virkning).TimePeriod),array[]::TSTZRANGE[]) tzranges_of_new_reg
    FROM facet_relation b
    WHERE 
          b.facet_registrering_id=new_facet_registrering.id
          and
          b.rel_type=facet_relation_navn
  ) d
  JOIN facet_relation a ON true
  JOIN unnest(subtract_tstzrange_arr((a.virkning).TimePeriod,tzranges_of_new_reg)) as c(tz_range_leftover) on true
  WHERE a.facet_registrering_id=prev_facet_registrering.id 
        and a.rel_type=facet_relation_navn 
  ;
END LOOP;

/**********************/
-- 0..n relations

--The question regarding how the api-consumer is to specify the deletion of 0..n relation already registered is not answered.
--The following options presents itself:
--a) In this special case, the api-consumer has to specify the full set of the 0..n relation, when updating 
-- ref: ("Hvis indholdet i en liste af elementer rettes, skal hele den nye liste af elementer med i ObjektRet - p27 "Generelle egenskaber for serviceinterfaces på sags- og dokumentområdet")

--Assuming option 'a' above is selected, we only have to check if there are any of the relations with the given name present in the new registration, otherwise copy the ones from the previous registration


FOREACH facet_relation_navn in array ARRAY['Redaktoer'::FacetRelationKode]
LOOP

  IF NOT EXISTS  (SELECT 1 FROM facet_relation WHERE facet_registrering_id=new_facet_registrering.id and rel_type=facet_relation_navn) THEN

    INSERT INTO facet_relation (
          facet_registrering_id,
            virkning,
              rel_maal,
                rel_type
        )
    SELECT 
          new_facet_registrering.id,
            virkning,
              rel_maal,
                rel_type
    FROM facet_relation
    WHERE facet_registrering_id=prev_facet_registrering.id 
    and a.rel_type=facet_relation_navn 
    ;

  END IF;
            
END LOOP;
/**********************/
-- handle tilstande (states)

--1) Insert tilstande/states given as part of this update
--2) Insert tilstande/states of previous registration, taking overlapping virknings into consideration (using function subtract_tstzrange)


--facet_tils_publiceret

--Ad 1)

INSERT INTO facet_tils_publiceret (
        virkning,
          publiceret_status,
            facet_registrering_id
) 
SELECT
        (a.facet_tils_publiceret_obj).virkning,
          (a.facet_tils_publiceret_obj).publiceret_status,
            new_facet_registrering.id
FROM
unnest(tilsPubliceretStatus) as a(facet_tils_publiceret_obj)
;
 

--Ad 2

INSERT INTO facet_tils_publiceret (
        virkning,
          publiceret_status,
            facet_registrering_id
)
SELECT 
        ROW(
          c.tz_range_leftover,
            (a.virkning).AktoerRef,
            (a.virkning).AktoerTypeKode,
            (a.virkning).NoteTekst
        ) :: virkning,
          a.publiceret_status,
            new_facet_registrering.id
FROM
(
 --build an array of the timeperiod of the virkning of the facet_tils_publiceret of the new registrering to pass to subtract_tstzrange_arr on the facet_tils_publiceret of the previous registrering 
    SELECT coalesce(array_agg((b.virkning).TimePeriod),array[]::TSTZRANGE[]) tzranges_of_new_reg
    FROM facet_tils_publiceret b
    WHERE 
          b.facet_registrering_id=new_facet_registrering.id
) d
  JOIN facet_tils_publiceret a ON true  
  JOIN unnest(subtract_tstzrange_arr((a.virkning).TimePeriod,tzranges_of_new_reg)) as c(tz_range_leftover) on true
  WHERE a.facet_registrering_id=prev_facet_registrering.id     
;


--TODO: handle attributter (attributes)






return new_facet_registrering.id;



END;
$$ LANGUAGE plpgsql VOLATILE;