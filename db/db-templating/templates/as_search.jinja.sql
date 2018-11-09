{% extends "basis.jinja.sql" %}
-- Copyright (C) 2015 Magenta ApS, http://magenta.dk.
-- Contact: info@magenta.dk.
--
-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at http://mozilla.org/MPL/2.0/.
{% block body %}

CREATE OR REPLACE FUNCTION as_search_{{oio_type}}(
	firstResult int,--TOOD ??
	{{oio_type}}_uuid uuid,
	registreringObj {{oio_type|title}}RegistreringType,
	virkningSoeg TSTZRANGE, -- = TSTZRANGE(current_timestamp,current_timestamp,'[]'),
	maxResults int = 2147483647,
	anyAttrValueArr text[] = '{}'::text[],
	anyuuidArr	uuid[] = '{}'::uuid[],
	anyurnArr text[] = '{}'::text[],
	auth_criteria_arr {{oio_type|title}}RegistreringType[]=null
	)
  RETURNS uuid[] AS 
$$
DECLARE
	{{oio_type}}_candidates uuid[];
	{{oio_type}}_candidates_is_initialized boolean;
	--to_be_applyed_filter_uuids uuid[];
	{%-for attribut , attribut_fields in attributter.items() %} 
	attr{{attribut|title}}TypeObj {{oio_type|title}}{{attribut|title}}AttrType;
	{%- endfor %}
	{% for tilstand, tilstand_values in tilstande.items() %}
  	tils{{tilstand|title}}TypeObj {{oio_type|title}}{{tilstand|title}}TilsType;
  	{%- endfor %}
	relationTypeObj {{oio_type|title}}RelationType;
	anyAttrValue text;
	anyuuid uuid;
	anyurn text;
	auth_filtered_uuids uuid[];
BEGIN

--RAISE DEBUG 'step 0:registreringObj:%',registreringObj;

{{oio_type}}_candidates_is_initialized := false;

IF {{oio_type}}_uuid is not NULL THEN
	{{oio_type}}_candidates:= ARRAY[{{oio_type}}_uuid];
	{{oio_type}}_candidates_is_initialized:=true;
	IF registreringObj IS NULL THEN
	--RAISE DEBUG 'no registreringObj'
	ELSE	
		{{oio_type}}_candidates:=array(
				SELECT DISTINCT
				b.{{oio_type}}_id 
				FROM
				{{oio_type}} a
				JOIN {{oio_type}}_registrering b on b.{{oio_type}}_id=a.id
				WHERE
				{% include 'as_search_mixin_filter_reg.jinja.sql' %}
		);		
	END IF;
	
END IF;


--RAISE DEBUG '{{oio_type}}_candidates_is_initialized step 1:%',{{oio_type}}_candidates_is_initialized;
--RAISE DEBUG '{{oio_type}}_candidates step 1:%',{{oio_type}}_candidates;
--/****************************//


--RAISE NOTICE '{{oio_type}}_candidates_is_initialized step 2:%',{{oio_type}}_candidates_is_initialized;
--RAISE NOTICE '{{oio_type}}_candidates step 2:%',{{oio_type}}_candidates;

--/****************************//
--filter on attributes

{%-for attribut , attribut_fields in attributter.items() %} 
--/**********************************************************//
--Filtration on attribute: {{attribut|title}}
--/**********************************************************//
IF registreringObj IS NULL OR (registreringObj).attr{{attribut|title}} IS NULL THEN
	--RAISE DEBUG 'as_search_{{oio_type}}: skipping filtration on attr{{attribut|title}}';
ELSE
	IF (coalesce(array_length({{oio_type}}_candidates,1),0)>0 OR NOT {{oio_type}}_candidates_is_initialized) THEN
		FOREACH attr{{attribut|title}}TypeObj IN ARRAY registreringObj.attr{{attribut|title}}
		LOOP
			{{oio_type}}_candidates:=array(
			SELECT DISTINCT
			b.{{oio_type}}_id 
			FROM  {{oio_type}}_attr_{{attribut}} a
			JOIN {{oio_type}}_registrering b on a.{{oio_type}}_registrering_id=b.id
			WHERE
				(
					(
						attr{{attribut|title}}TypeObj.virkning IS NULL 
						OR
						(
							(
								(
							 		(attr{{attribut|title}}TypeObj.virkning).TimePeriod IS NULL
								)
								OR
								(
									(attr{{attribut|title}}TypeObj.virkning).TimePeriod && (a.virkning).TimePeriod
								)
							)
							AND
							(
									(attr{{attribut|title}}TypeObj.virkning).AktoerRef IS NULL OR (attr{{attribut|title}}TypeObj.virkning).AktoerRef=(a.virkning).AktoerRef
							)
							AND
							(
									(attr{{attribut|title}}TypeObj.virkning).AktoerTypeKode IS NULL OR (attr{{attribut|title}}TypeObj.virkning).AktoerTypeKode=(a.virkning).AktoerTypeKode
							)
							AND
							(
									(attr{{attribut|title}}TypeObj.virkning).NoteTekst IS NULL OR  (a.virkning).NoteTekst ILIKE (attr{{attribut|title}}TypeObj.virkning).NoteTekst  
							)
						)
					)
				)
				AND
				(
					(NOT (attr{{attribut|title}}TypeObj.virkning IS NULL OR (attr{{attribut|title}}TypeObj.virkning).TimePeriod IS NULL)) --we have already filtered on virkning above
					OR
					(
						virkningSoeg IS NULL
						OR
						virkningSoeg && (a.virkning).TimePeriod
					)
				)
				{%- for attribut_field in attribut_fields %}
				AND
				(
					attr{{attribut|title}}TypeObj.{{attribut_field}} IS NULL
					OR
					 {%- if  attributter_metadata is defined and attributter_metadata[attribut] is defined and attributter_metadata[attribut][attribut_field] is defined and attributter_metadata[attribut][attribut_field]['type'] %}
						{%-if attributter_metadata[attribut][attribut_field]['type'] == "text[]" %}
					_as_search_match_array(attr{{attribut|title}}TypeObj.{{attribut_field}},a.{{attribut_field}})  
						{%- else %} 
						{%-if attributter_metadata[attribut][attribut_field]['type'] == "offentlighedundtagettype" %}
						(
							(
								(attr{{attribut|title}}TypeObj.{{attribut_field}}).AlternativTitel IS NULL
								OR
								(a.{{attribut_field}}).AlternativTitel ILIKE (attr{{attribut|title}}TypeObj.{{attribut_field}}).AlternativTitel 
							)
							AND
							(
								(attr{{attribut|title}}TypeObj.{{attribut_field}}).Hjemmel IS NULL
								OR
								(a.{{attribut_field}}).Hjemmel ILIKE (attr{{attribut|title}}TypeObj.{{attribut_field}}).Hjemmel
							)
						)
						{%- else %} 
					a.{{attribut_field}} = attr{{attribut|title}}TypeObj.{{attribut_field}}
						{%- endif %}
						{%- endif %}		
					{%- else %} 
					a.{{attribut_field}} ILIKE attr{{attribut|title}}TypeObj.{{attribut_field}} --case insensitive
					{%- endif %} 
				)
				{%- endfor %}
				AND
				{% include 'as_search_mixin_filter_reg.jinja.sql' %}
			);
			

			{{oio_type}}_candidates_is_initialized:=true;
			

		END LOOP;
	END IF;
END IF;





{%- endfor %}
--RAISE DEBUG '{{oio_type}}_candidates_is_initialized step 3:%',{{oio_type}}_candidates_is_initialized;
--RAISE DEBUG '{{oio_type}}_candidates step 3:%',{{oio_type}}_candidates;

--/**********************************************************//
--Filtration on anyAttrValueArr
--/**********************************************************//
IF coalesce(array_length(anyAttrValueArr ,1),0)>0 THEN

	FOREACH anyAttrValue IN ARRAY anyAttrValueArr
	LOOP
		{{oio_type}}_candidates:=array(

			{%-for attribut , attribut_fields in attributter.items() %} 

			SELECT DISTINCT
			b.{{oio_type}}_id 
			FROM  {{oio_type}}_attr_{{attribut}} a
			JOIN {{oio_type}}_registrering b on a.{{oio_type}}_registrering_id=b.id
			WHERE
			(
				{%- for attribut_field in attribut_fields %}
					{%- if  attributter_metadata is defined and attributter_metadata[attribut] is defined and attributter_metadata[attribut][attribut_field] is defined and attributter_metadata[attribut][attribut_field]['type'] %}
						{%-if attributter_metadata[attribut][attribut_field]['type'] == "text[]" %}
							  _as_search_ilike_array(anyAttrValue,a.{{attribut_field}})  {%- if (not loop.last)%} OR {%- endif %}
						{%-else %}
							{%-if attributter_metadata[attribut][attribut_field]['type'] == "boolean" %}
								{# boolean is skipped intentionally #}
							{%-else %}
								{%-if attributter_metadata[attribut][attribut_field]['type'] == "offentlighedundtagettype" %}
									(a.{{attribut_field}}).Hjemmel ilike anyAttrValue OR (a.{{attribut_field}}).AlternativTitel ilike anyAttrValue {%- if (not loop.last)%} OR {%- endif %}
								{%-else %}
									a.{{attribut_field}}::text ilike anyAttrValue  {%- if (not loop.last)%} OR {%- endif %}
								{%- endif -%}
							{%- endif -%}
						{%- endif -%}
					{%-else %}
						a.{{attribut_field}} ILIKE anyAttrValue {%- if (not loop.last)%} OR {%- endif %}
					{%- endif -%}
				{%- endfor %}
			)
			AND
			(
				virkningSoeg IS NULL
				OR
				virkningSoeg && (a.virkning).TimePeriod
			)
			AND
			{% include 'as_search_mixin_filter_reg.jinja.sql' %}

			{%- if (not loop.last)%}
			UNION
			{%- endif %}
			{%- endfor %}

		);

	{{oio_type}}_candidates_is_initialized:=true;

	END LOOP;

END IF;



--RAISE DEBUG 'registrering,%',registreringObj;

{% for tilstand, tilstand_values in tilstande.items() %}
--/**********************************************************//
--Filtration on state: {{tilstand|title}}
--/**********************************************************//
IF registreringObj IS NULL OR (registreringObj).tils{{tilstand|title}} IS NULL THEN
	--RAISE DEBUG 'as_search_{{oio_type}}: skipping filtration on tils{{tilstand|title}}';
ELSE
	IF (coalesce(array_length({{oio_type}}_candidates,1),0)>0 OR {{oio_type}}_candidates_is_initialized IS FALSE ) THEN 

		FOREACH tils{{tilstand|title}}TypeObj IN ARRAY registreringObj.tils{{tilstand|title}}
		LOOP
			{{oio_type}}_candidates:=array(
			SELECT DISTINCT
			b.{{oio_type}}_id 
			FROM  {{oio_type}}_tils_{{tilstand}} a
			JOIN {{oio_type}}_registrering b on a.{{oio_type}}_registrering_id=b.id
			WHERE
				(
					tils{{tilstand|title}}TypeObj.virkning IS NULL
					OR
					(
						(
					 		(tils{{tilstand|title}}TypeObj.virkning).TimePeriod IS NULL 
							OR
							(tils{{tilstand|title}}TypeObj.virkning).TimePeriod && (a.virkning).TimePeriod
						)
						AND
						(
								(tils{{tilstand|title}}TypeObj.virkning).AktoerRef IS NULL OR (tils{{tilstand|title}}TypeObj.virkning).AktoerRef=(a.virkning).AktoerRef
						)
						AND
						(
								(tils{{tilstand|title}}TypeObj.virkning).AktoerTypeKode IS NULL OR (tils{{tilstand|title}}TypeObj.virkning).AktoerTypeKode=(a.virkning).AktoerTypeKode
						)
						AND
						(
								(tils{{tilstand|title}}TypeObj.virkning).NoteTekst IS NULL OR (a.virkning).NoteTekst ILIKE (tils{{tilstand|title}}TypeObj.virkning).NoteTekst
						)
					)
				)
				AND
				(
					(NOT ((tils{{tilstand|title}}TypeObj.virkning) IS NULL OR (tils{{tilstand|title}}TypeObj.virkning).TimePeriod IS NULL)) --we have already filtered on virkning above
					OR
					(
						virkningSoeg IS NULL
						OR
						virkningSoeg && (a.virkning).TimePeriod
					)
				)
				AND
				(
					tils{{tilstand|title}}TypeObj.{{tilstand}} IS NULL
					OR
					tils{{tilstand|title}}TypeObj.{{tilstand}} = a.{{tilstand}}
				)
				AND
				{% include 'as_search_mixin_filter_reg.jinja.sql' %}
	);
			

			{{oio_type}}_candidates_is_initialized:=true;
			

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


IF registreringObj IS NULL OR (registreringObj).relationer IS NULL THEN
	--RAISE DEBUG 'as_search_{{oio_type}}: skipping filtration on relationer';
ELSE
	IF (coalesce(array_length({{oio_type}}_candidates,1),0)>0 OR NOT {{oio_type}}_candidates_is_initialized) AND (registreringObj).relationer IS NOT NULL THEN
		FOREACH relationTypeObj IN ARRAY registreringObj.relationer
		LOOP
			{{oio_type}}_candidates:=array(
			SELECT DISTINCT
			b.{{oio_type}}_id 
			FROM  {{oio_type}}_relation a
			JOIN {{oio_type}}_registrering b on a.{{oio_type}}_registrering_id=b.id
			WHERE
				(
					relationTypeObj.virkning IS NULL
					OR
					(
						(
						 	(relationTypeObj.virkning).TimePeriod IS NULL 
							OR
							(relationTypeObj.virkning).TimePeriod && (a.virkning).TimePeriod
						)
						AND
						(
								(relationTypeObj.virkning).AktoerRef IS NULL OR (relationTypeObj.virkning).AktoerRef=(a.virkning).AktoerRef
						)
						AND
						(
								(relationTypeObj.virkning).AktoerTypeKode IS NULL OR (relationTypeObj.virkning).AktoerTypeKode=(a.virkning).AktoerTypeKode
						)
						AND
						(
								(relationTypeObj.virkning).NoteTekst IS NULL OR (a.virkning).NoteTekst ILIKE (relationTypeObj.virkning).NoteTekst
						)
					)
				)
				AND
				(
					(NOT (relationTypeObj.virkning IS NULL OR (relationTypeObj.virkning).TimePeriod IS NULL)) --we have already filtered on virkning above
					OR
					(
						virkningSoeg IS NULL
						OR
						virkningSoeg && (a.virkning).TimePeriod
					)
				)
				AND
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
				AND
				{% include 'as_search_mixin_filter_reg.jinja.sql' %}
	);
			
			{{oio_type}}_candidates_is_initialized:=true;
			

		END LOOP;
	END IF;
END IF;
--/**********************//

IF coalesce(array_length(anyuuidArr ,1),0)>0 THEN

	FOREACH anyuuid IN ARRAY anyuuidArr
	LOOP
		{{oio_type}}_candidates:=array(
			SELECT DISTINCT
			b.{{oio_type}}_id 
			FROM  {{oio_type}}_relation a
			JOIN {{oio_type}}_registrering b on a.{{oio_type}}_registrering_id=b.id
			WHERE
			anyuuid = a.rel_maal_uuid
			AND
			(
				virkningSoeg IS NULL
				OR
				virkningSoeg && (a.virkning).TimePeriod
			)
			AND
			{% include 'as_search_mixin_filter_reg.jinja.sql' %}

			);

	{{oio_type}}_candidates_is_initialized:=true;
	END LOOP;
END IF;

--/**********************//

IF coalesce(array_length(anyurnArr ,1),0)>0 THEN

	FOREACH anyurn IN ARRAY anyurnArr
	LOOP
		{{oio_type}}_candidates:=array(
			SELECT DISTINCT
			b.{{oio_type}}_id 
			FROM  {{oio_type}}_relation a
			JOIN {{oio_type}}_registrering b on a.{{oio_type}}_registrering_id=b.id
			WHERE
			anyurn = a.rel_maal_urn
			AND
			(
				virkningSoeg IS NULL
				OR
				virkningSoeg && (a.virkning).TimePeriod
			)
			AND
			{% include 'as_search_mixin_filter_reg.jinja.sql' %}

			);

	{{oio_type}}_candidates_is_initialized:=true;
	END LOOP;
END IF;

--/**********************//

{% include  include_mixin  %} 



--RAISE DEBUG '{{oio_type}}_candidates_is_initialized step 5:%',{{oio_type}}_candidates_is_initialized;
--RAISE DEBUG '{{oio_type}}_candidates step 5:%',{{oio_type}}_candidates;

IF registreringObj IS NULL THEN
	--RAISE DEBUG 'registreringObj IS NULL';
ELSE
	IF NOT {{oio_type}}_candidates_is_initialized THEN 
		{{oio_type}}_candidates:=array(
		SELECT DISTINCT
			{{oio_type}}_id
		FROM
			{{oio_type}}_registrering b
		WHERE
		{% include 'as_search_mixin_filter_reg.jinja.sql' %}
		)
		;

		{{oio_type}}_candidates_is_initialized:=true;
	END IF;
END IF;


IF NOT {{oio_type}}_candidates_is_initialized THEN
	--No filters applied!
	{{oio_type}}_candidates:=array(
		SELECT DISTINCT id FROM {{oio_type}} a
	);
ELSE
	{{oio_type}}_candidates:=array(
		SELECT DISTINCT id FROM unnest({{oio_type}}_candidates) as a(id)
		);
END IF;

--RAISE DEBUG '{{oio_type}}_candidates_is_initialized step 6:%',{{oio_type}}_candidates_is_initialized;
--RAISE DEBUG '{{oio_type}}_candidates step 6:%',{{oio_type}}_candidates;


										 
/*** Filter out the objects that does not meets the stipulated access criteria  ***/
auth_filtered_uuids:=_as_filter_unauth_{{oio_type}}({{oio_type}}_candidates,auth_criteria_arr); 
/*********************/
IF firstResult > 0 or maxResults < 2147483647 THEN
   auth_filtered_uuids = _as_sorted_{{oio_type}}(auth_filtered_uuids, virkningSoeg, registreringObj, firstResult, maxResults);
END IF;
return auth_filtered_uuids;


END;
$$ LANGUAGE plpgsql STABLE; 



{% endblock %}
