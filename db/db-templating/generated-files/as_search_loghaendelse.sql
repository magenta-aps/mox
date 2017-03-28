-- Copyright (C) 2015 Magenta ApS, http://magenta.dk.
-- Contact: info@magenta.dk.
--
-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at http://mozilla.org/MPL/2.0/.

/*
NOTICE: This file is auto-generated using the script: apply-template.py loghaendelse as_search.jinja.sql
*/


CREATE OR REPLACE FUNCTION as_search_loghaendelse(
	firstResult int,--TOOD ??
	loghaendelse_uuid uuid,
	registreringObj LoghaendelseRegistreringType,
	virkningSoeg TSTZRANGE, -- = TSTZRANGE(current_timestamp,current_timestamp,'[]'),
	maxResults int = 2147483647,
	anyAttrValueArr text[] = '{}'::text[],
	anyuuidArr	uuid[] = '{}'::uuid[],
	anyurnArr text[] = '{}'::text[],
	auth_criteria_arr LoghaendelseRegistreringType[]=null
	)
  RETURNS uuid[] AS 
$$
DECLARE
	loghaendelse_candidates uuid[];
	loghaendelse_candidates_is_initialized boolean;
	--to_be_applyed_filter_uuids uuid[]; 
	attrEgenskaberTypeObj LoghaendelseEgenskaberAttrType;
	
  	tilsGyldighedTypeObj LoghaendelseGyldighedTilsType;
	relationTypeObj LoghaendelseRelationType;
	anyAttrValue text;
	anyuuid uuid;
	anyurn text;
	auth_filtered_uuids uuid[];
BEGIN

--RAISE DEBUG 'step 0:registreringObj:%',registreringObj;

loghaendelse_candidates_is_initialized := false;

IF loghaendelse_uuid is not NULL THEN
	loghaendelse_candidates:= ARRAY[loghaendelse_uuid];
	loghaendelse_candidates_is_initialized:=true;
	IF registreringObj IS NULL THEN
	--RAISE DEBUG 'no registreringObj'
	ELSE	
		loghaendelse_candidates:=array(
				SELECT DISTINCT
				b.loghaendelse_id 
				FROM
				loghaendelse a
				JOIN loghaendelse_registrering b on b.loghaendelse_id=a.id
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
		( (NOT loghaendelse_candidates_is_initialized) OR b.loghaendelse_id = ANY (loghaendelse_candidates) )

		);		
	END IF;
	
END IF;


--RAISE DEBUG 'loghaendelse_candidates_is_initialized step 1:%',loghaendelse_candidates_is_initialized;
--RAISE DEBUG 'loghaendelse_candidates step 1:%',loghaendelse_candidates;
--/****************************//


--RAISE NOTICE 'loghaendelse_candidates_is_initialized step 2:%',loghaendelse_candidates_is_initialized;
--RAISE NOTICE 'loghaendelse_candidates step 2:%',loghaendelse_candidates;

--/****************************//
--filter on attributes 
--/**********************************************************//
--Filtration on attribute: Egenskaber
--/**********************************************************//
IF registreringObj IS NULL OR (registreringObj).attrEgenskaber IS NULL THEN
	--RAISE DEBUG 'as_search_loghaendelse: skipping filtration on attrEgenskaber';
ELSE
	IF (coalesce(array_length(loghaendelse_candidates,1),0)>0 OR NOT loghaendelse_candidates_is_initialized) THEN
		FOREACH attrEgenskaberTypeObj IN ARRAY registreringObj.attrEgenskaber
		LOOP
			loghaendelse_candidates:=array(
			SELECT DISTINCT
			b.loghaendelse_id 
			FROM  loghaendelse_attr_egenskaber a
			JOIN loghaendelse_registrering b on a.loghaendelse_registrering_id=b.id
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
					attrEgenskaberTypeObj.service IS NULL
					OR 
					a.service ILIKE attrEgenskaberTypeObj.service --case insensitive 
				)
				AND
				(
					attrEgenskaberTypeObj.klasse IS NULL
					OR 
					a.klasse ILIKE attrEgenskaberTypeObj.klasse --case insensitive 
				)
				AND
				(
					attrEgenskaberTypeObj.tidspunkt IS NULL
					OR 
					a.tidspunkt ILIKE attrEgenskaberTypeObj.tidspunkt --case insensitive 
				)
				AND
				(
					attrEgenskaberTypeObj.operation IS NULL
					OR 
					a.operation ILIKE attrEgenskaberTypeObj.operation --case insensitive 
				)
				AND
				(
					attrEgenskaberTypeObj.objekttype IS NULL
					OR 
					a.objekttype ILIKE attrEgenskaberTypeObj.objekttype --case insensitive 
				)
				AND
				(
					attrEgenskaberTypeObj.returkode IS NULL
					OR 
					a.returkode ILIKE attrEgenskaberTypeObj.returkode --case insensitive 
				)
				AND
				(
					attrEgenskaberTypeObj.returtekst IS NULL
					OR 
					a.returtekst ILIKE attrEgenskaberTypeObj.returtekst --case insensitive 
				)
				AND
				(
					attrEgenskaberTypeObj.note IS NULL
					OR 
					a.note ILIKE attrEgenskaberTypeObj.note --case insensitive 
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
		( (NOT loghaendelse_candidates_is_initialized) OR b.loghaendelse_id = ANY (loghaendelse_candidates) )

			);
			

			loghaendelse_candidates_is_initialized:=true;
			

		END LOOP;
	END IF;
END IF;
--RAISE DEBUG 'loghaendelse_candidates_is_initialized step 3:%',loghaendelse_candidates_is_initialized;
--RAISE DEBUG 'loghaendelse_candidates step 3:%',loghaendelse_candidates;

--/**********************************************************//
--Filtration on anyAttrValueArr
--/**********************************************************//
IF coalesce(array_length(anyAttrValueArr ,1),0)>0 THEN

	FOREACH anyAttrValue IN ARRAY anyAttrValueArr
	LOOP
		loghaendelse_candidates:=array( 

			SELECT DISTINCT
			b.loghaendelse_id 
			FROM  loghaendelse_attr_egenskaber a
			JOIN loghaendelse_registrering b on a.loghaendelse_registrering_id=b.id
			WHERE
			(
						a.service ILIKE anyAttrValue OR
						a.klasse ILIKE anyAttrValue OR
						a.tidspunkt ILIKE anyAttrValue OR
						a.operation ILIKE anyAttrValue OR
						a.objekttype ILIKE anyAttrValue OR
						a.returkode ILIKE anyAttrValue OR
						a.returtekst ILIKE anyAttrValue OR
						a.note ILIKE anyAttrValue
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
		( (NOT loghaendelse_candidates_is_initialized) OR b.loghaendelse_id = ANY (loghaendelse_candidates) )


		);

	loghaendelse_candidates_is_initialized:=true;

	END LOOP;

END IF;



--RAISE DEBUG 'registrering,%',registreringObj;


--/**********************************************************//
--Filtration on state: Gyldighed
--/**********************************************************//
IF registreringObj IS NULL OR (registreringObj).tilsGyldighed IS NULL THEN
	--RAISE DEBUG 'as_search_loghaendelse: skipping filtration on tilsGyldighed';
ELSE
	IF (coalesce(array_length(loghaendelse_candidates,1),0)>0 OR loghaendelse_candidates_is_initialized IS FALSE ) THEN 

		FOREACH tilsGyldighedTypeObj IN ARRAY registreringObj.tilsGyldighed
		LOOP
			loghaendelse_candidates:=array(
			SELECT DISTINCT
			b.loghaendelse_id 
			FROM  loghaendelse_tils_gyldighed a
			JOIN loghaendelse_registrering b on a.loghaendelse_registrering_id=b.id
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
		( (NOT loghaendelse_candidates_is_initialized) OR b.loghaendelse_id = ANY (loghaendelse_candidates) )

	);
			

			loghaendelse_candidates_is_initialized:=true;
			

		END LOOP;
	END IF;
END IF;

/*
--relationer LoghaendelseRelationType[]
*/


--RAISE DEBUG 'loghaendelse_candidates_is_initialized step 4:%',loghaendelse_candidates_is_initialized;
--RAISE DEBUG 'loghaendelse_candidates step 4:%',loghaendelse_candidates;

--/**********************************************************//
--Filtration on relations
--/**********************************************************//


IF registreringObj IS NULL OR (registreringObj).relationer IS NULL THEN
	--RAISE DEBUG 'as_search_loghaendelse: skipping filtration on relationer';
ELSE
	IF (coalesce(array_length(loghaendelse_candidates,1),0)>0 OR NOT loghaendelse_candidates_is_initialized) AND (registreringObj).relationer IS NOT NULL THEN
		FOREACH relationTypeObj IN ARRAY registreringObj.relationer
		LOOP
			loghaendelse_candidates:=array(
			SELECT DISTINCT
			b.loghaendelse_id 
			FROM  loghaendelse_relation a
			JOIN loghaendelse_registrering b on a.loghaendelse_registrering_id=b.id
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
		( (NOT loghaendelse_candidates_is_initialized) OR b.loghaendelse_id = ANY (loghaendelse_candidates) )

	);
			
			loghaendelse_candidates_is_initialized:=true;
			

		END LOOP;
	END IF;
END IF;
--/**********************//

IF coalesce(array_length(anyuuidArr ,1),0)>0 THEN

	FOREACH anyuuid IN ARRAY anyuuidArr
	LOOP
		loghaendelse_candidates:=array(
			SELECT DISTINCT
			b.loghaendelse_id 
			FROM  loghaendelse_relation a
			JOIN loghaendelse_registrering b on a.loghaendelse_registrering_id=b.id
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
		( (NOT loghaendelse_candidates_is_initialized) OR b.loghaendelse_id = ANY (loghaendelse_candidates) )


			);

	loghaendelse_candidates_is_initialized:=true;
	END LOOP;
END IF;

--/**********************//

IF coalesce(array_length(anyurnArr ,1),0)>0 THEN

	FOREACH anyurn IN ARRAY anyurnArr
	LOOP
		loghaendelse_candidates:=array(
			SELECT DISTINCT
			b.loghaendelse_id 
			FROM  loghaendelse_relation a
			JOIN loghaendelse_registrering b on a.loghaendelse_registrering_id=b.id
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
		( (NOT loghaendelse_candidates_is_initialized) OR b.loghaendelse_id = ANY (loghaendelse_candidates) )


			);

	loghaendelse_candidates_is_initialized:=true;
	END LOOP;
END IF;

--/**********************//

 



--RAISE DEBUG 'loghaendelse_candidates_is_initialized step 5:%',loghaendelse_candidates_is_initialized;
--RAISE DEBUG 'loghaendelse_candidates step 5:%',loghaendelse_candidates;

IF registreringObj IS NULL THEN
	--RAISE DEBUG 'registreringObj IS NULL';
ELSE
	IF NOT loghaendelse_candidates_is_initialized THEN 
		loghaendelse_candidates:=array(
		SELECT DISTINCT
			loghaendelse_id
		FROM
			loghaendelse_registrering b
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
		( (NOT loghaendelse_candidates_is_initialized) OR b.loghaendelse_id = ANY (loghaendelse_candidates) )

		)
		;

		loghaendelse_candidates_is_initialized:=true;
	END IF;
END IF;


IF NOT loghaendelse_candidates_is_initialized THEN
	--No filters applied!
	loghaendelse_candidates:=array(
		SELECT DISTINCT id FROM loghaendelse a LIMIT maxResults
	);
ELSE
	loghaendelse_candidates:=array(
		SELECT DISTINCT id FROM unnest(loghaendelse_candidates) as a(id) LIMIT maxResults
		);
END IF;

--RAISE DEBUG 'loghaendelse_candidates_is_initialized step 6:%',loghaendelse_candidates_is_initialized;
--RAISE DEBUG 'loghaendelse_candidates step 6:%',loghaendelse_candidates;


										 
/*** Filter out the objects that does not meets the stipulated access criteria  ***/
auth_filtered_uuids:=_as_filter_unauth_loghaendelse(loghaendelse_candidates,auth_criteria_arr); 
/*********************/


return auth_filtered_uuids;


END;
$$ LANGUAGE plpgsql STABLE; 





