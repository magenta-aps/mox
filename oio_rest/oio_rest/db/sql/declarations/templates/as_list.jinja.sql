{% extends "basis.jinja.sql" %}
-- SPDX-FileCopyrightText: 2018-2020 Magenta ApS
-- SPDX-License-Identifier: MPL-2.0
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
array_agg(x.{{oio_type}}Obj) into result
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
			a.{{oio_type|title}}RelationArr{% if oio_type == "dokument" %},
            b.varianter{% endif %}
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
				b.objekt_type{% if oio_type == "aktivitet" %},
                b.rel_index,
                b.aktoer_attr{% elif oio_type == "indsats" %},
                b.rel_index{% elif oio_type == "sag" %},
                b.rel_index,
                b.rel_type_spec,
                b.journal_notat,
                b.journal_dokument_attr{% elif oio_type == "tilstand" %},
                b.rel_index,
                b.tilstand_vaerdi_attr{% endif %}
			):: {{oio_type|title}}RelationType
		ELSE
		NULL
		END
        {% if oio_type == "aktivitet" %}
		order by b.rel_maal_uuid,b.rel_maal_urn,b.rel_type,b.objekt_type,b.rel_index,b.aktoer_attr,b.virkning
        {% elif oio_type == "indsats" %}
		order by b.rel_maal_uuid,b.rel_maal_urn,b.rel_type,b.objekt_type,b.rel_index,b.virkning
        {% elif oio_type == "sag" %}
        order by b.rel_type,b.rel_index,b.rel_maal_uuid,b.rel_maal_urn,b.objekt_type,b.rel_type_spec,b.journal_notat,b.journal_dokument_attr,b.virkning
        {% elif oio_type == "tilstand" %}
		order by b.rel_maal_uuid,b.rel_maal_urn,b.rel_type,b.objekt_type,b.rel_index,b.tilstand_vaerdi_attr,b.virkning
        {% else %}
		order by b.rel_maal_uuid,b.rel_maal_urn,b.rel_type,b.objekt_type,b.virkning
        {% endif %}
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
                        {% if oio_type == "klasse" %}
						WHEN a.attr_id is not null THEN
                        {% else %}
						WHEN b.id is not null THEN
                        {% endif %}
						ROW(
                            {% if oio_type == "klasse" %}
                                                       a.brugervendtnoegle,
                                                       a.beskrivelse,
                                                       a.eksempel,
                                                       a.omfang,
                                                       a.titel,
                                                       a.retskilde,
                                                       a.aendringsnotat,
                                                       a.integrationsdata,
                                                       a.KlasseAttrEgenskaberSoegeordTypeArr,
                                                       a.virkning 
                            {% else %}
							{%-for field in attribut_fields %}
					 		b.{{field}},
							{%- endfor %}
					   		b.virkning
                            {% endif %}
							)::{{oio_type|title}}{{attribut|title}}AttrType
						ELSE
						NULL
						END
                        {% if oio_type == "klasse" %}
                        order by a.brugervendtnoegle,a.beskrivelse,a.eksempel,a.omfang,a.titel,a.retskilde,a.aendringsnotat,a.virkning,a.KlasseAttrEgenskaberSoegeordTypeArr
                        {% else %}
						order by b.{{attribut_fields|join(',b.')}},b.virkning
                        {% endif %}
					)) {{oio_type|title}}Attr{{attribut|title}}Arr
                    {% if oio_type == "klasse" %}
                               FROM            
                               (
                                               SELECT
                                               a.klasse_id,
                                               a.klasse_registrering_id,
                                               a.registrering,
                                               b.id attr_id,
                                               b.brugervendtnoegle,
                                               b.beskrivelse,
                                               b.eksempel,
                                               b.omfang,
                                               b.titel,
                                               b.retskilde,
                                               b.aendringsnotat,
                                               b.integrationsdata,
                                               b.virkning,     
                                               _remove_nulls_in_array(array_agg(
                                                       CASE 
                                                       WHEN c.id is not null THEN
                                                       ROW(
                                                               c.soegeordidentifikator,
                                                               c.beskrivelse,
                                                               c.soegeordskategori 
                                                       )::KlasseSoegeordType
                                               ELSE
                                               NULL
                                               END
                                               order by c.soegeordidentifikator,c.beskrivelse,c.soegeordskategori
                                       )) KlasseAttrEgenskaberSoegeordTypeArr
                    {% endif %}
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
				{%-for attribut , attribut_fields in attributter.items() | reverse %}{% set outer_loop = loop %}
					) as a
					LEFT JOIN {{oio_type}}_attr_{{attribut}} as b ON b.{{oio_type}}_registrering_id=a.{{oio_type}}_registrering_id AND (virkning_tstzrange is null OR (b.virkning).TimePeriod && virkning_tstzrange) --filter ON virkning_tstzrange if given
                    {% if oio_type == "klasse" %}
                                               LEFT JOIN klasse_attr_egenskaber_soegeord as c ON c.klasse_attr_egenskaber_id=b.id
                                               GROUP BY 
                                               a.klasse_id,
                                               a.klasse_registrering_id,
                                               a.registrering,
                                               b.id,
                                               b.brugervendtnoegle,
                                               b.beskrivelse,
                                               b.eksempel,
                                               b.omfang,
                                               b.titel,
                                               b.retskilde,
                                               b.aendringsnotat,
                                               b.integrationsdata,
                                               b.virkning
                               ) as a
                    {% endif %}
					GROUP BY 
					a.{{oio_type}}_id,
					a.{{oio_type}}_registrering_id,
					a.registrering
					{%-for attribut_inner_loop , attribut_fields_inner_loop in attributter.items() | reverse %}
							{%- if loop.index<outer_loop.index  %}{%- if(loop.first) %},{%- endif%}
					a.{{oio_type|title}}Attr{{attribut_inner_loop|title}}Arr{%- if (not loop.last) and (loop.index+1<outer_loop.index)%},{%- endif%}
							{%- endif %} 
					{%- endfor %}
				{%- endfor %}
				{%-for tilstand , tilstand_values in tilstande.items() | reverse %}{%- set outer_loop = loop %}	
			) as a
			LEFT JOIN {{oio_type}}_tils_{{tilstand}} as b ON b.{{oio_type}}_registrering_id=a.{{oio_type}}_registrering_id AND (virkning_tstzrange is null OR (b.virkning).TimePeriod && virkning_tstzrange) --filter ON virkning_tstzrange if given			
			GROUP BY 
			a.{{oio_type}}_id,
			a.{{oio_type}}_registrering_id,
			a.registrering,
			{%-for attribut_inner_loop , attribut_fields_inner_loop in attributter.items() | reverse %}
			a.{{oio_type|title}}Attr{{attribut_inner_loop|title}}Arr{%-if not (loop.last and outer_loop.index==1) %},{%- endif %}{%- endfor %}
			{%-for tilstand_inner_loop , tilstand_values_inner_loop in tilstande.items() | reverse %}
			{%- if loop.index<outer_loop.index  %}
			a.{{oio_type|title}}Tils{{tilstand_inner_loop|title}}Arr{%- if (not loop.last) and (loop.index+1<outer_loop.index)%},{%- endif%}{%- endif %}{%- endfor %}
				{%- endfor %}
	) as a
	LEFT JOIN {{oio_type}}_relation b ON b.{{oio_type}}_registrering_id=a.{{oio_type}}_registrering_id AND (virkning_tstzrange is null OR (b.virkning).TimePeriod && virkning_tstzrange) --filter ON virkning_tstzrange if given
	GROUP BY
	a.{{oio_type}}_id,
	a.{{oio_type}}_registrering_id,
	a.registrering,
	{%-for attribut_inner_loop , attribut_fields_inner_loop in attributter.items() | reverse %}
	a.{{oio_type|title}}Attr{{attribut_inner_loop|title}}Arr,{%- endfor %}
	{%-for tilstand_inner_loop , tilstand_values_inner_loop in tilstande.items() | reverse %}
	a.{{oio_type|title}}Tils{{tilstand_inner_loop|title}}Arr{%- if (not loop.last)%},{%- endif%}{%- endfor %}
) as a
{% if oio_type == "dokument" %}
LEFT JOIN _as_list_dokument_varianter(dokument_uuids,registrering_tstzrange,virkning_tstzrange) b on a.dokument_registrering_id=b.dokument_registrering_id
{% endif %}
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
