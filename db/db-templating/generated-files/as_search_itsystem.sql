-- Copyright (C) 2015 Magenta ApS, http://magenta.dk.
-- Contact: info@magenta.dk.
--
-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at http://mozilla.org/MPL/2.0/.

/*
NOTICE: This file is auto-generated using the script: apply-template.py itsystem as_search.jinja.sql
*/


CREATE OR REPLACE FUNCTION as_search_itsystem(
	firstResult int,--TOOD ??
	itsystem_uuid uuid,
	registreringObj ItsystemRegistreringType,
	virkningSoeg TSTZRANGE, -- = TSTZRANGE(current_timestamp,current_timestamp,'[]'),
	maxResults int = 2147483647,
	anyAttrValueArr text[] = '{}'::text[],
	anyRelUuidArr	uuid[] = '{}'::uuid[],
	anyRelUrnArr text[] = '{}'::text[],
	auth_criteria_arr ItsystemRegistreringType[]=null
	)
  RETURNS uuid[] AS 
$$
DECLARE
	itsystem_candidates uuid[];
	itsystem_candidates_is_initialized boolean;
	--to_be_applyed_filter_uuids uuid[]; 
	attrEgenskaberTypeObj ItsystemEgenskaberAttrType;
	
  	tilsGyldighedTypeObj ItsystemGyldighedTilsType;
	relationTypeObj ItsystemRelationType;
	anyAttrValue text;
	anyRelUuid uuid;
	anyRelUrn text;
	auth_filtered_uuids uuid[];
BEGIN

--RAISE DEBUG 'step 0:registreringObj:%',registreringObj;

itsystem_candidates_is_initialized := false;

IF itsystem_uuid is not NULL THEN
	itsystem_candidates:= ARRAY[itsystem_uuid];
	itsystem_candidates_is_initialized:=true;
	IF registreringObj IS NULL THEN
	--RAISE DEBUG 'no registreringObj'
	ELSE	
		itsystem_candidates:=array(
				SELECT DISTINCT
				b.itsystem_id 
				FROM
				itsystem a
				JOIN itsystem_registrering b on b.itsystem_id=a.id
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
		( (NOT itsystem_candidates_is_initialized) OR b.itsystem_id = ANY (itsystem_candidates) )

		);		
	END IF;
	
END IF;


--RAISE DEBUG 'itsystem_candidates_is_initialized step 1:%',itsystem_candidates_is_initialized;
--RAISE DEBUG 'itsystem_candidates step 1:%',itsystem_candidates;
--/****************************//


--RAISE NOTICE 'itsystem_candidates_is_initialized step 2:%',itsystem_candidates_is_initialized;
--RAISE NOTICE 'itsystem_candidates step 2:%',itsystem_candidates;

--/****************************//
--filter on attributes 
--/**********************************************************//
--Filtration on attribute: Egenskaber
--/**********************************************************//
IF registreringObj IS NULL OR (registreringObj).attrEgenskaber IS NULL THEN
	--RAISE DEBUG 'as_search_itsystem: skipping filtration on attrEgenskaber';
ELSE
	IF (coalesce(array_length(itsystem_candidates,1),0)>0 OR NOT itsystem_candidates_is_initialized) THEN
		FOREACH attrEgenskaberTypeObj IN ARRAY registreringObj.attrEgenskaber
		LOOP
			itsystem_candidates:=array(
			SELECT DISTINCT
			b.itsystem_id 
			FROM  itsystem_attr_egenskaber a
			JOIN itsystem_registrering b on a.itsystem_registrering_id=b.id
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
					attrEgenskaberTypeObj.itsystemnavn IS NULL
					OR 
					a.itsystemnavn ILIKE attrEgenskaberTypeObj.itsystemnavn --case insensitive 
				)
				AND
				(
					attrEgenskaberTypeObj.itsystemtype IS NULL
					OR 
					a.itsystemtype ILIKE attrEgenskaberTypeObj.itsystemtype --case insensitive 
				)
				AND
				(
					attrEgenskaberTypeObj.konfigurationreference IS NULL
					OR
					_as_search_match_array(attrEgenskaberTypeObj.konfigurationreference,a.konfigurationreference) 
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
		( (NOT itsystem_candidates_is_initialized) OR b.itsystem_id = ANY (itsystem_candidates) )

			);
			

			itsystem_candidates_is_initialized:=true;
			

		END LOOP;
	END IF;
END IF;
--RAISE DEBUG 'itsystem_candidates_is_initialized step 3:%',itsystem_candidates_is_initialized;
--RAISE DEBUG 'itsystem_candidates step 3:%',itsystem_candidates;

--/**********************************************************//
--Filtration on anyAttrValueArr
--/**********************************************************//
IF coalesce(array_length(anyAttrValueArr ,1),0)>0 THEN

	FOREACH anyAttrValue IN ARRAY anyAttrValueArr
	LOOP
		itsystem_candidates:=array( 

			SELECT DISTINCT
			b.itsystem_id 
			FROM  itsystem_attr_egenskaber a
			JOIN itsystem_registrering b on a.itsystem_registrering_id=b.id
			WHERE
			(
				a.brugervendtnoegle ILIKE anyAttrValue
				OR
				a.itsystemnavn ILIKE anyAttrValue
				OR
				a.itsystemtype ILIKE anyAttrValue
				OR
				anyAttrValue ILIKE ANY (a.konfigurationreference)
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
		( (NOT itsystem_candidates_is_initialized) OR b.itsystem_id = ANY (itsystem_candidates) )


		);

	itsystem_candidates_is_initialized:=true;

	END LOOP;

END IF;



--RAISE DEBUG 'registrering,%',registreringObj;


--/**********************************************************//
--Filtration on state: Gyldighed
--/**********************************************************//
IF registreringObj IS NULL OR (registreringObj).tilsGyldighed IS NULL THEN
	--RAISE DEBUG 'as_search_itsystem: skipping filtration on tilsGyldighed';
ELSE
	IF (coalesce(array_length(itsystem_candidates,1),0)>0 OR itsystem_candidates_is_initialized IS FALSE ) THEN 

		FOREACH tilsGyldighedTypeObj IN ARRAY registreringObj.tilsGyldighed
		LOOP
			itsystem_candidates:=array(
			SELECT DISTINCT
			b.itsystem_id 
			FROM  itsystem_tils_gyldighed a
			JOIN itsystem_registrering b on a.itsystem_registrering_id=b.id
			WHERE
				(
					tilsGyldighedTypeObj.virkning IS NULL
					OR
					(
						(
					 		(tilsGyldighedTypeObj.virkning).TimePeriod IS NULL 
							OR
							(tilsGyldighedTypeObj.virkning).TimePeriod && (a.virkning).TimePeriod
						)
						AND
						(
								(tilsGyldighedTypeObj.virkning).AktoerRef IS NULL OR (tilsGyldighedTypeObj.virkning).AktoerRef=(a.virkning).AktoerRef
						)
						AND
						(
								(tilsGyldighedTypeObj.virkning).AktoerTypeKode IS NULL OR (tilsGyldighedTypeObj.virkning).AktoerTypeKode=(a.virkning).AktoerTypeKode
						)
						AND
						(
								(tilsGyldighedTypeObj.virkning).NoteTekst IS NULL OR (a.virkning).NoteTekst ILIKE (tilsGyldighedTypeObj.virkning).NoteTekst
						)
					)
				)
				AND
				(
					(NOT ((tilsGyldighedTypeObj.virkning) IS NULL OR (tilsGyldighedTypeObj.virkning).TimePeriod IS NULL)) --we have already filtered on virkning above
					OR
					(
						virkningSoeg IS NULL
						OR
						virkningSoeg && (a.virkning).TimePeriod
					)
				)
				AND
				(
					tilsGyldighedTypeObj.gyldighed IS NULL
					OR
					tilsGyldighedTypeObj.gyldighed = a.gyldighed
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
		( (NOT itsystem_candidates_is_initialized) OR b.itsystem_id = ANY (itsystem_candidates) )

	);
			

			itsystem_candidates_is_initialized:=true;
			

		END LOOP;
	END IF;
END IF;

/*
--relationer ItsystemRelationType[]
*/


--RAISE DEBUG 'itsystem_candidates_is_initialized step 4:%',itsystem_candidates_is_initialized;
--RAISE DEBUG 'itsystem_candidates step 4:%',itsystem_candidates;

--/**********************************************************//
--Filtration on relations
--/**********************************************************//


IF registreringObj IS NULL OR (registreringObj).relationer IS NULL THEN
	--RAISE DEBUG 'as_search_itsystem: skipping filtration on relationer';
ELSE
	IF (coalesce(array_length(itsystem_candidates,1),0)>0 OR NOT itsystem_candidates_is_initialized) AND (registreringObj).relationer IS NOT NULL THEN
		FOREACH relationTypeObj IN ARRAY registreringObj.relationer
		LOOP
			itsystem_candidates:=array(
			SELECT DISTINCT
			b.itsystem_id 
			FROM  itsystem_relation a
			JOIN itsystem_registrering b on a.itsystem_registrering_id=b.id
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
					relationTypeObj.relMaalUuid IS NULL
					OR
					relationTypeObj.relMaalUuid = a.rel_maal_uuid	
				)
				AND
				(
					relationTypeObj.objektType IS NULL
					OR
					relationTypeObj.objektType = a.objekt_type
				)
				AND
				(
					relationTypeObj.relMaalUrn IS NULL
					OR
					relationTypeObj.relMaalUrn = a.rel_maal_urn
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
		( (NOT itsystem_candidates_is_initialized) OR b.itsystem_id = ANY (itsystem_candidates) )

	);
			
			itsystem_candidates_is_initialized:=true;
			

		END LOOP;
	END IF;
END IF;
--/**********************//

IF coalesce(array_length(anyRelUuidArr ,1),0)>0 THEN

	FOREACH anyRelUuid IN ARRAY anyRelUuidArr
	LOOP
		itsystem_candidates:=array(
			SELECT DISTINCT
			b.itsystem_id 
			FROM  itsystem_relation a
			JOIN itsystem_registrering b on a.itsystem_registrering_id=b.id
			WHERE
			anyRelUuid = a.rel_maal_uuid
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
		( (NOT itsystem_candidates_is_initialized) OR b.itsystem_id = ANY (itsystem_candidates) )


			);

	itsystem_candidates_is_initialized:=true;
	END LOOP;
END IF;

--/**********************//

IF coalesce(array_length(anyRelUrnArr ,1),0)>0 THEN

	FOREACH anyRelUrn IN ARRAY anyRelUrnArr
	LOOP
		itsystem_candidates:=array(
			SELECT DISTINCT
			b.itsystem_id 
			FROM  itsystem_relation a
			JOIN itsystem_registrering b on a.itsystem_registrering_id=b.id
			WHERE
			anyRelUrn = a.rel_maal_urn
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
		( (NOT itsystem_candidates_is_initialized) OR b.itsystem_id = ANY (itsystem_candidates) )


			);

	itsystem_candidates_is_initialized:=true;
	END LOOP;
END IF;

--/**********************//

 



--RAISE DEBUG 'itsystem_candidates_is_initialized step 5:%',itsystem_candidates_is_initialized;
--RAISE DEBUG 'itsystem_candidates step 5:%',itsystem_candidates;

IF registreringObj IS NULL THEN
	--RAISE DEBUG 'registreringObj IS NULL';
ELSE
	IF NOT itsystem_candidates_is_initialized THEN 
		itsystem_candidates:=array(
		SELECT DISTINCT
			itsystem_id
		FROM
			itsystem_registrering b
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
		( (NOT itsystem_candidates_is_initialized) OR b.itsystem_id = ANY (itsystem_candidates) )

		)
		;

		itsystem_candidates_is_initialized:=true;
	END IF;
END IF;


IF NOT itsystem_candidates_is_initialized THEN
	--No filters applied!
	itsystem_candidates:=array(
		SELECT DISTINCT id FROM itsystem a LIMIT maxResults
	);
ELSE
	itsystem_candidates:=array(
		SELECT DISTINCT id FROM unnest(itsystem_candidates) as a(id) LIMIT maxResults
		);
END IF;

--RAISE DEBUG 'itsystem_candidates_is_initialized step 6:%',itsystem_candidates_is_initialized;
--RAISE DEBUG 'itsystem_candidates step 6:%',itsystem_candidates;


										 
/*** Filter out the objects that does not meets the stipulated access criteria  ***/
auth_filtered_uuids:=_as_filter_unauth_itsystem(itsystem_candidates,auth_criteria_arr); 
/*********************/


return auth_filtered_uuids;


END;
$$ LANGUAGE plpgsql STABLE; 





