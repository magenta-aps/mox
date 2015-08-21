{% extends "basis.jinja.sql" %}
-- Copyright (C) 2015 Magenta ApS, http://magenta.dk.
-- Contact: info@magenta.dk.
--
-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at http://mozilla.org/MPL/2.0/.
{% block body %}



--Also notice, that the given arrays of {{oio_type|title}}Attr...Type must be consistent regarding virkning (although the allowance of null-values might make it possible to construct 'logically consistent'-arrays of objects with overlapping virknings)

CREATE OR REPLACE FUNCTION as_update_{{oio_type}}(
  {{oio_type}}_uuid uuid,
  brugerref uuid,
  note text,
  livscykluskode Livscykluskode,
  {%-for attribut , attribut_fields in attributter.iteritems() %}           
  attr{{attribut|title}} {{oio_type|title}}{{attribut|title}}AttrType[],
  {%- endfor %}
  {%- for tilstand, tilstand_values in tilstande.iteritems() %}
  tils{{tilstand|title}} {{oio_type|title}}{{tilstand|title}}TilsType[],
  {%- endfor %}
  relationer {{oio_type|title}}RelationType[],
  lostUpdatePreventionTZ TIMESTAMPTZ = null,
  auth_criteria_arr {{oio_type|title}}RegistreringType[]=null
	)
  RETURNS bigint AS 
$$
DECLARE
  read_new_{{oio_type}} {{oio_type|title}}Type;
  read_prev_{{oio_type}} {{oio_type|title}}Type;
  read_new_{{oio_type}}_reg {{oio_type|title}}RegistreringType;
  read_prev_{{oio_type}}_reg {{oio_type|title}}RegistreringType;
  new_{{oio_type}}_registrering {{oio_type}}_registrering;
  prev_{{oio_type}}_registrering {{oio_type}}_registrering;
  {{oio_type}}_relation_navn {{oio_type|title}}RelationKode;
  {%- for attribut , attribut_fields in attributter.iteritems() %}
  attr{{attribut|title}}Obj {{oio_type|title}}{{attribut|title}}AttrType;{%- endfor %}
  auth_filtered_uuids uuid[];
BEGIN

--create a new registrering

IF NOT EXISTS (select a.id from {{oio_type}} a join {{oio_type}}_registrering b on b.{{oio_type}}_id=a.id  where a.id={{oio_type}}_uuid) THEN
   RAISE EXCEPTION 'Unable to update {{oio_type}} with uuid [%], being unable to find any previous registrations.',{{oio_type}}_uuid USING ERRCODE = 'MO400';
END IF;

PERFORM a.id FROM {{oio_type}} a
WHERE a.id={{oio_type}}_uuid
FOR UPDATE; --We synchronize concurrent invocations of as_updates of this particular object on a exclusive row lock. This lock will be held by the current transaction until it terminates.

/*** Verify that the object meets the stipulated access allowed criteria  ***/
auth_filtered_uuids:=_as_filter_unauth_{{oio_type}}(array[{{oio_type}}_uuid]::uuid[],auth_criteria_arr); 
IF NOT (coalesce(array_length(auth_filtered_uuids,1),0)=1 AND auth_filtered_uuids @>ARRAY[{{oio_type}}_uuid]) THEN
  RAISE EXCEPTION 'Unable to update {{oio_type}} with uuid [%]. Object does not met stipulated criteria:%',{{oio_type}}_uuid,to_json(auth_criteria_arr)  USING ERRCODE = 'MO401'; 
END IF;
/*********************/


new_{{oio_type}}_registrering := _as_create_{{oio_type}}_registrering({{oio_type}}_uuid,livscykluskode, brugerref, note);
prev_{{oio_type}}_registrering := _as_get_prev_{{oio_type}}_registrering(new_{{oio_type}}_registrering);

IF lostUpdatePreventionTZ IS NOT NULL THEN
  IF NOT (LOWER((prev_{{oio_type}}_registrering.registrering).timeperiod)=lostUpdatePreventionTZ) THEN
    RAISE EXCEPTION 'Unable to update {{oio_type}} with uuid [%], as the {{oio_type}} seems to have been updated since latest read by client (the given lostUpdatePreventionTZ [%] does not match the timesamp of latest registration [%]).',{{oio_type}}_uuid,lostUpdatePreventionTZ,LOWER((prev_{{oio_type}}_registrering.registrering).timeperiod) USING ERRCODE = 'MO409';
  END IF;   
END IF;




--handle relationer (relations)

IF relationer IS NOT NULL AND coalesce(array_length(relationer,1),0)=0 THEN
--raise notice 'Skipping relations, as it is explicit set to empty array. Update note [%]',note;
ELSE

  --1) Insert relations given as part of this update
  --2) Insert relations of previous registration, taking overlapping virknings into consideration (using function subtract_tstzrange)

  --Ad 1)



      INSERT INTO {{oio_type}}_relation (
        {{oio_type}}_registrering_id,
          virkning,
            rel_maal_uuid,
              rel_maal_urn,
                rel_type,
                  objekt_type
      )
      SELECT
        new_{{oio_type}}_registrering.id,
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
   

  FOREACH {{oio_type}}_relation_navn in array  ARRAY[{%-for relkode in relationer_nul_til_en  %}'{{relkode}}'::{{oio_type|title}}RelationKode{% if not loop.last%},{% endif %}{% endfor %}]
  LOOP

    INSERT INTO {{oio_type}}_relation (
        {{oio_type}}_registrering_id,
          virkning,
            rel_maal_uuid,
              rel_maal_urn,
                rel_type,
                  objekt_type
      )
    SELECT 
        new_{{oio_type}}_registrering.id, 
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
      FROM {{oio_type}}_relation b
      WHERE 
            b.{{oio_type}}_registrering_id=new_{{oio_type}}_registrering.id
            and
            b.rel_type={{oio_type}}_relation_navn
    ) d
    JOIN {{oio_type}}_relation a ON true
    JOIN unnest(_subtract_tstzrange_arr((a.virkning).TimePeriod,tzranges_of_new_reg)) as c(tz_range_leftover) on true
    WHERE a.{{oio_type}}_registrering_id=prev_{{oio_type}}_registrering.id 
          and a.rel_type={{oio_type}}_relation_navn 
    ;
  END LOOP;

  /**********************/
  -- 0..n relations

  --We only have to check if there are any of the relations with the given name present in the new registration, otherwise copy the ones from the previous registration


  FOREACH {{oio_type}}_relation_navn in array ARRAY[{%-for relkode in relationer_nul_til_mange  %}'{{relkode}}'::{{oio_type|title}}RelationKode{% if not loop.last%},{% endif %}{% endfor %}]
  LOOP

    IF NOT EXISTS  (SELECT 1 FROM {{oio_type}}_relation WHERE {{oio_type}}_registrering_id=new_{{oio_type}}_registrering.id and rel_type={{oio_type}}_relation_navn) THEN

      INSERT INTO {{oio_type}}_relation (
            {{oio_type}}_registrering_id,
              virkning,
                rel_maal_uuid,
                  rel_maal_urn,
                    rel_type,
                      objekt_type
          )
      SELECT 
            new_{{oio_type}}_registrering.id,
              virkning,
                rel_maal_uuid,
                  rel_maal_urn,
                    rel_type,
                      objekt_type
      FROM {{oio_type}}_relation
      WHERE {{oio_type}}_registrering_id=prev_{{oio_type}}_registrering.id 
      and rel_type={{oio_type}}_relation_navn 
      ;

    END IF;
              
  END LOOP;


/**********************/


END IF;
/**********************/
-- handle tilstande (states)

{%- for tilstand, tilstand_values in tilstande.iteritems() %}

IF tils{{tilstand|title}} IS NOT NULL AND coalesce(array_length(tils{{tilstand|title}},1),0)=0 THEN
--raise debug 'Skipping [{{tilstand|title}}] as it is explicit set to empty array';
ELSE
  --1) Insert tilstande/states given as part of this update
  --2) Insert tilstande/states of previous registration, taking overlapping virknings into consideration (using function subtract_tstzrange)

  /********************************************/
  --{{oio_type}}_tils_{{tilstand}}
  /********************************************/

  --Ad 1)

  INSERT INTO {{oio_type}}_tils_{{tilstand}} (
          virkning,
            {{tilstand}},
              {{oio_type}}_registrering_id
  ) 
  SELECT
          a.virkning,
            a.{{tilstand}},
              new_{{oio_type}}_registrering.id
  FROM
  unnest(tils{{tilstand|title}}) as a
  ;
   

  --Ad 2

  INSERT INTO {{oio_type}}_tils_{{tilstand}} (
          virkning,
            {{tilstand}},
              {{oio_type}}_registrering_id
  )
  SELECT 
          ROW(
            c.tz_range_leftover,
              (a.virkning).AktoerRef,
              (a.virkning).AktoerTypeKode,
              (a.virkning).NoteTekst
          ) :: virkning,
            a.{{tilstand}},
              new_{{oio_type}}_registrering.id
  FROM
  (
   --build an array of the timeperiod of the virkning of the {{oio_type}}_tils_{{tilstand}} of the new registrering to pass to _subtract_tstzrange_arr on the {{oio_type}}_tils_{{tilstand}} of the previous registrering 
      SELECT coalesce(array_agg((b.virkning).TimePeriod),array[]::TSTZRANGE[]) tzranges_of_new_reg
      FROM {{oio_type}}_tils_{{tilstand}} b
      WHERE 
            b.{{oio_type}}_registrering_id=new_{{oio_type}}_registrering.id
  ) d
    JOIN {{oio_type}}_tils_{{tilstand}} a ON true  
    JOIN unnest(_subtract_tstzrange_arr((a.virkning).TimePeriod,tzranges_of_new_reg)) as c(tz_range_leftover) on true
    WHERE a.{{oio_type}}_registrering_id=prev_{{oio_type}}_registrering.id     
  ;


/**********************/

END IF;

{% endfor %}
/**********************/
--Handle attributter (attributes) 

{%-for attribut , attribut_fields in attributter.iteritems() %} 

/********************************************/
--{{oio_type}}_attr_{{attribut}}
/********************************************/

--Generate and insert any merged objects, if any fields are null in attr{{oio_type|title}}Obj
IF attr{{attribut|title}} IS NOT null THEN

  --Input validation: 
  --Verify that there is no overlap in virkning in the array given

  IF EXISTS (
  SELECT
  a.*
  FROM unnest(attr{{attribut|title}}) a
  JOIN  unnest(attr{{attribut|title}}) b on (a.virkning).TimePeriod && (b.virkning).TimePeriod
  GROUP BY a.{{attribut_fields|join(',a.')}}, a.virkning
  HAVING COUNT(*)>1
  ) THEN
  RAISE EXCEPTION 'Unable to update {{oio_type}} with uuid [%], as the {{oio_type}} have overlapping virknings in the given {{attribut}} array :%',{{oio_type}}_uuid,to_json(attr{{attribut|title}})  USING ERRCODE = 'MO400';

  END IF;


  FOREACH attr{{attribut|title}}Obj in array attr{{attribut|title}}
  LOOP

  --To avoid needless fragmentation we'll check for presence of null values in the fields - and if none are present, we'll skip the merging operations
  IF {%-for field in attribut_fields %} (attr{{attribut|title}}Obj).{{field}} is null
  {%- if not loop.last %} OR {%- endif %} 
  {% endfor %}THEN

  INSERT INTO
  {{oio_type}}_attr_{{attribut}}
  (
    {{attribut_fields|join(',')}}
    ,virkning
    ,{{oio_type}}_registrering_id
  )
  SELECT {%-for fieldname in attribut_fields %}
  {%- if  attributter_type_override is defined and attributter_type_override[attribut] is defined and attributter_type_override[attribut][fieldname] is defined and ( attributter_type_override[attribut][fieldname] =='int' or attributter_type_override[attribut][fieldname] =='date' or attributter_type_override[attribut][fieldname]=='boolean')  %} 
    CASE WHEN (attr{{attribut|title}}Obj.{{fieldname}}).cleared THEN NULL 
    ELSE coalesce((attr{{attribut|title}}Obj.{{fieldname}}).value,a.{{fieldname}})
    END,
   {%-else %}
    coalesce(attr{{attribut|title}}Obj.{{fieldname}},a.{{fieldname}}),
    {%-endif %}
    {%- endfor %}
	ROW (
	  (a.virkning).TimePeriod * (attr{{attribut|title}}Obj.virkning).TimePeriod,
	  (attr{{attribut|title}}Obj.virkning).AktoerRef,
	  (attr{{attribut|title}}Obj.virkning).AktoerTypeKode,
	  (attr{{attribut|title}}Obj.virkning).NoteTekst
	)::Virkning,
    new_{{oio_type}}_registrering.id
  FROM {{oio_type}}_attr_{{attribut}} a
  WHERE
    a.{{oio_type}}_registrering_id=prev_{{oio_type}}_registrering.id 
    and (a.virkning).TimePeriod && (attr{{attribut|title}}Obj.virkning).TimePeriod
  ;

  --For any periods within the virkning of the attr{{attribut|title}}Obj, that is NOT covered by any "merged" rows inserted above, generate and insert rows

  INSERT INTO
  {{oio_type}}_attr_{{attribut}}
  (
    {{attribut_fields|join(',')}}
    ,virkning
    ,{{oio_type}}_registrering_id
  )
  SELECT {%-for fieldname in attribut_fields %} 
    attr{{attribut|title}}Obj.{{fieldname}},
    {%- endfor %}
	  ROW (
	       b.tz_range_leftover,
	      (attr{{attribut|title}}Obj.virkning).AktoerRef,
	      (attr{{attribut|title}}Obj.virkning).AktoerTypeKode,
	      (attr{{attribut|title}}Obj.virkning).NoteTekst
	  )::Virkning,
    new_{{oio_type}}_registrering.id
  FROM
  (
  --build an array of the timeperiod of the virkning of the {{oio_type}}_attr_{{attribut}} of the new registrering to pass to _subtract_tstzrange_arr 
      SELECT coalesce(array_agg((b.virkning).TimePeriod),array[]::TSTZRANGE[]) tzranges_of_new_reg
      FROM {{oio_type}}_attr_{{attribut}} b
      WHERE 
       b.{{oio_type}}_registrering_id=new_{{oio_type}}_registrering.id
  ) as a
  JOIN unnest(_subtract_tstzrange_arr((attr{{attribut|title}}Obj.virkning).TimePeriod,a.tzranges_of_new_reg)) as b(tz_range_leftover) on true
  ;

  ELSE
    --insert attr{{attribut|title}}Obj raw (if there were no null-valued fields) 

    INSERT INTO
    {{oio_type}}_attr_{{attribut}}
    (
    {{attribut_fields|join(',')}}
    ,virkning
    ,{{oio_type}}_registrering_id
    )
    VALUES (
      {%-for fieldname in attribut_fields %} 
    attr{{attribut|title}}Obj.{{fieldname}},
    {%- endfor %}
    attr{{attribut|title}}Obj.virkning,
    new_{{oio_type}}_registrering.id
    );

  END IF;

  END LOOP;
END IF;


IF attr{{attribut|title}} IS NOT NULL AND coalesce(array_length(attr{{attribut|title}},1),0)=0 THEN
--raise debug 'Skipping handling of {{attribut}} of previous registration as an empty array was explicit given.';  
ELSE 

--Handle {{attribut}} of previous registration, taking overlapping virknings into consideration (using function subtract_tstzrange)

INSERT INTO {{oio_type}}_attr_{{attribut}} (
    {{attribut_fields|join(',')}}
    ,virkning
    ,{{oio_type}}_registrering_id
)
SELECT 
   {%-for fieldname in attribut_fields %}
      a.{{fieldname}}, 
    {%- endfor %}
	  ROW(
	    c.tz_range_leftover,
	      (a.virkning).AktoerRef,
	      (a.virkning).AktoerTypeKode,
	      (a.virkning).NoteTekst
	  ) :: virkning,
	 new_{{oio_type}}_registrering.id
FROM
(
 --build an array of the timeperiod of the virkning of the {{oio_type}}_attr_{{attribut}} of the new registrering to pass to _subtract_tstzrange_arr on the {{oio_type}}_attr_{{attribut}} of the previous registrering 
    SELECT coalesce(array_agg((b.virkning).TimePeriod),array[]::TSTZRANGE[]) tzranges_of_new_reg
    FROM {{oio_type}}_attr_{{attribut}} b
    WHERE 
          b.{{oio_type}}_registrering_id=new_{{oio_type}}_registrering.id
) d
  JOIN {{oio_type}}_attr_{{attribut}} a ON true  
  JOIN unnest(_subtract_tstzrange_arr((a.virkning).TimePeriod,tzranges_of_new_reg)) as c(tz_range_leftover) on true
  WHERE a.{{oio_type}}_registrering_id=prev_{{oio_type}}_registrering.id     
;





END IF;


{%- endfor %}


/******************************************************************/
--If the new registrering is identical to the previous one, we need to throw an exception to abort the transaction. 

read_new_{{oio_type}}:=as_read_{{oio_type}}({{oio_type}}_uuid, (new_{{oio_type}}_registrering.registrering).timeperiod,null);
read_prev_{{oio_type}}:=as_read_{{oio_type}}({{oio_type}}_uuid, (prev_{{oio_type}}_registrering.registrering).timeperiod ,null);
 
--the ordering in as_list (called by as_read) ensures that the latest registration is returned at index pos 1

IF NOT (lower((read_new_{{oio_type}}.registrering[1].registrering).TimePeriod)=lower((new_{{oio_type}}_registrering.registrering).TimePeriod) AND lower((read_prev_{{oio_type}}.registrering[1].registrering).TimePeriod)=lower((prev_{{oio_type}}_registrering.registrering).TimePeriod)) THEN
  RAISE EXCEPTION 'Error updating {{oio_type}} with id [%]: The ordering of as_list_{{oio_type}} should ensure that the latest registrering can be found at index 1. Expected new reg: [%]. Actual new reg at index 1: [%]. Expected prev reg: [%]. Actual prev reg at index 1: [%].',{{oio_type}}_uuid,to_json(new_{{oio_type}}_registrering),to_json(read_new_{{oio_type}}.registrering[1].registrering),to_json(prev_{{oio_type}}_registrering),to_json(prev_new_{{oio_type}}.registrering[1].registrering) USING ERRCODE = 'MO500';
END IF;
 
 --we'll ignore the registreringBase part in the comparrison - except for the livcykluskode

read_new_{{oio_type}}_reg:=ROW(
ROW(null,(read_new_{{oio_type}}.registrering[1].registrering).livscykluskode,null,null)::registreringBase,
{%- for tilstand, tilstand_values in tilstande.iteritems() %}
(read_new_{{oio_type}}.registrering[1]).tils{{tilstand|title}} ,{% endfor %}
{%-for attribut , attribut_fields in attributter.iteritems() %}
(read_new_{{oio_type}}.registrering[1]).attr{{attribut|title}} ,{% endfor %}
(read_new_{{oio_type}}.registrering[1]).relationer 
)::{{oio_type}}RegistreringType
;

read_prev_{{oio_type}}_reg:=ROW(
ROW(null,(read_prev_{{oio_type}}.registrering[1].registrering).livscykluskode,null,null)::registreringBase,
{%- for tilstand, tilstand_values in tilstande.iteritems() %}
(read_prev_{{oio_type}}.registrering[1]).tils{{tilstand|title}} ,{% endfor %}
{%-for attribut , attribut_fields in attributter.iteritems() %}
(read_prev_{{oio_type}}.registrering[1]).attr{{attribut|title}} ,{% endfor %}
(read_prev_{{oio_type}}.registrering[1]).relationer 
)::{{oio_type}}RegistreringType
;


IF read_prev_{{oio_type}}_reg=read_new_{{oio_type}}_reg THEN
  --RAISE NOTICE 'Note[%]. Aborted reg:%',note,to_json(read_new_{{oio_type}}_reg);
  --RAISE NOTICE 'Note[%]. Previous reg:%',note,to_json(read_prev_{{oio_type}}_reg);
  RAISE EXCEPTION 'Aborted updating {{oio_type}} with id [%] as the given data, does not give raise to a new registration. Aborted reg:[%], previous reg:[%]',{{oio_type}}_uuid,to_json(read_new_{{oio_type}}_reg),to_json(read_prev_{{oio_type}}_reg) USING ERRCODE = 'MO400';
END IF;

/******************************************************************/

PERFORM actual_state._amqp_publish_notification('{{oio_type|title}}', livscykluskode, {{oio_type}}_uuid);

return new_{{oio_type}}_registrering.id;



END;
$$ LANGUAGE plpgsql VOLATILE;



{% endblock %}