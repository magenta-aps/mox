-- Copyright (C) 2015 Magenta ApS, http://magenta.dk.
-- Contact: info@magenta.dk.
--
-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at http://mozilla.org/MPL/2.0/.

/*
NOTICE: This file is auto-generated using the script: apply-template.py facet _as_filter_unauth.jinja.sql
*/


CREATE OR REPLACE FUNCTION _as_filter_unauth_facet(
	facet_uuids uuid[],
	registreringObjArr FacetRegistreringType[]
	)
  RETURNS uuid[] AS 
$$
DECLARE
	facet_passed_auth_filter uuid[]:=ARRAY[]::uuid[];
	facet_candidates uuid[];
	--to_be_applyed_filter_uuids uuid[]; 
	attrEgenskaberTypeObj FacetEgenskaberAttrType;
	
  	tilsPubliceretTypeObj FacetPubliceretTilsType;
	relationTypeObj FacetRelationType;
	registreringObj FacetRegistreringType;
	actual_virkning TIMESTAMPTZ:=current_timestamp;
BEGIN

--RAISE DEBUG 'step 0:registreringObj:%',registreringObj;

IF registreringObjArr IS NULL THEN
	RETURN facet_uuids; --special case: All is allowed, no criteria present
END IF;

IF coalesce(array_length(registreringObjArr,1),0)=0 THEN
	RETURN ARRAY[]::uuid[]; --special case: Nothing is allowed. Empty list of criteria where at least one has to be met.				
END IF; 

IF facet_uuids IS NULL OR  coalesce(array_length(facet_uuids,1),0)=0 THEN
	RETURN ARRAY[]::uuid[]; --special case: No candidates given to filter.
END IF;



FOREACH registreringObj IN ARRAY registreringObjArr
LOOP

facet_candidates:= facet_uuids;



--RAISE DEBUG 'facet_candidates_is_initialized step 1:%',facet_candidates_is_initialized;
--RAISE DEBUG 'facet_candidates step 1:%',facet_candidates;
--/****************************//

--filter on attributes 
--/**********************************************************//
--Filtration on attribute: Egenskaber
--/**********************************************************//
IF registreringObj IS NULL OR (registreringObj).attrEgenskaber IS NULL THEN
	--RAISE DEBUG 'as_search_facet: skipping filtration on attrEgenskaber';
ELSE
	IF coalesce(array_length(facet_candidates,1),0)>0 THEN
		FOREACH attrEgenskaberTypeObj IN ARRAY registreringObj.attrEgenskaber
		LOOP
			facet_candidates:=array(
			SELECT DISTINCT
			b.facet_id 
			FROM  facet_attr_egenskaber a 
			JOIN facet_registrering b on a.facet_registrering_id=b.id and upper((b.registrering).timeperiod)='infinity'::TIMESTAMPTZ 
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
					attrEgenskaberTypeObj.opbygning IS NULL
					OR 
					a.opbygning = attrEgenskaberTypeObj.opbygning 
				)
				AND
				(
					attrEgenskaberTypeObj.ophavsret IS NULL
					OR 
					a.ophavsret = attrEgenskaberTypeObj.ophavsret 
				)
				AND
				(
					attrEgenskaberTypeObj.plan IS NULL
					OR 
					a.plan = attrEgenskaberTypeObj.plan 
				)
				AND
				(
					attrEgenskaberTypeObj.supplement IS NULL
					OR 
					a.supplement = attrEgenskaberTypeObj.supplement 
				)
				AND
				(
					attrEgenskaberTypeObj.retskilde IS NULL
					OR 
					a.retskilde = attrEgenskaberTypeObj.retskilde 
				)
				AND b.facet_id = ANY (facet_candidates)
				AND (a.virkning).TimePeriod && actual_virkning 
			);
			
		END LOOP;
	END IF;
END IF;
--RAISE DEBUG 'facet_candidates_is_initialized step 3:%',facet_candidates_is_initialized;
--RAISE DEBUG 'facet_candidates step 3:%',facet_candidates;

--RAISE DEBUG 'registrering,%',registreringObj;


--/**********************************************************//
--Filtration on state: Publiceret
--/**********************************************************//
IF registreringObj IS NULL OR (registreringObj).tilsPubliceret IS NULL THEN
	--RAISE DEBUG 'as_search_facet: skipping filtration on tilsPubliceret';
ELSE
	IF coalesce(array_length(facet_candidates,1),0)>0 THEN 

		FOREACH tilsPubliceretTypeObj IN ARRAY registreringObj.tilsPubliceret
		LOOP
			facet_candidates:=array(
			SELECT DISTINCT
			b.facet_id 
			FROM  facet_tils_publiceret a
			JOIN facet_registrering b on a.facet_registrering_id=b.id and upper((b.registrering).timeperiod)='infinity'::TIMESTAMPTZ 
			WHERE
				(
					tilsPubliceretTypeObj.publiceret IS NULL
					OR
					tilsPubliceretTypeObj.publiceret = a.publiceret
				)
				AND b.facet_id = ANY (facet_candidates)
				AND (a.virkning).TimePeriod && actual_virkning
	);
			
		END LOOP;
	END IF;
END IF;

/*
--relationer FacetRelationType[]
*/


--RAISE DEBUG 'facet_candidates_is_initialized step 4:%',facet_candidates_is_initialized;
--RAISE DEBUG 'facet_candidates step 4:%',facet_candidates;

--/**********************************************************//
--Filtration on relations
--/**********************************************************//


IF registreringObj IS NULL OR (registreringObj).relationer IS NULL OR coalesce(array_length((registreringObj).relationer,1),0)=0 THEN
	--RAISE DEBUG 'as_search_facet: skipping filtration on relationer';
ELSE
	IF coalesce(array_length(facet_candidates,1),0)>0 THEN
		FOREACH relationTypeObj IN ARRAY registreringObj.relationer
		LOOP
			facet_candidates:=array(
			SELECT DISTINCT
			b.facet_id 
			FROM  facet_relation a
			JOIN facet_registrering b on a.facet_registrering_id=b.id and upper((b.registrering).timeperiod)='infinity'::TIMESTAMPTZ
			WHERE
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
				AND b.facet_id = ANY (facet_candidates)
				AND (a.virkning).TimePeriod && actual_virkning 
	);
		END LOOP;
	END IF;
END IF;
--/**********************//

--RAISE DEBUG 'facet_candidates_is_initialized step 5:%',facet_candidates_is_initialized;
--RAISE DEBUG 'facet_candidates step 5:%',facet_candidates;

facet_passed_auth_filter:=array(
SELECT
a.id 
FROM
unnest (facet_passed_auth_filter) a(id)
UNION
SELECT
b.id
FROM
unnest (facet_candidates) b(id)
);

--optimization 
IF coalesce(array_length(facet_passed_auth_filter,1),0)=coalesce(array_length(facet_uuids,1),0) AND facet_passed_auth_filter @>facet_uuids THEN
	RETURN facet_passed_auth_filter;
END IF;


END LOOP; --LOOP registreringObj


RETURN facet_passed_auth_filter;


END;
$$ LANGUAGE plpgsql STABLE; 





