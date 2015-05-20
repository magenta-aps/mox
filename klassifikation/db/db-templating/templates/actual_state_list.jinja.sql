{% extends "basis.jinja.sql" %}
-- Copyright (C) 2015 Magenta ApS, http://magenta.dk.
-- Contact: info@magenta.dk.
--
-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at http://mozilla.org/MPL/2.0/.
{% block body %}



			{%-for attribut , attribut_fields in attributter.iteritems() %}{%- set outer_loop = loop %}
				SELECT
				a.{{oio_type}}_id,
				a.{{oio_type}}_registrering_id,
				a.registrering,
				{%-for attribut_inner_loop , attribut_fields_inner_loop in attributter.iteritems() %}
					{%- if loop.index>outer_loop.index  %}
				a.{{oio_type|title}}Attr{{attribut_inner_loop|title}}Arr,{%- endif %}{%- endfor %}
				array_agg(
					ROW(
						{%-for field in attribut_fields %}
				 		b.{{field}},
						{%- endfor %}
				   		b.virkning 
						)::{{oio_type|title}}Attr{{attribut|title}}Type
					order by b.id
				) {{oio_type|title}}Attr{{attribut|title}}Arr 
			{%- endfor %}
				FROM
					(
						SELECT
						a.id {{oio_type}}_id,
						b.id {{oio_type}}_registrering_id,
						b.registrering			
						FROM		{{oio_type}} a
						JOIN 		{{oio_type}}_registrering b 	ON b.{{oio_type}}_id=a.id
						WHERE a.id = ANY ({{oio_type}}_uuids) AND (((registrering_tstzrange is null OR isempty(registrering_tstzrange)) AND upper((b.registrering).timeperiod)='infinity'::TIMESTAMPTZ) OR registrering_tstzrange && (b.registrering).timeperiod)--filter ON registrering_tstzrange
					) as a 
			{%-for attribut , attribut_fields in attributter.iteritems() %}{% set outer_loop = loop %}
				LEFT JOIN 	{{oio_type}}_attr_egenskaber b ON b.{{oio_type}}_registrering_id=a.{{oio_type}}_registrering_id AND ((virkning_tstzrange is null OR isempty(virkning_tstzrange)) OR (b.virkning).TimePeriod && virkning_tstzrange) --filter ON virkning_tstzrange if given			
				GROUP BY 
				a.{{oio_type}}_id,
				a.{{oio_type}}_registrering_id,
				a.registrering
				{%-for attribut_inner_loop , attribut_fields_inner_loop in attributter.iteritems() %}
						{%- if loop.index<outer_loop.index  %}
				a.{{oio_type|title}}Attr{{attribut_inner_loop|title}}Arr{%- if (not loop.last) and (loop.index+1<outer_loop.index)%},{%- endif%}
						{% endif %} 
				{%- endfor %}
			{%- endfor %}


$BODY$
LANGUAGE sql STABLE
;
{% endblock %}