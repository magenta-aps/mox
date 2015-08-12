-- Copyright (C) 2015 Magenta ApS, http://magenta.dk.
-- Contact: info@magenta.dk.
--
-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at http://mozilla.org/MPL/2.0/.

/*
NOTICE: This file is auto-generated using the script: apply-template.py bruger as_update.jinja.sql
*/




--Also notice, that the given arrays of BrugerAttr...Type must be consistent regarding virkning (although the allowance of null-values might make it possible to construct 'logically consistent'-arrays of objects with overlapping virknings)

CREATE OR REPLACE FUNCTION as_update_bruger(
  bruger_uuid uuid,
  brugerref uuid,
  note text,
  livscykluskode Livscykluskode,           
  attrEgenskaber BrugerEgenskaberAttrType[],
  tilsGyldighed BrugerGyldighedTilsType[],
  relationer BrugerRelationType[],
  lostUpdatePreventionTZ TIMESTAMPTZ = null,
  auth_criteria_arr BrugerRegistreringType[]=null
	)
  RETURNS bigint AS 
$$
DECLARE
  read_new_bruger BrugerType;
  read_prev_bruger BrugerType;
  read_new_bruger_reg BrugerRegistreringType;
  read_prev_bruger_reg BrugerRegistreringType;
  new_bruger_registrering bruger_registrering;
  prev_bruger_registrering bruger_registrering;
  bruger_relation_navn BrugerRelationKode;
  attrEgenskaberObj BrugerEgenskaberAttrType;
  auth_filtered_uuids uuid[];
BEGIN

--create a new registrering

IF NOT EXISTS (select a.id from bruger a join bruger_registrering b on b.bruger_id=a.id  where a.id=bruger_uuid) THEN
   RAISE EXCEPTION 'Unable to update bruger with uuid [%], being unable to find any previous registrations.',bruger_uuid;
END IF;

PERFORM a.id FROM bruger a
WHERE a.id=bruger_uuid
FOR UPDATE; --We synchronize concurrent invocations of as_updates of this particular object on a exclusive row lock. This lock will be held by the current transaction until it terminates.

/*** Verify that the object meets the stipulated access allowed criteria  ***/
auth_filtered_uuids:=_as_filter_unauth_bruger(array[bruger_uuid]::uuid[],auth_criteria_arr); 
IF NOT (coalesce(array_length(auth_filtered_uuids,1),0)=1 AND auth_filtered_uuids @>ARRAY[bruger_uuid]) THEN
  RAISE EXCEPTION 'Unable to update bruger with uuid [%]. Object does not met stipulated criteria:%',bruger_uuid,to_json(auth_criteria_arr)  USING ERRCODE = MO401; 
END IF;
/*********************/


new_bruger_registrering := _as_create_bruger_registrering(bruger_uuid,livscykluskode, brugerref, note);
prev_bruger_registrering := _as_get_prev_bruger_registrering(new_bruger_registrering);

IF lostUpdatePreventionTZ IS NOT NULL THEN
  IF NOT (LOWER((prev_bruger_registrering.registrering).timeperiod)=lostUpdatePreventionTZ) THEN
    RAISE EXCEPTION 'Unable to update bruger with uuid [%], as the bruger seems to have been updated since latest read by client (the given lostUpdatePreventionTZ [%] does not match the timesamp of latest registration [%]).',bruger_uuid,lostUpdatePreventionTZ,LOWER((prev_bruger_registrering.registrering).timeperiod);
  END IF;   
END IF;




--handle relationer (relations)

IF relationer IS NOT NULL AND coalesce(array_length(relationer,1),0)=0 THEN
--raise notice 'Skipping relations, as it is explicit set to empty array. Update note [%]',note;
ELSE

  --1) Insert relations given as part of this update
  --2) Insert relations of previous registration, taking overlapping virknings into consideration (using function subtract_tstzrange)

  --Ad 1)



      INSERT INTO bruger_relation (
        bruger_registrering_id,
          virkning,
            rel_maal_uuid,
              rel_maal_urn,
                rel_type,
                  objekt_type
      )
      SELECT
        new_bruger_registrering.id,
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
   

  FOREACH bruger_relation_navn in array  ARRAY['tilhoerer'::BrugerRelationKode]
  LOOP

    INSERT INTO bruger_relation (
        bruger_registrering_id,
          virkning,
            rel_maal_uuid,
              rel_maal_urn,
                rel_type,
                  objekt_type
      )
    SELECT 
        new_bruger_registrering.id, 
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
      FROM bruger_relation b
      WHERE 
            b.bruger_registrering_id=new_bruger_registrering.id
            and
            b.rel_type=bruger_relation_navn
    ) d
    JOIN bruger_relation a ON true
    JOIN unnest(_subtract_tstzrange_arr((a.virkning).TimePeriod,tzranges_of_new_reg)) as c(tz_range_leftover) on true
    WHERE a.bruger_registrering_id=prev_bruger_registrering.id 
          and a.rel_type=bruger_relation_navn 
    ;
  END LOOP;

  /**********************/
  -- 0..n relations

  --We only have to check if there are any of the relations with the given name present in the new registration, otherwise copy the ones from the previous registration


  FOREACH bruger_relation_navn in array ARRAY['adresser'::BrugerRelationKode,'brugertyper'::BrugerRelationKode,'opgaver'::BrugerRelationKode,'tilknyttedeenheder'::BrugerRelationKode,'tilknyttedefunktioner'::BrugerRelationKode,'tilknyttedeinteressefaellesskaber'::BrugerRelationKode,'tilknyttedeorganisationer'::BrugerRelationKode,'tilknyttedepersoner'::BrugerRelationKode,'tilknyttedeitsystemer'::BrugerRelationKode]
  LOOP

    IF NOT EXISTS  (SELECT 1 FROM bruger_relation WHERE bruger_registrering_id=new_bruger_registrering.id and rel_type=bruger_relation_navn) THEN

      INSERT INTO bruger_relation (
            bruger_registrering_id,
              virkning,
                rel_maal_uuid,
                  rel_maal_urn,
                    rel_type,
                      objekt_type
          )
      SELECT 
            new_bruger_registrering.id,
              virkning,
                rel_maal_uuid,
                  rel_maal_urn,
                    rel_type,
                      objekt_type
      FROM bruger_relation
      WHERE bruger_registrering_id=prev_bruger_registrering.id 
      and rel_type=bruger_relation_navn 
      ;

    END IF;
              
  END LOOP;


/**********************/


END IF;
/**********************/
-- handle tilstande (states)

IF tilsGyldighed IS NOT NULL AND coalesce(array_length(tilsGyldighed,1),0)=0 THEN
--raise debug 'Skipping [Gyldighed] as it is explicit set to empty array';
ELSE
  --1) Insert tilstande/states given as part of this update
  --2) Insert tilstande/states of previous registration, taking overlapping virknings into consideration (using function subtract_tstzrange)

  /********************************************/
  --bruger_tils_gyldighed
  /********************************************/

  --Ad 1)

  INSERT INTO bruger_tils_gyldighed (
          virkning,
            gyldighed,
              bruger_registrering_id
  ) 
  SELECT
          a.virkning,
            a.gyldighed,
              new_bruger_registrering.id
  FROM
  unnest(tilsGyldighed) as a
  ;
   

  --Ad 2

  INSERT INTO bruger_tils_gyldighed (
          virkning,
            gyldighed,
              bruger_registrering_id
  )
  SELECT 
          ROW(
            c.tz_range_leftover,
              (a.virkning).AktoerRef,
              (a.virkning).AktoerTypeKode,
              (a.virkning).NoteTekst
          ) :: virkning,
            a.gyldighed,
              new_bruger_registrering.id
  FROM
  (
   --build an array of the timeperiod of the virkning of the bruger_tils_gyldighed of the new registrering to pass to _subtract_tstzrange_arr on the bruger_tils_gyldighed of the previous registrering 
      SELECT coalesce(array_agg((b.virkning).TimePeriod),array[]::TSTZRANGE[]) tzranges_of_new_reg
      FROM bruger_tils_gyldighed b
      WHERE 
            b.bruger_registrering_id=new_bruger_registrering.id
  ) d
    JOIN bruger_tils_gyldighed a ON true  
    JOIN unnest(_subtract_tstzrange_arr((a.virkning).TimePeriod,tzranges_of_new_reg)) as c(tz_range_leftover) on true
    WHERE a.bruger_registrering_id=prev_bruger_registrering.id     
  ;


/**********************/

END IF;


/**********************/
--Handle attributter (attributes) 

/********************************************/
--bruger_attr_egenskaber
/********************************************/

--Generate and insert any merged objects, if any fields are null in attrBrugerObj
IF attrEgenskaber IS NOT null THEN

  --Input validation: 
  --Verify that there is no overlap in virkning in the array given

  IF EXISTS (
  SELECT
  a.*
  FROM unnest(attrEgenskaber) a
  JOIN  unnest(attrEgenskaber) b on (a.virkning).TimePeriod && (b.virkning).TimePeriod
  GROUP BY a.brugervendtnoegle,a.brugernavn,a.brugertype, a.virkning
  HAVING COUNT(*)>1
  ) THEN
  RAISE EXCEPTION 'Unable to update bruger with uuid [%], as the bruger have overlapping virknings in the given egenskaber array :%',bruger_uuid,to_json(attrEgenskaber)  USING ERRCODE = 22000;

  END IF;


  FOREACH attrEgenskaberObj in array attrEgenskaber
  LOOP

  --To avoid needless fragmentation we'll check for presence of null values in the fields - and if none are present, we'll skip the merging operations
  IF (attrEgenskaberObj).brugervendtnoegle is null OR 
   (attrEgenskaberObj).brugernavn is null OR 
   (attrEgenskaberObj).brugertype is null 
  THEN

  INSERT INTO
  bruger_attr_egenskaber
  (
    brugervendtnoegle,brugernavn,brugertype
    ,virkning
    ,bruger_registrering_id
  )
  SELECT
    coalesce(attrEgenskaberObj.brugervendtnoegle,a.brugervendtnoegle),
    coalesce(attrEgenskaberObj.brugernavn,a.brugernavn),
    coalesce(attrEgenskaberObj.brugertype,a.brugertype),
	ROW (
	  (a.virkning).TimePeriod * (attrEgenskaberObj.virkning).TimePeriod,
	  (attrEgenskaberObj.virkning).AktoerRef,
	  (attrEgenskaberObj.virkning).AktoerTypeKode,
	  (attrEgenskaberObj.virkning).NoteTekst
	)::Virkning,
    new_bruger_registrering.id
  FROM bruger_attr_egenskaber a
  WHERE
    a.bruger_registrering_id=prev_bruger_registrering.id 
    and (a.virkning).TimePeriod && (attrEgenskaberObj.virkning).TimePeriod
  ;

  --For any periods within the virkning of the attrEgenskaberObj, that is NOT covered by any "merged" rows inserted above, generate and insert rows

  INSERT INTO
  bruger_attr_egenskaber
  (
    brugervendtnoegle,brugernavn,brugertype
    ,virkning
    ,bruger_registrering_id
  )
  SELECT 
    attrEgenskaberObj.brugervendtnoegle, 
    attrEgenskaberObj.brugernavn, 
    attrEgenskaberObj.brugertype,
	  ROW (
	       b.tz_range_leftover,
	      (attrEgenskaberObj.virkning).AktoerRef,
	      (attrEgenskaberObj.virkning).AktoerTypeKode,
	      (attrEgenskaberObj.virkning).NoteTekst
	  )::Virkning,
    new_bruger_registrering.id
  FROM
  (
  --build an array of the timeperiod of the virkning of the bruger_attr_egenskaber of the new registrering to pass to _subtract_tstzrange_arr 
      SELECT coalesce(array_agg((b.virkning).TimePeriod),array[]::TSTZRANGE[]) tzranges_of_new_reg
      FROM bruger_attr_egenskaber b
      WHERE 
       b.bruger_registrering_id=new_bruger_registrering.id
  ) as a
  JOIN unnest(_subtract_tstzrange_arr((attrEgenskaberObj.virkning).TimePeriod,a.tzranges_of_new_reg)) as b(tz_range_leftover) on true
  ;

  ELSE
    --insert attrEgenskaberObj raw (if there were no null-valued fields) 

    INSERT INTO
    bruger_attr_egenskaber
    (
    brugervendtnoegle,brugernavn,brugertype
    ,virkning
    ,bruger_registrering_id
    )
    VALUES ( 
    attrEgenskaberObj.brugervendtnoegle, 
    attrEgenskaberObj.brugernavn, 
    attrEgenskaberObj.brugertype,
    attrEgenskaberObj.virkning,
    new_bruger_registrering.id
    );

  END IF;

  END LOOP;
END IF;


IF attrEgenskaber IS NOT NULL AND coalesce(array_length(attrEgenskaber,1),0)=0 THEN
--raise debug 'Skipping handling of egenskaber of previous registration as an empty array was explicit given.';  
ELSE 

--Handle egenskaber of previous registration, taking overlapping virknings into consideration (using function subtract_tstzrange)

INSERT INTO bruger_attr_egenskaber (
    brugervendtnoegle,brugernavn,brugertype
    ,virkning
    ,bruger_registrering_id
)
SELECT
      a.brugervendtnoegle,
      a.brugernavn,
      a.brugertype,
	  ROW(
	    c.tz_range_leftover,
	      (a.virkning).AktoerRef,
	      (a.virkning).AktoerTypeKode,
	      (a.virkning).NoteTekst
	  ) :: virkning,
	 new_bruger_registrering.id
FROM
(
 --build an array of the timeperiod of the virkning of the bruger_attr_egenskaber of the new registrering to pass to _subtract_tstzrange_arr on the bruger_attr_egenskaber of the previous registrering 
    SELECT coalesce(array_agg((b.virkning).TimePeriod),array[]::TSTZRANGE[]) tzranges_of_new_reg
    FROM bruger_attr_egenskaber b
    WHERE 
          b.bruger_registrering_id=new_bruger_registrering.id
) d
  JOIN bruger_attr_egenskaber a ON true  
  JOIN unnest(_subtract_tstzrange_arr((a.virkning).TimePeriod,tzranges_of_new_reg)) as c(tz_range_leftover) on true
  WHERE a.bruger_registrering_id=prev_bruger_registrering.id     
;





END IF;


/******************************************************************/
--If the new registrering is identical to the previous one, we need to throw an exception to abort the transaction. 

read_new_bruger:=as_read_bruger(bruger_uuid, (new_bruger_registrering.registrering).timeperiod,null);
read_prev_bruger:=as_read_bruger(bruger_uuid, (prev_bruger_registrering.registrering).timeperiod ,null);
 
--the ordering in as_list (called by as_read) ensures that the latest registration is returned at index pos 1

IF NOT (lower((read_new_bruger.registrering[1].registrering).TimePeriod)=lower((new_bruger_registrering.registrering).TimePeriod) AND lower((read_prev_bruger.registrering[1].registrering).TimePeriod)=lower((prev_bruger_registrering.registrering).TimePeriod)) THEN
  RAISE EXCEPTION 'Error updating bruger with id [%]: The ordering of as_list_bruger should ensure that the latest registrering can be found at index 1. Expected new reg: [%]. Actual new reg at index 1: [%]. Expected prev reg: [%]. Actual prev reg at index 1: [%].',bruger_uuid,to_json(new_bruger_registrering),to_json(read_new_bruger.registrering[1].registrering),to_json(prev_bruger_registrering),to_json(prev_new_bruger.registrering[1].registrering);
END IF;
 
 --we'll ignore the registreringBase part in the comparrison - except for the livcykluskode

read_new_bruger_reg:=ROW(
ROW(null,(read_new_bruger.registrering[1].registrering).livscykluskode,null,null)::registreringBase,
(read_new_bruger.registrering[1]).tilsGyldighed ,
(read_new_bruger.registrering[1]).attrEgenskaber ,
(read_new_bruger.registrering[1]).relationer 
)::brugerRegistreringType
;

read_prev_bruger_reg:=ROW(
ROW(null,(read_prev_bruger.registrering[1].registrering).livscykluskode,null,null)::registreringBase,
(read_prev_bruger.registrering[1]).tilsGyldighed ,
(read_prev_bruger.registrering[1]).attrEgenskaber ,
(read_prev_bruger.registrering[1]).relationer 
)::brugerRegistreringType
;


IF read_prev_bruger_reg=read_new_bruger_reg THEN
  --RAISE NOTICE 'Note[%]. Aborted reg:%',note,to_json(read_new_bruger_reg);
  --RAISE NOTICE 'Note[%]. Previous reg:%',note,to_json(read_prev_bruger_reg);
  RAISE EXCEPTION 'Aborted updating bruger with id [%] as the given data, does not give raise to a new registration. Aborted reg:[%], previous reg:[%]',bruger_uuid,to_json(read_new_bruger_reg),to_json(read_prev_bruger_reg) USING ERRCODE = 22000;
END IF;

/******************************************************************/

PERFORM actual_state._amqp_publish_notification('Bruger', livscykluskode, bruger_uuid);

return new_bruger_registrering.id;



END;
$$ LANGUAGE plpgsql VOLATILE;





