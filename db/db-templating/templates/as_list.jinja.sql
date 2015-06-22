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
  virkning_tstzrange tstzrange)
  RETURNS setof {{oio_type|title}}Type AS
  $BODY$

SELECT
ROW(
	a.{{oio_type}}_id,
	array_agg(
		ROW (
			a.registrering,
			{%-for tilstand_inner_loop , tilstand_values_inner_loop in tilstande.iteritems() %}
			a.{{oio_type|title}}Tils{{tilstand_inner_loop|title}}Arr,{%- endfor %}
			{%-for attribut_inner_loop , attribut_fields_inner_loop in attributter.iteritems() %}
			a.{{oio_type|title}}Attr{{attribut_inner_loop|title}}Arr,{%- endfor %}
			a.{{oio_type|title}}RelationArr
		)::{{oio_type|title}}RegistreringType
		order by upper((a.registrering).TimePeriod) DESC		
	) 
):: {{oio_type|title}}Type
FROM
(
	SELECT
	a.{{oio_type}}_id,
	a.{{oio_type}}_registrering_id,
	a.registrering,
	{%-for attribut_inner_loop , attribut_fields_inner_loop in attributter.iteritems() %}
	a.{{oio_type|title}}Attr{{attribut_inner_loop|title}}Arr,{%- endfor %}
	{%-for tilstand_inner_loop , tilstand_values_inner_loop in tilstande.iteritems() %}
	a.{{oio_type|title}}Tils{{tilstand_inner_loop|title}}Arr,{%- endfor %}
	_remove_nulls_in_array(array_agg(
		CASE
		WHEN b.id is not null THEN
		ROW (
				b.rel_type,
				b.virkning,
				b.rel_maal_uuid,
				b.rel_maal_urn 
			):: {{oio_type|title}}RelationType
		ELSE
		NULL
		END
		order by b.rel_maal_uuid,b.rel_maal_urn,b.rel_type,b.virkning
	)) {{oio_type|title}}RelationArr
	FROM
	(
			{%-for tilstand , tilstand_values in tilstande.iteritems() %}{%- set outer_loop = loop %}
			SELECT
			a.{{oio_type}}_id,
			a.{{oio_type}}_registrering_id,
			a.registrering,
			{%-for attribut_inner_loop , attribut_fields_inner_loop in attributter.iteritems() %}
			a.{{oio_type|title}}Attr{{attribut_inner_loop|title}}Arr,{%- endfor %}
			{%-for tilstand_inner_loop , tilstand_values_inner_loop in tilstande.iteritems() %}
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
				{%-for attribut , attribut_fields in attributter.iteritems() %}{%- set outer_loop = loop %}
					SELECT
					a.{{oio_type}}_id,
					a.{{oio_type}}_registrering_id,
					a.registrering,
					{%-for attribut_inner_loop , attribut_fields_inner_loop in attributter.iteritems() %}
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
				{%-for attribut , attribut_fields in attributter_revorder.iteritems() %}{% set outer_loop = loop %}
					) as a
					LEFT JOIN {{oio_type}}_attr_{{attribut}} as b ON b.{{oio_type}}_registrering_id=a.{{oio_type}}_registrering_id AND (virkning_tstzrange is null OR (b.virkning).TimePeriod && virkning_tstzrange) --filter ON virkning_tstzrange if given			
					GROUP BY 
					a.{{oio_type}}_id,
					a.{{oio_type}}_registrering_id,
					a.registrering
					{%-for attribut_inner_loop , attribut_fields_inner_loop in attributter_revorder.iteritems() %}
							{%- if loop.index<outer_loop.index  %}{%- if(loop.first) %},{%- endif%}
					a.{{oio_type|title}}Attr{{attribut_inner_loop|title}}Arr{%- if (not loop.last) and (loop.index+1<outer_loop.index)%},{%- endif%}
							{%- endif %} 
					{%- endfor %}
				{%- endfor %}
				{%-for tilstand , tilstand_values in tilstande_revorder.iteritems() %}{%- set outer_loop = loop %}	
			) as a
			LEFT JOIN {{oio_type}}_tils_{{tilstand}} as b ON b.{{oio_type}}_registrering_id=a.{{oio_type}}_registrering_id AND (virkning_tstzrange is null OR (b.virkning).TimePeriod && virkning_tstzrange) --filter ON virkning_tstzrange if given			
			GROUP BY 
			a.{{oio_type}}_id,
			a.{{oio_type}}_registrering_id,
			a.registrering,
			{%-for attribut_inner_loop , attribut_fields_inner_loop in attributter_revorder.iteritems() %}
			a.{{oio_type|title}}Attr{{attribut_inner_loop|title}}Arr{%-if not (loop.last and outer_loop.index==1) %},{%- endif %}{%- endfor %}
			{%-for tilstand_inner_loop , tilstand_values_inner_loop in tilstande_revorder.iteritems() %}
			{%- if loop.index<outer_loop.index  %}
			a.{{oio_type|title}}Tils{{tilstand_inner_loop|title}}Arr{%- if (not loop.last) and (loop.index+1<outer_loop.index)%},{%- endif%}{%- endif %}{%- endfor %}
				{%- endfor %}
	) as a
	LEFT JOIN {{oio_type}}_relation b ON b.{{oio_type}}_registrering_id=a.{{oio_type}}_registrering_id AND (virkning_tstzrange is null OR (b.virkning).TimePeriod && virkning_tstzrange) --filter ON virkning_tstzrange if given
	GROUP BY
	a.{{oio_type}}_id,
	a.{{oio_type}}_registrering_id,
	a.registrering,
	{%-for attribut_inner_loop , attribut_fields_inner_loop in attributter_revorder.iteritems() %}
	a.{{oio_type|title}}Attr{{attribut_inner_loop|title}}Arr,{%- endfor %}
	{%-for tilstand_inner_loop , tilstand_values_inner_loop in tilstande_revorder.iteritems() %}
	a.{{oio_type|title}}Tils{{tilstand_inner_loop|title}}Arr{%- if (not loop.last)%},{%- endif%}{%- endfor %}
) as a
WHERE a.{{oio_type}}_id IS NOT NULL
GROUP BY 
a.{{oio_type}}_id
order by a.{{oio_type}}_id

$BODY$
LANGUAGE sql STABLE
;
{% endblock %}