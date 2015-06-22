-- Copyright (C) 2015 Magenta ApS, http://magenta.dk.
-- Contact: info@magenta.dk.
--
-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at http://mozilla.org/MPL/2.0/.

/*
NOTICE: This file is auto-generated using the script: apply-template.py itsystem as_update.jinja.sql
*/



--Please notice that is it the responsibility of the invoker of this function to compare the resulting itsystem_registration (including the entire hierarchy)
--to the previous one, and abort the transaction if the two registrations are identical. (This is to comply with the stipulated behavior in 'Specifikation_af_generelle_egenskaber - til OIOkomiteen.pdf')

--Also notice, that the given array of ItsystemAttr...Type must be consistent regarding virkning (although the allowance of null-values might make it possible to construct 'logically consistent'-arrays of objects with overlapping virknings)

CREATE OR REPLACE FUNCTION as_update_itsystem(
  itsystem_uuid uuid,
  brugerref uuid,
  note text,
  livscykluskode Livscykluskode,           
  attrEgenskaber ItsystemEgenskaberAttrType[],
  tilsGyldighed ItsystemGyldighedTilsType[],
  relationer ItsystemRelationType[],
  lostUpdatePreventionTZ TIMESTAMPTZ = null
	)
  RETURNS bigint AS 
$$
DECLARE
  read_new_itsystem ItsystemType;
  read_prev_itsystem ItsystemType;
  read_new_itsystem_reg ItsystemRegistreringType;
  read_prev_itsystem_reg ItsystemRegistreringType;
  new_itsystem_registrering itsystem_registrering;
  prev_itsystem_registrering itsystem_registrering;
  itsystem_relation_navn ItsystemRelationKode;
  attrEgenskaberObj ItsystemEgenskaberAttrType;
BEGIN

--create a new registrering

IF NOT EXISTS (select a.id from itsystem a join itsystem_registrering b on b.itsystem_id=a.id  where a.id=itsystem_uuid) THEN
   RAISE EXCEPTION 'Unable to update itsystem with uuid [%], being unable to any previous registrations.',itsystem_uuid;
END IF;

new_itsystem_registrering := _as_create_itsystem_registrering(itsystem_uuid,livscykluskode, brugerref, note);
prev_itsystem_registrering := _as_get_prev_itsystem_registrering(new_itsystem_registrering);

IF lostUpdatePreventionTZ IS NOT NULL THEN
  IF NOT (LOWER((prev_itsystem_registrering.registrering).timeperiod)=lostUpdatePreventionTZ) THEN
    RAISE EXCEPTION 'Unable to update itsystem with uuid [%], as the itsystem seems to have been updated since latest read by client (the given lostUpdatePreventionTZ [%] does not match the timesamp of latest registration [%]).',itsystem_uuid,lostUpdatePreventionTZ,LOWER((prev_itsystem_registrering.registrering).timeperiod);
  END IF;   
END IF;




--handle relationer (relations)

IF relationer IS NOT NULL AND coalesce(array_length(relationer,1),0)=0 THEN
--raise notice 'Skipping relations, as it is explicit set to empty array. Update note [%]',note;
ELSE

  --1) Insert relations given as part of this update
  --2) Insert relations of previous registration, taking overlapping virknings into consideration (using function subtract_tstzrange)

  --Ad 1)



      INSERT INTO itsystem_relation (
        itsystem_registrering_id,
          virkning,
            rel_maal_uuid,
              rel_maal_urn,
                rel_type
      )
      SELECT
        new_itsystem_registrering.id,
          a.virkning,
            a.relMaalUuid,
              a.relMaalUrn,
                a.relType
      FROM unnest(relationer) as a
    ;

   
  --Ad 2)

  /**********************/
  -- 0..1 relations 
   

  FOREACH itsystem_relation_navn in array  ARRAY['tilhoerer'::ItsystemRelationKode]
  LOOP

    INSERT INTO itsystem_relation (
        itsystem_registrering_id,
          virkning,
            rel_maal_uuid,
              rel_maal_urn,
                rel_type
      )
    SELECT 
        new_itsystem_registrering.id, 
          ROW(
            c.tz_range_leftover,
              (a.virkning).AktoerRef,
              (a.virkning).AktoerTypeKode,
              (a.virkning).NoteTekst
          ) :: virkning,
            a.rel_maal_uuid,
              a.rel_maal_urn,
                a.rel_type
    FROM
    (
      --build an array of the timeperiod of the virkning of the relations of the new registrering to pass to _subtract_tstzrange_arr on the relations of the previous registrering 
      SELECT coalesce(array_agg((b.virkning).TimePeriod),array[]::TSTZRANGE[]) tzranges_of_new_reg
      FROM itsystem_relation b
      WHERE 
            b.itsystem_registrering_id=new_itsystem_registrering.id
            and
            b.rel_type=itsystem_relation_navn
    ) d
    JOIN itsystem_relation a ON true
    JOIN unnest(_subtract_tstzrange_arr((a.virkning).TimePeriod,tzranges_of_new_reg)) as c(tz_range_leftover) on true
    WHERE a.itsystem_registrering_id=prev_itsystem_registrering.id 
          and a.rel_type=itsystem_relation_navn 
    ;
  END LOOP;

  /**********************/
  -- 0..n relations

  --We only have to check if there are any of the relations with the given name present in the new registration, otherwise copy the ones from the previous registration


  FOREACH itsystem_relation_navn in array ARRAY['tilknyttedeorganisationer'::ItsystemRelationKode,'tilknyttedeenheder'::ItsystemRelationKode,'tilknyttedefunktioner'::ItsystemRelationKode,'tilknyttedebrugere'::ItsystemRelationKode,'tilknyttedeinteressefaellesskaber'::ItsystemRelationKode,'tilknyttedeitsystemer'::ItsystemRelationKode,'tilknyttedepersoner'::ItsystemRelationKode,'systemtyper'::ItsystemRelationKode,'opgaver'::ItsystemRelationKode,'adresser'::ItsystemRelationKode]
  LOOP

    IF NOT EXISTS  (SELECT 1 FROM itsystem_relation WHERE itsystem_registrering_id=new_itsystem_registrering.id and rel_type=itsystem_relation_navn) THEN

      INSERT INTO itsystem_relation (
            itsystem_registrering_id,
              virkning,
                rel_maal_uuid,
                  rel_maal_urn,
                    rel_type
          )
      SELECT 
            new_itsystem_registrering.id,
              virkning,
                rel_maal_uuid,
                  rel_maal_urn,
                  rel_type
      FROM itsystem_relation
      WHERE itsystem_registrering_id=prev_itsystem_registrering.id 
      and rel_type=itsystem_relation_navn 
      ;

    END IF;
              
  END LOOP;


/**********************/
--Remove any "cleared"/"deleted" relations
DELETE FROM itsystem_relation
WHERE 
itsystem_registrering_id=new_itsystem_registrering.id
AND (rel_maal_uuid IS NULL AND (rel_maal_urn IS NULL OR rel_maal_urn=''))
;

END IF;
/**********************/
-- handle tilstande (states)

IF tilsGyldighed IS NOT NULL AND coalesce(array_length(tilsGyldighed,1),0)=0 THEN
--raise debug 'Skipping [Gyldighed] as it is explicit set to empty array';
ELSE
  --1) Insert tilstande/states given as part of this update
  --2) Insert tilstande/states of previous registration, taking overlapping virknings into consideration (using function subtract_tstzrange)

  /********************************************/
  --itsystem_tils_gyldighed
  /********************************************/

  --Ad 1)

  INSERT INTO itsystem_tils_gyldighed (
          virkning,
            gyldighed,
              itsystem_registrering_id
  ) 
  SELECT
          a.virkning,
            a.gyldighed,
              new_itsystem_registrering.id
  FROM
  unnest(tilsGyldighed) as a
  ;
   

  --Ad 2

  INSERT INTO itsystem_tils_gyldighed (
          virkning,
            gyldighed,
              itsystem_registrering_id
  )
  SELECT 
          ROW(
            c.tz_range_leftover,
              (a.virkning).AktoerRef,
              (a.virkning).AktoerTypeKode,
              (a.virkning).NoteTekst
          ) :: virkning,
            a.gyldighed,
              new_itsystem_registrering.id
  FROM
  (
   --build an array of the timeperiod of the virkning of the itsystem_tils_gyldighed of the new registrering to pass to _subtract_tstzrange_arr on the itsystem_tils_gyldighed of the previous registrering 
      SELECT coalesce(array_agg((b.virkning).TimePeriod),array[]::TSTZRANGE[]) tzranges_of_new_reg
      FROM itsystem_tils_gyldighed b
      WHERE 
            b.itsystem_registrering_id=new_itsystem_registrering.id
  ) d
    JOIN itsystem_tils_gyldighed a ON true  
    JOIN unnest(_subtract_tstzrange_arr((a.virkning).TimePeriod,tzranges_of_new_reg)) as c(tz_range_leftover) on true
    WHERE a.itsystem_registrering_id=prev_itsystem_registrering.id     
  ;


/**********************/
--Remove any "cleared"/"deleted" tilstande
DELETE FROM itsystem_tils_gyldighed
WHERE 
itsystem_registrering_id=new_itsystem_registrering.id
AND gyldighed = ''::ItsystemGyldighedTils
;

END IF;


/**********************/
--Handle attributter (attributes) 

/********************************************/
--itsystem_attr_egenskaber
/********************************************/

--Generate and insert any merged objects, if any fields are null in attrItsystemObj
IF attrEgenskaber IS NOT null THEN

  --Input validation: 
  --Verify that there is no overlap in virkning in the array given

  IF EXISTS (
  SELECT
  a.*
  FROM unnest(attrEgenskaber) a
  JOIN  unnest(attrEgenskaber) b on (a.virkning).TimePeriod && (b.virkning).TimePeriod
  GROUP BY a.brugervendtnoegle,a.itsystemnavn,a.itsystemtype,a.konfigurationreference, a.virkning
  HAVING COUNT(*)>1
  ) THEN
  RAISE EXCEPTION 'Unable to update itsystem with uuid [%], as the itsystem have overlapping virknings in the given egenskaber array :%',itsystem_uuid,to_json(attrEgenskaber)  USING ERRCODE = 22000;

  END IF;


  FOREACH attrEgenskaberObj in array attrEgenskaber
  LOOP

  --To avoid needless fragmentation we'll check for presence of null values in the fields - and if none are present, we'll skip the merging operations
  IF (attrEgenskaberObj).brugervendtnoegle is null OR 
   (attrEgenskaberObj).itsystemnavn is null OR 
   (attrEgenskaberObj).itsystemtype is null OR 
   (attrEgenskaberObj).konfigurationreference is null 
  THEN

  INSERT INTO
  itsystem_attr_egenskaber
  (
    brugervendtnoegle,itsystemnavn,itsystemtype,konfigurationreference
    ,virkning
    ,itsystem_registrering_id
  )
  SELECT 
    coalesce(attrEgenskaberObj.brugervendtnoegle,a.brugervendtnoegle), 
    coalesce(attrEgenskaberObj.itsystemnavn,a.itsystemnavn), 
    coalesce(attrEgenskaberObj.itsystemtype,a.itsystemtype), 
    coalesce(attrEgenskaberObj.konfigurationreference,a.konfigurationreference),
	ROW (
	  (a.virkning).TimePeriod * (attrEgenskaberObj.virkning).TimePeriod,
	  (attrEgenskaberObj.virkning).AktoerRef,
	  (attrEgenskaberObj.virkning).AktoerTypeKode,
	  (attrEgenskaberObj.virkning).NoteTekst
	)::Virkning,
    new_itsystem_registrering.id
  FROM itsystem_attr_egenskaber a
  WHERE
    a.itsystem_registrering_id=prev_itsystem_registrering.id 
    and (a.virkning).TimePeriod && (attrEgenskaberObj.virkning).TimePeriod
  ;

  --For any periods within the virkning of the attrEgenskaberObj, that is NOT covered by any "merged" rows inserted above, generate and insert rows

  INSERT INTO
  itsystem_attr_egenskaber
  (
    brugervendtnoegle,itsystemnavn,itsystemtype,konfigurationreference
    ,virkning
    ,itsystem_registrering_id
  )
  SELECT 
    attrEgenskaberObj.brugervendtnoegle, 
    attrEgenskaberObj.itsystemnavn, 
    attrEgenskaberObj.itsystemtype, 
    attrEgenskaberObj.konfigurationreference,
	  ROW (
	       b.tz_range_leftover,
	      (attrEgenskaberObj.virkning).AktoerRef,
	      (attrEgenskaberObj.virkning).AktoerTypeKode,
	      (attrEgenskaberObj.virkning).NoteTekst
	  )::Virkning,
    new_itsystem_registrering.id
  FROM
  (
  --build an array of the timeperiod of the virkning of the itsystem_attr_egenskaber of the new registrering to pass to _subtract_tstzrange_arr 
      SELECT coalesce(array_agg((b.virkning).TimePeriod),array[]::TSTZRANGE[]) tzranges_of_new_reg
      FROM itsystem_attr_egenskaber b
      WHERE 
       b.itsystem_registrering_id=new_itsystem_registrering.id
  ) as a
  JOIN unnest(_subtract_tstzrange_arr((attrEgenskaberObj.virkning).TimePeriod,a.tzranges_of_new_reg)) as b(tz_range_leftover) on true
  ;

  ELSE
    --insert attrEgenskaberObj raw (if there were no null-valued fields) 

    INSERT INTO
    itsystem_attr_egenskaber
    (
    brugervendtnoegle,itsystemnavn,itsystemtype,konfigurationreference
    ,virkning
    ,itsystem_registrering_id
    )
    VALUES ( 
    attrEgenskaberObj.brugervendtnoegle, 
    attrEgenskaberObj.itsystemnavn, 
    attrEgenskaberObj.itsystemtype, 
    attrEgenskaberObj.konfigurationreference,
    attrEgenskaberObj.virkning,
    new_itsystem_registrering.id
    );

  END IF;

  END LOOP;
END IF;


IF attrEgenskaber IS NOT NULL AND coalesce(array_length(attrEgenskaber,1),0)=0 THEN
--raise debug 'Skipping handling of egenskaber of previous registration as an empty array was explicit given.';  
ELSE 

--Handle egenskaber of previous registration, taking overlapping virknings into consideration (using function subtract_tstzrange)

INSERT INTO itsystem_attr_egenskaber (
    brugervendtnoegle,itsystemnavn,itsystemtype,konfigurationreference
    ,virkning
    ,itsystem_registrering_id
)
SELECT
      a.brugervendtnoegle,
      a.itsystemnavn,
      a.itsystemtype,
      a.konfigurationreference,
	  ROW(
	    c.tz_range_leftover,
	      (a.virkning).AktoerRef,
	      (a.virkning).AktoerTypeKode,
	      (a.virkning).NoteTekst
	  ) :: virkning,
	 new_itsystem_registrering.id
FROM
(
 --build an array of the timeperiod of the virkning of the itsystem_attr_egenskaber of the new registrering to pass to _subtract_tstzrange_arr on the itsystem_attr_egenskaber of the previous registrering 
    SELECT coalesce(array_agg((b.virkning).TimePeriod),array[]::TSTZRANGE[]) tzranges_of_new_reg
    FROM itsystem_attr_egenskaber b
    WHERE 
          b.itsystem_registrering_id=new_itsystem_registrering.id
) d
  JOIN itsystem_attr_egenskaber a ON true  
  JOIN unnest(_subtract_tstzrange_arr((a.virkning).TimePeriod,tzranges_of_new_reg)) as c(tz_range_leftover) on true
  WHERE a.itsystem_registrering_id=prev_itsystem_registrering.id     
;



--Remove any "cleared"/"deleted" attributes
DELETE FROM itsystem_attr_egenskaber a
WHERE 
a.itsystem_registrering_id=new_itsystem_registrering.id
AND (a.brugervendtnoegle IS NULL OR a.brugervendtnoegle='') AND (a.itsystemnavn IS NULL OR a.itsystemnavn='') AND (a.itsystemtype IS NULL OR a.itsystemtype='') AND (a.konfigurationreference IS NULL OR coalesce(array_length(a.konfigurationreference,1),0)=0)
;

END IF;


/******************************************************************/
--If the new registrering is identical to the previous one, we need to throw an exception to abort the transaction. 

read_new_itsystem:=as_read_itsystem(itsystem_uuid, (new_itsystem_registrering.registrering).timeperiod,null);
read_prev_itsystem:=as_read_itsystem(itsystem_uuid, (prev_itsystem_registrering.registrering).timeperiod ,null);
 
--the ordering in as_list (called by as_read) ensures that the latest registration is returned at index pos 1

IF NOT (lower((read_new_itsystem.registrering[1].registrering).TimePeriod)=lower((new_itsystem_registrering.registrering).TimePeriod) AND lower((read_prev_itsystem.registrering[1].registrering).TimePeriod)=lower((prev_itsystem_registrering.registrering).TimePeriod)) THEN
  RAISE EXCEPTION 'Error updating itsystem with id [%]: The ordering of as_list_itsystem should ensure that the latest registrering can be found at index 1. Expected new reg: [%]. Actual new reg at index 1: [%]. Expected prev reg: [%]. Actual prev reg at index 1: [%].',itsystem_uuid,to_json(new_itsystem_registrering),to_json(read_new_itsystem.registrering[1].registrering),to_json(prev_itsystem_registrering),to_json(prev_new_itsystem.registrering[1].registrering);
END IF;
 
 --we'll ignore the registreringBase part in the comparrison - except for the livcykluskode

read_new_itsystem_reg:=ROW(
ROW(null,(read_new_itsystem.registrering[1].registrering).livscykluskode,null,null)::registreringBase,
(read_new_itsystem.registrering[1]).tilsGyldighed ,
(read_new_itsystem.registrering[1]).attrEgenskaber ,
(read_new_itsystem.registrering[1]).relationer 
)::itsystemRegistreringType
;

read_prev_itsystem_reg:=ROW(
ROW(null,(read_prev_itsystem.registrering[1].registrering).livscykluskode,null,null)::registreringBase,
(read_prev_itsystem.registrering[1]).tilsGyldighed ,
(read_prev_itsystem.registrering[1]).attrEgenskaber ,
(read_prev_itsystem.registrering[1]).relationer 
)::itsystemRegistreringType
;


IF read_prev_itsystem_reg=read_new_itsystem_reg THEN
  --RAISE NOTICE 'Note[%]. Aborted reg:%',note,to_json(read_new_itsystem_reg);
  --RAISE NOTICE 'Note[%]. Previous reg:%',note,to_json(read_prev_itsystem_reg);
  RAISE EXCEPTION 'Aborted updating itsystem with id [%] as the given data, does not give raise to a new registration. Aborted reg:[%], previous reg:[%]',itsystem_uuid,to_json(read_new_itsystem_reg),to_json(read_prev_itsystem_reg) USING ERRCODE = 22000;
END IF;

/******************************************************************/


return new_itsystem_registrering.id;



END;
$$ LANGUAGE plpgsql VOLATILE;





