-- Copyright (C) 2015 Magenta ApS, http://magenta.dk.
-- Contact: info@magenta.dk.
--
-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at http://mozilla.org/MPL/2.0/.

/*
NOTICE: This file is auto-generated using the script: oio_rest/apply-templates.py
*/


CREATE OR REPLACE FUNCTION as_search_klassifikation(
	firstResult int,--TOOD ??
	klassifikation_uuid uuid,
	registreringObj KlassifikationRegistreringType,
	virkningSoeg TSTZRANGE, -- = TSTZRANGE(current_timestamp,current_timestamp,'[]'),
	maxResults int = 2147483647,
	anyAttrValueArr text[] = '{}'::text[],
	anyuuidArr	uuid[] = '{}'::uuid[],
	anyurnArr text[] = '{}'::text[],
	auth_criteria_arr KlassifikationRegistreringType[]=null
	)
  RETURNS uuid[] AS 
$$
DECLARE
	klassifikation_candidates uuid[];
	klassifikation_candidates_is_initialized boolean;
	--to_be_applyed_filter_uuids uuid[]; 
	attrEgenskaberTypeObj KlassifikationEgenskaberAttrType;
	
  	tilsPubliceretTypeObj KlassifikationPubliceretTilsType;
	relationTypeObj KlassifikationRelationType;
	anyAttrValue text;
	anyuuid uuid;
	anyurn text;
    
	auth_filtered_uuids uuid[];
    
BEGIN

--RAISE DEBUG 'step 0:registreringObj:%',registreringObj;

klassifikation_candidates_is_initialized := false;

IF klassifikation_uuid is not NULL THEN
	klassifikation_candidates:= ARRAY[klassifikation_uuid];
	klassifikation_candidates_is_initialized:=true;
	IF registreringObj IS NULL THEN
	--RAISE DEBUG 'no registreringObj'
	ELSE	
		klassifikation_candidates:=array(
				SELECT DISTINCT
				b.klassifikation_id 
				FROM
				klassifikation a
				JOIN klassifikation_registrering b on b.klassifikation_id=a.id
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
						(b.registrering).note ILIKE (registreringObj.registrering).note
					)
			)
		)
		AND
		(
			(
				((b.registrering).livscykluskode <> 'Slettet'::Livscykluskode )
				AND
					(
						(registreringObj.registrering) IS NULL 
						OR
						(registreringObj.registrering).livscykluskode IS NULL 
					)
			)
			OR
			(
				(NOT ((registreringObj.registrering) IS NULL))
				AND
				(registreringObj.registrering).livscykluskode IS NOT NULL 
			)
		)
		AND
		(
			(
			  (
			  	(registreringObj.registrering) IS NULL
			  	OR
			  	(registreringObj.registrering).timeperiod IS NULL
			  )
			  AND
			  upper((b.registrering).timeperiod)='infinity'::TIMESTAMPTZ
			)  	
		OR
			(
				(NOT ((registreringObj.registrering) IS NULL))
				AND
				((registreringObj.registrering).timeperiod IS NOT NULL)
			)
		)
		AND
		( (NOT klassifikation_candidates_is_initialized) OR b.klassifikation_id = ANY (klassifikation_candidates) )

		);		
	END IF;
	
END IF;


--RAISE DEBUG 'klassifikation_candidates_is_initialized step 1:%',klassifikation_candidates_is_initialized;
--RAISE DEBUG 'klassifikation_candidates step 1:%',klassifikation_candidates;
--/****************************//


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

	IF (coalesce(array_length(klassifikation_candidates,1),0)>0 OR NOT klassifikation_candidates_is_initialized) THEN
        
		FOREACH attrEgenskaberTypeObj IN ARRAY registreringObj.attrEgenskaber
        
		LOOP
			klassifikation_candidates:=array(
			SELECT DISTINCT
			b.klassifikation_id 
			FROM  klassifikation_attr_egenskaber a
			JOIN klassifikation_registrering b on a.klassifikation_registrering_id=b.id
            
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
									(attrEgenskaberTypeObj.virkning).NoteTekst IS NULL OR  (a.virkning).NoteTekst ILIKE (attrEgenskaberTypeObj.virkning).NoteTekst  
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
					a.brugervendtnoegle ILIKE attrEgenskaberTypeObj.brugervendtnoegle --case insensitive 
				)
				AND
				(
					attrEgenskaberTypeObj.beskrivelse IS NULL
					OR 
					a.beskrivelse ILIKE attrEgenskaberTypeObj.beskrivelse --case insensitive 
				)
				AND
				(
					attrEgenskaberTypeObj.kaldenavn IS NULL
					OR 
					a.kaldenavn ILIKE attrEgenskaberTypeObj.kaldenavn --case insensitive 
				)
				AND
				(
					attrEgenskaberTypeObj.ophavsret IS NULL
					OR 
					a.ophavsret ILIKE attrEgenskaberTypeObj.ophavsret --case insensitive 
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
						(b.registrering).note ILIKE (registreringObj.registrering).note
					)
			)
		)
		AND
		(
			(
				((b.registrering).livscykluskode <> 'Slettet'::Livscykluskode )
				AND
					(
						(registreringObj.registrering) IS NULL 
						OR
						(registreringObj.registrering).livscykluskode IS NULL 
					)
			)
			OR
			(
				(NOT ((registreringObj.registrering) IS NULL))
				AND
				(registreringObj.registrering).livscykluskode IS NOT NULL 
			)
		)
		AND
		(
			(
			  (
			  	(registreringObj.registrering) IS NULL
			  	OR
			  	(registreringObj.registrering).timeperiod IS NULL
			  )
			  AND
			  upper((b.registrering).timeperiod)='infinity'::TIMESTAMPTZ
			)  	
		OR
			(
				(NOT ((registreringObj.registrering) IS NULL))
				AND
				((registreringObj.registrering).timeperiod IS NOT NULL)
			)
		)
		AND
		( (NOT klassifikation_candidates_is_initialized) OR b.klassifikation_id = ANY (klassifikation_candidates) )

			);
			

			klassifikation_candidates_is_initialized:=true;
			

		END LOOP;
	END IF;
END IF;
--RAISE DEBUG 'klassifikation_candidates_is_initialized step 3:%',klassifikation_candidates_is_initialized;
--RAISE DEBUG 'klassifikation_candidates step 3:%',klassifikation_candidates;

--/**********************************************************//
--Filtration on anyAttrValueArr
--/**********************************************************//
IF coalesce(array_length(anyAttrValueArr ,1),0)>0 THEN

	FOREACH anyAttrValue IN ARRAY anyAttrValueArr
	LOOP
		klassifikation_candidates:=array( 

			SELECT DISTINCT
			b.klassifikation_id
            
			FROM  klassifikation_attr_egenskaber a
			JOIN klassifikation_registrering b on a.klassifikation_registrering_id=b.id
            
			WHERE
			(
						a.brugervendtnoegle ILIKE anyAttrValue OR
						a.beskrivelse ILIKE anyAttrValue OR
						a.kaldenavn ILIKE anyAttrValue OR
						a.ophavsret ILIKE anyAttrValue
                
			)
			AND
			(
				virkningSoeg IS NULL
				OR
				virkningSoeg && (a.virkning).TimePeriod
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
						(b.registrering).note ILIKE (registreringObj.registrering).note
					)
			)
		)
		AND
		(
			(
				((b.registrering).livscykluskode <> 'Slettet'::Livscykluskode )
				AND
					(
						(registreringObj.registrering) IS NULL 
						OR
						(registreringObj.registrering).livscykluskode IS NULL 
					)
			)
			OR
			(
				(NOT ((registreringObj.registrering) IS NULL))
				AND
				(registreringObj.registrering).livscykluskode IS NOT NULL 
			)
		)
		AND
		(
			(
			  (
			  	(registreringObj.registrering) IS NULL
			  	OR
			  	(registreringObj.registrering).timeperiod IS NULL
			  )
			  AND
			  upper((b.registrering).timeperiod)='infinity'::TIMESTAMPTZ
			)  	
		OR
			(
				(NOT ((registreringObj.registrering) IS NULL))
				AND
				((registreringObj.registrering).timeperiod IS NOT NULL)
			)
		)
		AND
		( (NOT klassifikation_candidates_is_initialized) OR b.klassifikation_id = ANY (klassifikation_candidates) )


		);

	klassifikation_candidates_is_initialized:=true;

	END LOOP;

END IF;



--RAISE DEBUG 'registrering,%',registreringObj;


--/**********************************************************//
--Filtration on state: Publiceret
--/**********************************************************//
IF registreringObj IS NULL OR (registreringObj).tilsPubliceret IS NULL THEN
	--RAISE DEBUG 'as_search_klassifikation: skipping filtration on tilsPubliceret';
ELSE
	IF (coalesce(array_length(klassifikation_candidates,1),0)>0 OR klassifikation_candidates_is_initialized IS FALSE ) THEN 

		FOREACH tilsPubliceretTypeObj IN ARRAY registreringObj.tilsPubliceret
		LOOP
			klassifikation_candidates:=array(
			SELECT DISTINCT
			b.klassifikation_id 
			FROM  klassifikation_tils_publiceret a
			JOIN klassifikation_registrering b on a.klassifikation_registrering_id=b.id
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
								(tilsPubliceretTypeObj.virkning).NoteTekst IS NULL OR (a.virkning).NoteTekst ILIKE (tilsPubliceretTypeObj.virkning).NoteTekst
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
						(b.registrering).note ILIKE (registreringObj.registrering).note
					)
			)
		)
		AND
		(
			(
				((b.registrering).livscykluskode <> 'Slettet'::Livscykluskode )
				AND
					(
						(registreringObj.registrering) IS NULL 
						OR
						(registreringObj.registrering).livscykluskode IS NULL 
					)
			)
			OR
			(
				(NOT ((registreringObj.registrering) IS NULL))
				AND
				(registreringObj.registrering).livscykluskode IS NOT NULL 
			)
		)
		AND
		(
			(
			  (
			  	(registreringObj.registrering) IS NULL
			  	OR
			  	(registreringObj.registrering).timeperiod IS NULL
			  )
			  AND
			  upper((b.registrering).timeperiod)='infinity'::TIMESTAMPTZ
			)  	
		OR
			(
				(NOT ((registreringObj.registrering) IS NULL))
				AND
				((registreringObj.registrering).timeperiod IS NOT NULL)
			)
		)
		AND
		( (NOT klassifikation_candidates_is_initialized) OR b.klassifikation_id = ANY (klassifikation_candidates) )

	);
			

			klassifikation_candidates_is_initialized:=true;
			

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
	IF (coalesce(array_length(klassifikation_candidates,1),0)>0 OR NOT klassifikation_candidates_is_initialized) AND (registreringObj).relationer IS NOT NULL THEN
		FOREACH relationTypeObj IN ARRAY registreringObj.relationer
		LOOP
			klassifikation_candidates:=array(
			SELECT DISTINCT
			b.klassifikation_id 
			FROM  klassifikation_relation a
			JOIN klassifikation_registrering b on a.klassifikation_registrering_id=b.id
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
						(b.registrering).note ILIKE (registreringObj.registrering).note
					)
			)
		)
		AND
		(
			(
				((b.registrering).livscykluskode <> 'Slettet'::Livscykluskode )
				AND
					(
						(registreringObj.registrering) IS NULL 
						OR
						(registreringObj.registrering).livscykluskode IS NULL 
					)
			)
			OR
			(
				(NOT ((registreringObj.registrering) IS NULL))
				AND
				(registreringObj.registrering).livscykluskode IS NOT NULL 
			)
		)
		AND
		(
			(
			  (
			  	(registreringObj.registrering) IS NULL
			  	OR
			  	(registreringObj.registrering).timeperiod IS NULL
			  )
			  AND
			  upper((b.registrering).timeperiod)='infinity'::TIMESTAMPTZ
			)  	
		OR
			(
				(NOT ((registreringObj.registrering) IS NULL))
				AND
				((registreringObj.registrering).timeperiod IS NOT NULL)
			)
		)
		AND
		( (NOT klassifikation_candidates_is_initialized) OR b.klassifikation_id = ANY (klassifikation_candidates) )

	);
			
			klassifikation_candidates_is_initialized:=true;
			

		END LOOP;
	END IF;
END IF;
--/**********************//

IF coalesce(array_length(anyuuidArr ,1),0)>0 THEN

	FOREACH anyuuid IN ARRAY anyuuidArr
	LOOP
		klassifikation_candidates:=array(
			SELECT DISTINCT
			b.klassifikation_id 
            
			FROM  klassifikation_relation a
			JOIN klassifikation_registrering b on a.klassifikation_registrering_id=b.id
			WHERE
            
			anyuuid = a.rel_maal_uuid
            
			AND
			(
				virkningSoeg IS NULL
				OR
				virkningSoeg && (a.virkning).TimePeriod
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
						(b.registrering).note ILIKE (registreringObj.registrering).note
					)
			)
		)
		AND
		(
			(
				((b.registrering).livscykluskode <> 'Slettet'::Livscykluskode )
				AND
					(
						(registreringObj.registrering) IS NULL 
						OR
						(registreringObj.registrering).livscykluskode IS NULL 
					)
			)
			OR
			(
				(NOT ((registreringObj.registrering) IS NULL))
				AND
				(registreringObj.registrering).livscykluskode IS NOT NULL 
			)
		)
		AND
		(
			(
			  (
			  	(registreringObj.registrering) IS NULL
			  	OR
			  	(registreringObj.registrering).timeperiod IS NULL
			  )
			  AND
			  upper((b.registrering).timeperiod)='infinity'::TIMESTAMPTZ
			)  	
		OR
			(
				(NOT ((registreringObj.registrering) IS NULL))
				AND
				((registreringObj.registrering).timeperiod IS NOT NULL)
			)
		)
		AND
		( (NOT klassifikation_candidates_is_initialized) OR b.klassifikation_id = ANY (klassifikation_candidates) )


			);

	klassifikation_candidates_is_initialized:=true;
	END LOOP;
END IF;

--/**********************//

IF coalesce(array_length(anyurnArr ,1),0)>0 THEN

	FOREACH anyurn IN ARRAY anyurnArr
	LOOP
		klassifikation_candidates:=array(
			SELECT DISTINCT
			b.klassifikation_id 
            
			FROM  klassifikation_relation a
			JOIN klassifikation_registrering b on a.klassifikation_registrering_id=b.id
			WHERE
            
			anyurn = a.rel_maal_urn
            
			AND
			(
				virkningSoeg IS NULL
				OR
				virkningSoeg && (a.virkning).TimePeriod
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
						(b.registrering).note ILIKE (registreringObj.registrering).note
					)
			)
		)
		AND
		(
			(
				((b.registrering).livscykluskode <> 'Slettet'::Livscykluskode )
				AND
					(
						(registreringObj.registrering) IS NULL 
						OR
						(registreringObj.registrering).livscykluskode IS NULL 
					)
			)
			OR
			(
				(NOT ((registreringObj.registrering) IS NULL))
				AND
				(registreringObj.registrering).livscykluskode IS NOT NULL 
			)
		)
		AND
		(
			(
			  (
			  	(registreringObj.registrering) IS NULL
			  	OR
			  	(registreringObj.registrering).timeperiod IS NULL
			  )
			  AND
			  upper((b.registrering).timeperiod)='infinity'::TIMESTAMPTZ
			)  	
		OR
			(
				(NOT ((registreringObj.registrering) IS NULL))
				AND
				((registreringObj.registrering).timeperiod IS NOT NULL)
			)
		)
		AND
		( (NOT klassifikation_candidates_is_initialized) OR b.klassifikation_id = ANY (klassifikation_candidates) )


			);

	klassifikation_candidates_is_initialized:=true;
	END LOOP;
END IF;

--/**********************//

 




--RAISE DEBUG 'klassifikation_candidates_is_initialized step 5:%',klassifikation_candidates_is_initialized;
--RAISE DEBUG 'klassifikation_candidates step 5:%',klassifikation_candidates;

IF registreringObj IS NULL THEN
	--RAISE DEBUG 'registreringObj IS NULL';
ELSE
	IF NOT klassifikation_candidates_is_initialized THEN 
		klassifikation_candidates:=array(
		SELECT DISTINCT
			klassifikation_id
		FROM
			klassifikation_registrering b
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
						(b.registrering).note ILIKE (registreringObj.registrering).note
					)
			)
		)
		AND
		(
			(
				((b.registrering).livscykluskode <> 'Slettet'::Livscykluskode )
				AND
					(
						(registreringObj.registrering) IS NULL 
						OR
						(registreringObj.registrering).livscykluskode IS NULL 
					)
			)
			OR
			(
				(NOT ((registreringObj.registrering) IS NULL))
				AND
				(registreringObj.registrering).livscykluskode IS NOT NULL 
			)
		)
		AND
		(
			(
			  (
			  	(registreringObj.registrering) IS NULL
			  	OR
			  	(registreringObj.registrering).timeperiod IS NULL
			  )
			  AND
			  upper((b.registrering).timeperiod)='infinity'::TIMESTAMPTZ
			)  	
		OR
			(
				(NOT ((registreringObj.registrering) IS NULL))
				AND
				((registreringObj.registrering).timeperiod IS NOT NULL)
			)
		)
		AND
		( (NOT klassifikation_candidates_is_initialized) OR b.klassifikation_id = ANY (klassifikation_candidates) )

		)
		;

		klassifikation_candidates_is_initialized:=true;
	END IF;
END IF;


IF NOT klassifikation_candidates_is_initialized THEN
	--No filters applied!
	klassifikation_candidates:=array(
		SELECT DISTINCT id FROM klassifikation a LIMIT maxResults
	);
ELSE
	klassifikation_candidates:=array(
		SELECT DISTINCT id FROM unnest(klassifikation_candidates) as a(id) LIMIT maxResults
		);
END IF;

--RAISE DEBUG 'klassifikation_candidates_is_initialized step 6:%',klassifikation_candidates_is_initialized;
--RAISE DEBUG 'klassifikation_candidates step 6:%',klassifikation_candidates;


										 
/*** Filter out the objects that does not meets the stipulated access criteria  ***/
auth_filtered_uuids:=_as_filter_unauth_klassifikation(klassifikation_candidates,auth_criteria_arr); 
/*********************/


return auth_filtered_uuids;


END;
$$ LANGUAGE plpgsql STABLE; 





