-- Copyright (C) 2015 Magenta ApS, http://magenta.dk.
-- Contact: info@magenta.dk.
--
-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at http://mozilla.org/MPL/2.0/.

/*
NOTICE: This file is auto-generated using the script: apply-template.py loghaendelse _as_filter_unauth.jinja.sql
*/


CREATE OR REPLACE FUNCTION _as_filter_unauth_loghaendelse(
	loghaendelse_uuids uuid[],
	registreringObjArr LoghaendelseRegistreringType[]
	)
  RETURNS uuid[] AS 
$$
DECLARE
	loghaendelse_passed_auth_filter uuid[]:=ARRAY[]::uuid[];
	loghaendelse_candidates uuid[];
	--to_be_applyed_filter_uuids uuid[]; 
	attrEgenskaberTypeObj LoghaendelseEgenskaberAttrType;
	
  	tilsGyldighedTypeObj LoghaendelseGyldighedTilsType;
	relationTypeObj LoghaendelseRelationType;
	registreringObj LoghaendelseRegistreringType;
	actual_virkning TIMESTAMPTZ:=current_timestamp;
BEGIN

--RAISE DEBUG 'step 0:registreringObj:%',registreringObj;

IF registreringObjArr IS NULL THEN
	RETURN loghaendelse_uuids; --special case: All is allowed, no criteria present
END IF;

IF coalesce(array_length(registreringObjArr,1),0)=0 THEN
	RETURN ARRAY[]::uuid[]; --special case: Nothing is allowed. Empty list of criteria where at least one has to be met.				
END IF; 

IF loghaendelse_uuids IS NULL OR  coalesce(array_length(loghaendelse_uuids,1),0)=0 THEN
	RETURN ARRAY[]::uuid[]; --special case: No candidates given to filter.
END IF;



FOREACH registreringObj IN ARRAY registreringObjArr
LOOP

loghaendelse_candidates:= loghaendelse_uuids;



--RAISE DEBUG 'loghaendelse_candidates_is_initialized step 1:%',loghaendelse_candidates_is_initialized;
--RAISE DEBUG 'loghaendelse_candidates step 1:%',loghaendelse_candidates;
--/****************************//

--filter on attributes 
--/**********************************************************//
--Filtration on attribute: Egenskaber
--/**********************************************************//
IF registreringObj IS NULL OR (registreringObj).attrEgenskaber IS NULL THEN
	--RAISE DEBUG 'as_search_loghaendelse: skipping filtration on attrEgenskaber';
ELSE
	IF coalesce(array_length(loghaendelse_candidates,1),0)>0 THEN
		FOREACH attrEgenskaberTypeObj IN ARRAY registreringObj.attrEgenskaber
		LOOP
			loghaendelse_candidates:=array(
			SELECT DISTINCT
			b.loghaendelse_id 
			FROM  loghaendelse_attr_egenskaber a 
			JOIN loghaendelse_registrering b on a.loghaendelse_registrering_id=b.id and upper((b.registrering).timeperiod)='infinity'::TIMESTAMPTZ 
			WHERE
				(
					attrEgenskaberTypeObj.service IS NULL
					OR 
					a.service = attrEgenskaberTypeObj.service 
				)
				AND
				(
					attrEgenskaberTypeObj.klasse IS NULL
					OR 
					a.klasse = attrEgenskaberTypeObj.klasse 
				)
				AND
				(
					attrEgenskaberTypeObj.tidspunkt IS NULL
					OR 
					a.tidspunkt = attrEgenskaberTypeObj.tidspunkt 
				)
				AND
				(
					attrEgenskaberTypeObj.operation IS NULL
					OR 
					a.operation = attrEgenskaberTypeObj.operation 
				)
				AND
				(
					attrEgenskaberTypeObj.objekttype IS NULL
					OR 
					a.objekttype = attrEgenskaberTypeObj.objekttype 
				)
				AND
				(
					attrEgenskaberTypeObj.returkode IS NULL
					OR 
					a.returkode = attrEgenskaberTypeObj.returkode 
				)
				AND
				(
					attrEgenskaberTypeObj.returtekst IS NULL
					OR 
					a.returtekst = attrEgenskaberTypeObj.returtekst 
				)
				AND
				(
					attrEgenskaberTypeObj.note IS NULL
					OR 
					a.note = attrEgenskaberTypeObj.note 
				)
				AND b.loghaendelse_id = ANY (loghaendelse_candidates)
				AND (a.virkning).TimePeriod @> actual_virkning 
			);
			
		END LOOP;
	END IF;
END IF;
--RAISE DEBUG 'loghaendelse_candidates_is_initialized step 3:%',loghaendelse_candidates_is_initialized;
--RAISE DEBUG 'loghaendelse_candidates step 3:%',loghaendelse_candidates;

--RAISE DEBUG 'registrering,%',registreringObj;


--/**********************************************************//
--Filtration on state: Gyldighed
--/**********************************************************//
IF registreringObj IS NULL OR (registreringObj).tilsGyldighed IS NULL THEN
	--RAISE DEBUG 'as_search_loghaendelse: skipping filtration on tilsGyldighed';
ELSE
	IF coalesce(array_length(loghaendelse_candidates,1),0)>0 THEN 

		FOREACH tilsGyldighedTypeObj IN ARRAY registreringObj.tilsGyldighed
		LOOP
			loghaendelse_candidates:=array(
			SELECT DISTINCT
			b.loghaendelse_id 
			FROM  loghaendelse_tils_gyldighed a
			JOIN loghaendelse_registrering b on a.loghaendelse_registrering_id=b.id and upper((b.registrering).timeperiod)='infinity'::TIMESTAMPTZ 
			WHERE
				(
					tilsGyldighedTypeObj.gyldighed IS NULL
					OR
					tilsGyldighedTypeObj.gyldighed = a.gyldighed
				)
				AND b.loghaendelse_id = ANY (loghaendelse_candidates)
				AND (a.virkning).TimePeriod @> actual_virkning
	);
			
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


IF registreringObj IS NULL OR (registreringObj).relationer IS NULL OR coalesce(array_length((registreringObj).relationer,1),0)=0 THEN
	--RAISE DEBUG 'as_search_loghaendelse: skipping filtration on relationer';
ELSE
	IF coalesce(array_length(loghaendelse_candidates,1),0)>0 THEN
		FOREACH relationTypeObj IN ARRAY registreringObj.relationer
		LOOP
			loghaendelse_candidates:=array(
			SELECT DISTINCT
			b.loghaendelse_id 
			FROM  loghaendelse_relation a
			JOIN loghaendelse_registrering b on a.loghaendelse_registrering_id=b.id and upper((b.registrering).timeperiod)='infinity'::TIMESTAMPTZ
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
				AND b.loghaendelse_id = ANY (loghaendelse_candidates)
				AND (a.virkning).TimePeriod @> actual_virkning 
	);
		END LOOP;
	END IF;
END IF;
--/**********************//

--RAISE DEBUG 'loghaendelse_candidates_is_initialized step 5:%',loghaendelse_candidates_is_initialized;
--RAISE DEBUG 'loghaendelse_candidates step 5:%',loghaendelse_candidates;

loghaendelse_passed_auth_filter:=array(
SELECT
a.id 
FROM
unnest (loghaendelse_passed_auth_filter) a(id)
UNION
SELECT
b.id
FROM
unnest (loghaendelse_candidates) b(id)
);

--optimization 
IF coalesce(array_length(loghaendelse_passed_auth_filter,1),0)=coalesce(array_length(loghaendelse_uuids,1),0) AND loghaendelse_passed_auth_filter @>loghaendelse_uuids THEN
	RETURN loghaendelse_passed_auth_filter;
END IF;


END LOOP; --LOOP registreringObj


RETURN loghaendelse_passed_auth_filter;


END;
$$ LANGUAGE plpgsql STABLE; 





