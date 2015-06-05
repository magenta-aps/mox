-- Copyright (C) 2015 Magenta ApS, http://magenta.dk.
-- Contact: info@magenta.dk.
--
-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at http://mozilla.org/MPL/2.0/.

/*
NOTICE: This file is auto-generated using the script: apply-template.py klasse as_search.jinja.sql
*/


CREATE OR REPLACE FUNCTION as_search_klasse(
	firstResult int,--TOOD ??
	klasse_uuid uuid,
	registreringObj KlasseRegistreringType,
	virkningSoeg TSTZRANGE,
	maxResults int = 2147483647
	)
  RETURNS uuid[] AS 
$$
DECLARE
	klasse_candidates uuid[];
	klasse_candidates_is_initialized boolean;
	to_be_applyed_filter_uuids uuid[]; 
	attrEgenskaberTypeObj KlasseEgenskaberAttrType;
	
  	tilsPubliceretTypeObj KlassePubliceretTilsType;
	relationTypeObj KlasseRelationType;
	manipulatedAttrEgenskaberArr KlasseEgenskaberAttrType[]:='{}';
	soegeordObj KlasseSoegeordType;
BEGIN

--RAISE DEBUG 'step 0:registreringObj:%',registreringObj;

klasse_candidates_is_initialized := false;


IF klasse_uuid is not NULL THEN
	klasse_candidates:= ARRAY[klasse_uuid];
	klasse_candidates_is_initialized:=true;
END IF;


--RAISE DEBUG 'klasse_candidates_is_initialized step 1:%',klasse_candidates_is_initialized;
--RAISE DEBUG 'klasse_candidates step 1:%',klasse_candidates;
--/****************************//
--filter on registration

IF registreringObj IS NULL OR (registreringObj).registrering IS NULL THEN
	--RAISE DEBUG 'as_search_klasse: skipping filtration on registrering';
ELSE
	IF
	(
		(registreringObj.registrering).timeperiod IS NOT NULL  
		OR
		(registreringObj.registrering).livscykluskode IS NOT NULL
		OR
		(registreringObj.registrering).brugerref IS NOT NULL
		OR
		(registreringObj.registrering).note IS NOT NULL
	) THEN

		to_be_applyed_filter_uuids:=array(
		SELECT DISTINCT
			klasse_uuid
		FROM
			klasse_registrering b
		WHERE
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
		);


		IF klasse_candidates_is_initialized THEN
			klasse_candidates:= array(SELECT DISTINCT id from unnest(klasse_candidates) as a(id) INTERSECT SELECT DISTINCT id from unnest(to_be_applyed_filter_uuids) as b(id) );
		ELSE
			klasse_candidates:=to_be_applyed_filter_uuids;
			klasse_candidates_is_initialized:=true;
		END IF;

	END IF;
END IF;

--RAISE NOTICE 'klasse_candidates_is_initialized step 2:%',klasse_candidates_is_initialized;
--RAISE NOTICE 'klasse_candidates step 2:%',klasse_candidates;

--/****************************//
--filter on attributes 
--/**********************************************************//
--Filtration on attribute: Egenskaber
--/**********************************************************//
IF registreringObj IS NULL OR (registreringObj).attrEgenskaber IS NULL THEN
	--RAISE DEBUG 'as_search_klasse: skipping filtration on attrEgenskaber';
ELSE

--To help facilitate the comparrison efforts (while diverging at a minimum form the templated db-kode, 
--we'll manipulate the attrEgenskaber array so to make sure that every object only has 1 sogeord element - duplicating the parent elements in attrEgenskaber as needed  )

FOREACH attrEgenskaberTypeObj IN ARRAY registreringObj.attrEgenskaber
LOOP
	IF  (attrEgenskaberTypeObj).soegeord IS NULL OR coalesce(array_length((attrEgenskaberTypeObj).soegeord,1),0)<2 THEN
	manipulatedAttrEgenskaberArr:=array_append(manipulatedAttrEgenskaberArr,attrEgenskaberTypeObj); --The element only has 0 or 1 soegeord element, så no manipulations is needed.
	ELSE
		FOREACH soegeordObj IN ARRAY (attrEgenskaberTypeObj).soegeord
		LOOP
			manipulatedAttrEgenskaberArr:=array_append(manipulatedAttrEgenskaberArr,
				ROW (
					attrEgenskaberTypeObj.brugervendtnoegle,
					attrEgenskaberTypeObj.beskrivelse,
					attrEgenskaberTypeObj.eksempel,
					attrEgenskaberTypeObj.omfang,
					attrEgenskaberTypeObj.titel,
					attrEgenskaberTypeObj.retskilde,
					attrEgenskaberTypeObj.aendringsnotat,
					ARRAY[soegeordObj]::KlasseSoegeordType[], --NOTICE: Only 1 element in array
					attrEgenskaberTypeObj.virkning
					)::KlasseEgenskaberAttrType
				);
		END LOOP;
	END IF;
END LOOP;


	IF (coalesce(array_length(klasse_candidates,1),0)>0 OR NOT klasse_candidates_is_initialized) THEN
		FOREACH attrEgenskaberTypeObj IN ARRAY manipulatedAttrEgenskaberArr
		LOOP
			to_be_applyed_filter_uuids:=array(
			SELECT DISTINCT
			b.klasse_id 
			FROM  klasse_attr_egenskaber a
			JOIN klasse_registrering b on a.klasse_registrering_id=b.id
			LEFT JOIN klasse_attr_egenskaber_soegeord c on a.id=c.klasse_attr_egenskaber_id
			WHERE
				(
					attrEgenskaberTypeObj.virkning IS NULL
					OR
					(
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
					attrEgenskaberTypeObj.eksempel IS NULL
					OR
					attrEgenskaberTypeObj.eksempel = a.eksempel
				)
				AND
				(
					attrEgenskaberTypeObj.omfang IS NULL
					OR
					attrEgenskaberTypeObj.omfang = a.omfang
				)
				AND
				(
					attrEgenskaberTypeObj.titel IS NULL
					OR
					attrEgenskaberTypeObj.titel = a.titel
				)
				AND
				(
					attrEgenskaberTypeObj.retskilde IS NULL
					OR
					attrEgenskaberTypeObj.retskilde = a.retskilde
				)
				AND
				(
					attrEgenskaberTypeObj.aendringsnotat IS NULL
					OR
					attrEgenskaberTypeObj.aendringsnotat = a.aendringsnotat
				)
				AND
				(
					(attrEgenskaberTypeObj.soegeord IS NULL OR array_length(attrEgenskaberTypeObj.soegeord,1)=0)
					OR
					(
						(
							(attrEgenskaberTypeObj.soegeord[1]).soegeordidentifikator IS NULL
							OR
							(attrEgenskaberTypeObj.soegeord[1]).soegeordidentifikator = c.soegeordidentifikator
						)
						AND
						(
							(attrEgenskaberTypeObj.soegeord[1]).beskrivelse IS NULL
							OR
							(attrEgenskaberTypeObj.soegeord[1]).beskrivelse = c.beskrivelse
						)		
						AND
						(
							(attrEgenskaberTypeObj.soegeord[1]).soegeordskategori IS NULL
							OR
							(attrEgenskaberTypeObj.soegeord[1]).soegeordskategori = c.soegeordskategori
						)
					)
				)
		);
		
			

			IF klasse_candidates_is_initialized THEN
				klasse_candidates:= array(SELECT DISTINCT id from unnest(klasse_candidates) as a(id) INTERSECT SELECT DISTINCT b.id from unnest(to_be_applyed_filter_uuids) as b(id) );
			ELSE
				klasse_candidates:=to_be_applyed_filter_uuids;
				klasse_candidates_is_initialized:=true;
			END IF;

		END LOOP;
	END IF;
END IF;
--RAISE DEBUG 'klasse_candidates_is_initialized step 3:%',klasse_candidates_is_initialized;
--RAISE DEBUG 'klasse_candidates step 3:%',klasse_candidates;

--/****************************//


--filter on states -- publiceret
--RAISE DEBUG 'registrering,%',registreringObj;


--/**********************************************************//
--Filtration on state: Publiceret
--/**********************************************************//
IF registreringObj IS NULL OR (registreringObj).tilsPubliceret IS NULL THEN
	--RAISE DEBUG 'as_search_klasse: skipping filtration on tilsPubliceret';
ELSE
	IF (coalesce(array_length(klasse_candidates,1),0)>0 OR klasse_candidates_is_initialized IS FALSE ) THEN 

		FOREACH tilsPubliceretTypeObj IN ARRAY registreringObj.tilsPubliceret
		LOOP
			to_be_applyed_filter_uuids:=array(
			SELECT DISTINCT
			b.klasse_id 
			FROM  klasse_tils_publiceret a
			JOIN klasse_registrering b on a.klasse_registrering_id=b.id
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
	);
			

			IF klasse_candidates_is_initialized THEN
				klasse_candidates:= array(SELECT DISTINCT id from unnest(klasse_candidates) as a(id) INTERSECT SELECT DISTINCT b.id from unnest(to_be_applyed_filter_uuids) as b(id) );
			ELSE
				klasse_candidates:=to_be_applyed_filter_uuids;
				klasse_candidates_is_initialized:=true;
			END IF;

		END LOOP;
	END IF;
END IF;

/*
--relationer KlasseRelationType[]
*/


--RAISE DEBUG 'klasse_candidates_is_initialized step 4:%',klasse_candidates_is_initialized;
--RAISE DEBUG 'klasse_candidates step 4:%',klasse_candidates;

--/**********************************************************//
--Filtration on relations
--/**********************************************************//


IF registreringObj IS NULL OR (registreringObj).relationer IS NULL THEN
	--RAISE DEBUG 'as_search_klasse: skipping filtration on relationer';
ELSE
	IF (coalesce(array_length(klasse_candidates,1),0)>0 OR NOT klasse_candidates_is_initialized) AND (registreringObj).relationer IS NOT NULL THEN
		FOREACH relationTypeObj IN ARRAY registreringObj.relationer
		LOOP
			to_be_applyed_filter_uuids:=array(
			SELECT DISTINCT
			b.klasse_id 
			FROM  klasse_relation a
			JOIN klasse_registrering b on a.klasse_registrering_id=b.id
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
	);
			

			IF klasse_candidates_is_initialized THEN
				klasse_candidates:= array(SELECT DISTINCT id from unnest(klasse_candidates) as a(id) INTERSECT SELECT DISTINCT b.id from unnest(to_be_applyed_filter_uuids) as b(id) );
			ELSE
				klasse_candidates:=to_be_applyed_filter_uuids;
				klasse_candidates_is_initialized:=true;
			END IF;

		END LOOP;
	END IF;
END IF;
--/**********************//

--RAISE DEBUG 'klasse_candidates_is_initialized step 5:%',klasse_candidates_is_initialized;
--RAISE DEBUG 'klasse_candidates step 5:%',klasse_candidates;


IF NOT klasse_candidates_is_initialized THEN
	--No filters applied!
	klasse_candidates:=array(
		SELECT DISTINCT id FROM klasse a LIMIT maxResults
	);
ELSE
	klasse_candidates:=array(
		SELECT DISTINCT id FROM unnest(klasse_candidates) as a(id) LIMIT maxResults
		);
END IF;

--RAISE DEBUG 'klasse_candidates_is_initialized step 6:%',klasse_candidates_is_initialized;
--RAISE DEBUG 'klasse_candidates step 6:%',klasse_candidates;


return klasse_candidates;


END;
$$ LANGUAGE plpgsql STABLE; 





