-- Copyright (C) 2015 Magenta ApS, http://magenta.dk.
-- Contact: info@magenta.dk.
--
-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at http://mozilla.org/MPL/2.0/.

/*
NOTICE: This file is auto-generated using the script: apply-template.py aktivitet as_search.jinja.sql
*/


CREATE OR REPLACE FUNCTION as_search_aktivitet(
	firstResult int,--TOOD ??
	aktivitet_uuid uuid,
	registreringObj AktivitetRegistreringType,
	virkningSoeg TSTZRANGE, -- = TSTZRANGE(current_timestamp,current_timestamp,'[]'),
	maxResults int = 2147483647,
	anyAttrValueArr text[] = '{}'::text[],
	anyuuidArr	uuid[] = '{}'::uuid[],
	anyurnArr text[] = '{}'::text[],
	auth_criteria_arr AktivitetRegistreringType[]=null,
	search_operator_greater_than_or_equal_attr_egenskaber AktivitetEgenskaberAttrType[]=null,
	search_operator_less_than_or_equal_attr_egenskaber AktivitetEgenskaberAttrType[]=null
	)
  RETURNS uuid[] AS 
$$
DECLARE
	aktivitet_candidates uuid[];
	aktivitet_candidates_is_initialized boolean;
	--to_be_applyed_filter_uuids uuid[]; 
	attrEgenskaberTypeObj AktivitetEgenskaberAttrType;
	
  	tilsStatusTypeObj AktivitetStatusTilsType;
  	tilsPubliceretTypeObj AktivitetPubliceretTilsType;
	relationTypeObj AktivitetRelationType;
	anyAttrValue text;
	anyuuid uuid;
	anyurn text;
	auth_filtered_uuids uuid[];
BEGIN

--RAISE DEBUG 'step 0:registreringObj:%',registreringObj;

aktivitet_candidates_is_initialized := false;

IF aktivitet_uuid is not NULL THEN
	aktivitet_candidates:= ARRAY[aktivitet_uuid];
	aktivitet_candidates_is_initialized:=true;
	IF registreringObj IS NULL THEN
	--RAISE DEBUG 'no registreringObj'
	ELSE	
		aktivitet_candidates:=array(
				SELECT DISTINCT
				b.aktivitet_id 
				FROM
				aktivitet a
				JOIN aktivitet_registrering b on b.aktivitet_id=a.id
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
		( (NOT aktivitet_candidates_is_initialized) OR b.aktivitet_id = ANY (aktivitet_candidates) )

		);		
	END IF;
	
END IF;


--RAISE DEBUG 'aktivitet_candidates_is_initialized step 1:%',aktivitet_candidates_is_initialized;
--RAISE DEBUG 'aktivitet_candidates step 1:%',aktivitet_candidates;
--/****************************//


--RAISE NOTICE 'aktivitet_candidates_is_initialized step 2:%',aktivitet_candidates_is_initialized;
--RAISE NOTICE 'aktivitet_candidates step 2:%',aktivitet_candidates;

--/****************************//
--filter on attributes 
--/**********************************************************//
--Filtration on attribute: Egenskaber
--/**********************************************************//
IF registreringObj IS NULL OR (registreringObj).attrEgenskaber IS NULL THEN
	--RAISE DEBUG 'as_search_aktivitet: skipping filtration on attrEgenskaber';
ELSE
	IF (coalesce(array_length(aktivitet_candidates,1),0)>0 OR NOT aktivitet_candidates_is_initialized) THEN
		FOREACH attrEgenskaberTypeObj IN ARRAY registreringObj.attrEgenskaber
		LOOP
			aktivitet_candidates:=array(
			SELECT DISTINCT
			b.aktivitet_id 
			FROM  aktivitet_attr_egenskaber a
			JOIN aktivitet_registrering b on a.aktivitet_registrering_id=b.id
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
					attrEgenskaberTypeObj.aktivitetnavn IS NULL
					OR 
					a.aktivitetnavn ILIKE attrEgenskaberTypeObj.aktivitetnavn --case insensitive 
				)
				AND
				(
					attrEgenskaberTypeObj.beskrivelse IS NULL
					OR 
					a.beskrivelse ILIKE attrEgenskaberTypeObj.beskrivelse --case insensitive 
				)
				AND
				(
					attrEgenskaberTypeObj.starttidspunkt IS NULL
					OR 
					a.starttidspunkt = attrEgenskaberTypeObj.starttidspunkt 
				)
				AND
				(
					attrEgenskaberTypeObj.sluttidspunkt IS NULL
					OR 
					a.sluttidspunkt = attrEgenskaberTypeObj.sluttidspunkt 
				)
				AND
				(
					attrEgenskaberTypeObj.tidsforbrug IS NULL
					OR 
					a.tidsforbrug = attrEgenskaberTypeObj.tidsforbrug 
				)
				AND
				(
					attrEgenskaberTypeObj.formaal IS NULL
					OR 
					a.formaal ILIKE attrEgenskaberTypeObj.formaal --case insensitive 
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
		( (NOT aktivitet_candidates_is_initialized) OR b.aktivitet_id = ANY (aktivitet_candidates) )

			);
			

			aktivitet_candidates_is_initialized:=true;
			

		END LOOP;
	END IF;
END IF;
--RAISE DEBUG 'aktivitet_candidates_is_initialized step 3:%',aktivitet_candidates_is_initialized;
--RAISE DEBUG 'aktivitet_candidates step 3:%',aktivitet_candidates;

--/**********************************************************//
--Filtration on anyAttrValueArr
--/**********************************************************//
IF coalesce(array_length(anyAttrValueArr ,1),0)>0 THEN

	FOREACH anyAttrValue IN ARRAY anyAttrValueArr
	LOOP
		aktivitet_candidates:=array( 

			SELECT DISTINCT
			b.aktivitet_id 
			FROM  aktivitet_attr_egenskaber a
			JOIN aktivitet_registrering b on a.aktivitet_registrering_id=b.id
			WHERE
			(
						a.brugervendtnoegle ILIKE anyAttrValue OR
						a.aktivitetnavn ILIKE anyAttrValue OR
						a.beskrivelse ILIKE anyAttrValue OR
									a.starttidspunkt::text ilike anyAttrValue OR
									a.sluttidspunkt::text ilike anyAttrValue OR
									a.tidsforbrug::text ilike anyAttrValue OR
						a.formaal ILIKE anyAttrValue
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
		( (NOT aktivitet_candidates_is_initialized) OR b.aktivitet_id = ANY (aktivitet_candidates) )


		);

	aktivitet_candidates_is_initialized:=true;

	END LOOP;

END IF;



--RAISE DEBUG 'registrering,%',registreringObj;


--/**********************************************************//
--Filtration on state: Status
--/**********************************************************//
IF registreringObj IS NULL OR (registreringObj).tilsStatus IS NULL THEN
	--RAISE DEBUG 'as_search_aktivitet: skipping filtration on tilsStatus';
ELSE
	IF (coalesce(array_length(aktivitet_candidates,1),0)>0 OR aktivitet_candidates_is_initialized IS FALSE ) THEN 

		FOREACH tilsStatusTypeObj IN ARRAY registreringObj.tilsStatus
		LOOP
			aktivitet_candidates:=array(
			SELECT DISTINCT
			b.aktivitet_id 
			FROM  aktivitet_tils_status a
			JOIN aktivitet_registrering b on a.aktivitet_registrering_id=b.id
			WHERE
				(
					tilsStatusTypeObj.virkning IS NULL
					OR
					(
						(
					 		(tilsStatusTypeObj.virkning).TimePeriod IS NULL 
							OR
							(tilsStatusTypeObj.virkning).TimePeriod && (a.virkning).TimePeriod
						)
						AND
						(
								(tilsStatusTypeObj.virkning).AktoerRef IS NULL OR (tilsStatusTypeObj.virkning).AktoerRef=(a.virkning).AktoerRef
						)
						AND
						(
								(tilsStatusTypeObj.virkning).AktoerTypeKode IS NULL OR (tilsStatusTypeObj.virkning).AktoerTypeKode=(a.virkning).AktoerTypeKode
						)
						AND
						(
								(tilsStatusTypeObj.virkning).NoteTekst IS NULL OR (a.virkning).NoteTekst ILIKE (tilsStatusTypeObj.virkning).NoteTekst
						)
					)
				)
				AND
				(
					(NOT ((tilsStatusTypeObj.virkning) IS NULL OR (tilsStatusTypeObj.virkning).TimePeriod IS NULL)) --we have already filtered on virkning above
					OR
					(
						virkningSoeg IS NULL
						OR
						virkningSoeg && (a.virkning).TimePeriod
					)
				)
				AND
				(
					tilsStatusTypeObj.status IS NULL
					OR
					tilsStatusTypeObj.status = a.status
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
		( (NOT aktivitet_candidates_is_initialized) OR b.aktivitet_id = ANY (aktivitet_candidates) )

	);
			

			aktivitet_candidates_is_initialized:=true;
			

		END LOOP;
	END IF;
END IF;
--/**********************************************************//
--Filtration on state: Publiceret
--/**********************************************************//
IF registreringObj IS NULL OR (registreringObj).tilsPubliceret IS NULL THEN
	--RAISE DEBUG 'as_search_aktivitet: skipping filtration on tilsPubliceret';
ELSE
	IF (coalesce(array_length(aktivitet_candidates,1),0)>0 OR aktivitet_candidates_is_initialized IS FALSE ) THEN 

		FOREACH tilsPubliceretTypeObj IN ARRAY registreringObj.tilsPubliceret
		LOOP
			aktivitet_candidates:=array(
			SELECT DISTINCT
			b.aktivitet_id 
			FROM  aktivitet_tils_publiceret a
			JOIN aktivitet_registrering b on a.aktivitet_registrering_id=b.id
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
		( (NOT aktivitet_candidates_is_initialized) OR b.aktivitet_id = ANY (aktivitet_candidates) )

	);
			

			aktivitet_candidates_is_initialized:=true;
			

		END LOOP;
	END IF;
END IF;

/*
--relationer AktivitetRelationType[]
*/


--RAISE DEBUG 'aktivitet_candidates_is_initialized step 4:%',aktivitet_candidates_is_initialized;
--RAISE DEBUG 'aktivitet_candidates step 4:%',aktivitet_candidates;

--/**********************************************************//
--Filtration on relations
--/**********************************************************//


IF registreringObj IS NULL OR (registreringObj).relationer IS NULL THEN
	--RAISE DEBUG 'as_search_aktivitet: skipping filtration on relationer';
ELSE
	IF (coalesce(array_length(aktivitet_candidates,1),0)>0 OR NOT aktivitet_candidates_is_initialized) AND (registreringObj).relationer IS NOT NULL THEN
		FOREACH relationTypeObj IN ARRAY registreringObj.relationer
		LOOP
			aktivitet_candidates:=array(
			SELECT DISTINCT
			b.aktivitet_id 
			FROM  aktivitet_relation a
			JOIN aktivitet_registrering b on a.aktivitet_registrering_id=b.id
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
 					relationTypeObj.indeks IS NULL
 					OR
 					relationTypeObj.indeks = a.rel_index
 				)
				AND
				(
					relationTypeObj.aktoerAttr IS NULL
					OR
					(
						(
							(relationTypeObj.aktoerAttr).obligatorisk IS NULL
							OR
							(relationTypeObj.aktoerAttr).obligatorisk = (a.aktoer_attr).obligatorisk					
						)
						AND
						(
							(relationTypeObj.aktoerAttr).accepteret IS NULL
							OR
							(relationTypeObj.aktoerAttr).accepteret = (a.aktoer_attr).accepteret
						)
						AND
						(
							(relationTypeObj.aktoerAttr).repraesentation_uuid IS NULL
							OR
							(relationTypeObj.aktoerAttr).repraesentation_uuid = (a.aktoer_attr).repraesentation_uuid
						)
						AND
						(
							(relationTypeObj.aktoerAttr).repraesentation_urn IS NULL
							OR
							(relationTypeObj.aktoerAttr).repraesentation_urn = (a.aktoer_attr).repraesentation_urn
						)
					)
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
		( (NOT aktivitet_candidates_is_initialized) OR b.aktivitet_id = ANY (aktivitet_candidates) )

	);
			
			aktivitet_candidates_is_initialized:=true;
			

		END LOOP;
	END IF;
END IF;
--/**********************//

IF coalesce(array_length(anyuuidArr ,1),0)>0 THEN

	FOREACH anyuuid IN ARRAY anyuuidArr
	LOOP
		aktivitet_candidates:=array(
			SELECT DISTINCT
			b.aktivitet_id 
			FROM  aktivitet_relation a
			JOIN aktivitet_registrering b on a.aktivitet_registrering_id=b.id
			WHERE
			(
				anyuuid = a.rel_maal_uuid
			OR  
				((NOT (a.aktoer_attr IS NULL)) AND anyuuid = (a.aktoer_attr).repraesentation_uuid )
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
		( (NOT aktivitet_candidates_is_initialized) OR b.aktivitet_id = ANY (aktivitet_candidates) )


			);

	aktivitet_candidates_is_initialized:=true;
	END LOOP;
END IF;

--/**********************//

IF coalesce(array_length(anyurnArr ,1),0)>0 THEN

	FOREACH anyurn IN ARRAY anyurnArr
	LOOP
		aktivitet_candidates:=array(
			SELECT DISTINCT
			b.aktivitet_id 
			FROM  aktivitet_relation a
			JOIN aktivitet_registrering b on a.aktivitet_registrering_id=b.id
			WHERE
			(
				anyurn = a.rel_maal_urn
				OR 
				((NOT (a.aktoer_attr IS NULL)) AND anyurn = (a.aktoer_attr).repraesentation_urn)
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
		( (NOT aktivitet_candidates_is_initialized) OR b.aktivitet_id = ANY (aktivitet_candidates) )


			);

	aktivitet_candidates_is_initialized:=true;
	END LOOP;
END IF;

--/**********************//

 --/**********************************************************//
--Filtration using operator 'greather than or equal': Egenskaber
--/**********************************************************//
IF coalesce(array_length(search_operator_greater_than_or_equal_attr_egenskaber,1),0)>0 THEN
	IF (coalesce(array_length(aktivitet_candidates,1),0)>0 OR NOT aktivitet_candidates_is_initialized) THEN
		FOREACH attrEgenskaberTypeObj IN ARRAY search_operator_greater_than_or_equal_attr_egenskaber
		LOOP
			aktivitet_candidates:=array(
			SELECT DISTINCT
			b.aktivitet_id 
			FROM  aktivitet_attr_egenskaber a
			JOIN aktivitet_registrering b on a.aktivitet_registrering_id=b.id
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
					a.brugervendtnoegle >= attrEgenskaberTypeObj.brugervendtnoegle 
				)
				AND
				(
					attrEgenskaberTypeObj.aktivitetnavn IS NULL
					OR 
					a.aktivitetnavn >= attrEgenskaberTypeObj.aktivitetnavn 
				)
				AND
				(
					attrEgenskaberTypeObj.beskrivelse IS NULL
					OR 
					a.beskrivelse >= attrEgenskaberTypeObj.beskrivelse 
				)
				AND
				(
					attrEgenskaberTypeObj.starttidspunkt IS NULL
					OR 
					a.starttidspunkt >= attrEgenskaberTypeObj.starttidspunkt 
				)
				AND
				(
					attrEgenskaberTypeObj.sluttidspunkt IS NULL
					OR 
					a.sluttidspunkt >= attrEgenskaberTypeObj.sluttidspunkt 
				)
				AND
				(
					attrEgenskaberTypeObj.tidsforbrug IS NULL
					OR 
					a.tidsforbrug >= attrEgenskaberTypeObj.tidsforbrug 
				)
				AND
				(
					attrEgenskaberTypeObj.formaal IS NULL
					OR 
					a.formaal >= attrEgenskaberTypeObj.formaal 
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
		( (NOT aktivitet_candidates_is_initialized) OR b.aktivitet_id = ANY (aktivitet_candidates) )

			);
			

			aktivitet_candidates_is_initialized:=true;
			
			
			END LOOP;
		END IF;	
	END IF;

--RAISE DEBUG 'aktivitet_candidates_is_initialized step 3:%',aktivitet_candidates_is_initialized;
--RAISE DEBUG 'aktivitet_candidates step 3:%',aktivitet_candidates;

 --/**********************************************************//
--Filtration using operator 'less than or equal': Egenskaber
--/**********************************************************//
IF coalesce(array_length(search_operator_less_than_or_equal_attr_egenskaber,1),0)>0 THEN
	IF (coalesce(array_length(aktivitet_candidates,1),0)>0 OR NOT aktivitet_candidates_is_initialized) THEN
		FOREACH attrEgenskaberTypeObj IN ARRAY search_operator_less_than_or_equal_attr_egenskaber
		LOOP
			aktivitet_candidates:=array(
			SELECT DISTINCT
			b.aktivitet_id 
			FROM  aktivitet_attr_egenskaber a
			JOIN aktivitet_registrering b on a.aktivitet_registrering_id=b.id
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
					a.brugervendtnoegle <= attrEgenskaberTypeObj.brugervendtnoegle 
				)
				AND
				(
					attrEgenskaberTypeObj.aktivitetnavn IS NULL
					OR 
					a.aktivitetnavn <= attrEgenskaberTypeObj.aktivitetnavn 
				)
				AND
				(
					attrEgenskaberTypeObj.beskrivelse IS NULL
					OR 
					a.beskrivelse <= attrEgenskaberTypeObj.beskrivelse 
				)
				AND
				(
					attrEgenskaberTypeObj.starttidspunkt IS NULL
					OR 
					a.starttidspunkt <= attrEgenskaberTypeObj.starttidspunkt 
				)
				AND
				(
					attrEgenskaberTypeObj.sluttidspunkt IS NULL
					OR 
					a.sluttidspunkt <= attrEgenskaberTypeObj.sluttidspunkt 
				)
				AND
				(
					attrEgenskaberTypeObj.tidsforbrug IS NULL
					OR 
					a.tidsforbrug <= attrEgenskaberTypeObj.tidsforbrug 
				)
				AND
				(
					attrEgenskaberTypeObj.formaal IS NULL
					OR 
					a.formaal <= attrEgenskaberTypeObj.formaal 
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
		( (NOT aktivitet_candidates_is_initialized) OR b.aktivitet_id = ANY (aktivitet_candidates) )

			);
			

			aktivitet_candidates_is_initialized:=true;
			
			
			END LOOP;
		END IF;	
	END IF;

--RAISE DEBUG 'aktivitet_candidates_is_initialized step 3:%',aktivitet_candidates_is_initialized;
--RAISE DEBUG 'aktivitet_candidates step 3:%',aktivitet_candidates;

--/**********************//



--RAISE DEBUG 'aktivitet_candidates_is_initialized step 5:%',aktivitet_candidates_is_initialized;
--RAISE DEBUG 'aktivitet_candidates step 5:%',aktivitet_candidates;

IF registreringObj IS NULL THEN
	--RAISE DEBUG 'registreringObj IS NULL';
ELSE
	IF NOT aktivitet_candidates_is_initialized THEN 
		aktivitet_candidates:=array(
		SELECT DISTINCT
			aktivitet_id
		FROM
			aktivitet_registrering b
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
		( (NOT aktivitet_candidates_is_initialized) OR b.aktivitet_id = ANY (aktivitet_candidates) )

		)
		;

		aktivitet_candidates_is_initialized:=true;
	END IF;
END IF;


IF NOT aktivitet_candidates_is_initialized THEN
	--No filters applied!
	aktivitet_candidates:=array(
		SELECT DISTINCT id FROM aktivitet a LIMIT maxResults
	);
ELSE
	aktivitet_candidates:=array(
		SELECT DISTINCT id FROM unnest(aktivitet_candidates) as a(id) LIMIT maxResults
		);
END IF;

--RAISE DEBUG 'aktivitet_candidates_is_initialized step 6:%',aktivitet_candidates_is_initialized;
--RAISE DEBUG 'aktivitet_candidates step 6:%',aktivitet_candidates;


										 
/*** Filter out the objects that does not meets the stipulated access criteria  ***/
auth_filtered_uuids:=_as_filter_unauth_aktivitet(aktivitet_candidates,auth_criteria_arr); 
/*********************/


return auth_filtered_uuids;


END;
$$ LANGUAGE plpgsql STABLE; 





