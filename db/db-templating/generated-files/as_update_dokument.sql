-- Copyright (C) 2015 Magenta ApS, http://magenta.dk.
-- Contact: info@magenta.dk.
--
-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at http://mozilla.org/MPL/2.0/.

/*
NOTICE: This file is auto-generated using the script: apply-template.py dokument as_update.jinja.sql
*/




--Also notice, that the given arrays of DokumentAttr...Type must be consistent regarding virkning (although the allowance of null-values might make it possible to construct 'logically consistent'-arrays of objects with overlapping virknings)

CREATE OR REPLACE FUNCTION as_update_dokument(
  dokument_uuid uuid,
  brugerref uuid,
  note text,
  livscykluskode Livscykluskode,           
  attrEgenskaber DokumentEgenskaberAttrType[],
  tilsFremdrift DokumentFremdriftTilsType[],
  relationer DokumentRelationType[],
  lostUpdatePreventionTZ TIMESTAMPTZ = null
	)
  RETURNS bigint AS 
$$
DECLARE
  read_new_dokument DokumentType;
  read_prev_dokument DokumentType;
  read_new_dokument_reg DokumentRegistreringType;
  read_prev_dokument_reg DokumentRegistreringType;
  new_dokument_registrering dokument_registrering;
  prev_dokument_registrering dokument_registrering;
  dokument_relation_navn DokumentRelationKode;
  attrEgenskaberObj DokumentEgenskaberAttrType;
BEGIN

--create a new registrering

IF NOT EXISTS (select a.id from dokument a join dokument_registrering b on b.dokument_id=a.id  where a.id=dokument_uuid) THEN
   RAISE EXCEPTION 'Unable to update dokument with uuid [%], being unable to any previous registrations.',dokument_uuid;
END IF;

PERFORM a.id FROM dokument a
WHERE a.id=dokument_uuid
FOR UPDATE; --We synchronize concurrent invocations of as_updates of this particular object on a exclusive row lock. This lock will be held by the current transaction until it terminates.

new_dokument_registrering := _as_create_dokument_registrering(dokument_uuid,livscykluskode, brugerref, note);
prev_dokument_registrering := _as_get_prev_dokument_registrering(new_dokument_registrering);

IF lostUpdatePreventionTZ IS NOT NULL THEN
  IF NOT (LOWER((prev_dokument_registrering.registrering).timeperiod)=lostUpdatePreventionTZ) THEN
    RAISE EXCEPTION 'Unable to update dokument with uuid [%], as the dokument seems to have been updated since latest read by client (the given lostUpdatePreventionTZ [%] does not match the timesamp of latest registration [%]).',dokument_uuid,lostUpdatePreventionTZ,LOWER((prev_dokument_registrering.registrering).timeperiod);
  END IF;   
END IF;




--handle relationer (relations)

IF relationer IS NOT NULL AND coalesce(array_length(relationer,1),0)=0 THEN
--raise notice 'Skipping relations, as it is explicit set to empty array. Update note [%]',note;
ELSE

  --1) Insert relations given as part of this update
  --2) Insert relations of previous registration, taking overlapping virknings into consideration (using function subtract_tstzrange)

  --Ad 1)



      INSERT INTO dokument_relation (
        dokument_registrering_id,
          virkning,
            rel_maal_uuid,
              rel_maal_urn,
                rel_type,
                  objekt_type
      )
      SELECT
        new_dokument_registrering.id,
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
   

  FOREACH dokument_relation_navn in array  ARRAY['nyrevision'::DokumentRelationKode,'primaerklasse'::DokumentRelationKode,'ejer'::DokumentRelationKode,'ansvarlig'::DokumentRelationKode,'primaerbehandler'::DokumentRelationKode,'fordelttil'::DokumentRelationKode]
  LOOP

    INSERT INTO dokument_relation (
        dokument_registrering_id,
          virkning,
            rel_maal_uuid,
              rel_maal_urn,
                rel_type,
                  objekt_type
      )
    SELECT 
        new_dokument_registrering.id, 
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
      FROM dokument_relation b
      WHERE 
            b.dokument_registrering_id=new_dokument_registrering.id
            and
            b.rel_type=dokument_relation_navn
    ) d
    JOIN dokument_relation a ON true
    JOIN unnest(_subtract_tstzrange_arr((a.virkning).TimePeriod,tzranges_of_new_reg)) as c(tz_range_leftover) on true
    WHERE a.dokument_registrering_id=prev_dokument_registrering.id 
          and a.rel_type=dokument_relation_navn 
    ;
  END LOOP;

  /**********************/
  -- 0..n relations

  --We only have to check if there are any of the relations with the given name present in the new registration, otherwise copy the ones from the previous registration


  FOREACH dokument_relation_navn in array ARRAY['arkiver'::DokumentRelationKode,'besvarelser'::DokumentRelationKode,'udgangspunkter'::DokumentRelationKode,'kommentarer'::DokumentRelationKode,'bilag'::DokumentRelationKode,'andredokumenter'::DokumentRelationKode,'andreklasser'::DokumentRelationKode,'andrebehandlere'::DokumentRelationKode,'parter'::DokumentRelationKode,'kopiparter'::DokumentRelationKode,'tilknyttedesager'::DokumentRelationKode]
  LOOP

    IF NOT EXISTS  (SELECT 1 FROM dokument_relation WHERE dokument_registrering_id=new_dokument_registrering.id and rel_type=dokument_relation_navn) THEN

      INSERT INTO dokument_relation (
            dokument_registrering_id,
              virkning,
                rel_maal_uuid,
                  rel_maal_urn,
                    rel_type,
                      objekt_type
          )
      SELECT 
            new_dokument_registrering.id,
              virkning,
                rel_maal_uuid,
                  rel_maal_urn,
                    rel_type,
                      objekt_type
      FROM dokument_relation
      WHERE dokument_registrering_id=prev_dokument_registrering.id 
      and rel_type=dokument_relation_navn 
      ;

    END IF;
              
  END LOOP;


/**********************/
--Remove any "cleared"/"deleted" relations
DELETE FROM dokument_relation
WHERE 
dokument_registrering_id=new_dokument_registrering.id
AND (rel_maal_uuid IS NULL AND (rel_maal_urn IS NULL OR rel_maal_urn=''))
;

END IF;
/**********************/
-- handle tilstande (states)

IF tilsFremdrift IS NOT NULL AND coalesce(array_length(tilsFremdrift,1),0)=0 THEN
--raise debug 'Skipping [Fremdrift] as it is explicit set to empty array';
ELSE
  --1) Insert tilstande/states given as part of this update
  --2) Insert tilstande/states of previous registration, taking overlapping virknings into consideration (using function subtract_tstzrange)

  /********************************************/
  --dokument_tils_fremdrift
  /********************************************/

  --Ad 1)

  INSERT INTO dokument_tils_fremdrift (
          virkning,
            fremdrift,
              dokument_registrering_id
  ) 
  SELECT
          a.virkning,
            a.fremdrift,
              new_dokument_registrering.id
  FROM
  unnest(tilsFremdrift) as a
  ;
   

  --Ad 2

  INSERT INTO dokument_tils_fremdrift (
          virkning,
            fremdrift,
              dokument_registrering_id
  )
  SELECT 
          ROW(
            c.tz_range_leftover,
              (a.virkning).AktoerRef,
              (a.virkning).AktoerTypeKode,
              (a.virkning).NoteTekst
          ) :: virkning,
            a.fremdrift,
              new_dokument_registrering.id
  FROM
  (
   --build an array of the timeperiod of the virkning of the dokument_tils_fremdrift of the new registrering to pass to _subtract_tstzrange_arr on the dokument_tils_fremdrift of the previous registrering 
      SELECT coalesce(array_agg((b.virkning).TimePeriod),array[]::TSTZRANGE[]) tzranges_of_new_reg
      FROM dokument_tils_fremdrift b
      WHERE 
            b.dokument_registrering_id=new_dokument_registrering.id
  ) d
    JOIN dokument_tils_fremdrift a ON true  
    JOIN unnest(_subtract_tstzrange_arr((a.virkning).TimePeriod,tzranges_of_new_reg)) as c(tz_range_leftover) on true
    WHERE a.dokument_registrering_id=prev_dokument_registrering.id     
  ;


/**********************/
--Remove any "cleared"/"deleted" tilstande
DELETE FROM dokument_tils_fremdrift
WHERE 
dokument_registrering_id=new_dokument_registrering.id
AND fremdrift = ''::DokumentFremdriftTils
;

END IF;


/**********************/
--Handle attributter (attributes) 

/********************************************/
--dokument_attr_egenskaber
/********************************************/

--Generate and insert any merged objects, if any fields are null in attrDokumentObj
IF attrEgenskaber IS NOT null THEN

  --Input validation: 
  --Verify that there is no overlap in virkning in the array given

  IF EXISTS (
  SELECT
  a.*
  FROM unnest(attrEgenskaber) a
  JOIN  unnest(attrEgenskaber) b on (a.virkning).TimePeriod && (b.virkning).TimePeriod
  GROUP BY a.brugervendtnoegle,a.beskrivelse,a.brevdato,a.kassationskode,a.major,a.minor,a.offentlighedundtaget,a.titel,a.dokumenttype, a.virkning
  HAVING COUNT(*)>1
  ) THEN
  RAISE EXCEPTION 'Unable to update dokument with uuid [%], as the dokument have overlapping virknings in the given egenskaber array :%',dokument_uuid,to_json(attrEgenskaber)  USING ERRCODE = 22000;

  END IF;


  FOREACH attrEgenskaberObj in array attrEgenskaber
  LOOP

  --To avoid needless fragmentation we'll check for presence of null values in the fields - and if none are present, we'll skip the merging operations
  IF (attrEgenskaberObj).brugervendtnoegle is null OR 
   (attrEgenskaberObj).beskrivelse is null OR 
   (attrEgenskaberObj).brevdato is null OR 
   (attrEgenskaberObj).kassationskode is null OR 
   (attrEgenskaberObj).major is null OR 
   (attrEgenskaberObj).minor is null OR 
   (attrEgenskaberObj).offentlighedundtaget is null OR 
   (attrEgenskaberObj).titel is null OR 
   (attrEgenskaberObj).dokumenttype is null 
  THEN

  INSERT INTO
  dokument_attr_egenskaber
  (
    brugervendtnoegle,beskrivelse,brevdato,kassationskode,major,minor,offentlighedundtaget,titel,dokumenttype
    ,virkning
    ,dokument_registrering_id
  )
  SELECT 
    coalesce(attrEgenskaberObj.brugervendtnoegle,a.brugervendtnoegle), 
    coalesce(attrEgenskaberObj.beskrivelse,a.beskrivelse), 
    coalesce(attrEgenskaberObj.brevdato,a.brevdato), 
    coalesce(attrEgenskaberObj.kassationskode,a.kassationskode), 
    coalesce(attrEgenskaberObj.major,a.major), 
    coalesce(attrEgenskaberObj.minor,a.minor), 
    coalesce(attrEgenskaberObj.offentlighedundtaget,a.offentlighedundtaget), 
    coalesce(attrEgenskaberObj.titel,a.titel), 
    coalesce(attrEgenskaberObj.dokumenttype,a.dokumenttype),
	ROW (
	  (a.virkning).TimePeriod * (attrEgenskaberObj.virkning).TimePeriod,
	  (attrEgenskaberObj.virkning).AktoerRef,
	  (attrEgenskaberObj.virkning).AktoerTypeKode,
	  (attrEgenskaberObj.virkning).NoteTekst
	)::Virkning,
    new_dokument_registrering.id
  FROM dokument_attr_egenskaber a
  WHERE
    a.dokument_registrering_id=prev_dokument_registrering.id 
    and (a.virkning).TimePeriod && (attrEgenskaberObj.virkning).TimePeriod
  ;

  --For any periods within the virkning of the attrEgenskaberObj, that is NOT covered by any "merged" rows inserted above, generate and insert rows

  INSERT INTO
  dokument_attr_egenskaber
  (
    brugervendtnoegle,beskrivelse,brevdato,kassationskode,major,minor,offentlighedundtaget,titel,dokumenttype
    ,virkning
    ,dokument_registrering_id
  )
  SELECT 
    attrEgenskaberObj.brugervendtnoegle, 
    attrEgenskaberObj.beskrivelse, 
    attrEgenskaberObj.brevdato, 
    attrEgenskaberObj.kassationskode, 
    attrEgenskaberObj.major, 
    attrEgenskaberObj.minor, 
    attrEgenskaberObj.offentlighedundtaget, 
    attrEgenskaberObj.titel, 
    attrEgenskaberObj.dokumenttype,
	  ROW (
	       b.tz_range_leftover,
	      (attrEgenskaberObj.virkning).AktoerRef,
	      (attrEgenskaberObj.virkning).AktoerTypeKode,
	      (attrEgenskaberObj.virkning).NoteTekst
	  )::Virkning,
    new_dokument_registrering.id
  FROM
  (
  --build an array of the timeperiod of the virkning of the dokument_attr_egenskaber of the new registrering to pass to _subtract_tstzrange_arr 
      SELECT coalesce(array_agg((b.virkning).TimePeriod),array[]::TSTZRANGE[]) tzranges_of_new_reg
      FROM dokument_attr_egenskaber b
      WHERE 
       b.dokument_registrering_id=new_dokument_registrering.id
  ) as a
  JOIN unnest(_subtract_tstzrange_arr((attrEgenskaberObj.virkning).TimePeriod,a.tzranges_of_new_reg)) as b(tz_range_leftover) on true
  ;

  ELSE
    --insert attrEgenskaberObj raw (if there were no null-valued fields) 

    INSERT INTO
    dokument_attr_egenskaber
    (
    brugervendtnoegle,beskrivelse,brevdato,kassationskode,major,minor,offentlighedundtaget,titel,dokumenttype
    ,virkning
    ,dokument_registrering_id
    )
    VALUES ( 
    attrEgenskaberObj.brugervendtnoegle, 
    attrEgenskaberObj.beskrivelse, 
    attrEgenskaberObj.brevdato, 
    attrEgenskaberObj.kassationskode, 
    attrEgenskaberObj.major, 
    attrEgenskaberObj.minor, 
    attrEgenskaberObj.offentlighedundtaget, 
    attrEgenskaberObj.titel, 
    attrEgenskaberObj.dokumenttype,
    attrEgenskaberObj.virkning,
    new_dokument_registrering.id
    );

  END IF;

  END LOOP;
END IF;


IF attrEgenskaber IS NOT NULL AND coalesce(array_length(attrEgenskaber,1),0)=0 THEN
--raise debug 'Skipping handling of egenskaber of previous registration as an empty array was explicit given.';  
ELSE 

--Handle egenskaber of previous registration, taking overlapping virknings into consideration (using function subtract_tstzrange)

INSERT INTO dokument_attr_egenskaber (
    brugervendtnoegle,beskrivelse,brevdato,kassationskode,major,minor,offentlighedundtaget,titel,dokumenttype
    ,virkning
    ,dokument_registrering_id
)
SELECT
      a.brugervendtnoegle,
      a.beskrivelse,
      a.brevdato,
      a.kassationskode,
      a.major,
      a.minor,
      a.offentlighedundtaget,
      a.titel,
      a.dokumenttype,
	  ROW(
	    c.tz_range_leftover,
	      (a.virkning).AktoerRef,
	      (a.virkning).AktoerTypeKode,
	      (a.virkning).NoteTekst
	  ) :: virkning,
	 new_dokument_registrering.id
FROM
(
 --build an array of the timeperiod of the virkning of the dokument_attr_egenskaber of the new registrering to pass to _subtract_tstzrange_arr on the dokument_attr_egenskaber of the previous registrering 
    SELECT coalesce(array_agg((b.virkning).TimePeriod),array[]::TSTZRANGE[]) tzranges_of_new_reg
    FROM dokument_attr_egenskaber b
    WHERE 
          b.dokument_registrering_id=new_dokument_registrering.id
) d
  JOIN dokument_attr_egenskaber a ON true  
  JOIN unnest(_subtract_tstzrange_arr((a.virkning).TimePeriod,tzranges_of_new_reg)) as c(tz_range_leftover) on true
  WHERE a.dokument_registrering_id=prev_dokument_registrering.id     
;



--Remove any "cleared"/"deleted" attributes
DELETE FROM dokument_attr_egenskaber a
WHERE 
a.dokument_registrering_id=new_dokument_registrering.id
AND (a.brugervendtnoegle IS NULL OR a.brugervendtnoegle='') 
            AND  (a.beskrivelse IS NULL OR a.beskrivelse='') 
            AND  (a.brevdato IS NULL) 
            AND  (a.kassationskode IS NULL OR a.kassationskode='') 
            AND  (a.major IS NULL) 
            AND  (a.minor IS NULL) 
            AND  (a.offentlighedundtaget IS NULL OR (((a.offentlighedundtaget).AlternativTitel IS NULL OR (a.offentlighedundtaget).AlternativTitel='') AND ((a.offentlighedundtaget).Hjemmel IS NULL OR (a.offentlighedundtaget).Hjemmel=''))) 
            AND  (a.titel IS NULL OR a.titel='') 
            AND  (a.dokumenttype IS NULL OR a.dokumenttype='')
;

END IF;


/******************************************************************/
--If the new registrering is identical to the previous one, we need to throw an exception to abort the transaction. 

read_new_dokument:=as_read_dokument(dokument_uuid, (new_dokument_registrering.registrering).timeperiod,null);
read_prev_dokument:=as_read_dokument(dokument_uuid, (prev_dokument_registrering.registrering).timeperiod ,null);
 
--the ordering in as_list (called by as_read) ensures that the latest registration is returned at index pos 1

IF NOT (lower((read_new_dokument.registrering[1].registrering).TimePeriod)=lower((new_dokument_registrering.registrering).TimePeriod) AND lower((read_prev_dokument.registrering[1].registrering).TimePeriod)=lower((prev_dokument_registrering.registrering).TimePeriod)) THEN
  RAISE EXCEPTION 'Error updating dokument with id [%]: The ordering of as_list_dokument should ensure that the latest registrering can be found at index 1. Expected new reg: [%]. Actual new reg at index 1: [%]. Expected prev reg: [%]. Actual prev reg at index 1: [%].',dokument_uuid,to_json(new_dokument_registrering),to_json(read_new_dokument.registrering[1].registrering),to_json(prev_dokument_registrering),to_json(prev_new_dokument.registrering[1].registrering);
END IF;
 
 --we'll ignore the registreringBase part in the comparrison - except for the livcykluskode

read_new_dokument_reg:=ROW(
ROW(null,(read_new_dokument.registrering[1].registrering).livscykluskode,null,null)::registreringBase,
(read_new_dokument.registrering[1]).tilsFremdrift ,
(read_new_dokument.registrering[1]).attrEgenskaber ,
(read_new_dokument.registrering[1]).relationer 
)::dokumentRegistreringType
;

read_prev_dokument_reg:=ROW(
ROW(null,(read_prev_dokument.registrering[1].registrering).livscykluskode,null,null)::registreringBase,
(read_prev_dokument.registrering[1]).tilsFremdrift ,
(read_prev_dokument.registrering[1]).attrEgenskaber ,
(read_prev_dokument.registrering[1]).relationer 
)::dokumentRegistreringType
;


IF read_prev_dokument_reg=read_new_dokument_reg THEN
  --RAISE NOTICE 'Note[%]. Aborted reg:%',note,to_json(read_new_dokument_reg);
  --RAISE NOTICE 'Note[%]. Previous reg:%',note,to_json(read_prev_dokument_reg);
  RAISE EXCEPTION 'Aborted updating dokument with id [%] as the given data, does not give raise to a new registration. Aborted reg:[%], previous reg:[%]',dokument_uuid,to_json(read_new_dokument_reg),to_json(read_prev_dokument_reg) USING ERRCODE = 22000;
END IF;

/******************************************************************/


return new_dokument_registrering.id;



END;
$$ LANGUAGE plpgsql VOLATILE;





