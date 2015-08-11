-- Copyright (C) 2015 Magenta ApS, http://magenta.dk.
-- Contact: info@magenta.dk.
--
-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at http://mozilla.org/MPL/2.0/.

/*
NOTICE: This file is auto-generated using the script: apply-template.py facet as_update.jinja.sql
*/




--Also notice, that the given arrays of FacetAttr...Type must be consistent regarding virkning (although the allowance of null-values might make it possible to construct 'logically consistent'-arrays of objects with overlapping virknings)

CREATE OR REPLACE FUNCTION as_update_facet(
  facet_uuid uuid,
  brugerref uuid,
  note text,
  livscykluskode Livscykluskode,           
  attrEgenskaber FacetEgenskaberAttrType[],
  tilsPubliceret FacetPubliceretTilsType[],
  relationer FacetRelationType[],
  lostUpdatePreventionTZ TIMESTAMPTZ = null
	)
  RETURNS bigint AS 
$$
DECLARE
  read_new_facet FacetType;
  read_prev_facet FacetType;
  read_new_facet_reg FacetRegistreringType;
  read_prev_facet_reg FacetRegistreringType;
  new_facet_registrering facet_registrering;
  prev_facet_registrering facet_registrering;
  facet_relation_navn FacetRelationKode;
  attrEgenskaberObj FacetEgenskaberAttrType;
BEGIN

--create a new registrering

IF NOT EXISTS (select a.id from facet a join facet_registrering b on b.facet_id=a.id  where a.id=facet_uuid) THEN
   RAISE EXCEPTION 'Unable to update facet with uuid [%], being unable to any previous registrations.',facet_uuid;
END IF;

PERFORM a.id FROM facet a
WHERE a.id=facet_uuid
FOR UPDATE; --We synchronize concurrent invocations of as_updates of this particular object on a exclusive row lock. This lock will be held by the current transaction until it terminates.

new_facet_registrering := _as_create_facet_registrering(facet_uuid,livscykluskode, brugerref, note);
prev_facet_registrering := _as_get_prev_facet_registrering(new_facet_registrering);

IF lostUpdatePreventionTZ IS NOT NULL THEN
  IF NOT (LOWER((prev_facet_registrering.registrering).timeperiod)=lostUpdatePreventionTZ) THEN
    RAISE EXCEPTION 'Unable to update facet with uuid [%], as the facet seems to have been updated since latest read by client (the given lostUpdatePreventionTZ [%] does not match the timesamp of latest registration [%]).',facet_uuid,lostUpdatePreventionTZ,LOWER((prev_facet_registrering.registrering).timeperiod);
  END IF;   
END IF;




--handle relationer (relations)

IF relationer IS NOT NULL AND coalesce(array_length(relationer,1),0)=0 THEN
--raise notice 'Skipping relations, as it is explicit set to empty array. Update note [%]',note;
ELSE

  --1) Insert relations given as part of this update
  --2) Insert relations of previous registration, taking overlapping virknings into consideration (using function subtract_tstzrange)

  --Ad 1)



      INSERT INTO facet_relation (
        facet_registrering_id,
          virkning,
            rel_maal_uuid,
              rel_maal_urn,
                rel_type,
                  objekt_type
      )
      SELECT
        new_facet_registrering.id,
          a.virkning,
            a.relMaalUuid,
              a.relMaalUrn,
                a.relType,
                  a.objektType
      FROM unnest(relationer) as a
    ;

   
  --Ad 2)

  /**********************/
  -- 0..1 relations 
   

  FOREACH facet_relation_navn in array  ARRAY['ansvarlig'::FacetRelationKode,'ejer'::FacetRelationKode,'facettilhoerer'::FacetRelationKode]
  LOOP

    INSERT INTO facet_relation (
        facet_registrering_id,
          virkning,
            rel_maal_uuid,
              rel_maal_urn,
                rel_type,
                  objekt_type
      )
    SELECT 
        new_facet_registrering.id, 
          ROW(
            c.tz_range_leftover,
              (a.virkning).AktoerRef,
              (a.virkning).AktoerTypeKode,
              (a.virkning).NoteTekst
          ) :: virkning,
            a.rel_maal_uuid,
              a.rel_maal_urn,
                a.rel_type,
                  a.objekt_type
    FROM
    (
      --build an array of the timeperiod of the virkning of the relations of the new registrering to pass to _subtract_tstzrange_arr on the relations of the previous registrering 
      SELECT coalesce(array_agg((b.virkning).TimePeriod),array[]::TSTZRANGE[]) tzranges_of_new_reg
      FROM facet_relation b
      WHERE 
            b.facet_registrering_id=new_facet_registrering.id
            and
            b.rel_type=facet_relation_navn
    ) d
    JOIN facet_relation a ON true
    JOIN unnest(_subtract_tstzrange_arr((a.virkning).TimePeriod,tzranges_of_new_reg)) as c(tz_range_leftover) on true
    WHERE a.facet_registrering_id=prev_facet_registrering.id 
          and a.rel_type=facet_relation_navn 
    ;
  END LOOP;

  /**********************/
  -- 0..n relations

  --We only have to check if there are any of the relations with the given name present in the new registration, otherwise copy the ones from the previous registration


  FOREACH facet_relation_navn in array ARRAY['redaktoerer'::FacetRelationKode]
  LOOP

    IF NOT EXISTS  (SELECT 1 FROM facet_relation WHERE facet_registrering_id=new_facet_registrering.id and rel_type=facet_relation_navn) THEN

      INSERT INTO facet_relation (
            facet_registrering_id,
              virkning,
                rel_maal_uuid,
                  rel_maal_urn,
                    rel_type,
                      objekt_type
          )
      SELECT 
            new_facet_registrering.id,
              virkning,
                rel_maal_uuid,
                  rel_maal_urn,
                    rel_type,
                      objekt_type
      FROM facet_relation
      WHERE facet_registrering_id=prev_facet_registrering.id 
      and rel_type=facet_relation_navn 
      ;

    END IF;
              
  END LOOP;


/**********************/
--Remove any "cleared"/"deleted" relations
DELETE FROM facet_relation
WHERE 
facet_registrering_id=new_facet_registrering.id
AND (rel_maal_uuid IS NULL AND (rel_maal_urn IS NULL OR rel_maal_urn=''))
;

END IF;
/**********************/
-- handle tilstande (states)

IF tilsPubliceret IS NOT NULL AND coalesce(array_length(tilsPubliceret,1),0)=0 THEN
--raise debug 'Skipping [Publiceret] as it is explicit set to empty array';
ELSE
  --1) Insert tilstande/states given as part of this update
  --2) Insert tilstande/states of previous registration, taking overlapping virknings into consideration (using function subtract_tstzrange)

  /********************************************/
  --facet_tils_publiceret
  /********************************************/

  --Ad 1)

  INSERT INTO facet_tils_publiceret (
          virkning,
            publiceret,
              facet_registrering_id
  ) 
  SELECT
          a.virkning,
            a.publiceret,
              new_facet_registrering.id
  FROM
  unnest(tilsPubliceret) as a
  ;
   

  --Ad 2

  INSERT INTO facet_tils_publiceret (
          virkning,
            publiceret,
              facet_registrering_id
  )
  SELECT 
          ROW(
            c.tz_range_leftover,
              (a.virkning).AktoerRef,
              (a.virkning).AktoerTypeKode,
              (a.virkning).NoteTekst
          ) :: virkning,
            a.publiceret,
              new_facet_registrering.id
  FROM
  (
   --build an array of the timeperiod of the virkning of the facet_tils_publiceret of the new registrering to pass to _subtract_tstzrange_arr on the facet_tils_publiceret of the previous registrering 
      SELECT coalesce(array_agg((b.virkning).TimePeriod),array[]::TSTZRANGE[]) tzranges_of_new_reg
      FROM facet_tils_publiceret b
      WHERE 
            b.facet_registrering_id=new_facet_registrering.id
  ) d
    JOIN facet_tils_publiceret a ON true  
    JOIN unnest(_subtract_tstzrange_arr((a.virkning).TimePeriod,tzranges_of_new_reg)) as c(tz_range_leftover) on true
    WHERE a.facet_registrering_id=prev_facet_registrering.id     
  ;


/**********************/
--Remove any "cleared"/"deleted" tilstande
DELETE FROM facet_tils_publiceret
WHERE 
facet_registrering_id=new_facet_registrering.id
AND publiceret = ''::FacetPubliceretTils
;

END IF;


/**********************/
--Handle attributter (attributes) 

/********************************************/
--facet_attr_egenskaber
/********************************************/

--Generate and insert any merged objects, if any fields are null in attrFacetObj
IF attrEgenskaber IS NOT null THEN

  --Input validation: 
  --Verify that there is no overlap in virkning in the array given

  IF EXISTS (
  SELECT
  a.*
  FROM unnest(attrEgenskaber) a
  JOIN  unnest(attrEgenskaber) b on (a.virkning).TimePeriod && (b.virkning).TimePeriod
  GROUP BY a.brugervendtnoegle,a.beskrivelse,a.opbygning,a.ophavsret,a.plan,a.supplement,a.retskilde, a.virkning
  HAVING COUNT(*)>1
  ) THEN
  RAISE EXCEPTION 'Unable to update facet with uuid [%], as the facet have overlapping virknings in the given egenskaber array :%',facet_uuid,to_json(attrEgenskaber)  USING ERRCODE = 22000;

  END IF;


  FOREACH attrEgenskaberObj in array attrEgenskaber
  LOOP

  --To avoid needless fragmentation we'll check for presence of null values in the fields - and if none are present, we'll skip the merging operations
  IF (attrEgenskaberObj).brugervendtnoegle is null OR 
   (attrEgenskaberObj).beskrivelse is null OR 
   (attrEgenskaberObj).opbygning is null OR 
   (attrEgenskaberObj).ophavsret is null OR 
   (attrEgenskaberObj).plan is null OR 
   (attrEgenskaberObj).supplement is null OR 
   (attrEgenskaberObj).retskilde is null 
  THEN

  INSERT INTO
  facet_attr_egenskaber
  (
    brugervendtnoegle,beskrivelse,opbygning,ophavsret,plan,supplement,retskilde
    ,virkning
    ,facet_registrering_id
  )
  SELECT
    coalesce(attrEgenskaberObj.brugervendtnoegle,a.brugervendtnoegle),
    coalesce(attrEgenskaberObj.beskrivelse,a.beskrivelse),
    coalesce(attrEgenskaberObj.opbygning,a.opbygning),
    coalesce(attrEgenskaberObj.ophavsret,a.ophavsret),
    coalesce(attrEgenskaberObj.plan,a.plan),
    coalesce(attrEgenskaberObj.supplement,a.supplement),
    coalesce(attrEgenskaberObj.retskilde,a.retskilde),
	ROW (
	  (a.virkning).TimePeriod * (attrEgenskaberObj.virkning).TimePeriod,
	  (attrEgenskaberObj.virkning).AktoerRef,
	  (attrEgenskaberObj.virkning).AktoerTypeKode,
	  (attrEgenskaberObj.virkning).NoteTekst
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
    brugervendtnoegle,beskrivelse,opbygning,ophavsret,plan,supplement,retskilde
    ,virkning
    ,facet_registrering_id
  )
  SELECT 
    attrEgenskaberObj.brugervendtnoegle, 
    attrEgenskaberObj.beskrivelse, 
    attrEgenskaberObj.opbygning, 
    attrEgenskaberObj.ophavsret, 
    attrEgenskaberObj.plan, 
    attrEgenskaberObj.supplement, 
    attrEgenskaberObj.retskilde,
	  ROW (
	       b.tz_range_leftover,
	      (attrEgenskaberObj.virkning).AktoerRef,
	      (attrEgenskaberObj.virkning).AktoerTypeKode,
	      (attrEgenskaberObj.virkning).NoteTekst
	  )::Virkning,
    new_facet_registrering.id
  FROM
  (
  --build an array of the timeperiod of the virkning of the facet_attr_egenskaber of the new registrering to pass to _subtract_tstzrange_arr 
      SELECT coalesce(array_agg((b.virkning).TimePeriod),array[]::TSTZRANGE[]) tzranges_of_new_reg
      FROM facet_attr_egenskaber b
      WHERE 
       b.facet_registrering_id=new_facet_registrering.id
  ) as a
  JOIN unnest(_subtract_tstzrange_arr((attrEgenskaberObj.virkning).TimePeriod,a.tzranges_of_new_reg)) as b(tz_range_leftover) on true
  ;

  ELSE
    --insert attrEgenskaberObj raw (if there were no null-valued fields) 

    INSERT INTO
    facet_attr_egenskaber
    (
    brugervendtnoegle,beskrivelse,opbygning,ophavsret,plan,supplement,retskilde
    ,virkning
    ,facet_registrering_id
    )
    VALUES ( 
    attrEgenskaberObj.brugervendtnoegle, 
    attrEgenskaberObj.beskrivelse, 
    attrEgenskaberObj.opbygning, 
    attrEgenskaberObj.ophavsret, 
    attrEgenskaberObj.plan, 
    attrEgenskaberObj.supplement, 
    attrEgenskaberObj.retskilde,
    attrEgenskaberObj.virkning,
    new_facet_registrering.id
    );

  END IF;

  END LOOP;
END IF;


IF attrEgenskaber IS NOT NULL AND coalesce(array_length(attrEgenskaber,1),0)=0 THEN
--raise debug 'Skipping handling of egenskaber of previous registration as an empty array was explicit given.';  
ELSE 

--Handle egenskaber of previous registration, taking overlapping virknings into consideration (using function subtract_tstzrange)

INSERT INTO facet_attr_egenskaber (
    brugervendtnoegle,beskrivelse,opbygning,ophavsret,plan,supplement,retskilde
    ,virkning
    ,facet_registrering_id
)
SELECT
      a.brugervendtnoegle,
      a.beskrivelse,
      a.opbygning,
      a.ophavsret,
      a.plan,
      a.supplement,
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
 --build an array of the timeperiod of the virkning of the facet_attr_egenskaber of the new registrering to pass to _subtract_tstzrange_arr on the facet_attr_egenskaber of the previous registrering 
    SELECT coalesce(array_agg((b.virkning).TimePeriod),array[]::TSTZRANGE[]) tzranges_of_new_reg
    FROM facet_attr_egenskaber b
    WHERE 
          b.facet_registrering_id=new_facet_registrering.id
) d
  JOIN facet_attr_egenskaber a ON true  
  JOIN unnest(_subtract_tstzrange_arr((a.virkning).TimePeriod,tzranges_of_new_reg)) as c(tz_range_leftover) on true
  WHERE a.facet_registrering_id=prev_facet_registrering.id     
;



--Remove any "cleared"/"deleted" attributes
DELETE FROM facet_attr_egenskaber a
WHERE 
a.facet_registrering_id=new_facet_registrering.id
AND (a.brugervendtnoegle IS NULL OR a.brugervendtnoegle='') 
            AND  (a.beskrivelse IS NULL OR a.beskrivelse='') 
            AND  (a.opbygning IS NULL OR a.opbygning='') 
            AND  (a.ophavsret IS NULL OR a.ophavsret='') 
            AND  (a.plan IS NULL OR a.plan='') 
            AND  (a.supplement IS NULL OR a.supplement='') 
            AND  (a.retskilde IS NULL OR a.retskilde='')
;

END IF;


/******************************************************************/
--If the new registrering is identical to the previous one, we need to throw an exception to abort the transaction. 

read_new_facet:=as_read_facet(facet_uuid, (new_facet_registrering.registrering).timeperiod,null);
read_prev_facet:=as_read_facet(facet_uuid, (prev_facet_registrering.registrering).timeperiod ,null);
 
--the ordering in as_list (called by as_read) ensures that the latest registration is returned at index pos 1

IF NOT (lower((read_new_facet.registrering[1].registrering).TimePeriod)=lower((new_facet_registrering.registrering).TimePeriod) AND lower((read_prev_facet.registrering[1].registrering).TimePeriod)=lower((prev_facet_registrering.registrering).TimePeriod)) THEN
  RAISE EXCEPTION 'Error updating facet with id [%]: The ordering of as_list_facet should ensure that the latest registrering can be found at index 1. Expected new reg: [%]. Actual new reg at index 1: [%]. Expected prev reg: [%]. Actual prev reg at index 1: [%].',facet_uuid,to_json(new_facet_registrering),to_json(read_new_facet.registrering[1].registrering),to_json(prev_facet_registrering),to_json(prev_new_facet.registrering[1].registrering);
END IF;
 
 --we'll ignore the registreringBase part in the comparrison - except for the livcykluskode

read_new_facet_reg:=ROW(
ROW(null,(read_new_facet.registrering[1].registrering).livscykluskode,null,null)::registreringBase,
(read_new_facet.registrering[1]).tilsPubliceret ,
(read_new_facet.registrering[1]).attrEgenskaber ,
(read_new_facet.registrering[1]).relationer 
)::facetRegistreringType
;

read_prev_facet_reg:=ROW(
ROW(null,(read_prev_facet.registrering[1].registrering).livscykluskode,null,null)::registreringBase,
(read_prev_facet.registrering[1]).tilsPubliceret ,
(read_prev_facet.registrering[1]).attrEgenskaber ,
(read_prev_facet.registrering[1]).relationer 
)::facetRegistreringType
;


IF read_prev_facet_reg=read_new_facet_reg THEN
  --RAISE NOTICE 'Note[%]. Aborted reg:%',note,to_json(read_new_facet_reg);
  --RAISE NOTICE 'Note[%]. Previous reg:%',note,to_json(read_prev_facet_reg);
  RAISE EXCEPTION 'Aborted updating facet with id [%] as the given data, does not give raise to a new registration. Aborted reg:[%], previous reg:[%]',facet_uuid,to_json(read_new_facet_reg),to_json(read_prev_facet_reg) USING ERRCODE = 22000;
END IF;

/******************************************************************/

PERFORM actual_state._amqp_publish_notification('Facet', livscykluskode, facet_uuid);

return new_facet_registrering.id;



END;
$$ LANGUAGE plpgsql VOLATILE;





