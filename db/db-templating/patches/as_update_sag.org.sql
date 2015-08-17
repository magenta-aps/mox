-- Copyright (C) 2015 Magenta ApS, http://magenta.dk.
-- Contact: info@magenta.dk.
--
-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at http://mozilla.org/MPL/2.0/.

/*
NOTICE: This file is auto-generated using the script: apply-template.py sag as_update.jinja.sql
*/




--Also notice, that the given arrays of SagAttr...Type must be consistent regarding virkning (although the allowance of null-values might make it possible to construct 'logically consistent'-arrays of objects with overlapping virknings)

CREATE OR REPLACE FUNCTION as_update_sag(
  sag_uuid uuid,
  brugerref uuid,
  note text,
  livscykluskode Livscykluskode,           
  attrEgenskaber SagEgenskaberAttrType[],
  tilsFremdrift SagFremdriftTilsType[],
  relationer SagRelationType[],
  lostUpdatePreventionTZ TIMESTAMPTZ = null,
  auth_criteria_arr SagRegistreringType[]=null
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
  auth_filtered_uuids uuid[];
  rel_type_max_index_prev_rev int;
  rel_type_max_index_arr _SagRelationMaxIndex[];
  sag_rel_type_cardinality_unlimited SagRelationKode[]:=ARRAY['andetarkiv'::SagRelationKode,'andrebehandlere'::SagRelationKode,'sekundaerpart'::SagRelationKode,'andresager'::SagRelationKode,'byggeri'::SagRelationKode,'fredning'::SagRelationKode,'journalpost'::SagRelationKode]::SagRelationKode[];
  sag_uuid_underscores text;
  sag_rel_seq_name text;

BEGIN

--create a new registrering

IF NOT EXISTS (select a.id from sag a join sag_registrering b on b.sag_id=a.id  where a.id=sag_uuid) THEN
   RAISE EXCEPTION 'Unable to update sag with uuid [%], being unable to find any previous registrations.',sag_uuid;
END IF;

PERFORM a.id FROM sag a
WHERE a.id=sag_uuid
FOR UPDATE; --We synchronize concurrent invocations of as_updates of this particular object on a exclusive row lock. This lock will be held by the current transaction until it terminates.

/*** Verify that the object meets the stipulated access allowed criteria  ***/
auth_filtered_uuids:=_as_filter_unauth_sag(array[sag_uuid]::uuid[],auth_criteria_arr); 
IF NOT (coalesce(array_length(auth_filtered_uuids,1),0)=1 AND auth_filtered_uuids @>ARRAY[sag_uuid]) THEN
  RAISE EXCEPTION 'Unable to update sag with uuid [%]. Object does not met stipulated criteria:%',sag_uuid,to_json(auth_criteria_arr)  USING ERRCODE = 'MO401'; 
END IF;
/*********************/


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
  --2) Insert relations of previous registration, with index values not included in this update. Please notice that for the logic to work,
  --  it is very important that the index sequences start with the max value for index of the same type in the previous registration

  --Ad 1)

--build array with the max index values of the different types of relations of the previous registration
SELECT array_agg(rel_type_max_index)::_SagRelationMaxIndex[] into rel_type_max_index_arr
FROM
(
  SELECT
  (ROW(rel_type,coalesce(max(rel_index),0))::_SagRelationMaxIndex) rel_type_max_index  
  FROM sag_relation a
  where a.sag_registrering_id=prev_sag_registrering.id
  and a.rel_type = any (sag_rel_type_cardinality_unlimited)
  group by rel_type
) as a
;


--Create temporary sequences
sag_uuid_underscores:=replace(sag_uuid::text, '-', '_');

FOREACH sag_relation_navn IN ARRAY (SELECT array_agg( DISTINCT a.RelType) FROM  unnest(relationer) a WHERE a.RelType = any (sag_rel_type_cardinality_unlimited))
  LOOP
  sag_rel_seq_name := 'sag_rel_' || sag_relation_navn::text || sag_uuid_underscores;

  rel_type_max_index_prev_rev:=null;

  SELECT 
    a.relIndex into rel_type_max_index_prev_rev
  FROM
    unnest(rel_type_max_index_arr) a(relType,relIndex)
  WHERE
    a.relType=sag_relation_navn
  ;
  
  IF rel_type_max_index_prev_rev IS NULL THEN
    rel_type_max_index_prev_rev:=0;
  END IF;

  EXECUTE 'CREATE TEMPORARY SEQUENCE ' || sag_rel_seq_name || '
  INCREMENT 1
  MINVALUE 1
  MAXVALUE 9223372036854775807
  START ' ||  (rel_type_max_index_prev_rev+1)::text ||'
  CACHE 1;';

END LOOP;

      INSERT INTO sag_relation (
        sag_registrering_id,
          virkning,
            rel_maal_uuid,
              rel_maal_urn,
                rel_type,
                  objekt_type,
                    rel_index,
                      rel_type_spec,
                        journal_notat,
                          journal_dokument_attr
      )
      SELECT
        new_sag_registrering.id,
          a.virkning,
            a.relMaalUuid,
              a.relMaalUrn,
                a.relType,
                  a.objektType,
                    CASE 
                    WHEN a.relType = any (sag_rel_type_cardinality_unlimited) THEN
                      CASE WHEN a.relIndex IS NULL OR b.id IS NULL THEN --for new relations and relations with index given that is not found in prev registrering, we'll assign new index values 
                        nextval('sag_rel_' || a.relType::text || sag_uuid_underscores)
                      ELSE
                        a.relIndex
                      END
                    ELSE
                    NULL
                    END,
                      CASE 
                        WHEN a.relType='journalpost' THEN a.relTypeSpec
                        ELSE
                        NULL
                      END,
                        CASE 
                          WHEN  
                            (NOT (a.journalNotat IS NULL)) 
                            AND
                            (
                              (a.journalNotat).titel IS NOT NULL
                              OR
                              (a.journalNotat).notat IS NOT NULL
                              OR
                              (a.journalNotat).format IS NOT NULL
                            )
                           THEN a.journalNotat
                          ELSE
                           NULL
                        END
                          ,CASE 
                            WHEN ( 
                                    (NOT a.journalDokumentAttr IS NULL)
                                    AND
                                    (
                                      (a.journalDokumentAttr).dokumenttitel IS NOT NULL
                                      OR
                                      (
                                        NOT ((a.journalDokumentAttr).offentlighedUndtaget IS NULL)
                                        AND
                                        (
                                          ((a.journalDokumentAttr).offentlighedUndtaget).AlternativTitel IS NOT NULL
                                          OR
                                          ((a.journalDokumentAttr).offentlighedUndtaget).Hjemmel IS NOT NULL
                                        )
                                      )
                                   )
                                 ) THEN a.journalDokumentAttr
                            ELSE
                            NULL
                          END
      FROM unnest(relationer) as a
      LEFT JOIN sag_relation b on a.relType = any (sag_rel_type_cardinality_unlimited) and b.sag_registrering_id=prev_sag_registrering.id and a.relType=b.rel_type and a.relIndex=b.rel_index
    ;


--Drop temporary sequences
FOREACH sag_relation_navn IN ARRAY (SELECT array_agg( DISTINCT a.RelType) FROM  unnest(relationer) a WHERE a.RelType = any (sag_rel_type_cardinality_unlimited))
  LOOP
  sag_rel_seq_name := 'sag_rel_' || sag_relation_navn::text || sag_uuid_underscores;
  EXECUTE 'DROP  SEQUENCE ' || sag_rel_seq_name || ';';
END LOOP;


  --Ad 2)

  /**********************/
  -- 0..1 relations 
  --Please notice, that for 0..1 relations for Sag, we're ignoring index here, and handling it the same way, that is done for other object types (like Facet, Klasse etc). That is, you only make changes for the virkningsperiod that you explicitly specify (unless you delete all relations) 

  FOREACH sag_relation_navn in array  ARRAY['behandlingarkiv'::SagRelationKode,'afleveringsarkiv'::SagRelationKode,'primaerklasse'::SagRelationKode,'opgaveklasse'::SagRelationKode,'handlingsklasse'::SagRelationKode,'kontoklasse'::SagRelationKode,'sikkerhedsklasse'::SagRelationKode,'foelsomhedsklasse'::SagRelationKode,'indsatsklasse'::SagRelationKode,'ydelsesklasse'::SagRelationKode,'ejer'::SagRelationKode,'ansvarlig'::SagRelationKode,'primaerbehandler'::SagRelationKode,'udlaanttil'::SagRelationKode,'primaerpart'::SagRelationKode,'ydelsesmodtager'::SagRelationKode,'oversag'::SagRelationKode,'praecedens'::SagRelationKode,'afgiftsobjekt'::SagRelationKode,'ejendomsskat'::SagRelationKode]
  LOOP

    INSERT INTO sag_relation (
        sag_registrering_id,
          virkning,
            rel_maal_uuid,
              rel_maal_urn,
                rel_type,
                  objekt_type,
                    rel_index,
                      rel_type_spec,
                        journal_notat,
                          journal_dokument_attr

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
                  a.objekt_type,
                    NULL,--a.rel_index, rel_index is not to be used for 0..1 relations
                      a.rel_type_spec,
                        a.journal_notat,
                          a.journal_dokument_attr
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
  
      INSERT INTO sag_relation (
            sag_registrering_id,
              virkning,
                rel_maal_uuid,
                  rel_maal_urn,
                    rel_type,
                      objekt_type,
                        rel_index,
                          rel_type_spec,
                            journal_notat,
                              journal_dokument_attr
          )
      SELECT 
            new_sag_registrering.id,
              a.virkning,
                a.rel_maal_uuid,
                  a.rel_maal_urn,
                    a.rel_type,
                      a.objekt_type,
                        a.rel_index,
                          a.rel_type_spec,
                            a.journal_notat,
                              a.journal_dokument_attr
      FROM sag_relation a
      LEFT JOIN sag_relation b on b.sag_registrering_id=new_sag_registrering.id and b.rel_type=a.rel_type and b.rel_index=a.rel_index
      WHERE a.sag_registrering_id=prev_sag_registrering.id 
      and a.rel_type = any (sag_rel_type_cardinality_unlimited)
      and b.id is null --don't transfer relations of prev. registrering, if the index was specified in data given to the/this update-function
      ;

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
    CASE WHEN (attrEgenskaberObj.afleveret).cleared THEN NULL 
    ELSE coalesce((attrEgenskaberObj.afleveret).value,a.afleveret)
    END,
    coalesce(attrEgenskaberObj.beskrivelse,a.beskrivelse),
    coalesce(attrEgenskaberObj.hjemmel,a.hjemmel),
    coalesce(attrEgenskaberObj.kassationskode,a.kassationskode),
    coalesce(attrEgenskaberObj.offentlighedundtaget,a.offentlighedundtaget), 
    CASE WHEN (attrEgenskaberObj.principiel).cleared THEN NULL 
    ELSE coalesce((attrEgenskaberObj.principiel).value,a.principiel)
    END,
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

PERFORM actual_state._amqp_publish_notification('Sag', livscykluskode, sag_uuid);

return new_sag_registrering.id;



END;
$$ LANGUAGE plpgsql VOLATILE;





