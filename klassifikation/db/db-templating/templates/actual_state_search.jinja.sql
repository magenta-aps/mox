{% extends "basis.jinja.sql" %}
-- Copyright (C) 2015 Magenta ApS, http://magenta.dk.
-- Contact: info@magenta.dk.
--
-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at http://mozilla.org/MPL/2.0/.
{% block body %}

CREATE OR REPLACE FUNCTION actual_state_search_{{oio_type}}(
	firstResult int,--TOOD ??
	{{oio_type}}_uuid uuid,
	registreringObj {{oio_type|title}}RegistreringType,
	maxResults int = 2147483647
	)
  RETURNS uuid[] AS 
$$
DECLARE
	{{oio_type}}_candidates uuid[];
	{{oio_type}}_candidates_is_initialized boolean;
	to_be_applyed_filter_uuids uuid[];
	{%-for attribut , attribut_fields in attributter.iteritems() %} 
	attr{{attribut|title}}TypeObj {{oio_type|title}}Attr{{attribut|title}}Type;
	{%- endfor %}
	{% for tilstand, tilstand_values in tilstande.iteritems() %}
  	tils{{tilstand|title}}TypeObj {{oio_type|title}}Tils{{tilstand|title}}Type;
  	{%- endfor %}
	relationTypeObj {{oio_type|title}}RelationType;
BEGIN

--RAISE DEBUG 'step 0:registreringObj:%',registreringObj;

{{oio_type}}_candidates_is_initialized := false;


IF {{oio_type}}_uuid is not NULL THEN
	{{oio_type}}_candidates:= ARRAY[{{oio_type}}_uuid];
	{{oio_type}}_candidates_is_initialized:=true;
END IF;


--RAISE DEBUG '{{oio_type}}_candidates_is_initialized step 1:%',{{oio_type}}_candidates_is_initialized;
--RAISE DEBUG '{{oio_type}}_candidates step 1:%',{{oio_type}}_candidates;
--/****************************//
--filter on registration

IF registreringObj IS NULL OR (registreringObj).registrering IS NULL THEN
	--RAISE DEBUG 'actual_state_search_{{oio_type}}: skipping filtration on registrering';
ELSE
	IF
	(
		(registreringObj.registrering).timeperiod IS NOT NULL AND NOT isempty((registreringObj.registrering).timeperiod)  
		OR
		(registreringObj.registrering).livscykluskode IS NOT NULL
		OR
		(registreringObj.registrering).brugerref IS NOT NULL
		OR
		(registreringObj.registrering).note IS NOT NULL
	) THEN

		to_be_applyed_filter_uuids:=array(
		SELECT 
			{{oio_type}}_uuid
		FROM
			{{oio_type}}_registrering b
		WHERE
			(
				(
					(registreringObj.registrering).timeperiod IS NULL OR isempty((registreringObj.registrering).timeperiod)
				)
				OR
				(registreringObj.registrering).timeperiod && (b.registrering).timeperiod
			)
			AND
			(
				(registreringObj.registrering).livscykluskode IS NULL 
				OR
				(registreringObj.registrering).livscykluskode = (b.registrering).livscykluskode 		
			) 
			AND
			(
				(registreringObj.registrering).brugerref IS NULL
				OR
				(registreringObj.registrering).brugerref = (b.registrering).brugerref
			)
			AND
			(
				(registreringObj.registrering).note IS NULL
				OR
				(registreringObj.registrering).note = (b.registrering).note
			)
		);


		IF {{oio_type}}_candidates_is_initialized THEN
			{{oio_type}}_candidates:= array(SELECT id from unnest({{oio_type}}_candidates) as a(id) INTERSECT SELECT id from unnest(to_be_applyed_filter_uuids) as b(id) );
		ELSE
			{{oio_type}}_candidates:=to_be_applyed_filter_uuids;
			{{oio_type}}_candidates_is_initialized:=true;
		END IF;

	END IF;
END IF;

--RAISE NOTICE '{{oio_type}}_candidates_is_initialized step 2:%',{{oio_type}}_candidates_is_initialized;
--RAISE NOTICE '{{oio_type}}_candidates step 2:%',{{oio_type}}_candidates;

--/****************************//
--filter on attributes

{%-for attribut , attribut_fields in attributter.iteritems() %} 
--/**********************************************************//
--Filtration on attribute: {{attribut|title}}
--/**********************************************************//
IF registreringObj IS NULL OR (registreringObj).attr{{attribut|title}} IS NULL THEN
	--RAISE DEBUG 'actual_state_search_{{oio_type}}: skipping filtration on attr{{attribut|title}}';
ELSE
	IF (array_length({{oio_type}}_candidates,1)>0 OR NOT {{oio_type}}_candidates_is_initialized) THEN
		FOREACH attr{{attribut|title}}TypeObj IN ARRAY registreringObj.attr{{attribut|title}}
		LOOP
			to_be_applyed_filter_uuids:=array(
			SELECT
			b.{{oio_type}}_id 
			FROM  {{oio_type}}_attr_{{attribut}} a
			JOIN {{oio_type}}_registrering b on a.{{oio_type}}_registrering_id=b.id
			WHERE
				(
					attr{{attribut|title}}TypeObj.virkning IS NULL
					OR
					(
						(
							(
						 		(attr{{attribut|title}}TypeObj.virkning).TimePeriod IS NULL OR isempty((attr{{attribut|title}}TypeObj.virkning).TimePeriod)
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
								(attr{{attribut|title}}TypeObj.virkning).NoteTekst IS NULL OR (attr{{attribut|title}}TypeObj.virkning).NoteTekst=(a.virkning).NoteTekst
						)
					)
				)
				{%- for attribut_field in attribut_fields %}
				AND
				(
					attr{{attribut|title}}TypeObj.{{attribut_field}} IS NULL
					OR
					attr{{attribut|title}}TypeObj.{{attribut_field}} = a.{{attribut_field}}
				)
				{%- endfor %}
			);
			

			IF {{oio_type}}_candidates_is_initialized THEN
				{{oio_type}}_candidates:= array(SELECT id from unnest({{oio_type}}_candidates) as a(id) INTERSECT SELECT b.id from unnest(to_be_applyed_filter_uuids) as b(id) );
			ELSE
				{{oio_type}}_candidates:=to_be_applyed_filter_uuids;
				{{oio_type}}_candidates_is_initialized:=true;
			END IF;

		END LOOP;
	END IF;
END IF;

{%- endfor %}
--RAISE DEBUG '{{oio_type}}_candidates_is_initialized step 3:%',{{oio_type}}_candidates_is_initialized;
--RAISE DEBUG '{{oio_type}}_candidates step 3:%',{{oio_type}}_candidates;

--/****************************//


--filter on states -- publiceret
--RAISE DEBUG 'registrering,%',registreringObj;

{% for tilstand, tilstand_values in tilstande.iteritems() %}
--/**********************************************************//
--Filtration on state: {{tilstand|title}}
--/**********************************************************//
IF registreringObj IS NULL OR (registreringObj).tils{{tilstand|title}} IS NULL THEN
	--RAISE DEBUG 'actual_state_search_{{oio_type}}: skipping filtration on tils{{tilstand|title}}';
ELSE
	IF (array_length({{oio_type}}_candidates,1)>0 OR {{oio_type}}_candidates_is_initialized IS FALSE ) THEN --AND (IS NOT NULL THEN

		FOREACH tils{{tilstand|title}}TypeObj IN ARRAY registreringObj.tils{{tilstand|title}}
		LOOP
			to_be_applyed_filter_uuids:=array(
			SELECT
			b.{{oio_type}}_id 
			FROM  {{oio_type}}_tils_{{tilstand}} a
			JOIN {{oio_type}}_registrering b on a.{{oio_type}}_registrering_id=b.id
			WHERE
				(
					tils{{tilstand|title}}TypeObj.virkning IS NULL
					OR
					(
						(
							(
						 		(tils{{tilstand|title}}TypeObj.virkning).TimePeriod IS NULL OR isempty((tils{{tilstand|title}}TypeObj.virkning).TimePeriod)
							)
							OR
							(
								(tils{{tilstand|title}}TypeObj.virkning).TimePeriod && (a.virkning).TimePeriod
							)
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
								(tils{{tilstand|title}}TypeObj.virkning).NoteTekst IS NULL OR (tils{{tilstand|title}}TypeObj.virkning).NoteTekst=(a.virkning).NoteTekst
						)
					)
				)
				AND
				(
					tils{{tilstand|title}}TypeObj.{{tilstand}} IS NULL
					OR
					tils{{tilstand|title}}TypeObj.{{tilstand}} = a.{{tilstand}}
				)
	);
			

			IF {{oio_type}}_candidates_is_initialized THEN
				{{oio_type}}_candidates:= array(SELECT id from unnest({{oio_type}}_candidates) as a(id) INTERSECT SELECT b.id from unnest(to_be_applyed_filter_uuids) as b(id) );
			ELSE
				{{oio_type}}_candidates:=to_be_applyed_filter_uuids;
				{{oio_type}}_candidates_is_initialized:=true;
			END IF;

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
	--RAISE DEBUG 'actual_state_search_{{oio_type}}: skipping filtration on relationer';
ELSE
	IF (array_length({{oio_type}}_candidates,1)>0 OR NOT {{oio_type}}_candidates_is_initialized) AND registreringObj IS NOT NULL AND (registreringObj).relationer IS NOT NULL THEN
		FOREACH relationTypeObj IN ARRAY registreringObj.relationer
		LOOP
			to_be_applyed_filter_uuids:=array(
			SELECT
			b.{{oio_type}}_id 
			FROM  {{oio_type}}_relation a
			JOIN {{oio_type}}_registrering b on a.{{oio_type}}_registrering_id=b.id
			WHERE
				(
					relationTypeObj.virkning IS NULL
					OR
					(
						(
							(
						 		(relationTypeObj.virkning).TimePeriod IS NULL OR isempty((relationTypeObj.virkning).TimePeriod)
							)
							OR
							(
								(relationTypeObj.virkning).TimePeriod && (a.virkning).TimePeriod
							)
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
								(relationTypeObj.virkning).NoteTekst IS NULL OR (relationTypeObj.virkning).NoteTekst=(a.virkning).NoteTekst
						)
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
					relationTypeObj.relMaal IS NULL
					OR
					relationTypeObj.relMaal = a.rel_maal	
				)
	);
			

			IF {{oio_type}}_candidates_is_initialized THEN
				{{oio_type}}_candidates:= array(SELECT id from unnest({{oio_type}}_candidates) as a(id) INTERSECT SELECT b.id from unnest(to_be_applyed_filter_uuids) as b(id) );
			ELSE
				{{oio_type}}_candidates:=to_be_applyed_filter_uuids;
				{{oio_type}}_candidates_is_initialized:=true;
			END IF;

		END LOOP;
	END IF;
END IF;
--/**********************//

--RAISE DEBUG '{{oio_type}}_candidates_is_initialized step 5:%',{{oio_type}}_candidates_is_initialized;
--RAISE DEBUG '{{oio_type}}_candidates step 5:%',{{oio_type}}_candidates;


IF NOT {{oio_type}}_candidates_is_initialized THEN
	--No filters applied!
	{{oio_type}}_candidates:=array(
		SELECT id FROM {{oio_type}} a LIMIT maxResults
	);
ELSE
	{{oio_type}}_candidates:=array(
		SELECT id FROM unnest({{oio_type}}_candidates) as a(id) LIMIT maxResults
		);
END IF;

--RAISE DEBUG '{{oio_type}}_candidates_is_initialized step 6:%',{{oio_type}}_candidates_is_initialized;
--RAISE DEBUG '{{oio_type}}_candidates step 6:%',{{oio_type}}_candidates;


return {{oio_type}}_candidates;


END;
$$ LANGUAGE plpgsql STABLE; 



{% endblock %}