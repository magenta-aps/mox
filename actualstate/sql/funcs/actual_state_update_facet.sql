
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
  facet_relation_navn text;
  attrEgenskaberObj FacetAttrEgenskaberType;

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


/**********************/
--Handle attributter (attributes) -- Egenskaber



--Generate and insert any merged objects, if any fields are null in attrEgenskaberObj
FOREACH attrEgenskaberObj in array relationer
LOOP

--To avoid needless fragmentation we'll check for presence of null values in the fields - and if none are present, we'll skip the merging operations
IF attrEgenskaberObj.brugervendtNoegle is null 
  OR attrEgenskaberObj.facetbeskrivelse is null 
    OR attrEgenskaberObj.facetplan is null
      OR attrEgenskaberObj.facetopbygning  is null
        OR attrEgenskaberObj.facetophavsret is null
          OR attrEgenskaberObj.facetsupplement is null
            OR attrEgenskaberObj.retskilde is null 
THEN

INSERT INTO
facet_attr_egenskaber
(
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
  coalesce(attrEgenskaberObj.brugervendtNoegle,a.brugervendt_noegle),
    coalesce(attrEgenskaberObj.facetbeskrivelse,a.facetbeskrivelse),
      coalesce(attrEgenskaberObj.facetplan,a.facetplan),
        coalesce(attrEgenskaberObj.facetopbygning,a.facetopbygning),
          coalesce(attrEgenskaberObj.facetophavsret,a.facetophavsret),
            coalesce(attrEgenskaberObj.facetsupplement,a.facetsupplement),
              coalesce(attrEgenskaberObj.retskilde,a.retskilde),
                ROW (
                    (a.virkning).TimePeriod * (attrEgenskaberObj.virkning).TimePeriod,
                    attrEgenskaberObj.AktoerRef,
                    attrEgenskaberObj.AktoerTypeKode,
                    attrEgenskaberObj.NoteTekst
                )::Virkning,
                  new_facet_registrering.id
FROM facet_attr_egenskaber a
WHERE
  a.facet_registrering_id=prev_facet_registrering.id 
  and (a.virkning).TimePeriod && (attrEgenskaberObj.virkning).TimePeriod
;

--For any periods within the virkning of the attrEgenskaberObj, that is NOT covered by any "merged" rows inserted above, generate and insert rows

INSERT INTO
facet_attr_egenskaber
(
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
  attrEgenskaberObj.brugervendtNoegle,
    attrEgenskaberObj.facetbeskrivelse,
      attrEgenskaberObj.facetplan,
        attrEgenskaberObj.facetopbygning,
          attrEgenskaberObj.facetophavsret,
            attrEgenskaberObj.facetsupplement,
              attrEgenskaberObj.retskilde,
                ROW (
                     b.tz_range_leftover,
                    attrEgenskaberObj.AktoerRef,
                    attrEgenskaberObj.AktoerTypeKode,
                    attrEgenskaberObj.NoteTekst
                )::Virkning,
                  new_facet_registrering.id
FROM
(
--build an array of the timeperiod of the virkning of the facet_attr_egenskaber of the new registrering to pass to subtract_tstzrange_arr 
    SELECT coalesce(array_agg((b.virkning).TimePeriod),array[]::TSTZRANGE[]) tzranges_of_new_reg
    FROM facet_attr_egenskaber b
    WHERE 
     b.facet_registrering_id=new_facet_registrering.id
) as a
JOIN unnest(subtract_tstzrange_arr((attrEgenskaberObj.virkning).TimePeriod,a.tzranges_of_new_reg)) as b(tz_range_leftover) on true
;

ELSE
  --insert attrEgenskaberObj raw (if there were no null-valued fields) 

  INSERT INTO
  facet_attr_egenskaber
  (
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
  VALUES (
    attrEgenskaberObj.brugervendtNoegle,
      attrEgenskaberObj.facetbeskrivelse,
        attrEgenskaberObj.facetplan,
          attrEgenskaberObj.facetopbygning,
            attrEgenskaberObj.facetophavsret,
              attrEgenskaberObj.facetsupplement,
                attrEgenskaberObj.retskilde,
                  attrEgenskaberObj.virkning,
                    new_facet_registrering.id
  );

END IF;

END LOOP;

--Handle egenskaber of previous registration, taking overlapping virknings into consideration (using function subtract_tstzrange)

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
    a.brugervendt_noegle,
      a.facetbeskrivelse, 
        a.facetplan,
          a.facetopbygning,
            a.facetophavsret,
              a.facetsupplement,
                a.retskilde,
                  ROW(
                    c.tz_range_leftover,
                      (a.virkning).AktoerRef,
                      (a.virkning).AktoerTypeKode,
                      (a.virkning).NoteTekst
                  ) :: virkning,
                    new_facet_registrering.id
FROM
(
 --build an array of the timeperiod of the virkning of the facet_attr_egenskaber of the new registrering to pass to subtract_tstzrange_arr on the facet_attr_egenskaber of the previous registrering 
    SELECT coalesce(array_agg((b.virkning).TimePeriod),array[]::TSTZRANGE[]) tzranges_of_new_reg
    FROM facet_attr_egenskaber b
    WHERE 
          b.facet_registrering_id=new_facet_registrering.id
) d
  JOIN facet_attr_egenskaber a ON true  
  JOIN unnest(subtract_tstzrange_arr((a.virkning).TimePeriod,tzranges_of_new_reg)) as c(tz_range_leftover) on true
  WHERE a.facet_registrering_id=prev_facet_registrering.id     
;
--TODO: Test and verify!!!



return new_facet_registrering.id;



END;
$$ LANGUAGE plpgsql VOLATILE;