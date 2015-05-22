-- Copyright (C) 2015 Magenta ApS, http://magenta.dk.
-- Contact: info@magenta.dk.
--
-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at http://mozilla.org/MPL/2.0/.

/*
NOTICE: This file is auto-generated using the script: apply-template.py facet actual_state_search.jinja.sql
*/


CREATE OR REPLACE FUNCTION actual_state_search_facet(
	firstResult int,--TOOD ??
	facet_uuid uuid,
	registreringObj FacetRegistreringType,
	maxResults int = 2147483647
	)
  RETURNS uuid[] AS 
$$
DECLARE
	facet_candidates uuid[];
	facet_candidates_is_initialized boolean;
	to_be_applyed_filter_uuids uuid[]; 
	attrEgenskaberTypeObj FacetAttrEgenskaberType;
	
  	tilsPubliceretTypeObj FacetTilsPubliceretType;
	relationTypeObj FacetRelationType;
BEGIN

--RAISE DEBUG 'step 0:registreringObj:%',registreringObj;

facet_candidates_is_initialized := false;


IF facet_uuid is not NULL THEN
	facet_candidates:= ARRAY[facet_uuid];
	facet_candidates_is_initialized:=true;
END IF;


--RAISE DEBUG 'facet_candidates_is_initialized step 1:%',facet_candidates_is_initialized;
--RAISE DEBUG 'facet_candidates step 1:%',facet_candidates;
--/****************************//
--filter on registration

IF registreringObj IS NULL OR (registreringObj).registrering IS NULL THEN
	--RAISE DEBUG 'actual_state_search_facet: skipping filtration on registrering';
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
			facet_uuid
		FROM
			facet_registrering b
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


		IF facet_candidates_is_initialized THEN
			facet_candidates:= array(SELECT id from unnest(facet_candidates) as a(id) INTERSECT SELECT id from unnest(to_be_applyed_filter_uuids) as b(id) );
		ELSE
			facet_candidates:=to_be_applyed_filter_uuids;
			facet_candidates_is_initialized:=true;
		END IF;

	END IF;
END IF;

--RAISE NOTICE 'facet_candidates_is_initialized step 2:%',facet_candidates_is_initialized;
--RAISE NOTICE 'facet_candidates step 2:%',facet_candidates;

--/****************************//
--filter on attributes 
--/**********************************************************//
--Filtration on attribute: Egenskaber
--/**********************************************************//
IF registreringObj IS NULL OR (registreringObj).attrEgenskaber IS NULL THEN
	--RAISE DEBUG 'actual_state_search_facet: skipping filtration on attrEgenskaber';
ELSE
	IF (array_length(facet_candidates,1)>0 OR NOT facet_candidates_is_initialized) THEN
		FOREACH attrEgenskaberTypeObj IN ARRAY registreringObj.attrEgenskaber
		LOOP
			to_be_applyed_filter_uuids:=array(
			SELECT
			b.facet_id 
			FROM  facet_attr_egenskaber a
			JOIN facet_registrering b on a.facet_registrering_id=b.id
			WHERE
				(
					attrEgenskaberTypeObj.virkning IS NULL
					OR
					(
						(
							(
						 		(attrEgenskaberTypeObj.virkning).TimePeriod IS NULL OR isempty((attrEgenskaberTypeObj.virkning).TimePeriod)
							)
							OR
							(
								(attrEgenskaberTypeObj.virkning).TimePeriod && (a.virkning).TimePeriod
							)
						)
						AND
						(
								(attrEgenskaberTypeObj.virkning).AktoerRef IS NULL OR (attrEgenskaberTypeObj.virkning).AktoerRef=(a.virkning).AktoerRef
						)
						AND
						(
								(attrEgenskaberTypeObj.virkning).AktoerTypeKode IS NULL OR (attrEgenskaberTypeObj.virkning).AktoerTypeKode=(a.virkning).AktoerTypeKode
						)
						AND
						(
								(attrEgenskaberTypeObj.virkning).NoteTekst IS NULL OR (attrEgenskaberTypeObj.virkning).NoteTekst=(a.virkning).NoteTekst
						)
					)
				)
				AND
				(
					attrEgenskaberTypeObj.brugervendtnoegle IS NULL
					OR
					attrEgenskaberTypeObj.brugervendtnoegle = a.brugervendtnoegle
				)
				AND
				(
					attrEgenskaberTypeObj.beskrivelse IS NULL
					OR
					attrEgenskaberTypeObj.beskrivelse = a.beskrivelse
				)
				AND
				(
					attrEgenskaberTypeObj.opbygning IS NULL
					OR
					attrEgenskaberTypeObj.opbygning = a.opbygning
				)
				AND
				(
					attrEgenskaberTypeObj.ophavsret IS NULL
					OR
					attrEgenskaberTypeObj.ophavsret = a.ophavsret
				)
				AND
				(
					attrEgenskaberTypeObj.plan IS NULL
					OR
					attrEgenskaberTypeObj.plan = a.plan
				)
				AND
				(
					attrEgenskaberTypeObj.supplement IS NULL
					OR
					attrEgenskaberTypeObj.supplement = a.supplement
				)
				AND
				(
					attrEgenskaberTypeObj.retskilde IS NULL
					OR
					attrEgenskaberTypeObj.retskilde = a.retskilde
				)
			);
			

			IF facet_candidates_is_initialized THEN
				facet_candidates:= array(SELECT id from unnest(facet_candidates) as a(id) INTERSECT SELECT b.id from unnest(to_be_applyed_filter_uuids) as b(id) );
			ELSE
				facet_candidates:=to_be_applyed_filter_uuids;
				facet_candidates_is_initialized:=true;
			END IF;

		END LOOP;
	END IF;
END IF;
--RAISE DEBUG 'facet_candidates_is_initialized step 3:%',facet_candidates_is_initialized;
--RAISE DEBUG 'facet_candidates step 3:%',facet_candidates;

--/****************************//


--filter on states -- publiceret
--RAISE DEBUG 'registrering,%',registreringObj;


--/**********************************************************//
--Filtration on state: Publiceret
--/**********************************************************//
IF registreringObj IS NULL OR (registreringObj).tilsPubliceret IS NULL THEN
	--RAISE DEBUG 'actual_state_search_facet: skipping filtration on tilsPubliceret';
ELSE
	IF (array_length(facet_candidates,1)>0 OR facet_candidates_is_initialized IS FALSE ) THEN --AND (IS NOT NULL THEN

		FOREACH tilsPubliceretTypeObj IN ARRAY registreringObj.tilsPubliceret
		LOOP
			to_be_applyed_filter_uuids:=array(
			SELECT
			b.facet_id 
			FROM  facet_tils_publiceret a
			JOIN facet_registrering b on a.facet_registrering_id=b.id
			WHERE
				(
					tilsPubliceretTypeObj.virkning IS NULL
					OR
					(
						(
							(
						 		(tilsPubliceretTypeObj.virkning).TimePeriod IS NULL OR isempty((tilsPubliceretTypeObj.virkning).TimePeriod)
							)
							OR
							(
								(tilsPubliceretTypeObj.virkning).TimePeriod && (a.virkning).TimePeriod
							)
						)
						AND
						(
								(tilsPubliceretTypeObj.virkning).AktoerRef IS NULL OR (tilsPubliceretTypeObj.virkning).AktoerRef=(a.virkning).AktoerRef
						)
						AND
						(
								(tilsPubliceretTypeObj.virkning).AktoerTypeKode IS NULL OR (tilsPubliceretTypeObj.virkning).AktoerTypeKode=(a.virkning).AktoerTypeKode
						)
						AND
						(
								(tilsPubliceretTypeObj.virkning).NoteTekst IS NULL OR (tilsPubliceretTypeObj.virkning).NoteTekst=(a.virkning).NoteTekst
						)
					)
				)
				AND
				(
					tilsPubliceretTypeObj.publiceret IS NULL
					OR
					tilsPubliceretTypeObj.publiceret = a.publiceret
				)
	);
			

			IF facet_candidates_is_initialized THEN
				facet_candidates:= array(SELECT id from unnest(facet_candidates) as a(id) INTERSECT SELECT b.id from unnest(to_be_applyed_filter_uuids) as b(id) );
			ELSE
				facet_candidates:=to_be_applyed_filter_uuids;
				facet_candidates_is_initialized:=true;
			END IF;

		END LOOP;
	END IF;
END IF;

/*
--relationer FacetRelationType[]
*/


--RAISE DEBUG 'facet_candidates_is_initialized step 4:%',facet_candidates_is_initialized;
--RAISE DEBUG 'facet_candidates step 4:%',facet_candidates;

--/**********************************************************//
--Filtration on relations
--/**********************************************************//


IF registreringObj IS NULL OR (registreringObj).relationer IS NULL THEN
	--RAISE DEBUG 'actual_state_search_facet: skipping filtration on relationer';
ELSE
	IF (array_length(facet_candidates,1)>0 OR NOT facet_candidates_is_initialized) AND registreringObj IS NOT NULL AND (registreringObj).relationer IS NOT NULL THEN
		FOREACH relationTypeObj IN ARRAY registreringObj.relationer
		LOOP
			to_be_applyed_filter_uuids:=array(
			SELECT
			b.facet_id 
			FROM  facet_relation a
			JOIN facet_registrering b on a.facet_registrering_id=b.id
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
			

			IF facet_candidates_is_initialized THEN
				facet_candidates:= array(SELECT id from unnest(facet_candidates) as a(id) INTERSECT SELECT b.id from unnest(to_be_applyed_filter_uuids) as b(id) );
			ELSE
				facet_candidates:=to_be_applyed_filter_uuids;
				facet_candidates_is_initialized:=true;
			END IF;

		END LOOP;
	END IF;
END IF;
--/**********************//

--RAISE DEBUG 'facet_candidates_is_initialized step 5:%',facet_candidates_is_initialized;
--RAISE DEBUG 'facet_candidates step 5:%',facet_candidates;


IF NOT facet_candidates_is_initialized THEN
	--No filters applied!
	facet_candidates:=array(
		SELECT id FROM facet a LIMIT maxResults
	);
ELSE
	facet_candidates:=array(
		SELECT id FROM unnest(facet_candidates) as a(id) LIMIT maxResults
		);
END IF;

--RAISE DEBUG 'facet_candidates_is_initialized step 6:%',facet_candidates_is_initialized;
--RAISE DEBUG 'facet_candidates step 6:%',facet_candidates;


return facet_candidates;


END;
$$ LANGUAGE plpgsql STABLE; 





