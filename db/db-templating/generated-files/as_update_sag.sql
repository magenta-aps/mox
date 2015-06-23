-- Copyright (C) 2015 Magenta ApS, http://magenta.dk.
-- Contact: info@magenta.dk.
--
-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at http://mozilla.org/MPL/2.0/.

/*
NOTICE: This file is auto-generated using the script: apply-template.py sag as_update.jinja.sql
*/



--Please notice that is it the responsibility of the invoker of this function to compare the resulting sag_registration (including the entire hierarchy)
--to the previous one, and abort the transaction if the two registrations are identical. (This is to comply with the stipulated behavior in 'Specifikation_af_generelle_egenskaber - til OIOkomiteen.pdf')

--Also notice, that the given array of SagAttr...Type must be consistent regarding virkning (although the allowance of null-values might make it possible to construct 'logically consistent'-arrays of objects with overlapping virknings)

CREATE OR REPLACE FUNCTION as_update_sag(
  sag_uuid uuid,
  brugerref uuid,
  note text,
  livscykluskode Livscykluskode,           
  attrEgenskaber SagEgenskaberAttrType[],
  tilsFremdrift SagFremdriftTilsType[],
  relationer SagRelationType[],
  lostUpdatePreventionTZ TIMESTAMPTZ = null
	)
  RETURNS bigint AS 
$$
DECLARE
  read_new_sag SagType;
  read_prev_sag SagType;
  read_new_sag_reg SagRegistreringType;
  read_prev_sag_reg SagRegistreringType;
  new_sag_registrering sag_registrering;
  prev_sag_registrering sag_registrering;
  sag_relation_navn SagRelationKode;
  attrEgenskaberObj SagEgenskaberAttrType;
BEGIN

--create a new registrering

IF NOT EXISTS (select a.id from sag a join sag_registrering b on b.sag_id=a.id  where a.id=sag_uuid) THEN
   RAISE EXCEPTION 'Unable to update sag with uuid [%], being unable to any previous registrations.',sag_uuid;
END IF;

new_sag_registrering := _as_create_sag_registrering(sag_uuid,livscykluskode, brugerref, note);
prev_sag_registrering := _as_get_prev_sag_registrering(new_sag_registrering);

IF lostUpdatePreventionTZ IS NOT NULL THEN
  IF NOT (LOWER((prev_sag_registrering.registrering).timeperiod)=lostUpdatePreventionTZ) THEN
    RAISE EXCEPTION 'Unable to update sag with uuid [%], as the sag seems to have been updated since latest read by client (the given lostUpdatePreventionTZ [%] does not match the timesamp of latest registration [%]).',sag_uuid,lostUpdatePreventionTZ,LOWER((prev_sag_registrering.registrering).timeperiod);
  END IF;   
END IF;




--handle relationer (relations)

IF relationer IS NOT NULL AND coalesce(array_length(relationer,1),0)=0 THEN
--raise notice 'Skipping relations, as it is explicit set to empty array. Update note [%]',note;
ELSE

  --1) Insert relations given as part of this update
  --2) Insert relations of previous registration, taking overlapping virknings into consideration (using function subtract_tstzrange)

  --Ad 1)



      INSERT INTO sag_relation (
        sag_registrering_id,
          virkning,
            rel_maal_uuid,
              rel_maal_urn,
                rel_type,
                  objekt_type
      )
      SELECT
        new_sag_registrering.id,
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
   

  FOREACH sag_relation_navn in array  ARRAY['behandlingarkiv'::SagRelationKode,'afleveringsarkiv'::SagRelationKode,'primaerklasse'::SagRelationKode,'opgaveklasse'::SagRelationKode,'handlingsklasse'::SagRelationKode,'kontoklasse'::SagRelationKode,'sikkerhedsklasse'::SagRelationKode,'foelsomhedsklasse'::SagRelationKode,'indsatsklasse'::SagRelationKode,'ydelsesklasse'::SagRelationKode,'ejer'::SagRelationKode,'ansvarlig'::SagRelationKode,'primaerbehandler'::SagRelationKode,'udlaanttil'::SagRelationKode,'primaerpart'::SagRelationKode,'ydelsesmodtager'::SagRelationKode,'oversag'::SagRelationKode,'praecedens'::SagRelationKode,'afgiftsobjekt'::SagRelationKode,'ejendomsskat'::SagRelationKode]
  LOOP

    INSERT INTO sag_relation (
        sag_registrering_id,
          virkning,
            rel_maal_uuid,
              rel_maal_urn,
                rel_type,
                  objekt_type
      )
    SELECT 
        new_sag_registrering.id, 
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
      FROM sag_relation b
      WHERE 
            b.sag_registrering_id=new_sag_registrering.id
            and
            b.rel_type=sag_relation_navn
    ) d
    JOIN sag_relation a ON true
    JOIN unnest(_subtract_tstzrange_arr((a.virkning).TimePeriod,tzranges_of_new_reg)) as c(tz_range_leftover) on true
    WHERE a.sag_registrering_id=prev_sag_registrering.id 
          and a.rel_type=sag_relation_navn 
    ;
  END LOOP;

  /**********************/
  -- 0..n relations

  --We only have to check if there are any of the relations with the given name present in the new registration, otherwise copy the ones from the previous registration


  FOREACH sag_relation_navn in array ARRAY['andetarkiv'::SagRelationKode,'andrebehandlere'::SagRelationKode,'sekundaerpart'::SagRelationKode,'andresager'::SagRelationKode,'byggeri'::SagRelationKode,'fredning'::SagRelationKode,'journalpost'::SagRelationKode]
  LOOP

    IF NOT EXISTS  (SELECT 1 FROM sag_relation WHERE sag_registrering_id=new_sag_registrering.id and rel_type=sag_relation_navn) THEN

      INSERT INTO sag_relation (
            sag_registrering_id,
              virkning,
                rel_maal_uuid,
                  rel_maal_urn,
                    rel_type,
                      objekt_type
          )
      SELECT 
            new_sag_registrering.id,
              virkning,
                rel_maal_uuid,
                  rel_maal_urn,
                    rel_type,
                      objekt_type
      FROM sag_relation
      WHERE sag_registrering_id=prev_sag_registrering.id 
      and rel_type=sag_relation_navn 
      ;

    END IF;
              
  END LOOP;


/**********************/
--Remove any "cleared"/"deleted" relations
DELETE FROM sag_relation
WHERE 
sag_registrering_id=new_sag_registrering.id
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
  --sag_tils_fremdrift
  /********************************************/

  --Ad 1)

  INSERT INTO sag_tils_fremdrift (
          virkning,
            fremdrift,
              sag_registrering_id
  ) 
  SELECT
          a.virkning,
            a.fremdrift,
              new_sag_registrering.id
  FROM
  unnest(tilsFremdrift) as a
  ;
   

  --Ad 2

  INSERT INTO sag_tils_fremdrift (
          virkning,
            fremdrift,
              sag_registrering_id
  )
  SELECT 
          ROW(
            c.tz_range_leftover,
              (a.virkning).AktoerRef,
              (a.virkning).AktoerTypeKode,
              (a.virkning).NoteTekst
          ) :: virkning,
            a.fremdrift,
              new_sag_registrering.id
  FROM
  (
   --build an array of the timeperiod of the virkning of the sag_tils_fremdrift of the new registrering to pass to _subtract_tstzrange_arr on the sag_tils_fremdrift of the previous registrering 
      SELECT coalesce(array_agg((b.virkning).TimePeriod),array[]::TSTZRANGE[]) tzranges_of_new_reg
      FROM sag_tils_fremdrift b
      WHERE 
            b.sag_registrering_id=new_sag_registrering.id
  ) d
    JOIN sag_tils_fremdrift a ON true  
    JOIN unnest(_subtract_tstzrange_arr((a.virkning).TimePeriod,tzranges_of_new_reg)) as c(tz_range_leftover) on true
    WHERE a.sag_registrering_id=prev_sag_registrering.id     
  ;


/**********************/
--Remove any "cleared"/"deleted" tilstande
DELETE FROM sag_tils_fremdrift
WHERE 
sag_registrering_id=new_sag_registrering.id
AND fremdrift = ''::SagFremdriftTils
;

END IF;


/**********************/
--Handle attributter (attributes) 

/********************************************/
--sag_attr_egenskaber
/********************************************/

--Generate and insert any merged objects, if any fields are null in attrSagObj
IF attrEgenskaber IS NOT null THEN

  --Input validation: 
  --Verify that there is no overlap in virkning in the array given

  IF EXISTS (
  SELECT
  a.*
  FROM unnest(attrEgenskaber) a
  JOIN  unnest(attrEgenskaber) b on (a.virkning).TimePeriod && (b.virkning).TimePeriod
  GROUP BY a.brugervendtnoegle,a.afleveret,a.beskrivelse,a.hjemmel,a.kassationskode,a.offentlighedundtaget,a.principiel,a.sagsnummer,a.titel, a.virkning
  HAVING COUNT(*)>1
  ) THEN
  RAISE EXCEPTION 'Unable to update sag with uuid [%], as the sag have overlapping virknings in the given egenskaber array :%',sag_uuid,to_json(attrEgenskaber)  USING ERRCODE = 22000;

  END IF;


  FOREACH attrEgenskaberObj in array attrEgenskaber
  LOOP

  --To avoid needless fragmentation we'll check for presence of null values in the fields - and if none are present, we'll skip the merging operations
  IF (attrEgenskaberObj).brugervendtnoegle is null OR 
   (attrEgenskaberObj).afleveret is null OR 
   (attrEgenskaberObj).beskrivelse is null OR 
   (attrEgenskaberObj).hjemmel is null OR 
   (attrEgenskaberObj).kassationskode is null OR 
   (attrEgenskaberObj).offentlighedundtaget is null OR 
   (attrEgenskaberObj).principiel is null OR 
   (attrEgenskaberObj).sagsnummer is null OR 
   (attrEgenskaberObj).titel is null 
  THEN

  INSERT INTO
  sag_attr_egenskaber
  (
    brugervendtnoegle,afleveret,beskrivelse,hjemmel,kassationskode,offentlighedundtaget,principiel,sagsnummer,titel
    ,virkning
    ,sag_registrering_id
  )
  SELECT 
    coalesce(attrEgenskaberObj.brugervendtnoegle,a.brugervendtnoegle), 
    coalesce(attrEgenskaberObj.afleveret,a.afleveret), 
    coalesce(attrEgenskaberObj.beskrivelse,a.beskrivelse), 
    coalesce(attrEgenskaberObj.hjemmel,a.hjemmel), 
    coalesce(attrEgenskaberObj.kassationskode,a.kassationskode), 
    coalesce(attrEgenskaberObj.offentlighedundtaget,a.offentlighedundtaget), 
    coalesce(attrEgenskaberObj.principiel,a.principiel), 
    coalesce(attrEgenskaberObj.sagsnummer,a.sagsnummer), 
    coalesce(attrEgenskaberObj.titel,a.titel),
	ROW (
	  (a.virkning).TimePeriod * (attrEgenskaberObj.virkning).TimePeriod,
	  (attrEgenskaberObj.virkning).AktoerRef,
	  (attrEgenskaberObj.virkning).AktoerTypeKode,
	  (attrEgenskaberObj.virkning).NoteTekst
	)::Virkning,
    new_sag_registrering.id
  FROM sag_attr_egenskaber a
  WHERE
    a.sag_registrering_id=prev_sag_registrering.id 
    and (a.virkning).TimePeriod && (attrEgenskaberObj.virkning).TimePeriod
  ;

  --For any periods within the virkning of the attrEgenskaberObj, that is NOT covered by any "merged" rows inserted above, generate and insert rows

  INSERT INTO
  sag_attr_egenskaber
  (
    brugervendtnoegle,afleveret,beskrivelse,hjemmel,kassationskode,offentlighedundtaget,principiel,sagsnummer,titel
    ,virkning
    ,sag_registrering_id
  )
  SELECT 
    attrEgenskaberObj.brugervendtnoegle, 
    attrEgenskaberObj.afleveret, 
    attrEgenskaberObj.beskrivelse, 
    attrEgenskaberObj.hjemmel, 
    attrEgenskaberObj.kassationskode, 
    attrEgenskaberObj.offentlighedundtaget, 
    attrEgenskaberObj.principiel, 
    attrEgenskaberObj.sagsnummer, 
    attrEgenskaberObj.titel,
	  ROW (
	       b.tz_range_leftover,
	      (attrEgenskaberObj.virkning).AktoerRef,
	      (attrEgenskaberObj.virkning).AktoerTypeKode,
	      (attrEgenskaberObj.virkning).NoteTekst
	  )::Virkning,
    new_sag_registrering.id
  FROM
  (
  --build an array of the timeperiod of the virkning of the sag_attr_egenskaber of the new registrering to pass to _subtract_tstzrange_arr 
      SELECT coalesce(array_agg((b.virkning).TimePeriod),array[]::TSTZRANGE[]) tzranges_of_new_reg
      FROM sag_attr_egenskaber b
      WHERE 
       b.sag_registrering_id=new_sag_registrering.id
  ) as a
  JOIN unnest(_subtract_tstzrange_arr((attrEgenskaberObj.virkning).TimePeriod,a.tzranges_of_new_reg)) as b(tz_range_leftover) on true
  ;

  ELSE
    --insert attrEgenskaberObj raw (if there were no null-valued fields) 

    INSERT INTO
    sag_attr_egenskaber
    (
    brugervendtnoegle,afleveret,beskrivelse,hjemmel,kassationskode,offentlighedundtaget,principiel,sagsnummer,titel
    ,virkning
    ,sag_registrering_id
    )
    VALUES ( 
    attrEgenskaberObj.brugervendtnoegle, 
    attrEgenskaberObj.afleveret, 
    attrEgenskaberObj.beskrivelse, 
    attrEgenskaberObj.hjemmel, 
    attrEgenskaberObj.kassationskode, 
    attrEgenskaberObj.offentlighedundtaget, 
    attrEgenskaberObj.principiel, 
    attrEgenskaberObj.sagsnummer, 
    attrEgenskaberObj.titel,
    attrEgenskaberObj.virkning,
    new_sag_registrering.id
    );

  END IF;

  END LOOP;
END IF;


IF attrEgenskaber IS NOT NULL AND coalesce(array_length(attrEgenskaber,1),0)=0 THEN
--raise debug 'Skipping handling of egenskaber of previous registration as an empty array was explicit given.';  
ELSE 

--Handle egenskaber of previous registration, taking overlapping virknings into consideration (using function subtract_tstzrange)

INSERT INTO sag_attr_egenskaber (
    brugervendtnoegle,afleveret,beskrivelse,hjemmel,kassationskode,offentlighedundtaget,principiel,sagsnummer,titel
    ,virkning
    ,sag_registrering_id
)
SELECT
      a.brugervendtnoegle,
      a.afleveret,
      a.beskrivelse,
      a.hjemmel,
      a.kassationskode,
      a.offentlighedundtaget,
      a.principiel,
      a.sagsnummer,
      a.titel,
	  ROW(
	    c.tz_range_leftover,
	      (a.virkning).AktoerRef,
	      (a.virkning).AktoerTypeKode,
	      (a.virkning).NoteTekst
	  ) :: virkning,
	 new_sag_registrering.id
FROM
(
 --build an array of the timeperiod of the virkning of the sag_attr_egenskaber of the new registrering to pass to _subtract_tstzrange_arr on the sag_attr_egenskaber of the previous registrering 
    SELECT coalesce(array_agg((b.virkning).TimePeriod),array[]::TSTZRANGE[]) tzranges_of_new_reg
    FROM sag_attr_egenskaber b
    WHERE 
          b.sag_registrering_id=new_sag_registrering.id
) d
  JOIN sag_attr_egenskaber a ON true  
  JOIN unnest(_subtract_tstzrange_arr((a.virkning).TimePeriod,tzranges_of_new_reg)) as c(tz_range_leftover) on true
  WHERE a.sag_registrering_id=prev_sag_registrering.id     
;



--Remove any "cleared"/"deleted" attributes
DELETE FROM sag_attr_egenskaber a
WHERE 
a.sag_registrering_id=new_sag_registrering.id
AND (a.brugervendtnoegle IS NULL OR a.brugervendtnoegle='') 
            AND  (a.afleveret IS NULL) 
            AND  (a.beskrivelse IS NULL OR a.beskrivelse='') 
            AND  (a.hjemmel IS NULL OR a.hjemmel='') 
            AND  (a.kassationskode IS NULL OR a.kassationskode='') 
            AND  (a.offentlighedundtaget IS NULL OR (((a.offentlighedundtaget).AlternativTitel IS NULL OR (a.offentlighedundtaget).AlternativTitel='') AND ((a.offentlighedundtaget).Hjemmel IS NULL OR (a.offentlighedundtaget).Hjemmel=''))) 
            AND  (a.principiel IS NULL) 
            AND  (a.sagsnummer IS NULL OR a.sagsnummer='') 
            AND  (a.titel IS NULL OR a.titel='')
;

END IF;


/******************************************************************/
--If the new registrering is identical to the previous one, we need to throw an exception to abort the transaction. 

read_new_sag:=as_read_sag(sag_uuid, (new_sag_registrering.registrering).timeperiod,null);
read_prev_sag:=as_read_sag(sag_uuid, (prev_sag_registrering.registrering).timeperiod ,null);
 
--the ordering in as_list (called by as_read) ensures that the latest registration is returned at index pos 1

IF NOT (lower((read_new_sag.registrering[1].registrering).TimePeriod)=lower((new_sag_registrering.registrering).TimePeriod) AND lower((read_prev_sag.registrering[1].registrering).TimePeriod)=lower((prev_sag_registrering.registrering).TimePeriod)) THEN
  RAISE EXCEPTION 'Error updating sag with id [%]: The ordering of as_list_sag should ensure that the latest registrering can be found at index 1. Expected new reg: [%]. Actual new reg at index 1: [%]. Expected prev reg: [%]. Actual prev reg at index 1: [%].',sag_uuid,to_json(new_sag_registrering),to_json(read_new_sag.registrering[1].registrering),to_json(prev_sag_registrering),to_json(prev_new_sag.registrering[1].registrering);
END IF;
 
 --we'll ignore the registreringBase part in the comparrison - except for the livcykluskode

read_new_sag_reg:=ROW(
ROW(null,(read_new_sag.registrering[1].registrering).livscykluskode,null,null)::registreringBase,
(read_new_sag.registrering[1]).tilsFremdrift ,
(read_new_sag.registrering[1]).attrEgenskaber ,
(read_new_sag.registrering[1]).relationer 
)::sagRegistreringType
;

read_prev_sag_reg:=ROW(
ROW(null,(read_prev_sag.registrering[1].registrering).livscykluskode,null,null)::registreringBase,
(read_prev_sag.registrering[1]).tilsFremdrift ,
(read_prev_sag.registrering[1]).attrEgenskaber ,
(read_prev_sag.registrering[1]).relationer 
)::sagRegistreringType
;


IF read_prev_sag_reg=read_new_sag_reg THEN
  --RAISE NOTICE 'Note[%]. Aborted reg:%',note,to_json(read_new_sag_reg);
  --RAISE NOTICE 'Note[%]. Previous reg:%',note,to_json(read_prev_sag_reg);
  RAISE EXCEPTION 'Aborted updating sag with id [%] as the given data, does not give raise to a new registration. Aborted reg:[%], previous reg:[%]',sag_uuid,to_json(read_new_sag_reg),to_json(read_prev_sag_reg) USING ERRCODE = 22000;
END IF;

/******************************************************************/


return new_sag_registrering.id;



END;
$$ LANGUAGE plpgsql VOLATILE;





