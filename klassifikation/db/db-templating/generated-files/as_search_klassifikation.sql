-- Copyright (C) 2015 Magenta ApS, http://magenta.dk.
-- Contact: info@magenta.dk.
--
-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at http://mozilla.org/MPL/2.0/.

/*
NOTICE: This file is auto-generated using the script: apply-template.py klassifikation as_search.jinja.sql
*/


CREATE OR REPLACE FUNCTION as_search_klassifikation(
	firstResult int,--TOOD ??
	klassifikation_uuid uuid,
	registreringObj KlassifikationRegistreringType,
	maxResults int = 2147483647
	)
  RETURNS uuid[] AS 
$$
DECLARE
	klassifikation_candidates uuid[];
	klassifikation_candidates_is_initialized boolean;
	to_be_applyed_filter_uuids uuid[]; 
	attrEgenskaberTypeObj KlassifikationEgenskaberAttrType;
	
  	tilsPubliceretTypeObj KlassifikationPubliceretTilsType;
	relationTypeObj KlassifikationRelationType;
BEGIN

--RAISE DEBUG 'step 0:registreringObj:%',registreringObj;

klassifikation_candidates_is_initialized := false;


IF klassifikation_uuid is not NULL THEN
	klassifikation_candidates:= ARRAY[klassifikation_uuid];
	klassifikation_candidates_is_initialized:=true;
END IF;


--RAISE DEBUG 'klassifikation_candidates_is_initialized step 1:%',klassifikation_candidates_is_initialized;
--RAISE DEBUG 'klassifikation_candidates step 1:%',klassifikation_candidates;
--/****************************//
--filter on registration

IF registreringObj IS NULL OR (registreringObj).registrering IS NULL THEN
	--RAISE DEBUG 'as_search_klassifikation: skipping filtration on registrering';
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
			klassifikation_uuid
		FROM
			klassifikation_registrering b
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


		IF klassifikation_candidates_is_initialized THEN
			klassifikation_candidates:= array(SELECT id from unnest(klassifikation_candidates) as a(id) INTERSECT SELECT id from unnest(to_be_applyed_filter_uuids) as b(id) );
		ELSE
			klassifikation_candidates:=to_be_applyed_filter_uuids;
			klassifikation_candidates_is_initialized:=true;
		END IF;

	END IF;
END IF;

--RAISE NOTICE 'klassifikation_candidates_is_initialized step 2:%',klassifikation_candidates_is_initialized;
--RAISE NOTICE 'klassifikation_candidates step 2:%',klassifikation_candidates;

--/****************************//
--filter on attributes 
--/**********************************************************//
--Filtration on attribute: Egenskaber
--/**********************************************************//
IF registreringObj IS NULL OR (registreringObj).attrEgenskaber IS NULL THEN
	--RAISE DEBUG 'as_search_klassifikation: skipping filtration on attrEgenskaber';
ELSE
	IF (array_length(klassifikation_candidates,1)>0 OR NOT klassifikation_candidates_is_initialized) THEN
		FOREACH attrEgenskaberTypeObj IN ARRAY registreringObj.attrEgenskaber
		LOOP
			to_be_applyed_filter_uuids:=array(
			SELECT
			b.klassifikation_id 
			FROM  klassifikation_attr_egenskaber a
			JOIN klassifikation_registrering b on a.klassifikation_registrering_id=b.id
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
					attrEgenskaberTypeObj.kaldenavn IS NULL
					OR
					attrEgenskaberTypeObj.kaldenavn = a.kaldenavn
				)
				AND
				(
					attrEgenskaberTypeObj.ophavsret IS NULL
					OR
					attrEgenskaberTypeObj.ophavsret = a.ophavsret
				)
			);
			

			IF klassifikation_candidates_is_initialized THEN
				klassifikation_candidates:= array(SELECT id from unnest(klassifikation_candidates) as a(id) INTERSECT SELECT b.id from unnest(to_be_applyed_filter_uuids) as b(id) );
			ELSE
				klassifikation_candidates:=to_be_applyed_filter_uuids;
				klassifikation_candidates_is_initialized:=true;
			END IF;

		END LOOP;
	END IF;
END IF;
--RAISE DEBUG 'klassifikation_candidates_is_initialized step 3:%',klassifikation_candidates_is_initialized;
--RAISE DEBUG 'klassifikation_candidates step 3:%',klassifikation_candidates;

--/****************************//


--filter on states -- publiceret
--RAISE DEBUG 'registrering,%',registreringObj;


--/**********************************************************//
--Filtration on state: Publiceret
--/**********************************************************//
IF registreringObj IS NULL OR (registreringObj).tilsPubliceret IS NULL THEN
	--RAISE DEBUG 'as_search_klassifikation: skipping filtration on tilsPubliceret';
ELSE
	IF (array_length(klassifikation_candidates,1)>0 OR klassifikation_candidates_is_initialized IS FALSE ) THEN 

		FOREACH tilsPubliceretTypeObj IN ARRAY registreringObj.tilsPubliceret
		LOOP
			to_be_applyed_filter_uuids:=array(
			SELECT
			b.klassifikation_id 
			FROM  klassifikation_tils_publiceret a
			JOIN klassifikation_registrering b on a.klassifikation_registrering_id=b.id
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
			

			IF klassifikation_candidates_is_initialized THEN
				klassifikation_candidates:= array(SELECT id from unnest(klassifikation_candidates) as a(id) INTERSECT SELECT b.id from unnest(to_be_applyed_filter_uuids) as b(id) );
			ELSE
				klassifikation_candidates:=to_be_applyed_filter_uuids;
				klassifikation_candidates_is_initialized:=true;
			END IF;

		END LOOP;
	END IF;
END IF;

/*
--relationer KlassifikationRelationType[]
*/


--RAISE DEBUG 'klassifikation_candidates_is_initialized step 4:%',klassifikation_candidates_is_initialized;
--RAISE DEBUG 'klassifikation_candidates step 4:%',klassifikation_candidates;

--/**********************************************************//
--Filtration on relations
--/**********************************************************//


IF registreringObj IS NULL OR (registreringObj).relationer IS NULL THEN
	--RAISE DEBUG 'as_search_klassifikation: skipping filtration on relationer';
ELSE
	IF (array_length(klassifikation_candidates,1)>0 OR NOT klassifikation_candidates_is_initialized) AND (registreringObj).relationer IS NOT NULL THEN
		FOREACH relationTypeObj IN ARRAY registreringObj.relationer
		LOOP
			to_be_applyed_filter_uuids:=array(
			SELECT
			b.klassifikation_id 
			FROM  klassifikation_relation a
			JOIN klassifikation_registrering b on a.klassifikation_registrering_id=b.id
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
			

			IF klassifikation_candidates_is_initialized THEN
				klassifikation_candidates:= array(SELECT id from unnest(klassifikation_candidates) as a(id) INTERSECT SELECT b.id from unnest(to_be_applyed_filter_uuids) as b(id) );
			ELSE
				klassifikation_candidates:=to_be_applyed_filter_uuids;
				klassifikation_candidates_is_initialized:=true;
			END IF;

		END LOOP;
	END IF;
END IF;
--/**********************//

--RAISE DEBUG 'klassifikation_candidates_is_initialized step 5:%',klassifikation_candidates_is_initialized;
--RAISE DEBUG 'klassifikation_candidates step 5:%',klassifikation_candidates;


IF NOT klassifikation_candidates_is_initialized THEN
	--No filters applied!
	klassifikation_candidates:=array(
		SELECT id FROM klassifikation a LIMIT maxResults
	);
ELSE
	klassifikation_candidates:=array(
		SELECT id FROM unnest(klassifikation_candidates) as a(id) LIMIT maxResults
		);
END IF;

--RAISE DEBUG 'klassifikation_candidates_is_initialized step 6:%',klassifikation_candidates_is_initialized;
--RAISE DEBUG 'klassifikation_candidates step 6:%',klassifikation_candidates;


return klassifikation_candidates;


END;
$$ LANGUAGE plpgsql STABLE; 





