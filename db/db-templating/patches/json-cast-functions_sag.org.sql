-- Copyright (C) 2015 Magenta ApS, http://magenta.dk.
-- Contact: info@magenta.dk.
--
-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at http://mozilla.org/MPL/2.0/.

/*
NOTICE: This file is auto-generated using the script: apply-template.py sag json-cast-functions.jinja.sql
*/



CREATE OR REPLACE FUNCTION actual_state._cast_SagRegistreringType_to_json(SagRegistreringType) 

RETURNS
json
AS 
$$
DECLARE 
result json;

BEGIN

SELECT row_to_json(a.*) into result
FROM
(
  WITH 
  attr AS (
    SELECT 
    row_to_json(
      c.*
      ) attr_json
    FROM 
      (
        SELECT
        CASE 
        WHEN coalesce(array_length($1.attrEgenskaber,0),0)>0 THEN to_json($1.attrEgenskaber) 
        ELSE 
        NULL
        END sagegenskaber
        
        
      ) as c
  ),
  tils as (
      SELECT 
    row_to_json(
      d.*
      ) tils_json
    FROM 
      ( 
        SELECT 
        
        CASE 
        WHEN coalesce(array_length($1.tilsFremdrift,0),0)>0 THEN to_json($1.tilsFremdrift) 
        ELSE 
        NULL
        END sagfremdrift
        
        
      ) as d
  ),
  rel as (
    SELECT 
    ('{' || string_agg(   to_json(f.relType::text) || ':' || array_to_json(f.rel_json_arr,false) ,',') || '}')::json rel_json
    FROM
    (
      SELECT
      e.relType,
      array_agg( _json_object_delete_keys( (ROW(e.relType,e.virkning,e.relMaalUuid,e.relMaalUrn,e.objektType,e.relIndex,e.relTypeSpec,e.journalNotat,e.journalDokumentAttr)::SagRelationType)::json,ARRAY['reltype']::text[])) rel_json_arr
      from unnest($1.relationer) e(relType,virkning,relMaalUuid,relMaalUrn,objektType) 
      group by e.relType
    ) as f
  )
  SELECT 
  row_to_json(FraTidspunkt.*) FraTidspunkt
  ,($1.registrering).livscykluskode
  ,($1.registrering).note
  ,($1.registrering).brugerref
  ,(SELECT attr_json FROM attr) attributter
  ,(SELECT tils_json FROM tils) tilstande
  ,CASE WHEN coalesce(array_length($1.relationer,1),0)>0 THEN
    (SELECT rel_json from rel) 
    ELSE
    NULL
    END relationer
  FROM
    (
    SELECT
     (SELECT LOWER(($1.registrering).TimePeriod)) as TidsstempelDatoTid --TODO: Consider formating timestamp (also consider loosing precision vs. ability of api-consumer to determine current registrering )
    ,(SELECT lower_inc(($1.registrering).TimePeriod)) as GraenseIndikator  --TODO verify meaning of GraenseIndikator
    ) as  FraTidspunkt
  

)
as a
;

RETURN result;

END;
$$ LANGUAGE plpgsql immutable;


--drop cast (SagRegistreringType as json);
create cast (SagRegistreringType as json) with function actual_state._cast_SagRegistreringType_to_json(SagRegistreringType);


---------------------------------------------------------

CREATE OR REPLACE FUNCTION actual_state._cast_sagType_to_json(SagType) 

RETURNS
json
AS 
$$
DECLARE 
result json;
reg_json_arr json[];
reg SagRegistreringType;
BEGIN

 FOREACH reg IN ARRAY $1.registrering
  LOOP
  reg_json_arr:=array_append(reg_json_arr,reg::json);
END LOOP;


SELECT row_to_json(a.*) into result
FROM
(
  SELECT
    $1.id id,
    reg_json_arr registreringer
) as a
;

RETURN result;

END;
$$ LANGUAGE plpgsql immutable;

--drop cast (SagType as json);
create cast (SagType as json) with function actual_state._cast_sagType_to_json(SagType); 




--we create custom cast function to json for SagRelationType, which will be invoked by custom cast to json form SagType
CREATE OR REPLACE FUNCTION actual_state._sag_relation_type_to_json(SagRelationType) 

RETURNS
json
AS 
$$
DECLARE 
result json;
keys_to_delete text[];
BEGIN

IF $1.relindex IS NULL THEN
  keys_to_delete:=array_append(keys_to_delete,'relindex');
END IF;

IF $1.reltypespec IS NULL THEN
  keys_to_delete:=array_append(keys_to_delete,'reltypespec');
END IF;

IF $1.journalnotat IS NULL OR ( ($1.journalnotat).titel IS NULL AND ($1.journalnotat).notat IS NULL AND ($1.journalnotat).format IS NULL) THEN
  keys_to_delete:=array_append(keys_to_delete,'journalnotat');
END IF;

IF $1.journaldokumentattr IS NULL 
    OR ( 
        ($1.journaldokumentattr).dokumenttitel IS NULL 
        AND 
        (
          ($1.journaldokumentattr).offentlighedundtaget IS NULL 
          OR
          (
            (($1.journaldokumentattr).offentlighedundtaget).alternativtitel IS NULL
            AND 
             (($1.journaldokumentattr).offentlighedundtaget).hjemmel IS NULL  
          )
        )
      ) THEN
    keys_to_delete:=array_append(keys_to_delete,'journaldokumentattr');
END IF;    

SELECT actual_state._json_object_delete_keys(row_to_json($1),keys_to_delete) into result;

RETURN result;

END;
$$ LANGUAGE plpgsql immutable;

create cast (SagRelationType as json) with function _sag_relation_type_to_json (SagRelationType); 


