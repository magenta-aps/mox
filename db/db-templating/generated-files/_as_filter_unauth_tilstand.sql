-- Copyright (C) 2015 Magenta ApS, http://magenta.dk.
-- Contact: info@magenta.dk.
--
-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at http://mozilla.org/MPL/2.0/.

/*
NOTICE: This file is auto-generated using the script: apply-template.py tilstand _as_filter_unauth.jinja.sql
*/


CREATE OR REPLACE FUNCTION _as_filter_unauth_tilstand(
	tilstand_uuids uuid[],
	registreringObjArr TilstandRegistreringType[]
	)
  RETURNS uuid[] AS 
$$
DECLARE
	tilstand_passed_auth_filter uuid[]:=ARRAY[]::uuid[];
	tilstand_candidates uuid[];
	--to_be_applyed_filter_uuids uuid[]; 
	attrEgenskaberTypeObj TilstandEgenskaberAttrType;
	
  	tilsStatusTypeObj TilstandStatusTilsType;
  	tilsPubliceretTypeObj TilstandPubliceretTilsType;
	relationTypeObj TilstandRelationType;
	registreringObj TilstandRegistreringType;
	actual_virkning TIMESTAMPTZ:=current_timestamp;
BEGIN

--RAISE DEBUG 'step 0:registreringObj:%',registreringObj;

IF registreringObjArr IS NULL THEN
	RETURN tilstand_uuids; --special case: All is allowed, no criteria present
END IF;

IF coalesce(array_length(registreringObjArr,1),0)=0 THEN
	RETURN ARRAY[]::uuid[]; --special case: Nothing is allowed. Empty list of criteria where at least one has to be met.				
END IF; 

IF tilstand_uuids IS NULL OR  coalesce(array_length(tilstand_uuids,1),0)=0 THEN
	RETURN ARRAY[]::uuid[]; --special case: No candidates given to filter.
END IF;



FOREACH registreringObj IN ARRAY registreringObjArr
LOOP

tilstand_candidates:= tilstand_uuids;



--RAISE DEBUG 'tilstand_candidates_is_initialized step 1:%',tilstand_candidates_is_initialized;
--RAISE DEBUG 'tilstand_candidates step 1:%',tilstand_candidates;
--/****************************//

--filter on attributes 
--/**********************************************************//
--Filtration on attribute: Egenskaber
--/**********************************************************//
IF registreringObj IS NULL OR (registreringObj).attrEgenskaber IS NULL THEN
	--RAISE DEBUG 'as_search_tilstand: skipping filtration on attrEgenskaber';
ELSE
	IF coalesce(array_length(tilstand_candidates,1),0)>0 THEN
		FOREACH attrEgenskaberTypeObj IN ARRAY registreringObj.attrEgenskaber
		LOOP
			tilstand_candidates:=array(
			SELECT DISTINCT
			b.tilstand_id 
			FROM  tilstand_attr_egenskaber a 
			JOIN tilstand_registrering b on a.tilstand_registrering_id=b.id and upper((b.registrering).timeperiod)='infinity'::TIMESTAMPTZ 
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
				AND b.tilstand_id = ANY (tilstand_candidates)
				AND (a.virkning).TimePeriod @> actual_virkning 
			);
			
		END LOOP;
	END IF;
END IF;
--RAISE DEBUG 'tilstand_candidates_is_initialized step 3:%',tilstand_candidates_is_initialized;
--RAISE DEBUG 'tilstand_candidates step 3:%',tilstand_candidates;

--RAISE DEBUG 'registrering,%',registreringObj;


--/**********************************************************//
--Filtration on state: Status
--/**********************************************************//
IF registreringObj IS NULL OR (registreringObj).tilsStatus IS NULL THEN
	--RAISE DEBUG 'as_search_tilstand: skipping filtration on tilsStatus';
ELSE
	IF coalesce(array_length(tilstand_candidates,1),0)>0 THEN 

		FOREACH tilsStatusTypeObj IN ARRAY registreringObj.tilsStatus
		LOOP
			tilstand_candidates:=array(
			SELECT DISTINCT
			b.tilstand_id 
			FROM  tilstand_tils_status a
			JOIN tilstand_registrering b on a.tilstand_registrering_id=b.id and upper((b.registrering).timeperiod)='infinity'::TIMESTAMPTZ 
			WHERE
				(
					tilsStatusTypeObj.status IS NULL
					OR
					tilsStatusTypeObj.status = a.status
				)
				AND b.tilstand_id = ANY (tilstand_candidates)
				AND (a.virkning).TimePeriod @> actual_virkning
	);
			
		END LOOP;
	END IF;
END IF;
--/**********************************************************//
--Filtration on state: Publiceret
--/**********************************************************//
IF registreringObj IS NULL OR (registreringObj).tilsPubliceret IS NULL THEN
	--RAISE DEBUG 'as_search_tilstand: skipping filtration on tilsPubliceret';
ELSE
	IF coalesce(array_length(tilstand_candidates,1),0)>0 THEN 

		FOREACH tilsPubliceretTypeObj IN ARRAY registreringObj.tilsPubliceret
		LOOP
			tilstand_candidates:=array(
			SELECT DISTINCT
			b.tilstand_id 
			FROM  tilstand_tils_publiceret a
			JOIN tilstand_registrering b on a.tilstand_registrering_id=b.id and upper((b.registrering).timeperiod)='infinity'::TIMESTAMPTZ 
			WHERE
				(
					tilsPubliceretTypeObj.publiceret IS NULL
					OR
					tilsPubliceretTypeObj.publiceret = a.publiceret
				)
				AND b.tilstand_id = ANY (tilstand_candidates)
				AND (a.virkning).TimePeriod @> actual_virkning
	);
			
		END LOOP;
	END IF;
END IF;

/*
--relationer TilstandRelationType[]
*/


--RAISE DEBUG 'tilstand_candidates_is_initialized step 4:%',tilstand_candidates_is_initialized;
--RAISE DEBUG 'tilstand_candidates step 4:%',tilstand_candidates;

--/**********************************************************//
--Filtration on relations
--/**********************************************************//


IF registreringObj IS NULL OR (registreringObj).relationer IS NULL OR coalesce(array_length((registreringObj).relationer,1),0)=0 THEN
	--RAISE DEBUG 'as_search_tilstand: skipping filtration on relationer';
ELSE
	IF coalesce(array_length(tilstand_candidates,1),0)>0 THEN
		FOREACH relationTypeObj IN ARRAY registreringObj.relationer
		LOOP
			tilstand_candidates:=array(
			SELECT DISTINCT
			b.tilstand_id 
			FROM  tilstand_relation a
			JOIN tilstand_registrering b on a.tilstand_registrering_id=b.id and upper((b.registrering).timeperiod)='infinity'::TIMESTAMPTZ
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
				AND b.tilstand_id = ANY (tilstand_candidates)
				AND (a.virkning).TimePeriod @> actual_virkning 
	);
		END LOOP;
	END IF;
END IF;
--/**********************//

--RAISE DEBUG 'tilstand_candidates_is_initialized step 5:%',tilstand_candidates_is_initialized;
--RAISE DEBUG 'tilstand_candidates step 5:%',tilstand_candidates;

tilstand_passed_auth_filter:=array(
SELECT
a.id 
FROM
unnest (tilstand_passed_auth_filter) a(id)
UNION
SELECT
b.id
FROM
unnest (tilstand_candidates) b(id)
);

--optimization 
IF coalesce(array_length(tilstand_passed_auth_filter,1),0)=coalesce(array_length(tilstand_uuids,1),0) AND tilstand_passed_auth_filter @>tilstand_uuids THEN
	RETURN tilstand_passed_auth_filter;
END IF;


END LOOP; --LOOP registreringObj


RETURN tilstand_passed_auth_filter;


END;
$$ LANGUAGE plpgsql STABLE; 





