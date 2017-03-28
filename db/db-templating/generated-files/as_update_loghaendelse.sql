-- Copyright (C) 2015 Magenta ApS, http://magenta.dk.
-- Contact: info@magenta.dk.
--
-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at http://mozilla.org/MPL/2.0/.

/*
NOTICE: This file is auto-generated using the script: apply-template.py loghaendelse as_update.jinja.sql
*/




--Also notice, that the given arrays of LoghaendelseAttr...Type must be consistent regarding virkning (although the allowance of null-values might make it possible to construct 'logically consistent'-arrays of objects with overlapping virknings)

CREATE OR REPLACE FUNCTION as_update_loghaendelse(
  loghaendelse_uuid uuid,
  brugerref uuid,
  note text,
  livscykluskode Livscykluskode,           
  attrEgenskaber LoghaendelseEgenskaberAttrType[],
  tilsGyldighed LoghaendelseGyldighedTilsType[],
  relationer LoghaendelseRelationType[],
  lostUpdatePreventionTZ TIMESTAMPTZ = null,
  auth_criteria_arr LoghaendelseRegistreringType[]=null
	)
  RETURNS bigint AS 
$$
DECLARE
  read_new_loghaendelse LoghaendelseType;
  read_prev_loghaendelse LoghaendelseType;
  read_new_loghaendelse_reg LoghaendelseRegistreringType;
  read_prev_loghaendelse_reg LoghaendelseRegistreringType;
  new_loghaendelse_registrering loghaendelse_registrering;
  prev_loghaendelse_registrering loghaendelse_registrering;
  loghaendelse_relation_navn LoghaendelseRelationKode;
  attrEgenskaberObj LoghaendelseEgenskaberAttrType;
  auth_filtered_uuids uuid[];
BEGIN

--create a new registrering

IF NOT EXISTS (select a.id from loghaendelse a join loghaendelse_registrering b on b.loghaendelse_id=a.id  where a.id=loghaendelse_uuid) THEN
   RAISE EXCEPTION 'Unable to update loghaendelse with uuid [%], being unable to find any previous registrations.',loghaendelse_uuid USING ERRCODE = 'MO400';
END IF;

PERFORM a.id FROM loghaendelse a
WHERE a.id=loghaendelse_uuid
FOR UPDATE; --We synchronize concurrent invocations of as_updates of this particular object on a exclusive row lock. This lock will be held by the current transaction until it terminates.

/*** Verify that the object meets the stipulated access allowed criteria  ***/
auth_filtered_uuids:=_as_filter_unauth_loghaendelse(array[loghaendelse_uuid]::uuid[],auth_criteria_arr); 
IF NOT (coalesce(array_length(auth_filtered_uuids,1),0)=1 AND auth_filtered_uuids @>ARRAY[loghaendelse_uuid]) THEN
  RAISE EXCEPTION 'Unable to update loghaendelse with uuid [%]. Object does not met stipulated criteria:%',loghaendelse_uuid,to_json(auth_criteria_arr)  USING ERRCODE = 'MO401'; 
END IF;
/*********************/


new_loghaendelse_registrering := _as_create_loghaendelse_registrering(loghaendelse_uuid,livscykluskode, brugerref, note);
prev_loghaendelse_registrering := _as_get_prev_loghaendelse_registrering(new_loghaendelse_registrering);

IF lostUpdatePreventionTZ IS NOT NULL THEN
  IF NOT (LOWER((prev_loghaendelse_registrering.registrering).timeperiod)=lostUpdatePreventionTZ) THEN
    RAISE EXCEPTION 'Unable to update loghaendelse with uuid [%], as the loghaendelse seems to have been updated since latest read by client (the given lostUpdatePreventionTZ [%] does not match the timesamp of latest registration [%]).',loghaendelse_uuid,lostUpdatePreventionTZ,LOWER((prev_loghaendelse_registrering.registrering).timeperiod) USING ERRCODE = 'MO409';
  END IF;   
END IF;




--handle relationer (relations)

IF relationer IS NOT NULL AND coalesce(array_length(relationer,1),0)=0 THEN
--raise notice 'Skipping relations, as it is explicit set to empty array. Update note [%]',note;
ELSE

  --1) Insert relations given as part of this update
  --2) Insert relations of previous registration, taking overlapping virknings into consideration (using function subtract_tstzrange)

  --Ad 1)



      INSERT INTO loghaendelse_relation (
        loghaendelse_registrering_id,
          virkning,
            rel_maal_uuid,
              rel_maal_urn,
                rel_type,
                  objekt_type
      )
      SELECT
        new_loghaendelse_registrering.id,
          a.virkning,
            a.uuid,
              a.urn,
                a.relType,
                  a.objektType
      FROM unnest(relationer) as a
    ;

   
  --Ad 2)

  /**********************/
  -- 0..1 relations 
   

  FOREACH loghaendelse_relation_navn in array  ARRAY['objekt'::LoghaendelseRelationKode,'bruger'::LoghaendelseRelationKode,'brugerrolle'::LoghaendelseRelationKode]::LoghaendelseRelationKode[]
  LOOP

    INSERT INTO loghaendelse_relation (
        loghaendelse_registrering_id,
          virkning,
            rel_maal_uuid,
              rel_maal_urn,
                rel_type,
                  objekt_type
      )
    SELECT 
        new_loghaendelse_registrering.id, 
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
      FROM loghaendelse_relation b
      WHERE 
            b.loghaendelse_registrering_id=new_loghaendelse_registrering.id
            and
            b.rel_type=loghaendelse_relation_navn
    ) d
    JOIN loghaendelse_relation a ON true
    JOIN unnest(_subtract_tstzrange_arr((a.virkning).TimePeriod,tzranges_of_new_reg)) as c(tz_range_leftover) on true
    WHERE a.loghaendelse_registrering_id=prev_loghaendelse_registrering.id 
          and a.rel_type=loghaendelse_relation_navn 
    ;
  END LOOP;

  /**********************/
  -- 0..n relations

  --We only have to check if there are any of the relations with the given name present in the new registration, otherwise copy the ones from the previous registration


  FOREACH loghaendelse_relation_navn in array ARRAY[]::LoghaendelseRelationKode[]
  LOOP

    IF NOT EXISTS  (SELECT 1 FROM loghaendelse_relation WHERE loghaendelse_registrering_id=new_loghaendelse_registrering.id and rel_type=loghaendelse_relation_navn) THEN

      INSERT INTO loghaendelse_relation (
            loghaendelse_registrering_id,
              virkning,
                rel_maal_uuid,
                  rel_maal_urn,
                    rel_type,
                      objekt_type
          )
      SELECT 
            new_loghaendelse_registrering.id,
              virkning,
                rel_maal_uuid,
                  rel_maal_urn,
                    rel_type,
                      objekt_type
      FROM loghaendelse_relation
      WHERE loghaendelse_registrering_id=prev_loghaendelse_registrering.id 
      and rel_type=loghaendelse_relation_navn 
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
  --loghaendelse_tils_gyldighed
  /********************************************/

  --Ad 1)

  INSERT INTO loghaendelse_tils_gyldighed (
          virkning,
            gyldighed,
              loghaendelse_registrering_id
  ) 
  SELECT
          a.virkning,
            a.gyldighed,
              new_loghaendelse_registrering.id
  FROM
  unnest(tilsGyldighed) as a
  ;
   

  --Ad 2

  INSERT INTO loghaendelse_tils_gyldighed (
          virkning,
            gyldighed,
              loghaendelse_registrering_id
  )
  SELECT 
          ROW(
            c.tz_range_leftover,
              (a.virkning).AktoerRef,
              (a.virkning).AktoerTypeKode,
              (a.virkning).NoteTekst
          ) :: virkning,
            a.gyldighed,
              new_loghaendelse_registrering.id
  FROM
  (
   --build an array of the timeperiod of the virkning of the loghaendelse_tils_gyldighed of the new registrering to pass to _subtract_tstzrange_arr on the loghaendelse_tils_gyldighed of the previous registrering 
      SELECT coalesce(array_agg((b.virkning).TimePeriod),array[]::TSTZRANGE[]) tzranges_of_new_reg
      FROM loghaendelse_tils_gyldighed b
      WHERE 
            b.loghaendelse_registrering_id=new_loghaendelse_registrering.id
  ) d
    JOIN loghaendelse_tils_gyldighed a ON true  
    JOIN unnest(_subtract_tstzrange_arr((a.virkning).TimePeriod,tzranges_of_new_reg)) as c(tz_range_leftover) on true
    WHERE a.loghaendelse_registrering_id=prev_loghaendelse_registrering.id     
  ;


/**********************/

END IF;


/**********************/
--Handle attributter (attributes) 

/********************************************/
--loghaendelse_attr_egenskaber
/********************************************/

--Generate and insert any merged objects, if any fields are null in attrLoghaendelseObj
IF attrEgenskaber IS NOT null THEN

  --Input validation: 
  --Verify that there is no overlap in virkning in the array given

  IF EXISTS (
  SELECT
  a.*
  FROM unnest(attrEgenskaber) a
  JOIN  unnest(attrEgenskaber) b on (a.virkning).TimePeriod && (b.virkning).TimePeriod
  GROUP BY a.service,a.klasse,a.tidspunkt,a.operation,a.objekttype,a.returkode,a.returtekst,a.note, a.virkning
  HAVING COUNT(*)>1
  ) THEN
  RAISE EXCEPTION 'Unable to update loghaendelse with uuid [%], as the loghaendelse have overlapping virknings in the given egenskaber array :%',loghaendelse_uuid,to_json(attrEgenskaber)  USING ERRCODE = 'MO400';

  END IF;


  FOREACH attrEgenskaberObj in array attrEgenskaber
  LOOP

  --To avoid needless fragmentation we'll check for presence of null values in the fields - and if none are present, we'll skip the merging operations
  IF (attrEgenskaberObj).service is null OR 
   (attrEgenskaberObj).klasse is null OR 
   (attrEgenskaberObj).tidspunkt is null OR 
   (attrEgenskaberObj).operation is null OR 
   (attrEgenskaberObj).objekttype is null OR 
   (attrEgenskaberObj).returkode is null OR 
   (attrEgenskaberObj).returtekst is null OR 
   (attrEgenskaberObj).note is null 
  THEN

  INSERT INTO
  loghaendelse_attr_egenskaber
  (
    service,klasse,tidspunkt,operation,objekttype,returkode,returtekst,note
    ,virkning
    ,loghaendelse_registrering_id
  )
  SELECT
    coalesce(attrEgenskaberObj.service,a.service),
    coalesce(attrEgenskaberObj.klasse,a.klasse),
    coalesce(attrEgenskaberObj.tidspunkt,a.tidspunkt),
    coalesce(attrEgenskaberObj.operation,a.operation),
    coalesce(attrEgenskaberObj.objekttype,a.objekttype),
    coalesce(attrEgenskaberObj.returkode,a.returkode),
    coalesce(attrEgenskaberObj.returtekst,a.returtekst),
    coalesce(attrEgenskaberObj.note,a.note),
	ROW (
	  (a.virkning).TimePeriod * (attrEgenskaberObj.virkning).TimePeriod,
	  (attrEgenskaberObj.virkning).AktoerRef,
	  (attrEgenskaberObj.virkning).AktoerTypeKode,
	  (attrEgenskaberObj.virkning).NoteTekst
	)::Virkning,
    new_loghaendelse_registrering.id
  FROM loghaendelse_attr_egenskaber a
  WHERE
    a.loghaendelse_registrering_id=prev_loghaendelse_registrering.id 
    and (a.virkning).TimePeriod && (attrEgenskaberObj.virkning).TimePeriod
  ;

  --For any periods within the virkning of the attrEgenskaberObj, that is NOT covered by any "merged" rows inserted above, generate and insert rows

  INSERT INTO
  loghaendelse_attr_egenskaber
  (
    service,klasse,tidspunkt,operation,objekttype,returkode,returtekst,note
    ,virkning
    ,loghaendelse_registrering_id
  )
  SELECT 
    attrEgenskaberObj.service, 
    attrEgenskaberObj.klasse, 
    attrEgenskaberObj.tidspunkt, 
    attrEgenskaberObj.operation, 
    attrEgenskaberObj.objekttype, 
    attrEgenskaberObj.returkode, 
    attrEgenskaberObj.returtekst, 
    attrEgenskaberObj.note,
	  ROW (
	       b.tz_range_leftover,
	      (attrEgenskaberObj.virkning).AktoerRef,
	      (attrEgenskaberObj.virkning).AktoerTypeKode,
	      (attrEgenskaberObj.virkning).NoteTekst
	  )::Virkning,
    new_loghaendelse_registrering.id
  FROM
  (
  --build an array of the timeperiod of the virkning of the loghaendelse_attr_egenskaber of the new registrering to pass to _subtract_tstzrange_arr 
      SELECT coalesce(array_agg((b.virkning).TimePeriod),array[]::TSTZRANGE[]) tzranges_of_new_reg
      FROM loghaendelse_attr_egenskaber b
      WHERE 
       b.loghaendelse_registrering_id=new_loghaendelse_registrering.id
  ) as a
  JOIN unnest(_subtract_tstzrange_arr((attrEgenskaberObj.virkning).TimePeriod,a.tzranges_of_new_reg)) as b(tz_range_leftover) on true
  ;

  ELSE
    --insert attrEgenskaberObj raw (if there were no null-valued fields) 

    INSERT INTO
    loghaendelse_attr_egenskaber
    (
    service,klasse,tidspunkt,operation,objekttype,returkode,returtekst,note
    ,virkning
    ,loghaendelse_registrering_id
    )
    VALUES ( 
    attrEgenskaberObj.service, 
    attrEgenskaberObj.klasse, 
    attrEgenskaberObj.tidspunkt, 
    attrEgenskaberObj.operation, 
    attrEgenskaberObj.objekttype, 
    attrEgenskaberObj.returkode, 
    attrEgenskaberObj.returtekst, 
    attrEgenskaberObj.note,
    attrEgenskaberObj.virkning,
    new_loghaendelse_registrering.id
    );

  END IF;

  END LOOP;
END IF;


IF attrEgenskaber IS NOT NULL AND coalesce(array_length(attrEgenskaber,1),0)=0 THEN
--raise debug 'Skipping handling of egenskaber of previous registration as an empty array was explicit given.';  
ELSE 

--Handle egenskaber of previous registration, taking overlapping virknings into consideration (using function subtract_tstzrange)

INSERT INTO loghaendelse_attr_egenskaber (
    service,klasse,tidspunkt,operation,objekttype,returkode,returtekst,note
    ,virkning
    ,loghaendelse_registrering_id
)
SELECT
      a.service,
      a.klasse,
      a.tidspunkt,
      a.operation,
      a.objekttype,
      a.returkode,
      a.returtekst,
      a.note,
	  ROW(
	    c.tz_range_leftover,
	      (a.virkning).AktoerRef,
	      (a.virkning).AktoerTypeKode,
	      (a.virkning).NoteTekst
	  ) :: virkning,
	 new_loghaendelse_registrering.id
FROM
(
 --build an array of the timeperiod of the virkning of the loghaendelse_attr_egenskaber of the new registrering to pass to _subtract_tstzrange_arr on the loghaendelse_attr_egenskaber of the previous registrering 
    SELECT coalesce(array_agg((b.virkning).TimePeriod),array[]::TSTZRANGE[]) tzranges_of_new_reg
    FROM loghaendelse_attr_egenskaber b
    WHERE 
          b.loghaendelse_registrering_id=new_loghaendelse_registrering.id
) d
  JOIN loghaendelse_attr_egenskaber a ON true  
  JOIN unnest(_subtract_tstzrange_arr((a.virkning).TimePeriod,tzranges_of_new_reg)) as c(tz_range_leftover) on true
  WHERE a.loghaendelse_registrering_id=prev_loghaendelse_registrering.id     
;





END IF;


/******************************************************************/
--If the new registrering is identical to the previous one, we need to throw an exception to abort the transaction. 

read_new_loghaendelse:=as_read_loghaendelse(loghaendelse_uuid, (new_loghaendelse_registrering.registrering).timeperiod,null);
read_prev_loghaendelse:=as_read_loghaendelse(loghaendelse_uuid, (prev_loghaendelse_registrering.registrering).timeperiod ,null);
 
--the ordering in as_list (called by as_read) ensures that the latest registration is returned at index pos 1

IF NOT (lower((read_new_loghaendelse.registrering[1].registrering).TimePeriod)=lower((new_loghaendelse_registrering.registrering).TimePeriod) AND lower((read_prev_loghaendelse.registrering[1].registrering).TimePeriod)=lower((prev_loghaendelse_registrering.registrering).TimePeriod)) THEN
  RAISE EXCEPTION 'Error updating loghaendelse with id [%]: The ordering of as_list_loghaendelse should ensure that the latest registrering can be found at index 1. Expected new reg: [%]. Actual new reg at index 1: [%]. Expected prev reg: [%]. Actual prev reg at index 1: [%].',loghaendelse_uuid,to_json(new_loghaendelse_registrering),to_json(read_new_loghaendelse.registrering[1].registrering),to_json(prev_loghaendelse_registrering),to_json(prev_new_loghaendelse.registrering[1].registrering) USING ERRCODE = 'MO500';
END IF;
 
 --we'll ignore the registreringBase part in the comparrison - except for the livcykluskode

read_new_loghaendelse_reg:=ROW(
ROW(null,(read_new_loghaendelse.registrering[1].registrering).livscykluskode,null,null)::registreringBase,
(read_new_loghaendelse.registrering[1]).tilsGyldighed ,
(read_new_loghaendelse.registrering[1]).attrEgenskaber ,
(read_new_loghaendelse.registrering[1]).relationer 
)::loghaendelseRegistreringType
;

read_prev_loghaendelse_reg:=ROW(
ROW(null,(read_prev_loghaendelse.registrering[1].registrering).livscykluskode,null,null)::registreringBase,
(read_prev_loghaendelse.registrering[1]).tilsGyldighed ,
(read_prev_loghaendelse.registrering[1]).attrEgenskaber ,
(read_prev_loghaendelse.registrering[1]).relationer 
)::loghaendelseRegistreringType
;


IF read_prev_loghaendelse_reg=read_new_loghaendelse_reg THEN
  --RAISE NOTICE 'Note[%]. Aborted reg:%',note,to_json(read_new_loghaendelse_reg);
  --RAISE NOTICE 'Note[%]. Previous reg:%',note,to_json(read_prev_loghaendelse_reg);
  RAISE EXCEPTION 'Aborted updating loghaendelse with id [%] as the given data, does not give raise to a new registration. Aborted reg:[%], previous reg:[%]',loghaendelse_uuid,to_json(read_new_loghaendelse_reg),to_json(read_prev_loghaendelse_reg) USING ERRCODE = 'MO400';
END IF;

/******************************************************************/

PERFORM actual_state._amqp_publish_notification('Loghaendelse', livscykluskode, loghaendelse_uuid);

return new_loghaendelse_registrering.id;



END;
$$ LANGUAGE plpgsql VOLATILE;





