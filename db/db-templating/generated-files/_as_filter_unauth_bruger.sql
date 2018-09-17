-- Copyright (C) 2015 Magenta ApS, http://magenta.dk.
-- Contact: info@magenta.dk.
--
-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at http://mozilla.org/MPL/2.0/.

/*
NOTICE: This file is auto-generated using the script: oio_rest/apply-templates.py
*/


CREATE OR REPLACE FUNCTION _as_filter_unauth_bruger(
	bruger_uuids uuid[],
	registreringObjArr BrugerRegistreringType[]
	)
  RETURNS uuid[] AS 
$$
DECLARE
	bruger_passed_auth_filter uuid[]:=ARRAY[]::uuid[];
	bruger_candidates uuid[];
	--to_be_applyed_filter_uuids uuid[]; 
	attrEgenskaberTypeObj BrugerEgenskaberAttrType;
	
  	tilsGyldighedTypeObj BrugerGyldighedTilsType;
	relationTypeObj BrugerRelationType;
	registreringObj BrugerRegistreringType;
	actual_virkning TIMESTAMPTZ:=current_timestamp;
BEGIN

--RAISE DEBUG 'step 0:registreringObj:%',registreringObj;

IF registreringObjArr IS NULL THEN
	RETURN bruger_uuids; --special case: All is allowed, no criteria present
END IF;

IF coalesce(array_length(registreringObjArr,1),0)=0 THEN
	RETURN ARRAY[]::uuid[]; --special case: Nothing is allowed. Empty list of criteria where at least one has to be met.				
END IF; 

IF bruger_uuids IS NULL OR  coalesce(array_length(bruger_uuids,1),0)=0 THEN
	RETURN ARRAY[]::uuid[]; --special case: No candidates given to filter.
END IF;



FOREACH registreringObj IN ARRAY registreringObjArr
LOOP

bruger_candidates:= bruger_uuids;



--RAISE DEBUG 'bruger_candidates_is_initialized step 1:%',bruger_candidates_is_initialized;
--RAISE DEBUG 'bruger_candidates step 1:%',bruger_candidates;
--/****************************//

--filter on attributes 
--/**********************************************************//
--Filtration on attribute: Egenskaber
--/**********************************************************//
IF registreringObj IS NULL OR (registreringObj).attrEgenskaber IS NULL THEN
	--RAISE DEBUG 'as_search_bruger: skipping filtration on attrEgenskaber';
ELSE
	IF coalesce(array_length(bruger_candidates,1),0)>0 THEN
		FOREACH attrEgenskaberTypeObj IN ARRAY registreringObj.attrEgenskaber
		LOOP
			bruger_candidates:=array(
			SELECT DISTINCT
			b.bruger_id 
			FROM  bruger_attr_egenskaber a 
			JOIN bruger_registrering b on a.bruger_registrering_id=b.id and upper((b.registrering).timeperiod)='infinity'::TIMESTAMPTZ 
			WHERE
				(
					attrEgenskaberTypeObj.brugervendtnoegle IS NULL
					OR 
					a.brugervendtnoegle = attrEgenskaberTypeObj.brugervendtnoegle 
				)
				AND
				(
					attrEgenskaberTypeObj.brugernavn IS NULL
					OR 
					a.brugernavn = attrEgenskaberTypeObj.brugernavn 
				)
				AND
				(
					attrEgenskaberTypeObj.brugertype IS NULL
					OR 
					a.brugertype = attrEgenskaberTypeObj.brugertype 
				)
				AND b.bruger_id = ANY (bruger_candidates)
				AND (a.virkning).TimePeriod @> actual_virkning 
			);
			
		END LOOP;
	END IF;
END IF;
--RAISE DEBUG 'bruger_candidates_is_initialized step 3:%',bruger_candidates_is_initialized;
--RAISE DEBUG 'bruger_candidates step 3:%',bruger_candidates;

--RAISE DEBUG 'registrering,%',registreringObj;


--/**********************************************************//
--Filtration on state: Gyldighed
--/**********************************************************//
IF registreringObj IS NULL OR (registreringObj).tilsGyldighed IS NULL THEN
	--RAISE DEBUG 'as_search_bruger: skipping filtration on tilsGyldighed';
ELSE
	IF coalesce(array_length(bruger_candidates,1),0)>0 THEN 

		FOREACH tilsGyldighedTypeObj IN ARRAY registreringObj.tilsGyldighed
		LOOP
			bruger_candidates:=array(
			SELECT DISTINCT
			b.bruger_id 
			FROM  bruger_tils_gyldighed a
			JOIN bruger_registrering b on a.bruger_registrering_id=b.id and upper((b.registrering).timeperiod)='infinity'::TIMESTAMPTZ 
			WHERE
				(
					tilsGyldighedTypeObj.gyldighed IS NULL
					OR
					tilsGyldighedTypeObj.gyldighed = a.gyldighed
				)
				AND b.bruger_id = ANY (bruger_candidates)
				AND (a.virkning).TimePeriod @> actual_virkning
	);
			
		END LOOP;
	END IF;
END IF;

/*
--relationer BrugerRelationType[]
*/


--RAISE DEBUG 'bruger_candidates_is_initialized step 4:%',bruger_candidates_is_initialized;
--RAISE DEBUG 'bruger_candidates step 4:%',bruger_candidates;

--/**********************************************************//
--Filtration on relations
--/**********************************************************//


IF registreringObj IS NULL OR (registreringObj).relationer IS NULL OR coalesce(array_length((registreringObj).relationer,1),0)=0 THEN
	--RAISE DEBUG 'as_search_bruger: skipping filtration on relationer';
ELSE
	IF coalesce(array_length(bruger_candidates,1),0)>0 THEN
		FOREACH relationTypeObj IN ARRAY registreringObj.relationer
		LOOP
			bruger_candidates:=array(
			SELECT DISTINCT
			b.bruger_id 
			FROM  bruger_relation a
			JOIN bruger_registrering b on a.bruger_registrering_id=b.id and upper((b.registrering).timeperiod)='infinity'::TIMESTAMPTZ
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
				AND b.bruger_id = ANY (bruger_candidates)
				AND (a.virkning).TimePeriod @> actual_virkning 
	);
		END LOOP;
	END IF;
END IF;
--/**********************//

--RAISE DEBUG 'bruger_candidates_is_initialized step 5:%',bruger_candidates_is_initialized;
--RAISE DEBUG 'bruger_candidates step 5:%',bruger_candidates;

bruger_passed_auth_filter:=array(
SELECT
a.id 
FROM
unnest (bruger_passed_auth_filter) a(id)
UNION
SELECT
b.id
FROM
unnest (bruger_candidates) b(id)
);

--optimization 
IF coalesce(array_length(bruger_passed_auth_filter,1),0)=coalesce(array_length(bruger_uuids,1),0) AND bruger_passed_auth_filter @>bruger_uuids THEN
	RETURN bruger_passed_auth_filter;
END IF;


END LOOP; --LOOP registreringObj


RETURN bruger_passed_auth_filter;


END;
$$ LANGUAGE plpgsql STABLE; 





