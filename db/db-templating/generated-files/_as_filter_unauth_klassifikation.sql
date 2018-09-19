-- Copyright (C) 2015 Magenta ApS, http://magenta.dk.
-- Contact: info@magenta.dk.
--
-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at http://mozilla.org/MPL/2.0/.

/*
NOTICE: This file is auto-generated using the script: oio_rest/apply-templates.py
*/


CREATE OR REPLACE FUNCTION _as_filter_unauth_klassifikation(
	klassifikation_uuids uuid[],
	registreringObjArr KlassifikationRegistreringType[]
	)
  RETURNS uuid[] AS 
$$
DECLARE
	klassifikation_passed_auth_filter uuid[]:=ARRAY[]::uuid[];
	klassifikation_candidates uuid[];
	--to_be_applyed_filter_uuids uuid[]; 
	attrEgenskaberTypeObj KlassifikationEgenskaberAttrType;
	
  	tilsPubliceretTypeObj KlassifikationPubliceretTilsType;
	relationTypeObj KlassifikationRelationType;
	registreringObj KlassifikationRegistreringType;
	actual_virkning TIMESTAMPTZ:=current_timestamp;
BEGIN

--RAISE DEBUG 'step 0:registreringObj:%',registreringObj;

IF registreringObjArr IS NULL THEN
	RETURN klassifikation_uuids; --special case: All is allowed, no criteria present
END IF;

IF coalesce(array_length(registreringObjArr,1),0)=0 THEN
	RETURN ARRAY[]::uuid[]; --special case: Nothing is allowed. Empty list of criteria where at least one has to be met.				
END IF; 

IF klassifikation_uuids IS NULL OR  coalesce(array_length(klassifikation_uuids,1),0)=0 THEN
	RETURN ARRAY[]::uuid[]; --special case: No candidates given to filter.
END IF;



FOREACH registreringObj IN ARRAY registreringObjArr
LOOP

klassifikation_candidates:= klassifikation_uuids;



--RAISE DEBUG 'klassifikation_candidates_is_initialized step 1:%',klassifikation_candidates_is_initialized;
--RAISE DEBUG 'klassifikation_candidates step 1:%',klassifikation_candidates;
--/****************************//

--filter on attributes 
--/**********************************************************//
--Filtration on attribute: Egenskaber
--/**********************************************************//
IF registreringObj IS NULL OR (registreringObj).attrEgenskaber IS NULL THEN
	--RAISE DEBUG 'as_search_klassifikation: skipping filtration on attrEgenskaber';
ELSE
	IF coalesce(array_length(klassifikation_candidates,1),0)>0 THEN
		FOREACH attrEgenskaberTypeObj IN ARRAY registreringObj.attrEgenskaber
		LOOP
			klassifikation_candidates:=array(
			SELECT DISTINCT
			b.klassifikation_id 
			FROM  klassifikation_attr_egenskaber a 
			JOIN klassifikation_registrering b on a.klassifikation_registrering_id=b.id and upper((b.registrering).timeperiod)='infinity'::TIMESTAMPTZ 
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
					attrEgenskaberTypeObj.kaldenavn IS NULL
					OR 
					a.kaldenavn = attrEgenskaberTypeObj.kaldenavn 
				)
				AND
				(
					attrEgenskaberTypeObj.ophavsret IS NULL
					OR 
					a.ophavsret = attrEgenskaberTypeObj.ophavsret 
				)
				AND b.klassifikation_id = ANY (klassifikation_candidates)
				AND (a.virkning).TimePeriod @> actual_virkning 
			);
			
		END LOOP;
	END IF;
END IF;
--RAISE DEBUG 'klassifikation_candidates_is_initialized step 3:%',klassifikation_candidates_is_initialized;
--RAISE DEBUG 'klassifikation_candidates step 3:%',klassifikation_candidates;

--RAISE DEBUG 'registrering,%',registreringObj;


--/**********************************************************//
--Filtration on state: Publiceret
--/**********************************************************//
IF registreringObj IS NULL OR (registreringObj).tilsPubliceret IS NULL THEN
	--RAISE DEBUG 'as_search_klassifikation: skipping filtration on tilsPubliceret';
ELSE
	IF coalesce(array_length(klassifikation_candidates,1),0)>0 THEN 

		FOREACH tilsPubliceretTypeObj IN ARRAY registreringObj.tilsPubliceret
		LOOP
			klassifikation_candidates:=array(
			SELECT DISTINCT
			b.klassifikation_id 
			FROM  klassifikation_tils_publiceret a
			JOIN klassifikation_registrering b on a.klassifikation_registrering_id=b.id and upper((b.registrering).timeperiod)='infinity'::TIMESTAMPTZ 
			WHERE
				(
					tilsPubliceretTypeObj.publiceret IS NULL
					OR
					tilsPubliceretTypeObj.publiceret = a.publiceret
				)
				AND b.klassifikation_id = ANY (klassifikation_candidates)
				AND (a.virkning).TimePeriod @> actual_virkning
	);
			
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


IF registreringObj IS NULL OR (registreringObj).relationer IS NULL OR coalesce(array_length((registreringObj).relationer,1),0)=0 THEN
	--RAISE DEBUG 'as_search_klassifikation: skipping filtration on relationer';
ELSE
	IF coalesce(array_length(klassifikation_candidates,1),0)>0 THEN
		FOREACH relationTypeObj IN ARRAY registreringObj.relationer
		LOOP
			klassifikation_candidates:=array(
			SELECT DISTINCT
			b.klassifikation_id 
			FROM  klassifikation_relation a
			JOIN klassifikation_registrering b on a.klassifikation_registrering_id=b.id and upper((b.registrering).timeperiod)='infinity'::TIMESTAMPTZ
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
				AND b.klassifikation_id = ANY (klassifikation_candidates)
				AND (a.virkning).TimePeriod @> actual_virkning 
	);
		END LOOP;
	END IF;
END IF;
--/**********************//

--RAISE DEBUG 'klassifikation_candidates_is_initialized step 5:%',klassifikation_candidates_is_initialized;
--RAISE DEBUG 'klassifikation_candidates step 5:%',klassifikation_candidates;

klassifikation_passed_auth_filter:=array(
SELECT
a.id 
FROM
unnest (klassifikation_passed_auth_filter) a(id)
UNION
SELECT
b.id
FROM
unnest (klassifikation_candidates) b(id)
);

--optimization 
IF coalesce(array_length(klassifikation_passed_auth_filter,1),0)=coalesce(array_length(klassifikation_uuids,1),0) AND klassifikation_passed_auth_filter @>klassifikation_uuids THEN
	RETURN klassifikation_passed_auth_filter;
END IF;


END LOOP; --LOOP registreringObj


RETURN klassifikation_passed_auth_filter;


END;
$$ LANGUAGE plpgsql STABLE; 





