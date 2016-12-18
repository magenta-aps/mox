-- Copyright (C) 2015 Magenta ApS, http://magenta.dk.
-- Contact: info@magenta.dk.
--
-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at http://mozilla.org/MPL/2.0/.

/*
NOTICE: This file is auto-generated using the script: apply-template.py indsats as_update.jinja.sql
*/




--Also notice, that the given arrays of IndsatsAttr...Type must be consistent regarding virkning (although the allowance of null-values might make it possible to construct 'logically consistent'-arrays of objects with overlapping virknings)

CREATE OR REPLACE FUNCTION as_update_indsats(
  indsats_uuid uuid,
  brugerref uuid,
  note text,
  livscykluskode Livscykluskode,           
  attrEgenskaber IndsatsEgenskaberAttrType[],
  tilsPubliceret IndsatsPubliceretTilsType[],
  tilsFremdrift IndsatsFremdriftTilsType[],
  relationer IndsatsRelationType[],
  lostUpdatePreventionTZ TIMESTAMPTZ = null,
  auth_criteria_arr IndsatsRegistreringType[]=null
	)
  RETURNS bigint AS 
$$
DECLARE
  read_new_indsats IndsatsType;
  read_prev_indsats IndsatsType;
  read_new_indsats_reg IndsatsRegistreringType;
  read_prev_indsats_reg IndsatsRegistreringType;
  new_indsats_registrering indsats_registrering;
  prev_indsats_registrering indsats_registrering;
  indsats_relation_navn IndsatsRelationKode;
  attrEgenskaberObj IndsatsEgenskaberAttrType;
  auth_filtered_uuids uuid[];
  rel_type_max_index_prev_rev int;
  rel_type_max_index_arr _indsatsRelationMaxIndex[];
  indsats_rel_type_cardinality_unlimited indsatsRelationKode[]:=ARRAY['indsatskvalitet'::IndsatsRelationKode,'indsatsaktoer'::IndsatsRelationKode,'samtykke'::IndsatsRelationKode,'indsatssag'::IndsatsRelationKode,'indsatsdokument'::IndsatsRelationKode];
  indsats_uuid_underscores text;
  indsats_rel_seq_name text;
  indsats_rel_type_cardinality_unlimited_present_in_argument IndsatsRelationKode[];
BEGIN

--create a new registrering

IF NOT EXISTS (select a.id from indsats a join indsats_registrering b on b.indsats_id=a.id  where a.id=indsats_uuid) THEN
   RAISE EXCEPTION 'Unable to update indsats with uuid [%], being unable to find any previous registrations.',indsats_uuid USING ERRCODE = 'MO400';
END IF;

PERFORM a.id FROM indsats a
WHERE a.id=indsats_uuid
FOR UPDATE; --We synchronize concurrent invocations of as_updates of this particular object on a exclusive row lock. This lock will be held by the current transaction until it terminates.

/*** Verify that the object meets the stipulated access allowed criteria  ***/
auth_filtered_uuids:=_as_filter_unauth_indsats(array[indsats_uuid]::uuid[],auth_criteria_arr); 
IF NOT (coalesce(array_length(auth_filtered_uuids,1),0)=1 AND auth_filtered_uuids @>ARRAY[indsats_uuid]) THEN
  RAISE EXCEPTION 'Unable to update indsats with uuid [%]. Object does not met stipulated criteria:%',indsats_uuid,to_json(auth_criteria_arr)  USING ERRCODE = 'MO401'; 
END IF;
/*********************/


new_indsats_registrering := _as_create_indsats_registrering(indsats_uuid,livscykluskode, brugerref, note);
prev_indsats_registrering := _as_get_prev_indsats_registrering(new_indsats_registrering);

IF lostUpdatePreventionTZ IS NOT NULL THEN
  IF NOT (LOWER((prev_indsats_registrering.registrering).timeperiod)=lostUpdatePreventionTZ) THEN
    RAISE EXCEPTION 'Unable to update indsats with uuid [%], as the indsats seems to have been updated since latest read by client (the given lostUpdatePreventionTZ [%] does not match the timesamp of latest registration [%]).',indsats_uuid,lostUpdatePreventionTZ,LOWER((prev_indsats_registrering.registrering).timeperiod) USING ERRCODE = 'MO409';
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
SELECT array_agg(rel_type_max_index)::_indsatsRelationMaxIndex[] into rel_type_max_index_arr
FROM
(
  SELECT
  (ROW(rel_type,coalesce(max(rel_index),0))::_indsatsRelationMaxIndex) rel_type_max_index  
  FROM indsats_relation a
  where a.indsats_registrering_id=prev_indsats_registrering.id
  and a.rel_type = any (indsats_rel_type_cardinality_unlimited)
  group by rel_type
) as a
;


--Create temporary sequences
indsats_uuid_underscores:=replace(indsats_uuid::text, '-', '_');

SELECT array_agg( DISTINCT a.RelType) into indsats_rel_type_cardinality_unlimited_present_in_argument FROM  unnest(relationer) a WHERE a.RelType = any (indsats_rel_type_cardinality_unlimited) ;
IF coalesce(array_length(indsats_rel_type_cardinality_unlimited_present_in_argument,1),0)>0 THEN
FOREACH indsats_relation_navn IN ARRAY (indsats_rel_type_cardinality_unlimited_present_in_argument)
  LOOP
  indsats_rel_seq_name := 'indsats_' || indsats_relation_navn::text || indsats_uuid_underscores;

  rel_type_max_index_prev_rev:=null;

  SELECT 
    a.indeks into rel_type_max_index_prev_rev
  FROM
    unnest(rel_type_max_index_arr) a(relType,indeks)
  WHERE
    a.relType=indsats_relation_navn
  ;
  
  IF rel_type_max_index_prev_rev IS NULL THEN
    rel_type_max_index_prev_rev:=0;
  END IF;

  EXECUTE 'CREATE TEMPORARY SEQUENCE ' || indsats_rel_seq_name || '
  INCREMENT 1
  MINVALUE 1
  MAXVALUE 9223372036854775807
  START ' ||  (rel_type_max_index_prev_rev+1)::text ||'
  CACHE 1;';

END LOOP;
END IF;

      INSERT INTO indsats_relation (
        indsats_registrering_id,
          virkning,
            rel_maal_uuid,
              rel_maal_urn,
                rel_type,
                  objekt_type,
                    rel_index
      )
      SELECT
        new_indsats_registrering.id,
          a.virkning,
            a.uuid,
              a.urn,
                a.relType,
                  a.objektType,
                    CASE 
                    WHEN a.relType = any (indsats_rel_type_cardinality_unlimited) THEN
                      CASE WHEN a.indeks IS NULL OR b.id IS NULL THEN --for new relations and relations with index given that is not found in prev registrering, we'll assign new index values 
                        nextval('indsats_' || a.relType::text || indsats_uuid_underscores)
                      ELSE
                        a.indeks
                      END
                    ELSE
                    NULL
                    END
      FROM unnest(relationer) as a
      LEFT JOIN indsats_relation b on a.relType = any (indsats_rel_type_cardinality_unlimited) and b.indsats_registrering_id=prev_indsats_registrering.id and a.relType=b.rel_type and a.indeks=b.rel_index
    ;


--Drop temporary sequences
IF coalesce(array_length(indsats_rel_type_cardinality_unlimited_present_in_argument,1),0)>0 THEN
FOREACH indsats_relation_navn IN ARRAY (indsats_rel_type_cardinality_unlimited_present_in_argument)
  LOOP
  indsats_rel_seq_name := 'indsats_' || indsats_relation_navn::text || indsats_uuid_underscores;
  EXECUTE 'DROP  SEQUENCE ' || indsats_rel_seq_name || ';';
END LOOP;
END IF;

  --Ad 2)

  /**********************/
  -- 0..1 relations 
  --Please notice, that for 0..1 relations for indsats, we're ignoring index here, and handling it the same way, that is done for other object types (like Facet, Klasse etc). That is, you only make changes for the virkningsperiod that you explicitly specify (unless you delete all relations) 

  FOREACH indsats_relation_navn in array ARRAY['indsatstype'::IndsatsRelationKode,'indsatsmodtager'::IndsatsRelationKode]::IndsatsRelationKode[]
  LOOP

    INSERT INTO indsats_relation (
        indsats_registrering_id,
          virkning,
            rel_maal_uuid,
              rel_maal_urn,
                rel_type,
                  objekt_type,
                    rel_index          
      )
    SELECT 
        new_indsats_registrering.id, 
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
                    NULL--a.rel_index, rel_index is not to be used for 0..1 relations        
    FROM
    (
      --build an array of the timeperiod of the virkning of the relations of the new registrering to pass to _subtract_tstzrange_arr on the relations of the previous registrering 
      SELECT coalesce(array_agg((b.virkning).TimePeriod),array[]::TSTZRANGE[]) tzranges_of_new_reg
      FROM indsats_relation b
      WHERE 
            b.indsats_registrering_id=new_indsats_registrering.id
            and
            b.rel_type=indsats_relation_navn
    ) d
    JOIN indsats_relation a ON true
    JOIN unnest(_subtract_tstzrange_arr((a.virkning).TimePeriod,tzranges_of_new_reg)) as c(tz_range_leftover) on true
    WHERE a.indsats_registrering_id=prev_indsats_registrering.id 
          and a.rel_type=indsats_relation_navn 
    ;
  END LOOP;

  /**********************/
  -- 0..n relations
  
      INSERT INTO indsats_relation (
            indsats_registrering_id,
              virkning,
                rel_maal_uuid,
                  rel_maal_urn,
                    rel_type,
                      objekt_type,
                        rel_index
          )
      SELECT 
            new_indsats_registrering.id,
              a.virkning,
                a.rel_maal_uuid,
                  a.rel_maal_urn,
                    a.rel_type,
                      a.objekt_type,
                        a.rel_index
      FROM indsats_relation a
      LEFT JOIN indsats_relation b on b.indsats_registrering_id=new_indsats_registrering.id and b.rel_type=a.rel_type and b.rel_index=a.rel_index
      WHERE a.indsats_registrering_id=prev_indsats_registrering.id 
      and a.rel_type = any (indsats_rel_type_cardinality_unlimited)
      and b.id is null --don't transfer relations of prev. registrering, if the index was specified in data given to the/this update-function
      ;

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
  --indsats_tils_publiceret
  /********************************************/

  --Ad 1)

  INSERT INTO indsats_tils_publiceret (
          virkning,
            publiceret,
              indsats_registrering_id
  ) 
  SELECT
          a.virkning,
            a.publiceret,
              new_indsats_registrering.id
  FROM
  unnest(tilsPubliceret) as a
  ;
   

  --Ad 2

  INSERT INTO indsats_tils_publiceret (
          virkning,
            publiceret,
              indsats_registrering_id
  )
  SELECT 
          ROW(
            c.tz_range_leftover,
              (a.virkning).AktoerRef,
              (a.virkning).AktoerTypeKode,
              (a.virkning).NoteTekst
          ) :: virkning,
            a.publiceret,
              new_indsats_registrering.id
  FROM
  (
   --build an array of the timeperiod of the virkning of the indsats_tils_publiceret of the new registrering to pass to _subtract_tstzrange_arr on the indsats_tils_publiceret of the previous registrering 
      SELECT coalesce(array_agg((b.virkning).TimePeriod),array[]::TSTZRANGE[]) tzranges_of_new_reg
      FROM indsats_tils_publiceret b
      WHERE 
            b.indsats_registrering_id=new_indsats_registrering.id
  ) d
    JOIN indsats_tils_publiceret a ON true  
    JOIN unnest(_subtract_tstzrange_arr((a.virkning).TimePeriod,tzranges_of_new_reg)) as c(tz_range_leftover) on true
    WHERE a.indsats_registrering_id=prev_indsats_registrering.id     
  ;


/**********************/

END IF;



IF tilsFremdrift IS NOT NULL AND coalesce(array_length(tilsFremdrift,1),0)=0 THEN
--raise debug 'Skipping [Fremdrift] as it is explicit set to empty array';
ELSE
  --1) Insert tilstande/states given as part of this update
  --2) Insert tilstande/states of previous registration, taking overlapping virknings into consideration (using function subtract_tstzrange)

  /********************************************/
  --indsats_tils_fremdrift
  /********************************************/

  --Ad 1)

  INSERT INTO indsats_tils_fremdrift (
          virkning,
            fremdrift,
              indsats_registrering_id
  ) 
  SELECT
          a.virkning,
            a.fremdrift,
              new_indsats_registrering.id
  FROM
  unnest(tilsFremdrift) as a
  ;
   

  --Ad 2

  INSERT INTO indsats_tils_fremdrift (
          virkning,
            fremdrift,
              indsats_registrering_id
  )
  SELECT 
          ROW(
            c.tz_range_leftover,
              (a.virkning).AktoerRef,
              (a.virkning).AktoerTypeKode,
              (a.virkning).NoteTekst
          ) :: virkning,
            a.fremdrift,
              new_indsats_registrering.id
  FROM
  (
   --build an array of the timeperiod of the virkning of the indsats_tils_fremdrift of the new registrering to pass to _subtract_tstzrange_arr on the indsats_tils_fremdrift of the previous registrering 
      SELECT coalesce(array_agg((b.virkning).TimePeriod),array[]::TSTZRANGE[]) tzranges_of_new_reg
      FROM indsats_tils_fremdrift b
      WHERE 
            b.indsats_registrering_id=new_indsats_registrering.id
  ) d
    JOIN indsats_tils_fremdrift a ON true  
    JOIN unnest(_subtract_tstzrange_arr((a.virkning).TimePeriod,tzranges_of_new_reg)) as c(tz_range_leftover) on true
    WHERE a.indsats_registrering_id=prev_indsats_registrering.id     
  ;


/**********************/

END IF;


/**********************/
--Handle attributter (attributes) 

/********************************************/
--indsats_attr_egenskaber
/********************************************/

--Generate and insert any merged objects, if any fields are null in attrIndsatsObj
IF attrEgenskaber IS NOT null THEN

  --Input validation: 
  --Verify that there is no overlap in virkning in the array given

  IF EXISTS (
  SELECT
  a.*
  FROM unnest(attrEgenskaber) a
  JOIN  unnest(attrEgenskaber) b on (a.virkning).TimePeriod && (b.virkning).TimePeriod
  GROUP BY a.brugervendtnoegle,a.beskrivelse,a.starttidspunkt,a.sluttidspunkt, a.virkning
  HAVING COUNT(*)>1
  ) THEN
  RAISE EXCEPTION 'Unable to update indsats with uuid [%], as the indsats have overlapping virknings in the given egenskaber array :%',indsats_uuid,to_json(attrEgenskaber)  USING ERRCODE = 'MO400';

  END IF;


  FOREACH attrEgenskaberObj in array attrEgenskaber
  LOOP

  --To avoid needless fragmentation we'll check for presence of null values in the fields - and if none are present, we'll skip the merging operations
  IF (attrEgenskaberObj).brugervendtnoegle is null OR 
   (attrEgenskaberObj).beskrivelse is null OR 
   (attrEgenskaberObj).starttidspunkt is null OR 
   (attrEgenskaberObj).sluttidspunkt is null 
  THEN

  INSERT INTO
  indsats_attr_egenskaber
  (
    brugervendtnoegle,beskrivelse,starttidspunkt,sluttidspunkt
    ,virkning
    ,indsats_registrering_id
  )
  SELECT
    coalesce(attrEgenskaberObj.brugervendtnoegle,a.brugervendtnoegle),
    coalesce(attrEgenskaberObj.beskrivelse,a.beskrivelse),
    CASE WHEN ((attrEgenskaberObj.starttidspunkt).cleared) THEN NULL 
        ELSE coalesce((attrEgenskaberObj.starttidspunkt).value,a.starttidspunkt)
        END,
    CASE WHEN ((attrEgenskaberObj.sluttidspunkt).cleared) THEN NULL 
        ELSE coalesce((attrEgenskaberObj.sluttidspunkt).value,a.sluttidspunkt)
        END,
	ROW (
	  (a.virkning).TimePeriod * (attrEgenskaberObj.virkning).TimePeriod,
	  (attrEgenskaberObj.virkning).AktoerRef,
	  (attrEgenskaberObj.virkning).AktoerTypeKode,
	  (attrEgenskaberObj.virkning).NoteTekst
	)::Virkning,
    new_indsats_registrering.id
  FROM indsats_attr_egenskaber a
  WHERE
    a.indsats_registrering_id=prev_indsats_registrering.id 
    and (a.virkning).TimePeriod && (attrEgenskaberObj.virkning).TimePeriod
  ;

  --For any periods within the virkning of the attrEgenskaberObj, that is NOT covered by any "merged" rows inserted above, generate and insert rows

  INSERT INTO
  indsats_attr_egenskaber
  (
    brugervendtnoegle,beskrivelse,starttidspunkt,sluttidspunkt
    ,virkning
    ,indsats_registrering_id
  )
  SELECT 
    attrEgenskaberObj.brugervendtnoegle, 
    attrEgenskaberObj.beskrivelse, 
    attrEgenskaberObj.starttidspunkt, 
    attrEgenskaberObj.sluttidspunkt,
	  ROW (
	       b.tz_range_leftover,
	      (attrEgenskaberObj.virkning).AktoerRef,
	      (attrEgenskaberObj.virkning).AktoerTypeKode,
	      (attrEgenskaberObj.virkning).NoteTekst
	  )::Virkning,
    new_indsats_registrering.id
  FROM
  (
  --build an array of the timeperiod of the virkning of the indsats_attr_egenskaber of the new registrering to pass to _subtract_tstzrange_arr 
      SELECT coalesce(array_agg((b.virkning).TimePeriod),array[]::TSTZRANGE[]) tzranges_of_new_reg
      FROM indsats_attr_egenskaber b
      WHERE 
       b.indsats_registrering_id=new_indsats_registrering.id
  ) as a
  JOIN unnest(_subtract_tstzrange_arr((attrEgenskaberObj.virkning).TimePeriod,a.tzranges_of_new_reg)) as b(tz_range_leftover) on true
  ;

  ELSE
    --insert attrEgenskaberObj raw (if there were no null-valued fields) 

    INSERT INTO
    indsats_attr_egenskaber
    (
    brugervendtnoegle,beskrivelse,starttidspunkt,sluttidspunkt
    ,virkning
    ,indsats_registrering_id
    )
    VALUES ( 
    attrEgenskaberObj.brugervendtnoegle, 
    attrEgenskaberObj.beskrivelse, 
    attrEgenskaberObj.starttidspunkt, 
    attrEgenskaberObj.sluttidspunkt,
    attrEgenskaberObj.virkning,
    new_indsats_registrering.id
    );

  END IF;

  END LOOP;
END IF;


IF attrEgenskaber IS NOT NULL AND coalesce(array_length(attrEgenskaber,1),0)=0 THEN
--raise debug 'Skipping handling of egenskaber of previous registration as an empty array was explicit given.';  
ELSE 

--Handle egenskaber of previous registration, taking overlapping virknings into consideration (using function subtract_tstzrange)

INSERT INTO indsats_attr_egenskaber (
    brugervendtnoegle,beskrivelse,starttidspunkt,sluttidspunkt
    ,virkning
    ,indsats_registrering_id
)
SELECT
      a.brugervendtnoegle,
      a.beskrivelse,
      a.starttidspunkt,
      a.sluttidspunkt,
	  ROW(
	    c.tz_range_leftover,
	      (a.virkning).AktoerRef,
	      (a.virkning).AktoerTypeKode,
	      (a.virkning).NoteTekst
	  ) :: virkning,
	 new_indsats_registrering.id
FROM
(
 --build an array of the timeperiod of the virkning of the indsats_attr_egenskaber of the new registrering to pass to _subtract_tstzrange_arr on the indsats_attr_egenskaber of the previous registrering 
    SELECT coalesce(array_agg((b.virkning).TimePeriod),array[]::TSTZRANGE[]) tzranges_of_new_reg
    FROM indsats_attr_egenskaber b
    WHERE 
          b.indsats_registrering_id=new_indsats_registrering.id
) d
  JOIN indsats_attr_egenskaber a ON true  
  JOIN unnest(_subtract_tstzrange_arr((a.virkning).TimePeriod,tzranges_of_new_reg)) as c(tz_range_leftover) on true
  WHERE a.indsats_registrering_id=prev_indsats_registrering.id     
;





END IF;


/******************************************************************/
--If the new registrering is identical to the previous one, we need to throw an exception to abort the transaction. 

read_new_indsats:=as_read_indsats(indsats_uuid, (new_indsats_registrering.registrering).timeperiod,null);
read_prev_indsats:=as_read_indsats(indsats_uuid, (prev_indsats_registrering.registrering).timeperiod ,null);
 
--the ordering in as_list (called by as_read) ensures that the latest registration is returned at index pos 1

IF NOT (lower((read_new_indsats.registrering[1].registrering).TimePeriod)=lower((new_indsats_registrering.registrering).TimePeriod) AND lower((read_prev_indsats.registrering[1].registrering).TimePeriod)=lower((prev_indsats_registrering.registrering).TimePeriod)) THEN
  RAISE EXCEPTION 'Error updating indsats with id [%]: The ordering of as_list_indsats should ensure that the latest registrering can be found at index 1. Expected new reg: [%]. Actual new reg at index 1: [%]. Expected prev reg: [%]. Actual prev reg at index 1: [%].',indsats_uuid,to_json(new_indsats_registrering),to_json(read_new_indsats.registrering[1].registrering),to_json(prev_indsats_registrering),to_json(prev_new_indsats.registrering[1].registrering) USING ERRCODE = 'MO500';
END IF;
 
 --we'll ignore the registreringBase part in the comparrison - except for the livcykluskode

read_new_indsats_reg:=ROW(
ROW(null,(read_new_indsats.registrering[1].registrering).livscykluskode,null,null)::registreringBase,
(read_new_indsats.registrering[1]).tilsPubliceret ,
(read_new_indsats.registrering[1]).tilsFremdrift ,
(read_new_indsats.registrering[1]).attrEgenskaber ,
(read_new_indsats.registrering[1]).relationer 
)::indsatsRegistreringType
;

read_prev_indsats_reg:=ROW(
ROW(null,(read_prev_indsats.registrering[1].registrering).livscykluskode,null,null)::registreringBase,
(read_prev_indsats.registrering[1]).tilsPubliceret ,
(read_prev_indsats.registrering[1]).tilsFremdrift ,
(read_prev_indsats.registrering[1]).attrEgenskaber ,
(read_prev_indsats.registrering[1]).relationer 
)::indsatsRegistreringType
;


IF read_prev_indsats_reg=read_new_indsats_reg THEN
  --RAISE NOTICE 'Note[%]. Aborted reg:%',note,to_json(read_new_indsats_reg);
  --RAISE NOTICE 'Note[%]. Previous reg:%',note,to_json(read_prev_indsats_reg);
  RAISE EXCEPTION 'Aborted updating indsats with id [%] as the given data, does not give raise to a new registration. Aborted reg:[%], previous reg:[%]',indsats_uuid,to_json(read_new_indsats_reg),to_json(read_prev_indsats_reg) USING ERRCODE = 'MO400';
END IF;

/******************************************************************/

PERFORM actual_state._amqp_publish_notification('Indsats', livscykluskode, indsats_uuid);

return new_indsats_registrering.id;



END;
$$ LANGUAGE plpgsql VOLATILE;





