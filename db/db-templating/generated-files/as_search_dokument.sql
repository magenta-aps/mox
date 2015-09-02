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
	anyuuidArr	uuid[] = '{}'::uuid[],
	anyurnArr text[] = '{}'::text[],
	auth_criteria_arr DokumentRegistreringType[]=null
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
	anyuuid uuid;
	anyurn text;
	variantTypeObj DokumentVariantType;
	variantEgenskaberTypeObj DokumentVariantEgenskaberType;
	delTypeObj DokumentDelType;
	delEgenskaberTypeObj DokumentDelEgenskaberType;
	delRelationTypeObj DokumentdelRelationType;
	variant_candidates_ids bigint[];
	variant_candidates_is_initialized boolean;
	auth_filtered_uuids uuid[];
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
			FROM  dokument_registrering b 
			LEFT JOIN dokument_attr_egenskaber a on a.dokument_registrering_id=b.id and (virkningSoeg IS NULL or virkningSoeg && (a.virkning).TimePeriod )
			LEFT JOIN dokument_variant c on c.dokument_registrering_id=b.id 
			LEFT JOIN dokument_del f on f.variant_id=c.id
			LEFT JOIN dokument_del_egenskaber d on d.del_id = f.id and (virkningSoeg IS NULL or virkningSoeg && (d.virkning).TimePeriod )
			LEFT JOIN dokument_variant_egenskaber e on e.variant_id = c.id and (virkningSoeg IS NULL or virkningSoeg && (e.virkning).TimePeriod )
			WHERE
			(
				(
					a.brugervendtnoegle ILIKE anyAttrValue OR
						a.beskrivelse ILIKE anyAttrValue OR
									a.brevdato::text ilike anyAttrValue OR
						a.kassationskode ILIKE anyAttrValue OR
									a.major::text ilike anyAttrValue OR
									a.minor::text ilike anyAttrValue OR
									(a.offentlighedundtaget).Hjemmel ilike anyAttrValue OR (a.offentlighedundtaget).AlternativTitel ilike anyAttrValue OR
						a.titel ILIKE anyAttrValue OR
						a.dokumenttype ILIKE anyAttrValue
				)
				OR
				(
					( c.varianttekst ilike anyAttrValue and e.id is not null) --varianttekst handled like it is logically part of variant egenskaber
				)
				OR
				(
					( f.deltekst ilike anyAttrValue and d.id is not null ) --deltekst handled like it is logically part of del egenskaber
					OR
					d.indeks::text = anyAttrValue
					OR
					d.indhold ILIKE anyAttrValue
					OR
					d.lokation ILIKE anyAttrValue
					OR
					d.mimetype ILIKE anyAttrValue
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
								(tilsFremdriftTypeObj.virkning).NoteTekst IS NULL OR (a.virkning).NoteTekst ILIKE (tilsFremdriftTypeObj.virkning).NoteTekst
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
		( (NOT dokument_candidates_is_initialized) OR b.dokument_id = ANY (dokument_candidates) )

	);
			
			dokument_candidates_is_initialized:=true;
			

		END LOOP;
	END IF;
END IF;
--/**********************//

IF coalesce(array_length(anyuuidArr ,1),0)>0 THEN

	FOREACH anyuuid IN ARRAY anyuuidArr
	LOOP
		dokument_candidates:=array(
			SELECT DISTINCT
			b.dokument_id 
 			FROM dokument_registrering b  
 			LEFT JOIN dokument_relation a on a.dokument_registrering_id=b.id and (virkningSoeg IS NULL or (virkningSoeg && (a.virkning).TimePeriod) )
 			LEFT JOIN dokument_variant c on c.dokument_registrering_id=b.id
 			LEFT JOIN dokument_del d on d.variant_id=c.id 
 			LEFT JOIN dokument_del_relation e on d.id=e.del_id and (virkningSoeg IS NULL or (virkningSoeg && (e.virkning).TimePeriod) )
  			WHERE
 			(anyuuid = a.rel_maal_uuid OR anyuuid = e.rel_maal_uuid)
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

IF coalesce(array_length(anyurnArr ,1),0)>0 THEN

	FOREACH anyurn IN ARRAY anyurnArr
	LOOP
		dokument_candidates:=array(
			SELECT DISTINCT
			b.dokument_id 
 			FROM dokument_registrering b  
 			LEFT JOIN dokument_relation a on a.dokument_registrering_id=b.id and (virkningSoeg IS NULL or virkningSoeg && (a.virkning).TimePeriod )
 			LEFT JOIN dokument_variant c on c.dokument_registrering_id=b.id
 			LEFT JOIN dokument_del d on d.variant_id=c.id
 			LEFT JOIN dokument_del_relation e on d.id=e.del_id and (virkningSoeg IS NULL or virkningSoeg && (e.virkning).TimePeriod)
  			WHERE
 			(anyurn = a.rel_maal_urn OR anyurn = e.rel_maal_urn)
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

--/**********************************************************//
--Filtration on variants and document parts (dele)
--/**********************************************************//


IF registreringObj IS NULL OR (registreringObj).varianter IS NULL THEN
	--RAISE DEBUG 'as_search_dokument: skipping filtration on relationer';
ELSE
		IF (registreringObj).varianter IS NOT NULL AND coalesce(array_length(registreringObj.varianter,1),0)>0  THEN
		FOREACH variantTypeObj IN ARRAY registreringObj.varianter
		LOOP

		variant_candidates_ids=array[]::bigint[];
		variant_candidates_is_initialized:=false;

		IF (coalesce(array_length(dokument_candidates,1),0)>0 OR NOT dokument_candidates_is_initialized) THEN 

		--HACK: As variant_name logically can be said to be part of variant egenskaber (regarding virkning), we'll force a filter on variant egenskaber if needed
		IF coalesce(array_length(variantTypeObj.egenskaber,1),0)=0 AND variantTypeObj.varianttekst IS NOT NULL THEN
			variantTypeObj.egenskaber:=ARRAY[ROW(null,null,null,null,null)::DokumentVariantEgenskaberType]::DokumentVariantEgenskaberType[];
		END IF;

		IF coalesce(array_length(variantTypeObj.egenskaber,1),0)>0 THEN
		
		FOREACH variantEgenskaberTypeObj in ARRAY variantTypeObj.egenskaber
		LOOP

		IF (coalesce(array_length(variant_candidates_ids,1),0)>0 OR not variant_candidates_is_initialized) THEN

			IF  variantTypeObj.varianttekst IS NOT NULL OR
				(
					(NOT (variantEgenskaberTypeObj.arkivering IS NULL))
					OR
					(NOT (variantEgenskaberTypeObj.delvisscannet IS NULL))
					OR
					(NOT (variantEgenskaberTypeObj.offentliggoerelse IS NULL))
					OR
					(NOT (variantEgenskaberTypeObj.produktion IS NULL))
				)
			 THEN --test if there is any data availiable for variant to filter on
			

			--part for searching on variant + egenskaber
			variant_candidates_ids:=array(
			SELECT DISTINCT
			a.id
			FROM  dokument_variant a
			JOIN dokument_registrering b on a.dokument_registrering_id=b.id
			JOIN dokument_variant_egenskaber c on c.variant_id=a.id  --we require the presence egenskaber (variant name is logically part of it)
			WHERE
			(
				variantTypeObj.varianttekst IS NULL
				OR
				a.varianttekst ilike variantTypeObj.varianttekst
			)
			AND
			(
				(
				virkningSoeg IS NULL
				OR
				virkningSoeg && (c.virkning).TimePeriod
				)
			)
			AND
			(
				(
				variantEgenskaberTypeObj.virkning IS NULL
				OR 
				(variantEgenskaberTypeObj.virkning).TimePeriod && (c.virkning).TimePeriod 
				)
			)
			AND
				(
				variantEgenskaberTypeObj.virkning IS NULL
				OR
					(
						(
								(variantEgenskaberTypeObj.virkning).AktoerRef IS NULL OR (c.virkning).AktoerRef = (variantEgenskaberTypeObj.virkning).AktoerRef
						)
						AND
						(
								(variantEgenskaberTypeObj.virkning).AktoerTypeKode IS NULL OR (variantEgenskaberTypeObj.virkning).AktoerTypeKode=(c.virkning).AktoerTypeKode
						)
						AND
						(
								(variantEgenskaberTypeObj.virkning).NoteTekst IS NULL OR (c.virkning).NoteTekst ilike (variantEgenskaberTypeObj.virkning).NoteTekst
						)
					)
				)
			AND
			(
				
				(
					variantEgenskaberTypeObj.arkivering IS NULL
					OR
					variantEgenskaberTypeObj.arkivering = c.arkivering
				)
				AND
				(
					variantEgenskaberTypeObj.delvisscannet IS NULL
					OR
					variantEgenskaberTypeObj.delvisscannet = c.delvisscannet
				)
				AND
				(
					variantEgenskaberTypeObj.offentliggoerelse IS NULL 
					OR
					variantEgenskaberTypeObj.offentliggoerelse = c.offentliggoerelse
				)
				AND
				(
					variantEgenskaberTypeObj.produktion IS NULL  
					OR
					variantEgenskaberTypeObj.produktion = c.produktion
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
		( (NOT dokument_candidates_is_initialized) OR b.dokument_id = ANY (dokument_candidates) )

			AND ( (NOT variant_candidates_is_initialized) OR a.id = ANY (variant_candidates_ids) )
			);

			variant_candidates_is_initialized:=true;

			END IF; --any variant candidates left

			END IF; --variant filter criterium exists
			END LOOP; --variant egenskaber

			
			END IF;--variantTypeObj.egenskaber exists  

			/**************    Dokument Dele        ******************/

			IF coalesce(array_length(variantTypeObj.dele,1),0)>0 THEN
			
			FOREACH delTypeObj IN ARRAY variantTypeObj.dele 
			LOOP

			--HACK: As del_name logically can be said to be part of del egenskaber (regarding virkning), we'll force a filter on del egenskaber if needed
			IF coalesce(array_length(delTypeObj.egenskaber,1),0)=0 AND delTypeObj.deltekst IS NOT NULL THEN
				delTypeObj.egenskaber:=ARRAY[ROW(null,null,null,null,null)::DokumentDelEgenskaberType]::DokumentDelEgenskaberType[];
			END IF;


			/**************    Dokument Del Egenskaber    ******************/

			IF coalesce(array_length(delTypeObj.egenskaber,1),0)>0 THEN 
			
			FOREACH delEgenskaberTypeObj IN ARRAY delTypeObj.egenskaber
			LOOP
			
			IF delTypeObj.deltekst IS NOT NULL  	
			OR (NOT delEgenskaberTypeObj.indeks IS NULL)
			OR delEgenskaberTypeObj.indhold IS NOT NULL
			OR delEgenskaberTypeObj.lokation IS NOT NULL
			OR delEgenskaberTypeObj.mimetype IS NOT NULL
			THEN 

			IF (coalesce(array_length(variant_candidates_ids,1),0)>0 OR not variant_candidates_is_initialized) THEN

			variant_candidates_ids:=array(
			SELECT DISTINCT
			a.id
			FROM  dokument_variant a
			JOIN dokument_registrering b on a.dokument_registrering_id=b.id
			JOIN dokument_del c on c.variant_id=a.id
			JOIN dokument_del_egenskaber d on d.del_id=c.id --we require the presence egenskaber (del name is logically part of it)
		
			WHERE
			(
				delTypeObj.deltekst IS NULL
				OR
				c.deltekst ilike delTypeObj.deltekst
			)
			AND
			(
				virkningSoeg IS NULL
				OR
				virkningSoeg && (d.virkning).TimePeriod
			)
			AND
			(
				delEgenskaberTypeObj.virkning IS NULL --NOTICE only looking at first del egenskaber object throughout
				OR 
				(delEgenskaberTypeObj.virkning).TimePeriod && (d.virkning).TimePeriod 
			)
			AND
			(
				delEgenskaberTypeObj.virkning IS NULL
				OR
					(
						(
								(delEgenskaberTypeObj.virkning).AktoerRef IS NULL OR (d.virkning).AktoerRef = (delEgenskaberTypeObj.virkning).AktoerRef
						)
						AND
						(
								(delEgenskaberTypeObj.virkning).AktoerTypeKode IS NULL OR (delEgenskaberTypeObj.virkning).AktoerTypeKode=(d.virkning).AktoerTypeKode
						)
						AND
						(
								(delEgenskaberTypeObj.virkning).NoteTekst IS NULL OR (d.virkning).NoteTekst ilike (delEgenskaberTypeObj.virkning).NoteTekst
						)
					)
			)
			AND
			(
				(
					(
						delEgenskaberTypeObj.indeks IS NULL  
						OR
						delEgenskaberTypeObj.indeks = d.indeks
					)
					AND
					(
						delEgenskaberTypeObj.indhold IS NULL  
						OR
						d.indhold ilike delEgenskaberTypeObj.indhold  
					)
					AND
					(
						delEgenskaberTypeObj.lokation IS NULL 
						OR
						d.lokation ilike delEgenskaberTypeObj.lokation 
					)
					AND
					(
						delEgenskaberTypeObj.mimetype IS NULL 
						OR
						d.mimetype ilike delEgenskaberTypeObj.mimetype
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
		( (NOT dokument_candidates_is_initialized) OR b.dokument_id = ANY (dokument_candidates) )

			AND ( (NOT variant_candidates_is_initialized) OR a.id = ANY (variant_candidates_ids) )
			);

			variant_candidates_is_initialized:=true;
			END IF; --any variant candidates left
			END IF; --del egenskaber not empty
			END LOOP; --loop del egenskaber
			END IF; -- del egenskaber exists

			/**************    Dokument Del Relationer    ******************/

			IF coalesce(array_length(delTypeObj.relationer,1),0)>0 THEN 
			
			FOREACH delRelationTypeObj IN ARRAY delTypeObj.relationer
			LOOP

			IF (coalesce(array_length(variant_candidates_ids,1),0)>0 OR not variant_candidates_is_initialized) THEN

			variant_candidates_ids:=array(
			SELECT DISTINCT
			a.id
			FROM  dokument_variant a
			JOIN dokument_registrering b on a.dokument_registrering_id=b.id
			JOIN dokument_del c on c.variant_id=a.id
			JOIN dokument_del_relation d on d.del_id=c.id
			WHERE
			(
				delTypeObj.deltekst IS NULL
				OR
				c.deltekst ilike delTypeObj.deltekst
			)
			AND
			(
				virkningSoeg IS NULL
				OR
				virkningSoeg && (d.virkning).TimePeriod
			)
			AND
			(
				delRelationTypeObj.virkning IS NULL 
				OR 
				(delRelationTypeObj.virkning).TimePeriod && (d.virkning).TimePeriod 
			)
			AND
			(
				delRelationTypeObj.virkning IS NULL
				OR
					(
						(
								(delRelationTypeObj.virkning).AktoerRef IS NULL OR (d.virkning).AktoerRef = (delRelationTypeObj.virkning).AktoerRef
						)
						AND
						(
								(delRelationTypeObj.virkning).AktoerTypeKode IS NULL OR (delRelationTypeObj.virkning).AktoerTypeKode=(d.virkning).AktoerTypeKode
						)
						AND
						(
								(delRelationTypeObj.virkning).NoteTekst IS NULL OR (d.virkning).NoteTekst ilike (delRelationTypeObj.virkning).NoteTekst
						)
					)
			)
			AND
			(	
				delRelationTypeObj.relType IS NULL
				OR
				delRelationTypeObj.relType = d.rel_type
			)
			AND
			(
				delRelationTypeObj.uuid IS NULL
				OR
				delRelationTypeObj.uuid = d.rel_maal_uuid	
			)
			AND
			(
				delRelationTypeObj.objektType IS NULL
				OR
				delRelationTypeObj.objektType = d.objekt_type
			)
			AND
			(
				delRelationTypeObj.urn IS NULL
				OR
				delRelationTypeObj.urn = d.rel_maal_urn
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

			AND ( (NOT variant_candidates_is_initialized) OR a.id = ANY (variant_candidates_ids) )
			);
			
			variant_candidates_is_initialized:=true;

			END IF; --any variant candidates left

			END LOOP; --loop del relationer
			END IF; --end if del relationer exists

			END LOOP; --loop del
			END IF;--dele exists


			
			IF variant_candidates_is_initialized THEN
			--We'll then translate the collected variant ids into document ids (please notice that the resulting uuids are already a subset of dokument_candidates)

			dokument_candidates:=array(
			SELECT DISTINCT
			b.dokument_id 
			FROM  dokument_variant a
			JOIN dokument_registrering b on a.dokument_registrering_id=b.id
			WHERE
			a.id = ANY (variant_candidates_ids)
			AND
			( (NOT dokument_candidates_is_initialized) OR b.dokument_id = ANY (dokument_candidates) )
			);

			dokument_candidates_is_initialized:=true;
			
			END IF; --variant_candidates_is_initialized

			END IF; --no doc candidates - skipping ahead;
			END LOOP; --FOREACH variantTypeObj
		
		END IF; --varianter exists
	END IF; --array registreringObj.varianter exists 



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


										 
/*** Filter out the objects that does not meets the stipulated access criteria  ***/
auth_filtered_uuids:=_as_filter_unauth_dokument(dokument_candidates,auth_criteria_arr); 
/*********************/


return auth_filtered_uuids;


END;
$$ LANGUAGE plpgsql STABLE; 





