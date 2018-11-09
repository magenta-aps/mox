-- Copyright (C) 2015 Magenta ApS, http://magenta.dk.
-- Contact: info@magenta.dk.
--
-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at http://mozilla.org/MPL/2.0/.

/*
NOTICE: This file is auto-generated using the script: oio_rest/apply-templates.py
*/


CREATE OR REPLACE FUNCTION _as_filter_unauth_klasse(
	klasse_uuids uuid[],
	registreringObjArr KlasseRegistreringType[]
	)
  RETURNS uuid[] AS 
$$
DECLARE
	klasse_passed_auth_filter uuid[]:=ARRAY[]::uuid[];
	klasse_candidates uuid[];
	--to_be_applyed_filter_uuids uuid[]; 
	attrEgenskaberTypeObj KlasseEgenskaberAttrType;
	
  	tilsPubliceretTypeObj KlassePubliceretTilsType;
	relationTypeObj KlasseRelationType;
	registreringObj KlasseRegistreringType;
	actual_virkning TIMESTAMPTZ:=current_timestamp;
BEGIN

--RAISE DEBUG 'step 0:registreringObj:%',registreringObj;

IF registreringObjArr IS NULL THEN
	RETURN klasse_uuids; --special case: All is allowed, no criteria present
END IF;

IF coalesce(array_length(registreringObjArr,1),0)=0 THEN
	RETURN ARRAY[]::uuid[]; --special case: Nothing is allowed. Empty list of criteria where at least one has to be met.				
END IF; 

IF klasse_uuids IS NULL OR  coalesce(array_length(klasse_uuids,1),0)=0 THEN
	RETURN ARRAY[]::uuid[]; --special case: No candidates given to filter.
END IF;



FOREACH registreringObj IN ARRAY registreringObjArr
LOOP

klasse_candidates:= klasse_uuids;



--RAISE DEBUG 'klasse_candidates_is_initialized step 1:%',klasse_candidates_is_initialized;
--RAISE DEBUG 'klasse_candidates step 1:%',klasse_candidates;
--/****************************//

--filter on attributes 
--/**********************************************************//
--Filtration on attribute: Egenskaber
--/**********************************************************//
IF registreringObj IS NULL OR (registreringObj).attrEgenskaber IS NULL THEN
	--RAISE DEBUG 'as_search_klasse: skipping filtration on attrEgenskaber';
ELSE
	IF coalesce(array_length(klasse_candidates,1),0)>0 THEN
		FOREACH attrEgenskaberTypeObj IN ARRAY registreringObj.attrEgenskaber
		LOOP
			klasse_candidates:=array(
			SELECT DISTINCT
			b.klasse_id 
			FROM  klasse_attr_egenskaber a 
			JOIN klasse_registrering b on a.klasse_registrering_id=b.id and upper((b.registrering).timeperiod)='infinity'::TIMESTAMPTZ 
			WHERE
				(
					attrEgenskaberTypeObj.brugervendtnoegle IS NULL
					OR 
					a.brugervendtnoegle = attrEgenskaberTypeObj.brugervendtnoegle 
				)
				AND
				(
					attrEgenskaberTypeObj.beskrivelse IS NULL
					OR 
					a.beskrivelse = attrEgenskaberTypeObj.beskrivelse 
				)
				AND
				(
					attrEgenskaberTypeObj.eksempel IS NULL
					OR 
					a.eksempel = attrEgenskaberTypeObj.eksempel 
				)
				AND
				(
					attrEgenskaberTypeObj.omfang IS NULL
					OR 
					a.omfang = attrEgenskaberTypeObj.omfang 
				)
				AND
				(
					attrEgenskaberTypeObj.titel IS NULL
					OR 
					a.titel = attrEgenskaberTypeObj.titel 
				)
				AND
				(
					attrEgenskaberTypeObj.retskilde IS NULL
					OR 
					a.retskilde = attrEgenskaberTypeObj.retskilde 
				)
				AND
				(
					attrEgenskaberTypeObj.aendringsnotat IS NULL
					OR 
					a.aendringsnotat = attrEgenskaberTypeObj.aendringsnotat 
				)
				AND b.klasse_id = ANY (klasse_candidates)
				AND (a.virkning).TimePeriod @> actual_virkning 
			);
			
		END LOOP;
	END IF;
END IF;
--RAISE DEBUG 'klasse_candidates_is_initialized step 3:%',klasse_candidates_is_initialized;
--RAISE DEBUG 'klasse_candidates step 3:%',klasse_candidates;

--RAISE DEBUG 'registrering,%',registreringObj;


--/**********************************************************//
--Filtration on state: Publiceret
--/**********************************************************//
IF registreringObj IS NULL OR (registreringObj).tilsPubliceret IS NULL THEN
	--RAISE DEBUG 'as_search_klasse: skipping filtration on tilsPubliceret';
ELSE
	IF coalesce(array_length(klasse_candidates,1),0)>0 THEN 

		FOREACH tilsPubliceretTypeObj IN ARRAY registreringObj.tilsPubliceret
		LOOP
			klasse_candidates:=array(
			SELECT DISTINCT
			b.klasse_id 
			FROM  klasse_tils_publiceret a
			JOIN klasse_registrering b on a.klasse_registrering_id=b.id and upper((b.registrering).timeperiod)='infinity'::TIMESTAMPTZ 
			WHERE
				(
					tilsPubliceretTypeObj.publiceret IS NULL
					OR
					tilsPubliceretTypeObj.publiceret = a.publiceret
				)
				AND b.klasse_id = ANY (klasse_candidates)
				AND (a.virkning).TimePeriod @> actual_virkning
	);
			
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


IF registreringObj IS NULL OR (registreringObj).relationer IS NULL OR coalesce(array_length((registreringObj).relationer,1),0)=0 THEN
	--RAISE DEBUG 'as_search_klasse: skipping filtration on relationer';
ELSE
	IF coalesce(array_length(klasse_candidates,1),0)>0 THEN
		FOREACH relationTypeObj IN ARRAY registreringObj.relationer
		LOOP
			klasse_candidates:=array(
			SELECT DISTINCT
			b.klasse_id 
			FROM  klasse_relation a
			JOIN klasse_registrering b on a.klasse_registrering_id=b.id and upper((b.registrering).timeperiod)='infinity'::TIMESTAMPTZ
			WHERE
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
				AND b.klasse_id = ANY (klasse_candidates)
				AND (a.virkning).TimePeriod @> actual_virkning 
	);
		END LOOP;
	END IF;
END IF;
--/**********************//

--RAISE DEBUG 'klasse_candidates_is_initialized step 5:%',klasse_candidates_is_initialized;
--RAISE DEBUG 'klasse_candidates step 5:%',klasse_candidates;

klasse_passed_auth_filter:=array(
SELECT
a.id 
FROM
unnest (klasse_passed_auth_filter) a(id)
UNION
SELECT
b.id
FROM
unnest (klasse_candidates) b(id)
);

--optimization 
IF coalesce(array_length(klasse_passed_auth_filter,1),0)=coalesce(array_length(klasse_uuids,1),0) AND klasse_passed_auth_filter @>klasse_uuids THEN
	RETURN klasse_passed_auth_filter;
END IF;


END LOOP; --LOOP registreringObj


RETURN klasse_passed_auth_filter;


END;
$$ LANGUAGE plpgsql STABLE; 





