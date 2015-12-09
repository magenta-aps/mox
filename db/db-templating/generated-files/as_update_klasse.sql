-- Copyright (C) 2015 Magenta ApS, http://magenta.dk.
-- Contact: info@magenta.dk.
--
-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at http://mozilla.org/MPL/2.0/.

/*
NOTICE: This file is auto-generated using the script: apply-template.py klasse as_update.jinja.sql
*/




--Also notice, that the given arrays of KlasseAttr...Type must be consistent regarding virkning (although the allowance of null-values might make it possible to construct 'logically consistent'-arrays of objects with overlapping virknings)

CREATE OR REPLACE FUNCTION as_update_klasse(
  klasse_uuid uuid,
  brugerref uuid,
  note text,
  livscykluskode Livscykluskode,           
  attrEgenskaber KlasseEgenskaberAttrType[],
  tilsPubliceret KlassePubliceretTilsType[],
  relationer KlasseRelationType[],
  lostUpdatePreventionTZ TIMESTAMPTZ = null,
  auth_criteria_arr KlasseRegistreringType[]=null
	)
  RETURNS bigint AS 
$$
DECLARE
  read_new_klasse KlasseType;
  read_prev_klasse KlasseType;
  read_new_klasse_reg KlasseRegistreringType;
  read_prev_klasse_reg KlasseRegistreringType;
  new_klasse_registrering klasse_registrering;
  prev_klasse_registrering klasse_registrering;
  klasse_relation_navn KlasseRelationKode;
  attrEgenskaberObj KlasseEgenskaberAttrType;
  new_id_klasse_attr_egenskaber bigint;
  klasseSoegeordObj KlasseSoegeordType;
  auth_filtered_uuids uuid[];
BEGIN

--create a new registrering

IF NOT EXISTS (select a.id from klasse a join klasse_registrering b on b.klasse_id=a.id  where a.id=klasse_uuid) THEN
   RAISE EXCEPTION 'Unable to update klasse with uuid [%], being unable to find any previous registrations.',klasse_uuid USING ERRCODE = 'MO400';
END IF;

PERFORM a.id FROM klasse a
WHERE a.id=klasse_uuid
FOR UPDATE; --We synchronize concurrent invocations of as_updates of this particular object on a exclusive row lock. This lock will be held by the current transaction until it terminates.

/*** Verify that the object meets the stipulated access allowed criteria  ***/
auth_filtered_uuids:=_as_filter_unauth_klasse(array[klasse_uuid]::uuid[],auth_criteria_arr); 
IF NOT (coalesce(array_length(auth_filtered_uuids,1),0)=1 AND auth_filtered_uuids @>ARRAY[klasse_uuid]) THEN
  RAISE EXCEPTION 'Unable to update klasse with uuid [%]. Object does not met stipulated criteria:%',klasse_uuid,to_json(auth_criteria_arr)  USING ERRCODE = 'MO401'; 
END IF;
/*********************/


new_klasse_registrering := _as_create_klasse_registrering(klasse_uuid,livscykluskode, brugerref, note);
prev_klasse_registrering := _as_get_prev_klasse_registrering(new_klasse_registrering);

IF lostUpdatePreventionTZ IS NOT NULL THEN
  IF NOT (LOWER((prev_klasse_registrering.registrering).timeperiod)=lostUpdatePreventionTZ) THEN
    RAISE EXCEPTION 'Unable to update klasse with uuid [%], as the klasse seems to have been updated since latest read by client (the given lostUpdatePreventionTZ [%] does not match the timesamp of latest registration [%]).',klasse_uuid,lostUpdatePreventionTZ,LOWER((prev_klasse_registrering.registrering).timeperiod) USING ERRCODE = 'MO409';
  END IF;   
END IF;




--handle relationer (relations)

IF relationer IS NOT NULL AND coalesce(array_length(relationer,1),0)=0 THEN
--raise notice 'Skipping relations, as it is explicit set to empty array. Update note [%]',note;
ELSE

  --1) Insert relations given as part of this update
  --2) Insert relations of previous registration, taking overlapping virknings into consideration (using function subtract_tstzrange)

  --Ad 1)



      INSERT INTO klasse_relation (
        klasse_registrering_id,
          virkning,
            rel_maal_uuid,
              rel_maal_urn,
                rel_type,
                  objekt_type
      )
      SELECT
        new_klasse_registrering.id,
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
   

  FOREACH klasse_relation_navn in array  ARRAY['ejer'::KlasseRelationKode,'ansvarlig'::KlasseRelationKode,'overordnetklasse'::KlasseRelationKode,'facet'::KlasseRelationKode]::KlasseRelationKode[]
  LOOP

    INSERT INTO klasse_relation (
        klasse_registrering_id,
          virkning,
            rel_maal_uuid,
              rel_maal_urn,
                rel_type,
                  objekt_type
      )
    SELECT 
        new_klasse_registrering.id, 
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
      FROM klasse_relation b
      WHERE 
            b.klasse_registrering_id=new_klasse_registrering.id
            and
            b.rel_type=klasse_relation_navn
    ) d
    JOIN klasse_relation a ON true
    JOIN unnest(_subtract_tstzrange_arr((a.virkning).TimePeriod,tzranges_of_new_reg)) as c(tz_range_leftover) on true
    WHERE a.klasse_registrering_id=prev_klasse_registrering.id 
          and a.rel_type=klasse_relation_navn 
    ;
  END LOOP;

  /**********************/
  -- 0..n relations

  --We only have to check if there are any of the relations with the given name present in the new registration, otherwise copy the ones from the previous registration


  FOREACH klasse_relation_navn in array ARRAY['redaktoerer'::KlasseRelationKode,'sideordnede'::KlasseRelationKode,'mapninger'::KlasseRelationKode,'tilfoejelser'::KlasseRelationKode,'erstatter'::KlasseRelationKode,'lovligekombinationer'::KlasseRelationKode]::KlasseRelationKode[]
  LOOP

    IF NOT EXISTS  (SELECT 1 FROM klasse_relation WHERE klasse_registrering_id=new_klasse_registrering.id and rel_type=klasse_relation_navn) THEN

      INSERT INTO klasse_relation (
            klasse_registrering_id,
              virkning,
                rel_maal_uuid,
                  rel_maal_urn,
                    rel_type,
                      objekt_type
          )
      SELECT 
            new_klasse_registrering.id,
              virkning,
                rel_maal_uuid,
                  rel_maal_urn,
                    rel_type,
                      objekt_type
      FROM klasse_relation
      WHERE klasse_registrering_id=prev_klasse_registrering.id 
      and rel_type=klasse_relation_navn 
      ;

    END IF;
              
  END LOOP;


/**********************/


END IF;
/**********************/
-- handle tilstande (states)

IF tilsPubliceret IS NOT NULL AND coalesce(array_length(tilsPubliceret,1),0)=0 THEN
--raise debug 'Skipping [Publiceret] as it is explicit set to empty array';
ELSE
  --1) Insert tilstande/states given as part of this update
  --2) Insert tilstande/states of previous registration, taking overlapping virknings into consideration (using function subtract_tstzrange)

  /********************************************/
  --klasse_tils_publiceret
  /********************************************/

  --Ad 1)

  INSERT INTO klasse_tils_publiceret (
          virkning,
            publiceret,
              klasse_registrering_id
  ) 
  SELECT
          a.virkning,
            a.publiceret,
              new_klasse_registrering.id
  FROM
  unnest(tilsPubliceret) as a
  ;
   

  --Ad 2

  INSERT INTO klasse_tils_publiceret (
          virkning,
            publiceret,
              klasse_registrering_id
  )
  SELECT 
          ROW(
            c.tz_range_leftover,
              (a.virkning).AktoerRef,
              (a.virkning).AktoerTypeKode,
              (a.virkning).NoteTekst
          ) :: virkning,
            a.publiceret,
              new_klasse_registrering.id
  FROM
  (
   --build an array of the timeperiod of the virkning of the klasse_tils_publiceret of the new registrering to pass to _subtract_tstzrange_arr on the klasse_tils_publiceret of the previous registrering 
      SELECT coalesce(array_agg((b.virkning).TimePeriod),array[]::TSTZRANGE[]) tzranges_of_new_reg
      FROM klasse_tils_publiceret b
      WHERE 
            b.klasse_registrering_id=new_klasse_registrering.id
  ) d
    JOIN klasse_tils_publiceret a ON true  
    JOIN unnest(_subtract_tstzrange_arr((a.virkning).TimePeriod,tzranges_of_new_reg)) as c(tz_range_leftover) on true
    WHERE a.klasse_registrering_id=prev_klasse_registrering.id     
  ;


/**********************/

END IF;


/**********************/
--Handle attributter (attributes) 

/********************************************/
--klasse_attr_egenskaber
/********************************************/

--Generate and insert any merged objects, if any fields are null in attrKlasseObj
IF attrEgenskaber IS NOT null THEN

  --Input validation: 
  --Verify that there is no overlap in virkning in the array given

  IF EXISTS (
  SELECT
  a.*
  FROM unnest(attrEgenskaber) a
  JOIN  unnest(attrEgenskaber) b on (a.virkning).TimePeriod && (b.virkning).TimePeriod
  GROUP BY a.brugervendtnoegle,a.beskrivelse,a.eksempel,a.omfang,a.titel,a.retskilde,a.aendringsnotat, a.virkning, a.soegeord
  HAVING COUNT(*)>1
  ) THEN
  RAISE EXCEPTION 'Unable to update klasse with uuid [%], as the klasse have overlapping virknings in the given egenskaber array :%',klasse_uuid,to_json(attrEgenskaber)  USING ERRCODE = 'MO400';

  END IF;


  FOREACH attrEgenskaberObj in array attrEgenskaber
  LOOP

  --To avoid needless fragmentation we'll check for presence of null values in the fields - and if none are present, we'll skip the merging operations
  IF (attrEgenskaberObj).brugervendtnoegle is null OR 
   (attrEgenskaberObj).beskrivelse is null OR 
   (attrEgenskaberObj).eksempel is null OR 
   (attrEgenskaberObj).omfang is null OR 
   (attrEgenskaberObj).titel is null OR 
   (attrEgenskaberObj).retskilde is null OR 
   (attrEgenskaberObj).aendringsnotat is null 
  THEN

WITH inserted_merged_attr_egenskaber AS (
  INSERT INTO
  klasse_attr_egenskaber
  (
    id,brugervendtnoegle,beskrivelse,eksempel,omfang,titel,retskilde,aendringsnotat
    ,virkning
    ,klasse_registrering_id
  )
  SELECT 
    nextval('klasse_attr_egenskaber_id_seq'),
    coalesce(attrEgenskaberObj.brugervendtnoegle,a.brugervendtnoegle),
    coalesce(attrEgenskaberObj.beskrivelse,a.beskrivelse),
    coalesce(attrEgenskaberObj.eksempel,a.eksempel),
    coalesce(attrEgenskaberObj.omfang,a.omfang),
    coalesce(attrEgenskaberObj.titel,a.titel),
    coalesce(attrEgenskaberObj.retskilde,a.retskilde),
    coalesce(attrEgenskaberObj.aendringsnotat,a.aendringsnotat),
	ROW (
	  (a.virkning).TimePeriod * (attrEgenskaberObj.virkning).TimePeriod,
	  (attrEgenskaberObj.virkning).AktoerRef,
	  (attrEgenskaberObj.virkning).AktoerTypeKode,
	  (attrEgenskaberObj.virkning).NoteTekst
	)::Virkning,
    new_klasse_registrering.id
  FROM klasse_attr_egenskaber a
  WHERE
    a.klasse_registrering_id=prev_klasse_registrering.id 
    and (a.virkning).TimePeriod && (attrEgenskaberObj.virkning).TimePeriod
    RETURNING id new_id,(virkning).TimePeriod merged_timeperiod
)
INSERT INTO 
klasse_attr_egenskaber_soegeord 
(soegeordidentifikator,beskrivelse,soegeordskategori,klasse_attr_egenskaber_id)
SELECT
  coalesce(b.soegeordidentifikator,c.soegeordidentifikator), --please notice that this is not a merge - one of the joins on b or c will fail.
  coalesce(b.beskrivelse,c.beskrivelse),--please notice that this is not a merge - one of the joins on b or c will fail.
  coalesce(b.soegeordskategori,c.soegeordskategori),--please notice that this is not a merge - one of the joins on b or c will fail.
  a.new_id
FROM inserted_merged_attr_egenskaber a
LEFT JOIN unnest(attrEgenskaberObj.soegeord) as b(soegeordidentifikator,beskrivelse,soegeordskategori) on attrEgenskaberObj.soegeord IS NOT NULL
LEFT JOIN klasse_attr_egenskaber as b2 on attrEgenskaberObj.soegeord IS NULL and b2.klasse_registrering_id=prev_klasse_registrering.id and (b2.virkning).TimePeriod @> a.merged_timeperiod --Please notice, that this will max hit exactly one row - the row that the new id was merged with
LEFT JOIN klasse_attr_egenskaber_soegeord as c on attrEgenskaberObj.soegeord IS NULL AND c.klasse_attr_egenskaber_id = b2.id
WHERE 
  (
    (attrEgenskaberObj.soegeord IS NULL and c.id is not null) --there is sogeord of merged egenskab
    or
    coalesce(array_length(attrEgenskaberObj.soegeord,1),0)>0   --soegeord is defined in array 
  )
  and
  (NOT (attrEgenskaberObj.soegeord IS NOT NULL AND array_length(attrEgenskaberObj.soegeord,1)=0)) --if the array is empty, no sogeord should be inserted  

;

  --For any periods within the virkning of the attrEgenskaberObj, that is NOT covered by any "merged" rows inserted above, generate and insert rows

WITH inserted_attr_egenskaber AS (
  INSERT INTO
  klasse_attr_egenskaber
  (
    id,brugervendtnoegle,beskrivelse,eksempel,omfang,titel,retskilde,aendringsnotat
    ,virkning
    ,klasse_registrering_id
  )
  SELECT 
    nextval('klasse_attr_egenskaber_id_seq'),
    attrEgenskaberObj.brugervendtnoegle, 
    attrEgenskaberObj.beskrivelse, 
    attrEgenskaberObj.eksempel, 
    attrEgenskaberObj.omfang, 
    attrEgenskaberObj.titel, 
    attrEgenskaberObj.retskilde, 
    attrEgenskaberObj.aendringsnotat,
	  ROW (
	       b.tz_range_leftover,
	      (attrEgenskaberObj.virkning).AktoerRef,
	      (attrEgenskaberObj.virkning).AktoerTypeKode,
	      (attrEgenskaberObj.virkning).NoteTekst
	  )::Virkning,
    new_klasse_registrering.id
  FROM
  (
  --build an array of the timeperiod of the virkning of the klasse_attr_egenskaber of the new registrering to pass to _subtract_tstzrange_arr 
      SELECT coalesce(array_agg((b.virkning).TimePeriod),array[]::TSTZRANGE[]) tzranges_of_new_reg
      FROM klasse_attr_egenskaber b
      WHERE 
       b.klasse_registrering_id=new_klasse_registrering.id
  ) as a
  JOIN unnest(_subtract_tstzrange_arr((attrEgenskaberObj.virkning).TimePeriod,a.tzranges_of_new_reg)) as b(tz_range_leftover) on true
  RETURNING id
  )
INSERT INTO 
klasse_attr_egenskaber_soegeord 
(soegeordidentifikator,beskrivelse,soegeordskategori,klasse_attr_egenskaber_id)
SELECT
a.soegeordidentifikator,a.beskrivelse,a.soegeordskategori,b.id
FROM
unnest(attrEgenskaberObj.soegeord) as a(soegeordidentifikator,beskrivelse,soegeordskategori)
JOIN inserted_attr_egenskaber b on true
;



  ELSE
    --insert attrEgenskaberObj raw (if there were no null-valued fields) 

    new_id_klasse_attr_egenskaber:=nextval('klasse_attr_egenskaber_id_seq');

    INSERT INTO
    klasse_attr_egenskaber
    (
    id,brugervendtnoegle,beskrivelse,eksempel,omfang,titel,retskilde,aendringsnotat
    ,virkning
    ,klasse_registrering_id
    )
    VALUES ( 
    new_id_klasse_attr_egenskaber,
    attrEgenskaberObj.brugervendtnoegle, 
    attrEgenskaberObj.beskrivelse, 
    attrEgenskaberObj.eksempel, 
    attrEgenskaberObj.omfang, 
    attrEgenskaberObj.titel, 
    attrEgenskaberObj.retskilde, 
    attrEgenskaberObj.aendringsnotat,
    attrEgenskaberObj.virkning,
    new_klasse_registrering.id
    )
    ;
   
    IF attrEgenskaberObj.soegeord IS NOT NULL THEN
    INSERT INTO klasse_attr_egenskaber_soegeord( 
          soegeordidentifikator,
          beskrivelse,
          soegeordskategori,
          klasse_attr_egenskaber_id
          )
    SELECT
    a.soegeordidentifikator,
    a.beskrivelse,
    a.soegeordskategori,
    new_id_klasse_attr_egenskaber
    FROM
    unnest(attrEgenskaberObj.soegeord) as a(soegeordidentifikator,beskrivelse,soegeordskategori)
    ;
    END IF;


  END IF;

  END LOOP;
END IF;


IF attrEgenskaber IS NOT NULL AND coalesce(array_length(attrEgenskaber,1),0)=0 THEN
--raise debug 'Skipping handling of egenskaber of previous registration as an empty array was explicit given.';  
ELSE 

--Handle egenskaber of previous registration, taking overlapping virknings into consideration (using function subtract_tstzrange)


WITH copied_attr_egenskaber AS (
INSERT INTO klasse_attr_egenskaber (
    id,brugervendtnoegle,beskrivelse,eksempel,omfang,titel,retskilde,aendringsnotat
    ,virkning
    ,klasse_registrering_id
)
SELECT
      nextval('klasse_attr_egenskaber_id_seq'),
      a.brugervendtnoegle,
      a.beskrivelse,
      a.eksempel,
      a.omfang,
      a.titel,
      a.retskilde,
      a.aendringsnotat,
	  ROW(
	    c.tz_range_leftover,
	      (a.virkning).AktoerRef,
	      (a.virkning).AktoerTypeKode,
	      (a.virkning).NoteTekst
	  ) :: virkning,
	 new_klasse_registrering.id
FROM
(
 --build an array of the timeperiod of the virkning of the klasse_attr_egenskaber of the new registrering to pass to _subtract_tstzrange_arr on the klasse_attr_egenskaber of the previous registrering 
    SELECT coalesce(array_agg((b.virkning).TimePeriod),array[]::TSTZRANGE[]) tzranges_of_new_reg
    FROM klasse_attr_egenskaber b
    WHERE 
          b.klasse_registrering_id=new_klasse_registrering.id
) d
  JOIN klasse_attr_egenskaber a ON true  
  JOIN unnest(_subtract_tstzrange_arr((a.virkning).TimePeriod,tzranges_of_new_reg)) as c(tz_range_leftover) on true
  WHERE a.klasse_registrering_id=prev_klasse_registrering.id 
  RETURNING id new_id,(virkning).TimePeriod  
)
INSERT INTO 
klasse_attr_egenskaber_soegeord 
(soegeordidentifikator,beskrivelse,soegeordskategori,klasse_attr_egenskaber_id)
SELECT
b.soegeordidentifikator,b.beskrivelse,b.soegeordskategori,a.new_id
FROM copied_attr_egenskaber a
JOIN klasse_attr_egenskaber a2 on a2.klasse_registrering_id=prev_klasse_registrering.id and (a2.virkning).TimePeriod @> a.TimePeriod --this will hit exactly one row - that is, the row that we copied. 
JOIN klasse_attr_egenskaber_soegeord b on a2.id=b.klasse_attr_egenskaber_id   
;





END IF;


/******************************************************************/
--If the new registrering is identical to the previous one, we need to throw an exception to abort the transaction. 

read_new_klasse:=as_read_klasse(klasse_uuid, (new_klasse_registrering.registrering).timeperiod,null);
read_prev_klasse:=as_read_klasse(klasse_uuid, (prev_klasse_registrering.registrering).timeperiod ,null);
 
--the ordering in as_list (called by as_read) ensures that the latest registration is returned at index pos 1

IF NOT (lower((read_new_klasse.registrering[1].registrering).TimePeriod)=lower((new_klasse_registrering.registrering).TimePeriod) AND lower((read_prev_klasse.registrering[1].registrering).TimePeriod)=lower((prev_klasse_registrering.registrering).TimePeriod)) THEN
  RAISE EXCEPTION 'Error updating klasse with id [%]: The ordering of as_list_klasse should ensure that the latest registrering can be found at index 1. Expected new reg: [%]. Actual new reg at index 1: [%]. Expected prev reg: [%]. Actual prev reg at index 1: [%].',klasse_uuid,to_json(new_klasse_registrering),to_json(read_new_klasse.registrering[1].registrering),to_json(prev_klasse_registrering),to_json(prev_new_klasse.registrering[1].registrering) USING ERRCODE = 'MO500';
END IF;
 
 --we'll ignore the registreringBase part in the comparrison - except for the livcykluskode

read_new_klasse_reg:=ROW(
ROW(null,(read_new_klasse.registrering[1].registrering).livscykluskode,null,null)::registreringBase,
(read_new_klasse.registrering[1]).tilsPubliceret ,
(read_new_klasse.registrering[1]).attrEgenskaber ,
(read_new_klasse.registrering[1]).relationer 
)::klasseRegistreringType
;

read_prev_klasse_reg:=ROW(
ROW(null,(read_prev_klasse.registrering[1].registrering).livscykluskode,null,null)::registreringBase,
(read_prev_klasse.registrering[1]).tilsPubliceret ,
(read_prev_klasse.registrering[1]).attrEgenskaber ,
(read_prev_klasse.registrering[1]).relationer 
)::klasseRegistreringType
;


IF read_prev_klasse_reg=read_new_klasse_reg THEN
  --RAISE NOTICE 'Note[%]. Aborted reg:%',note,to_json(read_new_klasse_reg);
  --RAISE NOTICE 'Note[%]. Previous reg:%',note,to_json(read_prev_klasse_reg);
  RAISE EXCEPTION 'Aborted updating klasse with id [%] as the given data, does not give raise to a new registration. Aborted reg:[%], previous reg:[%]',klasse_uuid,to_json(read_new_klasse_reg),to_json(read_prev_klasse_reg) USING ERRCODE = 'MO400';
END IF;

/******************************************************************/

PERFORM actual_state._amqp_publish_notification('Klasse', livscykluskode, klasse_uuid);

return new_klasse_registrering.id;



END;
$$ LANGUAGE plpgsql VOLATILE;





