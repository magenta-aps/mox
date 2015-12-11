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
  varianter  DokumentVariantType[],
  lostUpdatePreventionTZ TIMESTAMPTZ = null,
  auth_criteria_arr DokumentRegistreringType[]=null
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
  auth_filtered_uuids uuid[];
  dokument_variant_obj DokumentVariantType;
  dokument_variant_egenskab_obj DokumentVariantEgenskaberType;
  dokument_del_obj DokumentDelType;
  dokument_del_egenskaber_obj DokumentDelEgenskaberType;
  dokument_del_relation_obj DokumentDelRelationType;
  dokument_variant_new_id bigint;
  dokument_del_new_id bigint;
  dokument_variant_egenskaber_expl_deleted text[]:=array[]::text[];
  dokument_variant_dele_all_expl_deleted text[]:=array[]::text[];
  dokument_variant_del_egenskaber_deleted _DokumentVariantDelKey[]:=array[]::_DokumentVariantDelKey[];
  dokument_variant_del_relationer_deleted _DokumentVariantDelKey[]:=array[]::_DokumentVariantDelKey[];
  dokument_variants_prev_reg_arr text[];
  dokument_variant_egenskaber_prev_reg_varianttekst text;
  dokument_variant_id bigint;
  dokument_variant_del_prev_reg_arr _DokumentVariantDelKey[];
  dokument_variant_del_prev_reg _DokumentVariantDelKey;
  dokument_del_id bigint;
  dokument_variant_del_prev_reg_rel_transfer _DokumentVariantDelKey[];
BEGIN

--create a new registrering

IF NOT EXISTS (select a.id from dokument a join dokument_registrering b on b.dokument_id=a.id  where a.id=dokument_uuid) THEN
   RAISE EXCEPTION 'Unable to update dokument with uuid [%], being unable to find any previous registrations.',dokument_uuid USING ERRCODE = 'MO400';
END IF;

PERFORM a.id FROM dokument a
WHERE a.id=dokument_uuid
FOR UPDATE; --We synchronize concurrent invocations of as_updates of this particular object on a exclusive row lock. This lock will be held by the current transaction until it terminates.

/*** Verify that the object meets the stipulated access allowed criteria  ***/
auth_filtered_uuids:=_as_filter_unauth_dokument(array[dokument_uuid]::uuid[],auth_criteria_arr); 
IF NOT (coalesce(array_length(auth_filtered_uuids,1),0)=1 AND auth_filtered_uuids @>ARRAY[dokument_uuid]) THEN
  RAISE EXCEPTION 'Unable to update dokument with uuid [%]. Object does not met stipulated criteria:%',dokument_uuid,to_json(auth_criteria_arr)  USING ERRCODE = 'MO401'; 
END IF;
/*********************/


new_dokument_registrering := _as_create_dokument_registrering(dokument_uuid,livscykluskode, brugerref, note);
prev_dokument_registrering := _as_get_prev_dokument_registrering(new_dokument_registrering);

IF lostUpdatePreventionTZ IS NOT NULL THEN
  IF NOT (LOWER((prev_dokument_registrering.registrering).timeperiod)=lostUpdatePreventionTZ) THEN
    RAISE EXCEPTION 'Unable to update dokument with uuid [%], as the dokument seems to have been updated since latest read by client (the given lostUpdatePreventionTZ [%] does not match the timesamp of latest registration [%]).',dokument_uuid,lostUpdatePreventionTZ,LOWER((prev_dokument_registrering.registrering).timeperiod) USING ERRCODE = 'MO409';
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
            a.uuid,
              a.urn,
                a.relType,
                  a.objektType
      FROM unnest(relationer) as a
    ;

   
  --Ad 2)

  /**********************/
  -- 0..1 relations 
   

  FOREACH dokument_relation_navn in array  ARRAY['nyrevision'::DokumentRelationKode,'primaerklasse'::DokumentRelationKode,'ejer'::DokumentRelationKode,'ansvarlig'::DokumentRelationKode,'primaerbehandler'::DokumentRelationKode,'fordelttil'::DokumentRelationKode]::DokumentRelationKode[]
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


  FOREACH dokument_relation_navn in array ARRAY['arkiver'::DokumentRelationKode,'besvarelser'::DokumentRelationKode,'udgangspunkter'::DokumentRelationKode,'kommentarer'::DokumentRelationKode,'bilag'::DokumentRelationKode,'andredokumenter'::DokumentRelationKode,'andreklasser'::DokumentRelationKode,'andrebehandlere'::DokumentRelationKode,'parter'::DokumentRelationKode,'kopiparter'::DokumentRelationKode,'tilknyttedesager'::DokumentRelationKode]::DokumentRelationKode[]
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
  RAISE EXCEPTION 'Unable to update dokument with uuid [%], as the dokument have overlapping virknings in the given egenskaber array :%',dokument_uuid,to_json(attrEgenskaber)  USING ERRCODE = 'MO400';

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
    CASE WHEN (attrEgenskaberObj.brevdato).cleared THEN NULL 
    ELSE coalesce((attrEgenskaberObj.brevdato).value,a.brevdato)
    END,
    coalesce(attrEgenskaberObj.kassationskode,a.kassationskode), 
    CASE WHEN (attrEgenskaberObj.major).cleared THEN NULL 
    ELSE coalesce((attrEgenskaberObj.major).value,a.major)
    END, 
    CASE WHEN (attrEgenskaberObj.minor).cleared THEN NULL 
    ELSE coalesce((attrEgenskaberObj.minor).value,a.minor)
    END,
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





END IF;

/******************************************************************/
--Handling document variants and document parts

--check if the update explicitly clears all the doc variants (and parts) by explicitly giving an empty array, if so - no variant will be included in the new reg. 
IF varianter IS NOT NULL AND coalesce(array_length(varianter,1),0)=0 THEN
  --raise notice 'Skipping insertion of doc variants (and parts), as an empty array was given explicitly';
ELSE

--Check if any variants was given in the new update - otherwise we'll skip ahead to transfering the old variants
IF varianter IS NOT NULL AND coalesce(array_length(varianter,1),0)>0 THEN
  
FOREACH dokument_variant_obj IN ARRAY varianter
LOOP

dokument_variant_new_id:=_ensure_document_variant_exists_and_get(new_dokument_registrering.id,dokument_variant_obj.varianttekst);

--handle variant egenskaber
IF dokument_variant_obj.egenskaber IS NOT NULL AND coalesce(array_length(dokument_variant_obj.egenskaber,1),0)=0 THEN
dokument_variant_egenskaber_expl_deleted:=array_append(dokument_variant_egenskaber_expl_deleted, dokument_variant_obj.varianttekst);
ELSE 


IF dokument_variant_obj.egenskaber IS NOT NULL AND coalesce(array_length(dokument_variant_obj.egenskaber,1),0)>0 THEN

  --Input validation: 
  --Verify that there is no overlap in virkning in the array given

  IF EXISTS (
  SELECT
  a.*
  FROM unnest(dokument_variant_obj.egenskaber) a
  JOIN  unnest(dokument_variant_obj.egenskaber) b on (a.virkning).TimePeriod && (b.virkning).TimePeriod
  GROUP BY a.arkivering,a.delvisscannet,a.offentliggoerelse,a.produktion, a.virkning
  HAVING COUNT(*)>1
  ) THEN
  RAISE EXCEPTION 'Unable to update dokument with uuid [%], as the given dokument variant [%] have overlapping virknings in the given egenskaber array :%',dokument_uuid,dokument_variant_obj.varianttekst,to_json(dokument_variant_obj.egenskaber)  USING ERRCODE = 22000;

  END IF;


FOREACH dokument_variant_egenskab_obj IN ARRAY dokument_variant_obj.egenskaber
  LOOP

   IF (dokument_variant_egenskab_obj).arkivering is null OR 
   (dokument_variant_egenskab_obj).delvisscannet is null OR 
   (dokument_variant_egenskab_obj).offentliggoerelse is null OR 
   (dokument_variant_egenskab_obj).produktion is null 
  THEN


  INSERT INTO dokument_variant_egenskaber(
    variant_id,
        arkivering, 
          delvisscannet, 
            offentliggoerelse, 
              produktion,
                virkning
      )
  SELECT
    dokument_variant_new_id, 
        CASE WHEN (dokument_variant_egenskab_obj.arkivering).cleared THEN NULL 
        ELSE coalesce((dokument_variant_egenskab_obj.arkivering).value,a.arkivering)
        END, 
          CASE WHEN (dokument_variant_egenskab_obj.delvisscannet).cleared THEN NULL 
          ELSE coalesce((dokument_variant_egenskab_obj.delvisscannet).value,a.delvisscannet)
          END,
            CASE WHEN (dokument_variant_egenskab_obj.offentliggoerelse).cleared THEN NULL 
            ELSE coalesce((dokument_variant_egenskab_obj.offentliggoerelse).value,a.offentliggoerelse)
            END,
              CASE WHEN (dokument_variant_egenskab_obj.produktion).cleared THEN NULL 
              ELSE coalesce((dokument_variant_egenskab_obj.produktion).value,a.produktion)
              END,
                ROW (
                  (a.virkning).TimePeriod * (dokument_variant_egenskab_obj.virkning).TimePeriod,
                  (dokument_variant_egenskab_obj.virkning).AktoerRef,
                  (dokument_variant_egenskab_obj.virkning).AktoerTypeKode,
                  (dokument_variant_egenskab_obj.virkning).NoteTekst
                )::Virkning
  FROM dokument_variant_egenskaber a
  JOIN dokument_variant b on a.variant_id=b.id
  WHERE
    b.dokument_registrering_id=prev_dokument_registrering.id 
    and b.varianttekst=dokument_variant_obj.varianttekst
    and (a.virkning).TimePeriod && (dokument_variant_egenskab_obj.virkning).TimePeriod
  ;


  --For any periods within the virkning of the dokument_variant_egenskab_obj, that is NOT covered by any "merged" rows inserted above, generate and insert rows

  INSERT INTO
  dokument_variant_egenskaber
  (
    variant_id,
      arkivering, 
        delvisscannet, 
          offentliggoerelse, 
            produktion,
              virkning
  )
  SELECT 
    dokument_variant_new_id,
      dokument_variant_egenskab_obj.arkivering, 
        dokument_variant_egenskab_obj.delvisscannet, 
          dokument_variant_egenskab_obj.offentliggoerelse, 
            dokument_variant_egenskab_obj.produktion,
              ROW (
                   b.tz_range_leftover,
                  (dokument_variant_egenskab_obj.virkning).AktoerRef,
                  (dokument_variant_egenskab_obj.virkning).AktoerTypeKode,
                  (dokument_variant_egenskab_obj.virkning).NoteTekst
              )::Virkning
  FROM
  (
  --build an array of the timeperiod of the virkning of the dokument variant egenskaber of the new registrering to pass to _subtract_tstzrange_arr 
      SELECT coalesce(array_agg((b.virkning).TimePeriod),array[]::TSTZRANGE[]) tzranges_of_new_reg
      FROM dokument_variant_egenskaber b
      WHERE 
       b.variant_id=dokument_variant_new_id
  ) as a
  JOIN unnest(_subtract_tstzrange_arr((dokument_variant_egenskab_obj.virkning).TimePeriod,a.tzranges_of_new_reg)) as b(tz_range_leftover) on true
  ;
  ELSE 

   --insert attrEgenskaberObj raw (if there were no null-valued fields) 

   INSERT INTO
    dokument_variant_egenskaber (
      variant_id,
        arkivering, 
          delvisscannet, 
            offentliggoerelse, 
              produktion,
                virkning
    )
    VALUES ( 
      dokument_variant_new_id,
        dokument_variant_egenskab_obj.arkivering, 
          dokument_variant_egenskab_obj.delvisscannet, 
            dokument_variant_egenskab_obj.offentliggoerelse, 
              dokument_variant_egenskab_obj.produktion,
                dokument_variant_egenskab_obj.virkning
    );

  END IF; --else block: null elements present in -dokument_variant_obj.egenskab obj

  END LOOP; --dokument_variant_obj.egenskaber


END IF; --variant egenskaber given.

END IF; --else block: explicit empty array of variant egenskaber given


--handle variant dele
IF dokument_variant_obj.dele IS NOT NULL AND coalesce(array_length(dokument_variant_obj.dele,1),0)=0 THEN

dokument_variant_dele_all_expl_deleted :=array_append(dokument_variant_dele_all_expl_deleted, dokument_variant_obj.varianttekst);

ELSE

IF dokument_variant_obj.dele IS NOT NULL AND coalesce(array_length(dokument_variant_obj.dele,1),0)>0 THEN


FOREACH dokument_del_obj IN ARRAY dokument_variant_obj.dele
    LOOP

    dokument_del_new_id:=_ensure_document_del_exists_and_get(new_dokument_registrering.id, dokument_variant_new_id, dokument_del_obj.deltekst);

    IF dokument_del_obj.egenskaber IS NOT NULL AND coalesce(array_length(dokument_del_obj.egenskaber,1),0)=0 THEN
    dokument_variant_del_egenskaber_deleted:=array_append(dokument_variant_del_egenskaber_deleted,ROW( dokument_variant_obj.varianttekst, dokument_del_obj.deltekst)::_DokumentVariantDelKey);
    ELSE

    IF dokument_del_obj.egenskaber IS NOT NULL AND coalesce(array_length(dokument_del_obj.egenskaber,1),0)>0 THEN  

    --Input validation: 
    --Verify that there is no overlap in virkning in the array given
    IF EXISTS (
      SELECT
      a.*
      FROM unnest(dokument_del_obj.egenskaber) a
      JOIN  unnest(dokument_del_obj.egenskaber) b on (a.virkning).TimePeriod && (b.virkning).TimePeriod
      GROUP BY a.indeks,a.indhold,a.lokation,a.mimetype, a.virkning
      HAVING COUNT(*)>1
    ) THEN
    RAISE EXCEPTION 'Unable to update dokument with uuid [%], as the dokument variant [%] have del [%] with overlapping virknings in the given egenskaber array :%',dokument_uuid,dokument_variant_obj.varianttekst,dokument_del_obj.deltekst,to_json(dokument_del_obj.egenskaber)  USING ERRCODE = 22000;
    END IF;



  FOREACH dokument_del_egenskaber_obj in array dokument_del_obj.egenskaber
  LOOP

  --To avoid needless fragmentation we'll check for presence of null values in the fields - and if none are present, we'll skip the merging operations
  IF (dokument_del_egenskaber_obj).indeks is null OR 
   (dokument_del_egenskaber_obj).indhold is null OR 
   (dokument_del_egenskaber_obj).lokation is null OR 
   (dokument_del_egenskaber_obj).mimetype is null 
  THEN

  INSERT INTO
  dokument_del_egenskaber
  (
    del_id,
      indeks,
        indhold,
          lokation,
            mimetype,
              virkning
  )
  SELECT 
    dokument_del_new_id, 
      CASE WHEN (dokument_del_egenskaber_obj.indeks).cleared THEN NULL 
      ELSE coalesce((dokument_del_egenskaber_obj.indeks).value,a.indeks)
      END, 
        coalesce(dokument_del_egenskaber_obj.indhold,a.indhold), 
          coalesce(dokument_del_egenskaber_obj.lokation,a.lokation), 
            coalesce(dokument_del_egenskaber_obj.mimetype,a.mimetype),
              ROW (
                (a.virkning).TimePeriod * (dokument_del_egenskaber_obj.virkning).TimePeriod,
                (dokument_del_egenskaber_obj.virkning).AktoerRef,
                (dokument_del_egenskaber_obj.virkning).AktoerTypeKode,
                (dokument_del_egenskaber_obj.virkning).NoteTekst
              )::Virkning
  FROM dokument_del_egenskaber a
  JOIN dokument_del b on a.del_id=b.id
  JOIN dokument_variant c on b.variant_id=c.id
  WHERE
    c.dokument_registrering_id=prev_dokument_registrering.id 
    and c.varianttekst=dokument_variant_obj.varianttekst
    and b.deltekst=dokument_del_obj.deltekst
    and (a.virkning).TimePeriod && (dokument_del_egenskaber_obj.virkning).TimePeriod
  ;

  --For any periods within the virkning of the dokument_del_egenskaber_obj, that is NOT covered by any "merged" rows inserted above, generate and insert rows

  INSERT INTO
  dokument_del_egenskaber
  (
    del_id,
      indeks,
        indhold,
          lokation,
            mimetype,
              virkning
  )
  SELECT 
    dokument_del_new_id,
      dokument_del_egenskaber_obj.indeks, 
        dokument_del_egenskaber_obj.indhold, 
          dokument_del_egenskaber_obj.lokation, 
            dokument_del_egenskaber_obj.mimetype,
              ROW (
                   b.tz_range_leftover,
                  (dokument_del_egenskaber_obj.virkning).AktoerRef,
                  (dokument_del_egenskaber_obj.virkning).AktoerTypeKode,
                  (dokument_del_egenskaber_obj.virkning).NoteTekst
              )::Virkning
  FROM
  (
  --build an array of the timeperiod of the virkning of the relevant dokument_del_egenskaber of the new registrering to pass to _subtract_tstzrange_arr 
      SELECT coalesce(array_agg((b.virkning).TimePeriod),array[]::TSTZRANGE[]) tzranges_of_new_reg
      FROM dokument_del_egenskaber b
      JOIN dokument_del c on b.del_id=c.id
      JOIN dokument_variant d on c.variant_id=d.id
      WHERE 
      d.dokument_registrering_id=new_dokument_registrering.id
      and d.varianttekst=dokument_variant_obj.varianttekst
      and c.deltekst=dokument_del_obj.deltekst
  ) as a
  JOIN unnest(_subtract_tstzrange_arr((dokument_del_egenskaber_obj.virkning).TimePeriod,a.tzranges_of_new_reg)) as b(tz_range_leftover) on true
  ;
  ELSE
     --insert dokument_del_egenskaber_obj raw (if there were no null-valued fields)

  INSERT INTO
  dokument_del_egenskaber
  (
    del_id,
      indeks,
        indhold,
          lokation,
            mimetype,
              virkning
  )
  SELECT 
    dokument_del_new_id,
      dokument_del_egenskaber_obj.indeks, 
        dokument_del_egenskaber_obj.indhold, 
          dokument_del_egenskaber_obj.lokation, 
            dokument_del_egenskaber_obj.mimetype,
              dokument_del_egenskaber_obj.virkning
  ;

  END IF; --else block: null field in del egenskaber obj pesent

  END LOOP;
    END IF; --del obj has egenskaber given.

    END IF; --else block: explicit empty array of variant del egenskaber given

     IF dokument_del_obj.relationer IS NOT NULL AND coalesce(array_length(dokument_del_obj.relationer,1),0)=0 THEN
     dokument_variant_del_relationer_deleted:=array_append(dokument_variant_del_relationer_deleted,ROW( dokument_variant_obj.varianttekst, dokument_del_obj.deltekst)::_DokumentVariantDelKey);
    
    ELSE


    INSERT INTO dokument_del_relation(
        del_id, 
          virkning, 
            rel_maal_uuid, 
              rel_maal_urn, 
                rel_type, 
                  objekt_type
        )
    SELECT
        dokument_del_new_id,
          a.virkning,
            a.uuid,
              a.urn,
                a.relType,
                  a.objektType
    FROM unnest(dokument_del_obj.relationer) a(relType,virkning,uuid,urn,objektType)
    ;

    END IF; --explicit empty array of variant del relationer given

    END LOOP; --dokument_variant_obj.dele


END IF; --dokument dele present



END IF; --else block: explicit empty array of variant dele given





END LOOP;

END IF; --variants given with this update.


/****************************************************/
--carry over any variant egenskaber of the prev. registration, unless explicitly deleted - where there is room acording to virkning


SELECT array_agg(varianttekst) into dokument_variants_prev_reg_arr
FROM
dokument_variant a
WHERE a.dokument_registrering_id=prev_dokument_registrering.id
and a.varianttekst not in (select varianttekst from unnest(dokument_variant_egenskaber_expl_deleted) b(varianttekst) )
;

IF dokument_variants_prev_reg_arr IS NOT NULL AND coalesce(array_length(dokument_variants_prev_reg_arr,1),0)>0 THEN

FOREACH dokument_variant_egenskaber_prev_reg_varianttekst IN ARRAY dokument_variants_prev_reg_arr
LOOP 


dokument_variant_id:=_ensure_document_variant_exists_and_get(new_dokument_registrering.id,dokument_variant_egenskaber_prev_reg_varianttekst);

INSERT INTO
    dokument_variant_egenskaber (
      variant_id,
        arkivering, 
          delvisscannet, 
            offentliggoerelse, 
              produktion,
                virkning 
    )
SELECT
      dokument_variant_id,
        a.arkivering,
          a.delvisscannet,
            a.offentliggoerelse,
              a.produktion,               
                ROW(
                  c.tz_range_leftover,
              (a.virkning).AktoerRef,
              (a.virkning).AktoerTypeKode,
              (a.virkning).NoteTekst
                ) :: virkning
FROM
(
 --build an array of the timeperiod of the virkning of the dokument_variant_egenskaber of the new registrering to pass to _subtract_tstzrange_arr on the dokumentvariant_attr_egenskaber of the previous registrering 
    SELECT coalesce(array_agg((b.virkning).TimePeriod),array[]::TSTZRANGE[]) tzranges_of_new_reg
    FROM dokument_variant_egenskaber b
    WHERE 
    b.variant_id=dokument_variant_id

) d
  JOIN dokument_variant_egenskaber a ON true  
  JOIN dokument_variant e ON a.variant_id = e.id
  JOIN unnest(_subtract_tstzrange_arr((a.virkning).TimePeriod,tzranges_of_new_reg)) as c(tz_range_leftover) on true
  WHERE e.dokument_registrering_id=prev_dokument_registrering.id    
  and e.varianttekst=dokument_variant_egenskaber_prev_reg_varianttekst 
;

END LOOP; --loop dokument_variant_egenskaber_prev_reg_varianttekst
END IF;-- not null dokument_variants_prev_reg_arr


/****************************************************/
--carry over any variant del egenskaber of the prev. registration, unless explicitly deleted -  where there is room acording to virkning

  SELECT array_agg(row(a.varianttekst,a.deltekst)::_DokumentVariantDelKey) into dokument_variant_del_prev_reg_arr
  FROM
  (
  SELECT a.varianttekst,b.deltekst
  FROM
  dokument_variant a
  join dokument_del b on b.variant_id=a.id
  LEFT join unnest(dokument_variant_del_egenskaber_deleted) c(varianttekst,deltekst) on a.varianttekst=c.varianttekst and b.deltekst=c.deltekst
  LEFT JOIN unnest(dokument_variant_dele_all_expl_deleted) d(varianttekst) on d.varianttekst = a.varianttekst
  WHERE a.dokument_registrering_id=prev_dokument_registrering.id
  and d.varianttekst is null
  and (c.varianttekst is null and c.deltekst is null)
  group by a.varianttekst,b.deltekst
 ) as a
;
 

if dokument_variant_del_prev_reg_arr IS NOT NULL and coalesce(array_length(dokument_variant_del_prev_reg_arr,1),0)>0 THEN

  FOREACH dokument_variant_del_prev_reg in ARRAY dokument_variant_del_prev_reg_arr
  LOOP

  dokument_del_id:=_ensure_document_variant_and_del_exists_and_get_del(new_dokument_registrering.id,dokument_variant_del_prev_reg.varianttekst,dokument_variant_del_prev_reg.deltekst);

  INSERT INTO dokument_del_egenskaber (
      del_id,
        indeks,
          indhold,
            lokation,
              mimetype,
                virkning
    )
  SELECT
      dokument_del_id,
        a.indeks,
          a.indhold,
            a.lokation,
              a.mimetype,
                ROW(
                  c.tz_range_leftover,
                    (a.virkning).AktoerRef,
                    (a.virkning).AktoerTypeKode,
                    (a.virkning).NoteTekst
                ) :: virkning
  FROM
  (
   --build an array of the timeperiod of the virkning of the dokument_del_egenskaber of the new registrering to pass to _subtract_tstzrange_arr on the relevant dokument_del_egenskaber of the previous registrering 
      SELECT coalesce(array_agg((b.virkning).TimePeriod),array[]::TSTZRANGE[]) tzranges_of_new_reg
      FROM dokument_del_egenskaber b
      JOIN dokument_del c on b.del_id=c.id
      JOIN dokument_variant d on c.variant_id=d.id
      WHERE 
            d.dokument_registrering_id=new_dokument_registrering.id
            AND d.varianttekst=dokument_variant_del_prev_reg.varianttekst
            AND c.deltekst=dokument_variant_del_prev_reg.deltekst
  ) d
    JOIN dokument_del_egenskaber a ON true  
    JOIN dokument_del b on a.del_id=b.id
    JOIN dokument_variant e on b.variant_id=e.id
    JOIN unnest(_subtract_tstzrange_arr((a.virkning).TimePeriod,tzranges_of_new_reg)) as c(tz_range_leftover) on true
    WHERE e.dokument_registrering_id=prev_dokument_registrering.id    
    AND e.varianttekst=dokument_variant_del_prev_reg.varianttekst
    AND b.deltekst=dokument_variant_del_prev_reg.deltekst
  ;

  END LOOP;


END IF; --dokument_variant_del_prev_reg_arr not empty




/****************************************************/
--carry over any document part relations of the prev. relation if a) they were not explicitly cleared and b)no document part relations is already present for the variant del.



--3) Transfer relations of prev reg.

--Identify the variant + del combos that should have relations carried over
SELECT array_agg(ROW(e.varianttekst,e.deltekst)::_DokumentVariantDelKey) into dokument_variant_del_prev_reg_rel_transfer
FROM
(
  SELECT
  c.varianttekst,b.deltekst
  FROM dokument_del_relation a 
  JOIN dokument_del b on a.del_id=b.id
  JOIN dokument_variant c on b.variant_id=c.id
  LEFT JOIN unnest(dokument_variant_del_relationer_deleted) d(varianttekst,deltekst) on d.varianttekst=c.varianttekst and d.deltekst=b.deltekst
  WHERE c.dokument_registrering_id=prev_dokument_registrering.id
  AND ( d.varianttekst IS NULL AND d.deltekst IS NULL) 
  EXCEPT
  SELECT
  c.varianttekst,b.deltekst
  FROM dokument_del_relation a 
  JOIN dokument_del b on a.del_id=b.id
  JOIN dokument_variant c on b.variant_id=c.id
  WHERE c.dokument_registrering_id=new_dokument_registrering.id
) as e
;




-- Make sure that part + variants are in place 
IF dokument_variant_del_prev_reg_rel_transfer IS NOT NULL AND coalesce(array_length(dokument_variant_del_prev_reg_rel_transfer,1),0)>0 THEN
  FOREACH dokument_variant_del_prev_reg IN array dokument_variant_del_prev_reg_rel_transfer
  LOOP
     dokument_del_id:=_ensure_document_variant_and_del_exists_and_get_del(new_dokument_registrering.id,dokument_variant_del_prev_reg.varianttekst , dokument_variant_del_prev_reg.deltekst);

--transfer relations of prev reg.
INSERT INTO dokument_del_relation(
    del_id, 
      virkning, 
        rel_maal_uuid, 
          rel_maal_urn, 
            rel_type, 
              objekt_type
    )
SELECT
    dokument_del_id,
      a.virkning,
        a.rel_maal_uuid,
          a.rel_maal_urn,
            a.rel_type,
              a.objekt_type
FROM dokument_del_relation a 
JOIN dokument_del b on a.del_id=b.id
JOIN dokument_variant c on b.variant_id=c.id
WHERE c.dokument_registrering_id=prev_dokument_registrering.id
AND c.varianttekst=dokument_variant_del_prev_reg.varianttekst
AND b.deltekst=dokument_variant_del_prev_reg.deltekst
;

END LOOP;

END IF; --block: there are relations to transfer
END IF; --else block for skip on empty array for variants.


/******************************************************************/
--If the new registrering is identical to the previous one, we need to throw an exception to abort the transaction. 

read_new_dokument:=as_read_dokument(dokument_uuid, (new_dokument_registrering.registrering).timeperiod,null);
read_prev_dokument:=as_read_dokument(dokument_uuid, (prev_dokument_registrering.registrering).timeperiod ,null);
 
--the ordering in as_list (called by as_read) ensures that the latest registration is returned at index pos 1

IF NOT (lower((read_new_dokument.registrering[1].registrering).TimePeriod)=lower((new_dokument_registrering.registrering).TimePeriod) AND lower((read_prev_dokument.registrering[1].registrering).TimePeriod)=lower((prev_dokument_registrering.registrering).TimePeriod)) THEN
  RAISE EXCEPTION 'Error updating dokument with id [%]: The ordering of as_list_dokument should ensure that the latest registrering can be found at index 1. Expected new reg: [%]. Actual new reg at index 1: [%]. Expected prev reg: [%]. Actual prev reg at index 1: [%].',dokument_uuid,to_json(new_dokument_registrering),to_json(read_new_dokument.registrering[1].registrering),to_json(prev_dokument_registrering),to_json(prev_new_dokument.registrering[1].registrering) USING ERRCODE = 'MO500';
END IF;
 
 --we'll ignore the registreringBase part in the comparrison - except for the livcykluskode

read_new_dokument_reg:=ROW(
ROW(null,(read_new_dokument.registrering[1].registrering).livscykluskode,null,null)::registreringBase,
(read_new_dokument.registrering[1]).tilsFremdrift ,
(read_new_dokument.registrering[1]).attrEgenskaber ,
(read_new_dokument.registrering[1]).relationer,
(read_new_dokument.registrering[1]).varianter 
)::dokumentRegistreringType
;

read_prev_dokument_reg:=ROW(
ROW(null,(read_prev_dokument.registrering[1].registrering).livscykluskode,null,null)::registreringBase,
(read_prev_dokument.registrering[1]).tilsFremdrift ,
(read_prev_dokument.registrering[1]).attrEgenskaber ,
(read_prev_dokument.registrering[1]).relationer,
(read_prev_dokument.registrering[1]).varianter
)::dokumentRegistreringType
;


IF read_prev_dokument_reg=read_new_dokument_reg THEN
  --RAISE NOTICE 'Note[%]. Aborted reg:%',note,to_json(read_new_dokument_reg);
  --RAISE NOTICE 'Note[%]. Previous reg:%',note,to_json(read_prev_dokument_reg);
  RAISE EXCEPTION 'Aborted updating dokument with id [%] as the given data, does not give raise to a new registration. Aborted reg:[%], previous reg:[%]',dokument_uuid,to_json(read_new_dokument_reg),to_json(read_prev_dokument_reg) USING ERRCODE = 'MO400';
END IF;

/******************************************************************/

PERFORM actual_state._amqp_publish_notification('Dokument', livscykluskode, dokument_uuid);

return new_dokument_registrering.id;



END;
$$ LANGUAGE plpgsql VOLATILE;





