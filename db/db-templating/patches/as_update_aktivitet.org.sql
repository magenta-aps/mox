-- Copyright (C) 2015 Magenta ApS, http://magenta.dk.
-- Contact: info@magenta.dk.
--
-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at http://mozilla.org/MPL/2.0/.

/*
NOTICE: This file is auto-generated using the script: apply-template.py aktivitet as_update.jinja.sql
*/




--Also notice, that the given arrays of AktivitetAttr...Type must be consistent regarding virkning (although the allowance of null-values might make it possible to construct 'logically consistent'-arrays of objects with overlapping virknings)

CREATE OR REPLACE FUNCTION as_update_aktivitet(
  aktivitet_uuid uuid,
  brugerref uuid,
  note text,
  livscykluskode Livscykluskode,           
  attrEgenskaber AktivitetEgenskaberAttrType[],
  tilsStatus AktivitetStatusTilsType[],
  tilsPubliceret AktivitetPubliceretTilsType[],
  relationer AktivitetRelationType[],
  lostUpdatePreventionTZ TIMESTAMPTZ = null,
  auth_criteria_arr AktivitetRegistreringType[]=null
	)
  RETURNS bigint AS 
$$
DECLARE
  read_new_aktivitet AktivitetType;
  read_prev_aktivitet AktivitetType;
  read_new_aktivitet_reg AktivitetRegistreringType;
  read_prev_aktivitet_reg AktivitetRegistreringType;
  new_aktivitet_registrering aktivitet_registrering;
  prev_aktivitet_registrering aktivitet_registrering;
  aktivitet_relation_navn AktivitetRelationKode;
  attrEgenskaberObj AktivitetEgenskaberAttrType;
  auth_filtered_uuids uuid[];
  rel_type_max_index_prev_rev int;
  rel_type_max_index_arr _aktivitetRelationMaxIndex[];
  aktivitet_rel_type_cardinality_unlimited aktivitetRelationKode[]:=ARRAY['udfoererklasse'::AktivitetRelationKode,'deltagerklasse'::AktivitetRelationKode,'objektklasse'::AktivitetRelationKode,'resultatklasse'::AktivitetRelationKode,'grundlagklasse'::AktivitetRelationKode,'facilitetklasse'::AktivitetRelationKode,'adresse'::AktivitetRelationKode,'geoobjekt'::AktivitetRelationKode,'position'::AktivitetRelationKode,'facilitet'::AktivitetRelationKode,'lokale'::AktivitetRelationKode,'aktivitetdokument'::AktivitetRelationKode,'aktivitetgrundlag'::AktivitetRelationKode,'aktivitetresultat'::AktivitetRelationKode,'udfoerer'::AktivitetRelationKode,'deltager'::AktivitetRelationKode]::aktivitetRelationKode[];
  aktivitet_uuid_underscores text;
  aktivitet_rel_seq_name text;
  aktivitet_rel_type_cardinality_unlimited_present_in_argument aktivitetRelationKode[];
BEGIN

--create a new registrering

IF NOT EXISTS (select a.id from aktivitet a join aktivitet_registrering b on b.aktivitet_id=a.id  where a.id=aktivitet_uuid) THEN
   RAISE EXCEPTION 'Unable to update aktivitet with uuid [%], being unable to find any previous registrations.',aktivitet_uuid USING ERRCODE = 'MO400';
END IF;

PERFORM a.id FROM aktivitet a
WHERE a.id=aktivitet_uuid
FOR UPDATE; --We synchronize concurrent invocations of as_updates of this particular object on a exclusive row lock. This lock will be held by the current transaction until it terminates.

/*** Verify that the object meets the stipulated access allowed criteria  ***/
auth_filtered_uuids:=_as_filter_unauth_aktivitet(array[aktivitet_uuid]::uuid[],auth_criteria_arr); 
IF NOT (coalesce(array_length(auth_filtered_uuids,1),0)=1 AND auth_filtered_uuids @>ARRAY[aktivitet_uuid]) THEN
  RAISE EXCEPTION 'Unable to update aktivitet with uuid [%]. Object does not met stipulated criteria:%',aktivitet_uuid,to_json(auth_criteria_arr)  USING ERRCODE = 'MO401'; 
END IF;
/*********************/


new_aktivitet_registrering := _as_create_aktivitet_registrering(aktivitet_uuid,livscykluskode, brugerref, note);
prev_aktivitet_registrering := _as_get_prev_aktivitet_registrering(new_aktivitet_registrering);

IF lostUpdatePreventionTZ IS NOT NULL THEN
  IF NOT (LOWER((prev_aktivitet_registrering.registrering).timeperiod)=lostUpdatePreventionTZ) THEN
    RAISE EXCEPTION 'Unable to update aktivitet with uuid [%], as the aktivitet seems to have been updated since latest read by client (the given lostUpdatePreventionTZ [%] does not match the timesamp of latest registration [%]).',aktivitet_uuid,lostUpdatePreventionTZ,LOWER((prev_aktivitet_registrering.registrering).timeperiod) USING ERRCODE = 'MO409';
  END IF;   
END IF;



--handle relationer (relations)

IF relationer IS NOT NULL AND coalesce(array_length(relationer,1),0)=0 THEN
--raise notice 'Skipping relations, as it is explicit set to empty array. Update note [%]',note;
ELSE

  --1) Insert relations given as part of this update
  --2) Insert relations of previous registration, with index values not included in this update. Please notice that for the logic to work,
  --  it is very important that the index sequences start with the max value for index of the same type in the previous registration

  --Ad 1)

--build array with the max index values of the different types of relations of the previous registration
SELECT array_agg(rel_type_max_index)::_aktivitetRelationMaxIndex[] into rel_type_max_index_arr
FROM
(
  SELECT
  (ROW(rel_type,coalesce(max(rel_index),0))::_aktivitetRelationMaxIndex) rel_type_max_index  
  FROM aktivitet_relation a
  where a.aktivitet_registrering_id=prev_aktivitet_registrering.id
  and a.rel_type = any (aktivitet_rel_type_cardinality_unlimited)
  group by rel_type
) as a
;


--Create temporary sequences
aktivitet_uuid_underscores:=replace(aktivitet_uuid::text, '-', '_');

SELECT array_agg( DISTINCT a.RelType) into aktivitet_rel_type_cardinality_unlimited_present_in_argument FROM  unnest(relationer) a WHERE a.RelType = any (aktivitet_rel_type_cardinality_unlimited) ;
IF coalesce(array_length(aktivitet_rel_type_cardinality_unlimited_present_in_argument,1),0)>0 THEN
FOREACH aktivitet_relation_navn IN ARRAY (aktivitet_rel_type_cardinality_unlimited_present_in_argument)
  LOOP
  aktivitet_rel_seq_name := 'aktivitet_' || aktivitet_relation_navn::text || aktivitet_uuid_underscores;

  rel_type_max_index_prev_rev:=null;

  SELECT 
    a.indeks into rel_type_max_index_prev_rev
  FROM
    unnest(rel_type_max_index_arr) a(relType,indeks)
  WHERE
    a.relType=aktivitet_relation_navn
  ;
  
  IF rel_type_max_index_prev_rev IS NULL THEN
    rel_type_max_index_prev_rev:=0;
  END IF;

  EXECUTE 'CREATE TEMPORARY SEQUENCE ' || aktivitet_rel_seq_name || '
  INCREMENT 1
  MINVALUE 1
  MAXVALUE 9223372036854775807
  START ' ||  (rel_type_max_index_prev_rev+1)::text ||'
  CACHE 1;';

END LOOP;
END IF;

      INSERT INTO aktivitet_relation (
        aktivitet_registrering_id,
          virkning,
            rel_maal_uuid,
              rel_maal_urn,
                rel_type,
                  objekt_type,
                    rel_index,
                      aktoer_attr
      )
      SELECT
        new_aktivitet_registrering.id,
          a.virkning,
            a.uuid,
              a.urn,
                a.relType,
                  a.objektType,
                    CASE 
                    WHEN a.relType = any (aktivitet_rel_type_cardinality_unlimited) THEN
                      CASE WHEN a.indeks IS NULL OR b.id IS NULL THEN --for new relations and relations with index given that is not found in prev registrering, we'll assign new index values 
                        nextval('aktivitet_' || a.relType::text || aktivitet_uuid_underscores)
                      ELSE
                        a.indeks
                      END
                    ELSE
                    NULL
                    END,
                    CASE 
                  WHEN a.relType =('udfoerer'::AktivitetRelationKode)  OR rel_type=('deltager'::AktivitetRelationKode) OR rel_type=('ansvarlig'::AktivitetRelationKode) 
                  AND NOT (a.aktoerAttr IS NULL)
                  AND (
                    (a.aktoerAttr).obligatorisk IS NOT NULL
                    OR
                    (a.aktoerAttr).accepteret IS NOT NULL
                    OR
                      (
                        (a.aktoerAttr).repraesentation_uuid IS NOT NULL
                        OR
                        ((a.aktoerAttr).repraesentation_urn IS NOT NULL AND (a.aktoerAttr).repraesentation_urn<>'')
                      )
                    ) 
                  THEN a.aktoerAttr
                  ELSE
                  NULL
                END
      FROM unnest(relationer) as a
      LEFT JOIN aktivitet_relation b on a.relType = any (aktivitet_rel_type_cardinality_unlimited) and b.aktivitet_registrering_id=prev_aktivitet_registrering.id and a.relType=b.rel_type and a.indeks=b.rel_index
    ;


--Drop temporary sequences
IF coalesce(array_length(aktivitet_rel_type_cardinality_unlimited_present_in_argument,1),0)>0 THEN
FOREACH aktivitet_relation_navn IN ARRAY (aktivitet_rel_type_cardinality_unlimited_present_in_argument)
  LOOP
  aktivitet_rel_seq_name := 'aktivitet_' || aktivitet_relation_navn::text || aktivitet_uuid_underscores;
  EXECUTE 'DROP  SEQUENCE ' || aktivitet_rel_seq_name || ';';
END LOOP;
END IF;

  --Ad 2)

  /**********************/
  -- 0..1 relations 
  --Please notice, that for 0..1 relations for aktivitet, we're ignoring index here, and handling it the same way, that is done for other object types (like Facet, Klasse etc). That is, you only make changes for the virkningsperiod that you explicitly specify (unless you delete all relations) 

  FOREACH aktivitet_relation_navn in array ARRAY['aktivitetstype'::AktivitetRelationKode,'emne'::AktivitetRelationKode,'foelsomhedklasse'::AktivitetRelationKode,'ansvarligklasse'::AktivitetRelationKode,'rekvirentklasse'::AktivitetRelationKode,'ansvarlig'::AktivitetRelationKode,'tilhoerer'::AktivitetRelationKode]::AktivitetRelationKode[]
  LOOP

    INSERT INTO aktivitet_relation (
        aktivitet_registrering_id,
          virkning,
            rel_maal_uuid,
              rel_maal_urn,
                rel_type,
                  objekt_type,
                    rel_index,
                      aktoer_attr

      )
    SELECT 
        new_aktivitet_registrering.id, 
          ROW(
            c.tz_range_leftover,
              (a.virkning).AktoerRef,
              (a.virkning).AktoerTypeKode,
              (a.virkning).NoteTekst
          ) :: virkning,
            a.rel_maal_uuid,
              a.rel_maal_urn,
                a.rel_type,
                  a.objekt_type,
                    NULL,--a.rel_index, rel_index is not to be used for 0..1 relations     
                      a.aktoer_attr
    FROM
    (
      --build an array of the timeperiod of the virkning of the relations of the new registrering to pass to _subtract_tstzrange_arr on the relations of the previous registrering 
      SELECT coalesce(array_agg((b.virkning).TimePeriod),array[]::TSTZRANGE[]) tzranges_of_new_reg
      FROM aktivitet_relation b
      WHERE 
            b.aktivitet_registrering_id=new_aktivitet_registrering.id
            and
            b.rel_type=aktivitet_relation_navn
    ) d
    JOIN aktivitet_relation a ON true
    JOIN unnest(_subtract_tstzrange_arr((a.virkning).TimePeriod,tzranges_of_new_reg)) as c(tz_range_leftover) on true
    WHERE a.aktivitet_registrering_id=prev_aktivitet_registrering.id 
          and a.rel_type=aktivitet_relation_navn 
    ;
  END LOOP;

  /**********************/
  -- 0..n relations
  
      INSERT INTO aktivitet_relation (
            aktivitet_registrering_id,
              virkning,
                rel_maal_uuid,
                  rel_maal_urn,
                    rel_type,
                      objekt_type,
                        rel_index,
                          aktoer_attr
          )
      SELECT 
            new_aktivitet_registrering.id,
              a.virkning,
                a.rel_maal_uuid,
                  a.rel_maal_urn,
                    a.rel_type,
                      a.objekt_type,
                        a.rel_index,
                          a.aktoer_attr
      FROM aktivitet_relation a
      LEFT JOIN aktivitet_relation b on b.aktivitet_registrering_id=new_aktivitet_registrering.id and b.rel_type=a.rel_type and b.rel_index=a.rel_index
      WHERE a.aktivitet_registrering_id=prev_aktivitet_registrering.id 
      and a.rel_type = any (aktivitet_rel_type_cardinality_unlimited)
      and b.id is null --don't transfer relations of prev. registrering, if the index was specified in data given to the/this update-function
      ;

/**********************/


END IF;
/**********************/
-- handle tilstande (states)

IF tilsStatus IS NOT NULL AND coalesce(array_length(tilsStatus,1),0)=0 THEN
--raise debug 'Skipping [Status] as it is explicit set to empty array';
ELSE
  --1) Insert tilstande/states given as part of this update
  --2) Insert tilstande/states of previous registration, taking overlapping virknings into consideration (using function subtract_tstzrange)

  /********************************************/
  --aktivitet_tils_status
  /********************************************/

  --Ad 1)

  INSERT INTO aktivitet_tils_status (
          virkning,
            status,
              aktivitet_registrering_id
  ) 
  SELECT
          a.virkning,
            a.status,
              new_aktivitet_registrering.id
  FROM
  unnest(tilsStatus) as a
  ;
   

  --Ad 2

  INSERT INTO aktivitet_tils_status (
          virkning,
            status,
              aktivitet_registrering_id
  )
  SELECT 
          ROW(
            c.tz_range_leftover,
              (a.virkning).AktoerRef,
              (a.virkning).AktoerTypeKode,
              (a.virkning).NoteTekst
          ) :: virkning,
            a.status,
              new_aktivitet_registrering.id
  FROM
  (
   --build an array of the timeperiod of the virkning of the aktivitet_tils_status of the new registrering to pass to _subtract_tstzrange_arr on the aktivitet_tils_status of the previous registrering 
      SELECT coalesce(array_agg((b.virkning).TimePeriod),array[]::TSTZRANGE[]) tzranges_of_new_reg
      FROM aktivitet_tils_status b
      WHERE 
            b.aktivitet_registrering_id=new_aktivitet_registrering.id
  ) d
    JOIN aktivitet_tils_status a ON true  
    JOIN unnest(_subtract_tstzrange_arr((a.virkning).TimePeriod,tzranges_of_new_reg)) as c(tz_range_leftover) on true
    WHERE a.aktivitet_registrering_id=prev_aktivitet_registrering.id     
  ;


/**********************/

END IF;



IF tilsPubliceret IS NOT NULL AND coalesce(array_length(tilsPubliceret,1),0)=0 THEN
--raise debug 'Skipping [Publiceret] as it is explicit set to empty array';
ELSE
  --1) Insert tilstande/states given as part of this update
  --2) Insert tilstande/states of previous registration, taking overlapping virknings into consideration (using function subtract_tstzrange)

  /********************************************/
  --aktivitet_tils_publiceret
  /********************************************/

  --Ad 1)

  INSERT INTO aktivitet_tils_publiceret (
          virkning,
            publiceret,
              aktivitet_registrering_id
  ) 
  SELECT
          a.virkning,
            a.publiceret,
              new_aktivitet_registrering.id
  FROM
  unnest(tilsPubliceret) as a
  ;
   

  --Ad 2

  INSERT INTO aktivitet_tils_publiceret (
          virkning,
            publiceret,
              aktivitet_registrering_id
  )
  SELECT 
          ROW(
            c.tz_range_leftover,
              (a.virkning).AktoerRef,
              (a.virkning).AktoerTypeKode,
              (a.virkning).NoteTekst
          ) :: virkning,
            a.publiceret,
              new_aktivitet_registrering.id
  FROM
  (
   --build an array of the timeperiod of the virkning of the aktivitet_tils_publiceret of the new registrering to pass to _subtract_tstzrange_arr on the aktivitet_tils_publiceret of the previous registrering 
      SELECT coalesce(array_agg((b.virkning).TimePeriod),array[]::TSTZRANGE[]) tzranges_of_new_reg
      FROM aktivitet_tils_publiceret b
      WHERE 
            b.aktivitet_registrering_id=new_aktivitet_registrering.id
  ) d
    JOIN aktivitet_tils_publiceret a ON true  
    JOIN unnest(_subtract_tstzrange_arr((a.virkning).TimePeriod,tzranges_of_new_reg)) as c(tz_range_leftover) on true
    WHERE a.aktivitet_registrering_id=prev_aktivitet_registrering.id     
  ;


/**********************/

END IF;


/**********************/
--Handle attributter (attributes) 

/********************************************/
--aktivitet_attr_egenskaber
/********************************************/

--Generate and insert any merged objects, if any fields are null in attrAktivitetObj
IF attrEgenskaber IS NOT null THEN

  --Input validation: 
  --Verify that there is no overlap in virkning in the array given

  IF EXISTS (
  SELECT
  a.*
  FROM unnest(attrEgenskaber) a
  JOIN  unnest(attrEgenskaber) b on (a.virkning).TimePeriod && (b.virkning).TimePeriod
  GROUP BY a.brugervendtnoegle,a.aktivitetnavn,a.beskrivelse,a.starttidspunkt,a.sluttidspunkt,a.tidsforbrug,a.formaal, a.virkning
  HAVING COUNT(*)>1
  ) THEN
  RAISE EXCEPTION 'Unable to update aktivitet with uuid [%], as the aktivitet have overlapping virknings in the given egenskaber array :%',aktivitet_uuid,to_json(attrEgenskaber)  USING ERRCODE = 'MO400';

  END IF;


  FOREACH attrEgenskaberObj in array attrEgenskaber
  LOOP

  --To avoid needless fragmentation we'll check for presence of null values in the fields - and if none are present, we'll skip the merging operations
  IF (attrEgenskaberObj).brugervendtnoegle is null OR 
   (attrEgenskaberObj).aktivitetnavn is null OR 
   (attrEgenskaberObj).beskrivelse is null OR 
   (attrEgenskaberObj).starttidspunkt is null OR 
   (attrEgenskaberObj).sluttidspunkt is null OR 
   (attrEgenskaberObj).tidsforbrug is null OR 
   (attrEgenskaberObj).formaal is null 
  THEN

  INSERT INTO
  aktivitet_attr_egenskaber
  (
    brugervendtnoegle,aktivitetnavn,beskrivelse,starttidspunkt,sluttidspunkt,tidsforbrug,formaal
    ,virkning
    ,aktivitet_registrering_id
  )
  SELECT
    coalesce(attrEgenskaberObj.brugervendtnoegle,a.brugervendtnoegle),
    coalesce(attrEgenskaberObj.aktivitetnavn,a.aktivitetnavn),
    coalesce(attrEgenskaberObj.beskrivelse,a.beskrivelse),
    CASE WHEN ((attrEgenskaberObj.starttidspunkt).cleared) THEN NULL 
        ELSE coalesce((attrEgenskaberObj.starttidspunkt).value,a.starttidspunkt)
        END,
    CASE WHEN ((attrEgenskaberObj.sluttidspunkt).cleared) THEN NULL 
        ELSE coalesce((attrEgenskaberObj.sluttidspunkt).value,a.sluttidspunkt)
        END,
    CASE WHEN ((attrEgenskaberObj.tidsforbrug).cleared) THEN NULL 
        ELSE coalesce((attrEgenskaberObj.tidsforbrug).value,a.tidsforbrug)
        END,
    coalesce(attrEgenskaberObj.formaal,a.formaal),
	ROW (
	  (a.virkning).TimePeriod * (attrEgenskaberObj.virkning).TimePeriod,
	  (attrEgenskaberObj.virkning).AktoerRef,
	  (attrEgenskaberObj.virkning).AktoerTypeKode,
	  (attrEgenskaberObj.virkning).NoteTekst
	)::Virkning,
    new_aktivitet_registrering.id
  FROM aktivitet_attr_egenskaber a
  WHERE
    a.aktivitet_registrering_id=prev_aktivitet_registrering.id 
    and (a.virkning).TimePeriod && (attrEgenskaberObj.virkning).TimePeriod
  ;

  --For any periods within the virkning of the attrEgenskaberObj, that is NOT covered by any "merged" rows inserted above, generate and insert rows

  INSERT INTO
  aktivitet_attr_egenskaber
  (
    brugervendtnoegle,aktivitetnavn,beskrivelse,starttidspunkt,sluttidspunkt,tidsforbrug,formaal
    ,virkning
    ,aktivitet_registrering_id
  )
  SELECT 
    attrEgenskaberObj.brugervendtnoegle, 
    attrEgenskaberObj.aktivitetnavn, 
    attrEgenskaberObj.beskrivelse, 
    attrEgenskaberObj.starttidspunkt, 
    attrEgenskaberObj.sluttidspunkt, 
    attrEgenskaberObj.tidsforbrug, 
    attrEgenskaberObj.formaal,
	  ROW (
	       b.tz_range_leftover,
	      (attrEgenskaberObj.virkning).AktoerRef,
	      (attrEgenskaberObj.virkning).AktoerTypeKode,
	      (attrEgenskaberObj.virkning).NoteTekst
	  )::Virkning,
    new_aktivitet_registrering.id
  FROM
  (
  --build an array of the timeperiod of the virkning of the aktivitet_attr_egenskaber of the new registrering to pass to _subtract_tstzrange_arr 
      SELECT coalesce(array_agg((b.virkning).TimePeriod),array[]::TSTZRANGE[]) tzranges_of_new_reg
      FROM aktivitet_attr_egenskaber b
      WHERE 
       b.aktivitet_registrering_id=new_aktivitet_registrering.id
  ) as a
  JOIN unnest(_subtract_tstzrange_arr((attrEgenskaberObj.virkning).TimePeriod,a.tzranges_of_new_reg)) as b(tz_range_leftover) on true
  ;

  ELSE
    --insert attrEgenskaberObj raw (if there were no null-valued fields) 

    INSERT INTO
    aktivitet_attr_egenskaber
    (
    brugervendtnoegle,aktivitetnavn,beskrivelse,starttidspunkt,sluttidspunkt,tidsforbrug,formaal
    ,virkning
    ,aktivitet_registrering_id
    )
    VALUES ( 
    attrEgenskaberObj.brugervendtnoegle, 
    attrEgenskaberObj.aktivitetnavn, 
    attrEgenskaberObj.beskrivelse, 
    attrEgenskaberObj.starttidspunkt, 
    attrEgenskaberObj.sluttidspunkt, 
    attrEgenskaberObj.tidsforbrug, 
    attrEgenskaberObj.formaal,
    attrEgenskaberObj.virkning,
    new_aktivitet_registrering.id
    );

  END IF;

  END LOOP;
END IF;


IF attrEgenskaber IS NOT NULL AND coalesce(array_length(attrEgenskaber,1),0)=0 THEN
--raise debug 'Skipping handling of egenskaber of previous registration as an empty array was explicit given.';  
ELSE 

--Handle egenskaber of previous registration, taking overlapping virknings into consideration (using function subtract_tstzrange)

INSERT INTO aktivitet_attr_egenskaber (
    brugervendtnoegle,aktivitetnavn,beskrivelse,starttidspunkt,sluttidspunkt,tidsforbrug,formaal
    ,virkning
    ,aktivitet_registrering_id
)
SELECT
      a.brugervendtnoegle,
      a.aktivitetnavn,
      a.beskrivelse,
      a.starttidspunkt,
      a.sluttidspunkt,
      a.tidsforbrug,
      a.formaal,
	  ROW(
	    c.tz_range_leftover,
	      (a.virkning).AktoerRef,
	      (a.virkning).AktoerTypeKode,
	      (a.virkning).NoteTekst
	  ) :: virkning,
	 new_aktivitet_registrering.id
FROM
(
 --build an array of the timeperiod of the virkning of the aktivitet_attr_egenskaber of the new registrering to pass to _subtract_tstzrange_arr on the aktivitet_attr_egenskaber of the previous registrering 
    SELECT coalesce(array_agg((b.virkning).TimePeriod),array[]::TSTZRANGE[]) tzranges_of_new_reg
    FROM aktivitet_attr_egenskaber b
    WHERE 
          b.aktivitet_registrering_id=new_aktivitet_registrering.id
) d
  JOIN aktivitet_attr_egenskaber a ON true  
  JOIN unnest(_subtract_tstzrange_arr((a.virkning).TimePeriod,tzranges_of_new_reg)) as c(tz_range_leftover) on true
  WHERE a.aktivitet_registrering_id=prev_aktivitet_registrering.id     
;





END IF;


/******************************************************************/
--If the new registrering is identical to the previous one, we need to throw an exception to abort the transaction. 

read_new_aktivitet:=as_read_aktivitet(aktivitet_uuid, (new_aktivitet_registrering.registrering).timeperiod,null);
read_prev_aktivitet:=as_read_aktivitet(aktivitet_uuid, (prev_aktivitet_registrering.registrering).timeperiod ,null);
 
--the ordering in as_list (called by as_read) ensures that the latest registration is returned at index pos 1

IF NOT (lower((read_new_aktivitet.registrering[1].registrering).TimePeriod)=lower((new_aktivitet_registrering.registrering).TimePeriod) AND lower((read_prev_aktivitet.registrering[1].registrering).TimePeriod)=lower((prev_aktivitet_registrering.registrering).TimePeriod)) THEN
  RAISE EXCEPTION 'Error updating aktivitet with id [%]: The ordering of as_list_aktivitet should ensure that the latest registrering can be found at index 1. Expected new reg: [%]. Actual new reg at index 1: [%]. Expected prev reg: [%]. Actual prev reg at index 1: [%].',aktivitet_uuid,to_json(new_aktivitet_registrering),to_json(read_new_aktivitet.registrering[1].registrering),to_json(prev_aktivitet_registrering),to_json(prev_new_aktivitet.registrering[1].registrering) USING ERRCODE = 'MO500';
END IF;
 
 --we'll ignore the registreringBase part in the comparrison - except for the livcykluskode

read_new_aktivitet_reg:=ROW(
ROW(null,(read_new_aktivitet.registrering[1].registrering).livscykluskode,null,null)::registreringBase,
(read_new_aktivitet.registrering[1]).tilsStatus ,
(read_new_aktivitet.registrering[1]).tilsPubliceret ,
(read_new_aktivitet.registrering[1]).attrEgenskaber ,
(read_new_aktivitet.registrering[1]).relationer 
)::aktivitetRegistreringType
;

read_prev_aktivitet_reg:=ROW(
ROW(null,(read_prev_aktivitet.registrering[1].registrering).livscykluskode,null,null)::registreringBase,
(read_prev_aktivitet.registrering[1]).tilsStatus ,
(read_prev_aktivitet.registrering[1]).tilsPubliceret ,
(read_prev_aktivitet.registrering[1]).attrEgenskaber ,
(read_prev_aktivitet.registrering[1]).relationer 
)::aktivitetRegistreringType
;


IF read_prev_aktivitet_reg=read_new_aktivitet_reg THEN
  --RAISE NOTICE 'Note[%]. Aborted reg:%',note,to_json(read_new_aktivitet_reg);
  --RAISE NOTICE 'Note[%]. Previous reg:%',note,to_json(read_prev_aktivitet_reg);
  RAISE EXCEPTION 'Aborted updating aktivitet with id [%] as the given data, does not give raise to a new registration. Aborted reg:[%], previous reg:[%]',aktivitet_uuid,to_json(read_new_aktivitet_reg),to_json(read_prev_aktivitet_reg) USING ERRCODE = 'MO400';
END IF;

/******************************************************************/

PERFORM actual_state._amqp_publish_notification('Aktivitet', livscykluskode, aktivitet_uuid);

return new_aktivitet_registrering.id;



END;
$$ LANGUAGE plpgsql VOLATILE;





