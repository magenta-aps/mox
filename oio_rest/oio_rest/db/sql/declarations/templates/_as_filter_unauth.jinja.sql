{% extends "basis.jinja.sql" %}
-- SPDX-FileCopyrightText: 2018-2020 Magenta ApS
-- SPDX-License-Identifier: MPL-2.0
{% block body %}

CREATE OR REPLACE FUNCTION _as_filter_unauth_{{oio_type}}(
	{{oio_type}}_uuids uuid[],
	registreringObjArr {{oio_type|title}}RegistreringType[]
	)
  RETURNS uuid[] AS 
$$
DECLARE
	{{oio_type}}_passed_auth_filter uuid[]:=ARRAY[]::uuid[];
	{{oio_type}}_candidates uuid[];
	--to_be_applyed_filter_uuids uuid[];
	{%-for attribut , attribut_fields in attributter.items() %} 
	attr{{attribut|title}}TypeObj {{oio_type|title}}{{attribut|title}}AttrType;
	{%- endfor %}
	{% for tilstand, tilstand_values in tilstande.items() %}
  	tils{{tilstand|title}}TypeObj {{oio_type|title}}{{tilstand|title}}TilsType;
  	{%- endfor %}
	relationTypeObj {{oio_type|title}}RelationType;
	registreringObj {{oio_type|title}}RegistreringType;
	actual_virkning TIMESTAMPTZ:=current_timestamp;
BEGIN

--RAISE DEBUG 'step 0:registreringObj:%',registreringObj;

IF registreringObjArr IS NULL THEN
	RETURN {{oio_type}}_uuids; --special case: All is allowed, no criteria present
END IF;

IF coalesce(array_length(registreringObjArr,1),0)=0 THEN
	RETURN ARRAY[]::uuid[]; --special case: Nothing is allowed. Empty list of criteria where at least one has to be met.				
END IF; 

IF {{oio_type}}_uuids IS NULL OR coalesce(array_length({{oio_type}}_uuids,1),0)=0 THEN
	RETURN ARRAY[]::uuid[]; --special case: No candidates given to filter.
END IF;



FOREACH registreringObj IN ARRAY registreringObjArr
LOOP

{{oio_type}}_candidates:= {{oio_type}}_uuids;



--RAISE DEBUG '{{oio_type}}_candidates_is_initialized step 1:%',{{oio_type}}_candidates_is_initialized;
--RAISE DEBUG '{{oio_type}}_candidates step 1:%',{{oio_type}}_candidates;
--/****************************//

--filter on attributes

{%-for attribut , attribut_fields in attributter.items() %} 
--/**********************************************************//
--Filtration on attribute: {{attribut|title}}
--/**********************************************************//
IF registreringObj IS NULL OR (registreringObj).attr{{attribut|title}} IS NULL THEN
	--RAISE DEBUG 'as_search_{{oio_type}}: skipping filtration on attr{{attribut|title}}';
ELSE
	IF coalesce(array_length({{oio_type}}_candidates,1),0)>0 THEN
		FOREACH attr{{attribut|title}}TypeObj IN ARRAY registreringObj.attr{{attribut|title}}
		LOOP
			{{oio_type}}_candidates:=array(
			SELECT DISTINCT
			b.{{oio_type}}_id 
			FROM  {{oio_type}}_attr_{{attribut}} a 
			JOIN {{oio_type}}_registrering b on a.{{oio_type}}_registrering_id=b.id and upper((b.registrering).timeperiod)='infinity'::TIMESTAMPTZ 
			WHERE
				{%- for attribut_field in attribut_fields %}
				(
					attr{{attribut|title}}TypeObj.{{attribut_field}} IS NULL
					OR
					 {%- if attributter_metadata[attribut][attribut_field]['type'] is defined %} 
						{%-if attributter_metadata[attribut][attribut_field]['type'] == "text[]" %}
						((coalesce(array_length(attr{{attribut|title}}TypeObj.{{attribut_field}},1),0)=0 AND coalesce(array_length(a.{{attribut_field}},1),0)=0 ) OR (attr{{attribut|title}}TypeObj.{{attribut_field}} @> a.{{attribut_field}} AND a.{{attribut_field}} @>attr{{attribut|title}}TypeObj.{{attribut_field}}  )) 
						{%- else %} 
						{%-if attributter_metadata[attribut][attribut_field]['type'] == "offentlighedundtagettype" %}
						(
							(
								(attr{{attribut|title}}TypeObj.{{attribut_field}}).AlternativTitel IS NULL
								OR
								(a.{{attribut_field}}).AlternativTitel = (attr{{attribut|title}}TypeObj.{{attribut_field}}).AlternativTitel 
							)
							AND
							(
								(attr{{attribut|title}}TypeObj.{{attribut_field}}).Hjemmel IS NULL
								OR
								(a.{{attribut_field}}).Hjemmel = (attr{{attribut|title}}TypeObj.{{attribut_field}}).Hjemmel
							)
						)
						{%- else %} 
					a.{{attribut_field}} = attr{{attribut|title}}TypeObj.{{attribut_field}}
						{%- endif %}
						{%- endif %}		
					{%- else %} 
					a.{{attribut_field}} = attr{{attribut|title}}TypeObj.{{attribut_field}} 
					{%- endif %} 
				)
				{%- if (not loop.last)%}
				AND
				{%- endif %}
				{%- endfor %}
				AND b.{{oio_type}}_id = ANY ({{oio_type}}_candidates)
				AND (a.virkning).TimePeriod @> actual_virkning 
			);
			
		END LOOP;
	END IF;
END IF;



{%- endfor %}
--RAISE DEBUG '{{oio_type}}_candidates_is_initialized step 3:%',{{oio_type}}_candidates_is_initialized;
--RAISE DEBUG '{{oio_type}}_candidates step 3:%',{{oio_type}}_candidates;

--RAISE DEBUG 'registrering,%',registreringObj;

{% for tilstand, tilstand_values in tilstande.items() %}
--/**********************************************************//
--Filtration on state: {{tilstand|title}}
--/**********************************************************//
IF registreringObj IS NULL OR (registreringObj).tils{{tilstand|title}} IS NULL THEN
	--RAISE DEBUG 'as_search_{{oio_type}}: skipping filtration on tils{{tilstand|title}}';
ELSE
	IF coalesce(array_length({{oio_type}}_candidates,1),0)>0 THEN 

		FOREACH tils{{tilstand|title}}TypeObj IN ARRAY registreringObj.tils{{tilstand|title}}
		LOOP
			{{oio_type}}_candidates:=array(
			SELECT DISTINCT
			b.{{oio_type}}_id 
			FROM  {{oio_type}}_tils_{{tilstand}} a
			JOIN {{oio_type}}_registrering b on a.{{oio_type}}_registrering_id=b.id and upper((b.registrering).timeperiod)='infinity'::TIMESTAMPTZ 
			WHERE
				(
					tils{{tilstand|title}}TypeObj.{{tilstand}} IS NULL
					OR
					tils{{tilstand|title}}TypeObj.{{tilstand}} = a.{{tilstand}}
				)
				AND b.{{oio_type}}_id = ANY ({{oio_type}}_candidates)
				AND (a.virkning).TimePeriod @> actual_virkning
	);
			
		END LOOP;
	END IF;
END IF;

{%- endfor %}

/*
--relationer {{oio_type|title}}RelationType[]
*/


--RAISE DEBUG '{{oio_type}}_candidates_is_initialized step 4:%',{{oio_type}}_candidates_is_initialized;
--RAISE DEBUG '{{oio_type}}_candidates step 4:%',{{oio_type}}_candidates;

--/**********************************************************//
--Filtration on relations
--/**********************************************************//


IF registreringObj IS NULL OR (registreringObj).relationer IS NULL OR coalesce(array_length((registreringObj).relationer,1),0)=0 THEN
	--RAISE DEBUG 'as_search_{{oio_type}}: skipping filtration on relationer';
ELSE
	IF coalesce(array_length({{oio_type}}_candidates,1),0)>0 THEN
		FOREACH relationTypeObj IN ARRAY registreringObj.relationer
		LOOP
			{{oio_type}}_candidates:=array(
			SELECT DISTINCT
			b.{{oio_type}}_id 
			FROM  {{oio_type}}_relation a
			JOIN {{oio_type}}_registrering b on a.{{oio_type}}_registrering_id=b.id and upper((b.registrering).timeperiod)='infinity'::TIMESTAMPTZ
			WHERE
				(	
					relationTypeObj.relType IS NULL
					OR
					relationTypeObj.relType = a.rel_type
				)
				AND
				(
					relationTypeObj.uuid IS NULL
					OR
					relationTypeObj.uuid = a.rel_maal_uuid	
				)
				AND
				(
					relationTypeObj.objektType IS NULL
					OR
					relationTypeObj.objektType = a.objekt_type
				)
				AND
				(
					relationTypeObj.urn IS NULL
					OR
					relationTypeObj.urn = a.rel_maal_urn
				)
				AND b.{{oio_type}}_id = ANY ({{oio_type}}_candidates)
				AND (a.virkning).TimePeriod @> actual_virkning 
	);
		END LOOP;
	END IF;
END IF;
--/**********************//

--RAISE DEBUG '{{oio_type}}_candidates_is_initialized step 5:%',{{oio_type}}_candidates_is_initialized;
--RAISE DEBUG '{{oio_type}}_candidates step 5:%',{{oio_type}}_candidates;

{{oio_type}}_passed_auth_filter:=array(
SELECT
a.id 
FROM
unnest ({{oio_type}}_passed_auth_filter) a(id)
UNION
SELECT
b.id
FROM
unnest ({{oio_type}}_candidates) b(id)
);

--optimization 
IF coalesce(array_length({{oio_type}}_passed_auth_filter,1),0)=coalesce(array_length({{oio_type}}_uuids,1),0) AND {{oio_type}}_passed_auth_filter @>{{oio_type}}_uuids THEN
	RETURN {{oio_type}}_passed_auth_filter;
END IF;


END LOOP; --LOOP registreringObj


RETURN {{oio_type}}_passed_auth_filter;


END;
$$ LANGUAGE plpgsql STABLE; 



{% endblock %}
