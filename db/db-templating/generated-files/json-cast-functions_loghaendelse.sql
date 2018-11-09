-- Copyright (C) 2015 Magenta ApS, http://magenta.dk.
-- Contact: info@magenta.dk.
--
-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at http://mozilla.org/MPL/2.0/.

/*
NOTICE: This file is auto-generated using the script: oio_rest/apply-templates.py
*/



CREATE OR REPLACE FUNCTION actual_state._cast_LoghaendelseRegistreringType_to_json(LoghaendelseRegistreringType) 

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
        WHEN coalesce(array_length($1.attrEgenskaber,1),0)>0 THEN to_json($1.attrEgenskaber) 
        ELSE 
        NULL
        END loghaendelseegenskaber
        
        
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
        WHEN coalesce(array_length($1.tilsGyldighed,1),0)>0 THEN to_json($1.tilsGyldighed) 
        ELSE 
        NULL
        END loghaendelsegyldighed
        
        
      ) as d
  ),
  rel as (
    SELECT 
    ('{' || string_agg(   to_json(f.relType::text) || ':' || array_to_json(f.rel_json_arr,false) ,',') || '}')::json rel_json
    FROM
    (
      SELECT
      e.relType,

      array_agg( _json_object_delete_keys(row_to_json(ROW(e.relType,e.virkning,e.uuid,e.urn,e.objektType)::LoghaendelseRelationType),ARRAY['reltype']::text[])) rel_json_arr
      from unnest($1.relationer) e(relType,virkning,uuid,urn,objektType)

      group by e.relType
      order by e.relType asc
    ) as f
  )
  SELECT 
  row_to_json(FraTidspunkt.*) FraTidspunkt
  ,row_to_json(TilTidspunkt.*) TilTidspunkt
  ,($1.registrering).livscykluskode
  ,($1.registrering).note
  ,($1.registrering).brugerref
  ,(SELECT attr_json FROM attr) attributter
  ,(SELECT tils_json FROM tils) tilstande
  ,CASE WHEN coalesce(array_length($1.relationer,1),0)>0 THEN
    (SELECT rel_json from rel)
    ELSE
    '{}'::json
    END relationer

  FROM
    (
    SELECT
     (SELECT LOWER(($1.registrering).TimePeriod)) as TidsstempelDatoTid
    ,(SELECT lower_inc(($1.registrering).TimePeriod)) as GraenseIndikator
    ) as  FraTidspunkt,
    (
    SELECT
     (SELECT UPPER(($1.registrering).TimePeriod)) as TidsstempelDatoTid
    ,(SELECT upper_inc(($1.registrering).TimePeriod)) as GraenseIndikator
    ) as  TilTidspunkt
  

)
as a
;

RETURN result;

END;
$$ LANGUAGE plpgsql immutable;


drop cast if exists (LoghaendelseRegistreringType as json);
create cast (LoghaendelseRegistreringType as json) with function actual_state._cast_LoghaendelseRegistreringType_to_json(LoghaendelseRegistreringType);


---------------------------------------------------------

CREATE OR REPLACE FUNCTION actual_state._cast_loghaendelseType_to_json(LoghaendelseType) 

RETURNS
json
AS 
$$
DECLARE 
result json;
reg_json_arr json[];
reg LoghaendelseRegistreringType;
BEGIN


IF coalesce(array_length($1.registrering,1),0)>0 THEN
   FOREACH reg IN ARRAY $1.registrering
    LOOP
    reg_json_arr:=array_append(reg_json_arr,reg::json);
    END LOOP;
END IF;

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

drop cast if exists (LoghaendelseType as json);
create cast (LoghaendelseType as json) with function actual_state._cast_loghaendelseType_to_json(LoghaendelseType); 





