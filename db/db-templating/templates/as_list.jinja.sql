{% extends "basis.jinja.sql" %}
-- Copyright (C) 2015 Magenta ApS, http://magenta.dk.
-- Contact: info@magenta.dk.
--
-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at http://mozilla.org/MPL/2.0/.
{% block body %}
CREATE OR REPLACE FUNCTION as_list_{{oio_type}}({{oio_type}}_uuids uuid[],
  registrering_tstzrange tstzrange,
  virkning_tstzrange tstzrange,
  auth_criteria_arr {{oio_type|title}}RegistreringType[]=null
  )
  RETURNS {{oio_type|title}}Type[] AS
$$
DECLARE
	auth_filtered_uuids uuid[];
	result {{oio_type|title}}Type[];
BEGIN


/*** Verify that the object meets the stipulated access allowed criteria  ***/
auth_filtered_uuids:=_as_filter_unauth_{{oio_type}}({{oio_type}}_uuids,auth_criteria_arr); 
IF NOT (coalesce(array_length(auth_filtered_uuids,1),0)=coalesce(array_length({{oio_type}}_uuids,1),0) AND auth_filtered_uuids @>{{oio_type}}_uuids) THEN
  RAISE EXCEPTION 'Unable to list {{oio_type}} with uuids [%]. All objects do not fullfill the stipulated criteria:%',{{oio_type}}_uuids,to_json(auth_criteria_arr)  USING ERRCODE = 'MO401'; 
END IF;
/*********************/

SELECT 
array_agg( x.{{oio_type}}Obj) into result
FROM
(
SELECT
ROW(
	a.{{oio_type}}_id,
	array_agg(
		ROW (
			a.registrering,
			{%-for tilstand_inner_loop , tilstand_values_inner_loop in tilstande.items() %}
			a.{{oio_type|title}}Tils{{tilstand_inner_loop|title}}Arr,{%- endfor %}
			{%-for attribut_inner_loop , attribut_fields_inner_loop in attributter.items() %}
			a.{{oio_type|title}}Attr{{attribut_inner_loop|title}}Arr,{%- endfor %}
			a.{{oio_type|title}}RelationArr
		)::{{oio_type|title}}RegistreringType
		order by upper((a.registrering).TimePeriod) DESC		
	) 
):: {{oio_type|title}}Type  {{oio_type}}Obj
FROM
(
	SELECT
	a.{{oio_type}}_id,
	a.{{oio_type}}_registrering_id,
	a.registrering,
	{%-for attribut_inner_loop , attribut_fields_inner_loop in attributter.items() %}
	a.{{oio_type|title}}Attr{{attribut_inner_loop|title}}Arr,{%- endfor %}
	{%-for tilstand_inner_loop , tilstand_values_inner_loop in tilstande.items() %}
	a.{{oio_type|title}}Tils{{tilstand_inner_loop|title}}Arr,{%- endfor %}
	_remove_nulls_in_array(array_agg(
		CASE
		WHEN b.id is not null THEN
		ROW (
				b.rel_type,
				b.virkning,
				b.rel_maal_uuid,
				b.rel_maal_urn,
				b.objekt_type 
			):: {{oio_type|title}}RelationType
		ELSE
		NULL
		END
		order by b.rel_maal_uuid,b.rel_maal_urn,b.rel_type,b.objekt_type,b.virkning
	)) {{oio_type|title}}RelationArr
	FROM
	(
			{%-for tilstand , tilstand_values in tilstande.items() %}{%- set outer_loop = loop %}
			SELECT
			a.{{oio_type}}_id,
			a.{{oio_type}}_registrering_id,
			a.registrering,
			{%-for attribut_inner_loop , attribut_fields_inner_loop in attributter.items() %}
			a.{{oio_type|title}}Attr{{attribut_inner_loop|title}}Arr,{%- endfor %}
			{%-for tilstand_inner_loop , tilstand_values_inner_loop in tilstande.items() %}
			{%- if loop.index>outer_loop.index  %}
			a.{{oio_type|title}}Tils{{tilstand_inner_loop|title}}Arr,{%- endif %}{%- endfor %}
			_remove_nulls_in_array(array_agg
				(
					CASE
					WHEN b.id is not null THEN 
					ROW(
						b.virkning,
						b.{{tilstand}}
						) ::{{oio_type|title}}{{tilstand|title}}TilsType
					ELSE NULL
					END
					order by b.{{tilstand}},b.virkning
				)) {{oio_type|title}}Tils{{tilstand|title}}Arr		
			FROM
			(
			{%- endfor %}	
				{%-for attribut , attribut_fields in attributter.items() %}{%- set outer_loop = loop %}
					SELECT
					a.{{oio_type}}_id,
					a.{{oio_type}}_registrering_id,
					a.registrering,
					{%-for attribut_inner_loop , attribut_fields_inner_loop in attributter.items() %}
						{%- if loop.index>outer_loop.index  %}
					a.{{oio_type|title}}Attr{{attribut_inner_loop|title}}Arr,{%- endif %}{%- endfor %}
					_remove_nulls_in_array(array_agg(
						CASE 
						WHEN b.id is not null THEN
						ROW(
							{%-for field in attribut_fields %}
					 		b.{{field}},
							{%- endfor %}
					   		b.virkning 
							)::{{oio_type|title}}{{attribut|title}}AttrType
						ELSE
						NULL
						END
						order by b.{{attribut_fields|join(',b.')}},b.virkning
					)) {{oio_type|title}}Attr{{attribut|title}}Arr 
					FROM
					(
				{%- endfor %}
					SELECT
					a.id {{oio_type}}_id,
					b.id {{oio_type}}_registrering_id,
					b.registrering			
					FROM		{{oio_type}} a
					JOIN 		{{oio_type}}_registrering b 	ON b.{{oio_type}}_id=a.id
					WHERE a.id = ANY ({{oio_type}}_uuids) AND ((registrering_tstzrange is null AND upper((b.registrering).timeperiod)='infinity'::TIMESTAMPTZ) OR registrering_tstzrange && (b.registrering).timeperiod)--filter ON registrering_tstzrange
				{%-for attribut , attribut_fields in attributter_revorder.items() %}{% set outer_loop = loop %}
					) as a
					LEFT JOIN {{oio_type}}_attr_{{attribut}} as b ON b.{{oio_type}}_registrering_id=a.{{oio_type}}_registrering_id AND (virkning_tstzrange is null OR (b.virkning).TimePeriod && virkning_tstzrange) --filter ON virkning_tstzrange if given			
					GROUP BY 
					a.{{oio_type}}_id,
					a.{{oio_type}}_registrering_id,
					a.registrering
					{%-for attribut_inner_loop , attribut_fields_inner_loop in attributter_revorder.items() %}
							{%- if loop.index<outer_loop.index  %}{%- if(loop.first) %},{%- endif%}
					a.{{oio_type|title}}Attr{{attribut_inner_loop|title}}Arr{%- if (not loop.last) and (loop.index+1<outer_loop.index)%},{%- endif%}
							{%- endif %} 
					{%- endfor %}
				{%- endfor %}
				{%-for tilstand , tilstand_values in tilstande_revorder.items() %}{%- set outer_loop = loop %}	
			) as a
			LEFT JOIN {{oio_type}}_tils_{{tilstand}} as b ON b.{{oio_type}}_registrering_id=a.{{oio_type}}_registrering_id AND (virkning_tstzrange is null OR (b.virkning).TimePeriod && virkning_tstzrange) --filter ON virkning_tstzrange if given			
			GROUP BY 
			a.{{oio_type}}_id,
			a.{{oio_type}}_registrering_id,
			a.registrering,
			{%-for attribut_inner_loop , attribut_fields_inner_loop in attributter_revorder.items() %}
			a.{{oio_type|title}}Attr{{attribut_inner_loop|title}}Arr{%-if not (loop.last and outer_loop.index==1) %},{%- endif %}{%- endfor %}
			{%-for tilstand_inner_loop , tilstand_values_inner_loop in tilstande_revorder.items() %}
			{%- if loop.index<outer_loop.index  %}
			a.{{oio_type|title}}Tils{{tilstand_inner_loop|title}}Arr{%- if (not loop.last) and (loop.index+1<outer_loop.index)%},{%- endif%}{%- endif %}{%- endfor %}
				{%- endfor %}
	) as a
	LEFT JOIN {{oio_type}}_relation b ON b.{{oio_type}}_registrering_id=a.{{oio_type}}_registrering_id AND (virkning_tstzrange is null OR (b.virkning).TimePeriod && virkning_tstzrange) --filter ON virkning_tstzrange if given
	GROUP BY
	a.{{oio_type}}_id,
	a.{{oio_type}}_registrering_id,
	a.registrering,
	{%-for attribut_inner_loop , attribut_fields_inner_loop in attributter_revorder.items() %}
	a.{{oio_type|title}}Attr{{attribut_inner_loop|title}}Arr,{%- endfor %}
	{%-for tilstand_inner_loop , tilstand_values_inner_loop in tilstande_revorder.items() %}
	a.{{oio_type|title}}Tils{{tilstand_inner_loop|title}}Arr{%- if (not loop.last)%},{%- endif%}{%- endfor %}
) as a
WHERE a.{{oio_type}}_id IS NOT NULL
GROUP BY 
a.{{oio_type}}_id
order by a.{{oio_type}}_id
) as x
;



RETURN result;

END;
$$ LANGUAGE plpgsql STABLE;

{% endblock %}
