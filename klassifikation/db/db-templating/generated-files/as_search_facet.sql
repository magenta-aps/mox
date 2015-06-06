-- Copyright (C) 2015 Magenta ApS, http://magenta.dk.
-- Contact: info@magenta.dk.
--
-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at http://mozilla.org/MPL/2.0/.

/*
NOTICE: This file is auto-generated using the script: apply-template.py facet as_search.jinja.sql
*/


CREATE OR REPLACE FUNCTION as_search_facet(
	firstResult int,--TOOD ??
	facet_uuid uuid,
	registreringObj FacetRegistreringType,
	virkningSoeg TSTZRANGE,
	maxResults int = 2147483647
	)
  RETURNS uuid[] AS 
$$
DECLARE
	facet_candidates uuid[];
	facet_candidates_is_initialized boolean;
	--to_be_applyed_filter_uuids uuid[]; 
	attrEgenskaberTypeObj FacetEgenskaberAttrType;
	
  	tilsPubliceretTypeObj FacetPubliceretTilsType;
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


--RAISE NOTICE 'facet_candidates_is_initialized step 2:%',facet_candidates_is_initialized;
--RAISE NOTICE 'facet_candidates step 2:%',facet_candidates;

--/****************************//
--filter on attributes 
--/**********************************************************//
--Filtration on attribute: Egenskaber
--/**********************************************************//
IF registreringObj IS NULL OR (registreringObj).attrEgenskaber IS NULL THEN
	--RAISE DEBUG 'as_search_facet: skipping filtration on attrEgenskaber';
ELSE
	IF (coalesce(array_length(facet_candidates,1),0)>0 OR NOT facet_candidates_is_initialized) THEN
		FOREACH attrEgenskaberTypeObj IN ARRAY registreringObj.attrEgenskaber
		LOOP
			facet_candidates:=array(
			SELECT DISTINCT
			b.facet_id 
			FROM  facet_attr_egenskaber a
			JOIN facet_registrering b on a.facet_registrering_id=b.id
			WHERE
				(
					(
						attrEgenskaberTypeObj.virkning IS NULL 
						OR
						(
							(
								(
							 		(attrEgenskaberTypeObj.virkning).TimePeriod IS NULL
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
				)
				AND
				(
					(NOT (attrEgenskaberTypeObj.virkning IS NULL OR (attrEgenskaberTypeObj.virkning).TimePeriod IS NULL)) --we have already filtered on virkning above
					OR
					(
						virkningSoeg IS NULL
						OR
						virkningSoeg && (a.virkning).TimePeriod
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
				AND
							(
				(registreringObj.registrering) IS NULL 
				OR
				(
					(
						(registreringObj.registrering).timeperiod IS NULL 
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
			)
		)
		AND
		( (NOT facet_candidates_is_initialized) OR b.facet_id = ANY (facet_candidates) )

			);
			

			facet_candidates_is_initialized:=true;
			

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
	--RAISE DEBUG 'as_search_facet: skipping filtration on tilsPubliceret';
ELSE
	IF (coalesce(array_length(facet_candidates,1),0)>0 OR facet_candidates_is_initialized IS FALSE ) THEN 

		FOREACH tilsPubliceretTypeObj IN ARRAY registreringObj.tilsPubliceret
		LOOP
			facet_candidates:=array(
			SELECT DISTINCT
			b.facet_id 
			FROM  facet_tils_publiceret a
			JOIN facet_registrering b on a.facet_registrering_id=b.id
			WHERE
				(
					tilsPubliceretTypeObj.virkning IS NULL
					OR
					(
						(
					 		(tilsPubliceretTypeObj.virkning).TimePeriod IS NULL 
							OR
							(tilsPubliceretTypeObj.virkning).TimePeriod && (a.virkning).TimePeriod
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
					(NOT ((tilsPubliceretTypeObj.virkning) IS NULL OR (tilsPubliceretTypeObj.virkning).TimePeriod IS NULL)) --we have already filtered on virkning above
					OR
					(
						virkningSoeg IS NULL
						OR
						virkningSoeg && (a.virkning).TimePeriod
					)
				)
				AND
				(
					tilsPubliceretTypeObj.publiceret IS NULL
					OR
					tilsPubliceretTypeObj.publiceret = a.publiceret
				)
				AND
							(
				(registreringObj.registrering) IS NULL 
				OR
				(
					(
						(registreringObj.registrering).timeperiod IS NULL 
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
			)
		)
		AND
		( (NOT facet_candidates_is_initialized) OR b.facet_id = ANY (facet_candidates) )

	);
			

			facet_candidates_is_initialized:=true;
			

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
	--RAISE DEBUG 'as_search_facet: skipping filtration on relationer';
ELSE
	IF (coalesce(array_length(facet_candidates,1),0)>0 OR NOT facet_candidates_is_initialized) AND (registreringObj).relationer IS NOT NULL THEN
		FOREACH relationTypeObj IN ARRAY registreringObj.relationer
		LOOP
			facet_candidates:=array(
			SELECT DISTINCT
			b.facet_id 
			FROM  facet_relation a
			JOIN facet_registrering b on a.facet_registrering_id=b.id
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
								(relationTypeObj.virkning).NoteTekst IS NULL OR (relationTypeObj.virkning).NoteTekst=(a.virkning).NoteTekst
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
					relationTypeObj.relMaal IS NULL
					OR
					relationTypeObj.relMaal = a.rel_maal	
				)
				AND
							(
				(registreringObj.registrering) IS NULL 
				OR
				(
					(
						(registreringObj.registrering).timeperiod IS NULL 
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
			)
		)
		AND
		( (NOT facet_candidates_is_initialized) OR b.facet_id = ANY (facet_candidates) )

	);
			
			facet_candidates_is_initialized:=true;
			

		END LOOP;
	END IF;
END IF;
--/**********************//

--RAISE DEBUG 'facet_candidates_is_initialized step 5:%',facet_candidates_is_initialized;
--RAISE DEBUG 'facet_candidates step 5:%',facet_candidates;

IF registreringObj IS NULL THEN
	--RAISE DEBUG 'registreringObj IS NULL';
ELSE
	IF NOT facet_candidates_is_initialized THEN 
		facet_candidates:=array(
		SELECT DISTINCT
			facet_id
		FROM
			facet_registrering b
		WHERE
					(
				(registreringObj.registrering) IS NULL 
				OR
				(
					(
						(registreringObj.registrering).timeperiod IS NULL 
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
			)
		)
		AND
		( (NOT facet_candidates_is_initialized) OR b.facet_id = ANY (facet_candidates) )

		)
		;

		facet_candidates_is_initialized:=true;
	END IF;
END IF;


IF NOT facet_candidates_is_initialized THEN
	--No filters applied!
	facet_candidates:=array(
		SELECT DISTINCT id FROM facet a LIMIT maxResults
	);
ELSE
	facet_candidates:=array(
		SELECT DISTINCT id FROM unnest(facet_candidates) as a(id) LIMIT maxResults
		);
END IF;

--RAISE DEBUG 'facet_candidates_is_initialized step 6:%',facet_candidates_is_initialized;
--RAISE DEBUG 'facet_candidates step 6:%',facet_candidates;


return facet_candidates;


END;
$$ LANGUAGE plpgsql STABLE; 





