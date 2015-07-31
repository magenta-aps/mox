-- Copyright (C) 2015 Magenta ApS, http://magenta.dk.
-- Contact: info@magenta.dk.
--
-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at http://mozilla.org/MPL/2.0/.

/*
NOTICE: This file is auto-generated using the script: apply-template.py dokument as_search.jinja.sql
*/


CREATE OR REPLACE FUNCTION as_search_dokument(
	firstResult int,--TOOD ??
	dokument_uuid uuid,
	registreringObj DokumentRegistreringType,
	virkningSoeg TSTZRANGE, -- = TSTZRANGE(current_timestamp,current_timestamp,'[]'),
	maxResults int = 2147483647,
	anyAttrValueArr text[] = '{}'::text[],
	anyRelUuidArr	uuid[] = '{}'::uuid[],
	anyRelUrnArr text[] = '{}'::text[]
	)
  RETURNS uuid[] AS 
$$
DECLARE
	dokument_candidates uuid[];
	dokument_candidates_is_initialized boolean;
	--to_be_applyed_filter_uuids uuid[]; 
	attrEgenskaberTypeObj DokumentEgenskaberAttrType;
	
  	tilsFremdriftTypeObj DokumentFremdriftTilsType;
	relationTypeObj DokumentRelationType;
	anyAttrValue text;
	anyRelUuid uuid;
	anyRelUrn text;
BEGIN

--RAISE DEBUG 'step 0:registreringObj:%',registreringObj;

dokument_candidates_is_initialized := false;

IF dokument_uuid is not NULL THEN
	dokument_candidates:= ARRAY[dokument_uuid];
	dokument_candidates_is_initialized:=true;
	IF registreringObj IS NULL THEN
	--RAISE DEBUG 'no registreringObj'
	ELSE	
		dokument_candidates:=array(
				SELECT DISTINCT
				b.dokument_id 
				FROM
				dokument a
				JOIN dokument_registrering b on b.dokument_id=a.id
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
		( (NOT dokument_candidates_is_initialized) OR b.dokument_id = ANY (dokument_candidates) )

		);		
	END IF;
	
END IF;


--RAISE DEBUG 'dokument_candidates_is_initialized step 1:%',dokument_candidates_is_initialized;
--RAISE DEBUG 'dokument_candidates step 1:%',dokument_candidates;
--/****************************//


--RAISE NOTICE 'dokument_candidates_is_initialized step 2:%',dokument_candidates_is_initialized;
--RAISE NOTICE 'dokument_candidates step 2:%',dokument_candidates;

--/****************************//
--filter on attributes 
--/**********************************************************//
--Filtration on attribute: Egenskaber
--/**********************************************************//
IF registreringObj IS NULL OR (registreringObj).attrEgenskaber IS NULL THEN
	--RAISE DEBUG 'as_search_dokument: skipping filtration on attrEgenskaber';
ELSE
	IF (coalesce(array_length(dokument_candidates,1),0)>0 OR NOT dokument_candidates_is_initialized) THEN
		FOREACH attrEgenskaberTypeObj IN ARRAY registreringObj.attrEgenskaber
		LOOP
			dokument_candidates:=array(
			SELECT DISTINCT
			b.dokument_id 
			FROM  dokument_attr_egenskaber a
			JOIN dokument_registrering b on a.dokument_registrering_id=b.id
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
					attrEgenskaberTypeObj.brevdato IS NULL
					OR 
					a.brevdato = attrEgenskaberTypeObj.brevdato 
				)
				AND
				(
					attrEgenskaberTypeObj.kassationskode IS NULL
					OR 
					a.kassationskode ILIKE attrEgenskaberTypeObj.kassationskode --case insensitive 
				)
				AND
				(
					attrEgenskaberTypeObj.major IS NULL
					OR 
					a.major = attrEgenskaberTypeObj.major 
				)
				AND
				(
					attrEgenskaberTypeObj.minor IS NULL
					OR 
					a.minor = attrEgenskaberTypeObj.minor 
				)
				AND
				(
					attrEgenskaberTypeObj.offentlighedundtaget IS NULL
					OR
						(
							(
								(attrEgenskaberTypeObj.offentlighedundtaget).AlternativTitel IS NULL
								OR
								(a.offentlighedundtaget).AlternativTitel ILIKE (attrEgenskaberTypeObj.offentlighedundtaget).AlternativTitel 
							)
							AND
							(
								(attrEgenskaberTypeObj.offentlighedundtaget).Hjemmel IS NULL
								OR
								(a.offentlighedundtaget).Hjemmel ILIKE (attrEgenskaberTypeObj.offentlighedundtaget).Hjemmel
							)
						) 
				)
				AND
				(
					attrEgenskaberTypeObj.titel IS NULL
					OR 
					a.titel ILIKE attrEgenskaberTypeObj.titel --case insensitive 
				)
				AND
				(
					attrEgenskaberTypeObj.dokumenttype IS NULL
					OR 
					a.dokumenttype ILIKE attrEgenskaberTypeObj.dokumenttype --case insensitive 
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
		( (NOT dokument_candidates_is_initialized) OR b.dokument_id = ANY (dokument_candidates) )

			);
			

			dokument_candidates_is_initialized:=true;
			

		END LOOP;
	END IF;
END IF;
--RAISE DEBUG 'dokument_candidates_is_initialized step 3:%',dokument_candidates_is_initialized;
--RAISE DEBUG 'dokument_candidates step 3:%',dokument_candidates;

--/**********************************************************//
--Filtration on anyAttrValueArr
--/**********************************************************//
IF coalesce(array_length(anyAttrValueArr ,1),0)>0 THEN

	FOREACH anyAttrValue IN ARRAY anyAttrValueArr
	LOOP
		dokument_candidates:=array( 

			SELECT DISTINCT
			b.dokument_id 
			FROM  dokument_attr_egenskaber a
			JOIN dokument_registrering b on a.dokument_registrering_id=b.id
			WHERE
			(
				a.brugervendtnoegle ILIKE anyAttrValue
				OR
				a.beskrivelse ILIKE anyAttrValue
				OR
				anyAttrValue = a.brevdato
				OR
				a.kassationskode ILIKE anyAttrValue
				OR
				anyAttrValue = a.major
				OR
				anyAttrValue = a.minor
				OR
				anyAttrValue = a.offentlighedundtaget
				OR
				a.titel ILIKE anyAttrValue
				OR
				a.dokumenttype ILIKE anyAttrValue
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
		( (NOT dokument_candidates_is_initialized) OR b.dokument_id = ANY (dokument_candidates) )


		);

	dokument_candidates_is_initialized:=true;

	END LOOP;

END IF;



--RAISE DEBUG 'registrering,%',registreringObj;


--/**********************************************************//
--Filtration on state: Fremdrift
--/**********************************************************//
IF registreringObj IS NULL OR (registreringObj).tilsFremdrift IS NULL THEN
	--RAISE DEBUG 'as_search_dokument: skipping filtration on tilsFremdrift';
ELSE
	IF (coalesce(array_length(dokument_candidates,1),0)>0 OR dokument_candidates_is_initialized IS FALSE ) THEN 

		FOREACH tilsFremdriftTypeObj IN ARRAY registreringObj.tilsFremdrift
		LOOP
			dokument_candidates:=array(
			SELECT DISTINCT
			b.dokument_id 
			FROM  dokument_tils_fremdrift a
			JOIN dokument_registrering b on a.dokument_registrering_id=b.id
			WHERE
				(
					tilsFremdriftTypeObj.virkning IS NULL
					OR
					(
						(
					 		(tilsFremdriftTypeObj.virkning).TimePeriod IS NULL 
							OR
							(tilsFremdriftTypeObj.virkning).TimePeriod && (a.virkning).TimePeriod
						)
						AND
						(
								(tilsFremdriftTypeObj.virkning).AktoerRef IS NULL OR (tilsFremdriftTypeObj.virkning).AktoerRef=(a.virkning).AktoerRef
						)
						AND
						(
								(tilsFremdriftTypeObj.virkning).AktoerTypeKode IS NULL OR (tilsFremdriftTypeObj.virkning).AktoerTypeKode=(a.virkning).AktoerTypeKode
						)
						AND
						(
								(tilsFremdriftTypeObj.virkning).NoteTekst IS NULL OR (tilsFremdriftTypeObj.virkning).NoteTekst=(a.virkning).NoteTekst
						)
					)
				)
				AND
				(
					(NOT ((tilsFremdriftTypeObj.virkning) IS NULL OR (tilsFremdriftTypeObj.virkning).TimePeriod IS NULL)) --we have already filtered on virkning above
					OR
					(
						virkningSoeg IS NULL
						OR
						virkningSoeg && (a.virkning).TimePeriod
					)
				)
				AND
				(
					tilsFremdriftTypeObj.fremdrift IS NULL
					OR
					tilsFremdriftTypeObj.fremdrift = a.fremdrift
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
		( (NOT dokument_candidates_is_initialized) OR b.dokument_id = ANY (dokument_candidates) )

	);
			

			dokument_candidates_is_initialized:=true;
			

		END LOOP;
	END IF;
END IF;

/*
--relationer DokumentRelationType[]
*/


--RAISE DEBUG 'dokument_candidates_is_initialized step 4:%',dokument_candidates_is_initialized;
--RAISE DEBUG 'dokument_candidates step 4:%',dokument_candidates;

--/**********************************************************//
--Filtration on relations
--/**********************************************************//


IF registreringObj IS NULL OR (registreringObj).relationer IS NULL THEN
	--RAISE DEBUG 'as_search_dokument: skipping filtration on relationer';
ELSE
	IF (coalesce(array_length(dokument_candidates,1),0)>0 OR NOT dokument_candidates_is_initialized) AND (registreringObj).relationer IS NOT NULL THEN
		FOREACH relationTypeObj IN ARRAY registreringObj.relationer
		LOOP
			dokument_candidates:=array(
			SELECT DISTINCT
			b.dokument_id 
			FROM  dokument_relation a
			JOIN dokument_registrering b on a.dokument_registrering_id=b.id
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
		( (NOT dokument_candidates_is_initialized) OR b.dokument_id = ANY (dokument_candidates) )

	);
			
			dokument_candidates_is_initialized:=true;
			

		END LOOP;
	END IF;
END IF;
--/**********************//

IF coalesce(array_length(anyRelUuidArr ,1),0)>0 THEN

	FOREACH anyRelUuid IN ARRAY anyRelUuidArr
	LOOP
		dokument_candidates:=array(
			SELECT DISTINCT
			b.dokument_id 
			FROM  dokument_relation a
			JOIN dokument_registrering b on a.dokument_registrering_id=b.id
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
		( (NOT dokument_candidates_is_initialized) OR b.dokument_id = ANY (dokument_candidates) )


			);

	dokument_candidates_is_initialized:=true;
	END LOOP;
END IF;

--/**********************//

IF coalesce(array_length(anyRelUrnArr ,1),0)>0 THEN

	FOREACH anyRelUrn IN ARRAY anyRelUrnArr
	LOOP
		dokument_candidates:=array(
			SELECT DISTINCT
			b.dokument_id 
			FROM  dokument_relation a
			JOIN dokument_registrering b on a.dokument_registrering_id=b.id
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
		( (NOT dokument_candidates_is_initialized) OR b.dokument_id = ANY (dokument_candidates) )


			);

	dokument_candidates_is_initialized:=true;
	END LOOP;
END IF;

--/**********************//


--RAISE DEBUG 'dokument_candidates_is_initialized step 5:%',dokument_candidates_is_initialized;
--RAISE DEBUG 'dokument_candidates step 5:%',dokument_candidates;

IF registreringObj IS NULL THEN
	--RAISE DEBUG 'registreringObj IS NULL';
ELSE
	IF NOT dokument_candidates_is_initialized THEN 
		dokument_candidates:=array(
		SELECT DISTINCT
			dokument_id
		FROM
			dokument_registrering b
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
		( (NOT dokument_candidates_is_initialized) OR b.dokument_id = ANY (dokument_candidates) )

		)
		;

		dokument_candidates_is_initialized:=true;
	END IF;
END IF;


IF NOT dokument_candidates_is_initialized THEN
	--No filters applied!
	dokument_candidates:=array(
		SELECT DISTINCT id FROM dokument a LIMIT maxResults
	);
ELSE
	dokument_candidates:=array(
		SELECT DISTINCT id FROM unnest(dokument_candidates) as a(id) LIMIT maxResults
		);
END IF;

--RAISE DEBUG 'dokument_candidates_is_initialized step 6:%',dokument_candidates_is_initialized;
--RAISE DEBUG 'dokument_candidates step 6:%',dokument_candidates;


return dokument_candidates;


END;
$$ LANGUAGE plpgsql STABLE; 





