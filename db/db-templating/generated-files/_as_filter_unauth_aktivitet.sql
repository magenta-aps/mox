-- Copyright (C) 2015 Magenta ApS, http://magenta.dk.
-- Contact: info@magenta.dk.
--
-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at http://mozilla.org/MPL/2.0/.

/*
NOTICE: This file is auto-generated using the script: apply-template.py aktivitet _as_filter_unauth.jinja.sql
*/


CREATE OR REPLACE FUNCTION _as_filter_unauth_aktivitet(
	aktivitet_uuids uuid[],
	registreringObjArr AktivitetRegistreringType[]
	)
  RETURNS uuid[] AS 
$$
DECLARE
	aktivitet_passed_auth_filter uuid[]:=ARRAY[]::uuid[];
	aktivitet_candidates uuid[];
	--to_be_applyed_filter_uuids uuid[]; 
	attrEgenskaberTypeObj AktivitetEgenskaberAttrType;
	
  	tilsStatusTypeObj AktivitetStatusTilsType;
  	tilsPubliceretTypeObj AktivitetPubliceretTilsType;
	relationTypeObj AktivitetRelationType;
	registreringObj AktivitetRegistreringType;
	actual_virkning TIMESTAMPTZ:=current_timestamp;
BEGIN

--RAISE DEBUG 'step 0:registreringObj:%',registreringObj;

IF registreringObjArr IS NULL THEN
	RETURN aktivitet_uuids; --special case: All is allowed, no criteria present
END IF;

IF coalesce(array_length(registreringObjArr,1),0)=0 THEN
	RETURN ARRAY[]::uuid[]; --special case: Nothing is allowed. Empty list of criteria where at least one has to be met.				
END IF; 

IF aktivitet_uuids IS NULL OR  coalesce(array_length(aktivitet_uuids,1),0)=0 THEN
	RETURN ARRAY[]::uuid[]; --special case: No candidates given to filter.
END IF;



FOREACH registreringObj IN ARRAY registreringObjArr
LOOP

aktivitet_candidates:= aktivitet_uuids;



--RAISE DEBUG 'aktivitet_candidates_is_initialized step 1:%',aktivitet_candidates_is_initialized;
--RAISE DEBUG 'aktivitet_candidates step 1:%',aktivitet_candidates;
--/****************************//

--filter on attributes 
--/**********************************************************//
--Filtration on attribute: Egenskaber
--/**********************************************************//
IF registreringObj IS NULL OR (registreringObj).attrEgenskaber IS NULL THEN
	--RAISE DEBUG 'as_search_aktivitet: skipping filtration on attrEgenskaber';
ELSE
	IF coalesce(array_length(aktivitet_candidates,1),0)>0 THEN
		FOREACH attrEgenskaberTypeObj IN ARRAY registreringObj.attrEgenskaber
		LOOP
			aktivitet_candidates:=array(
			SELECT DISTINCT
			b.aktivitet_id 
			FROM  aktivitet_attr_egenskaber a 
			JOIN aktivitet_registrering b on a.aktivitet_registrering_id=b.id and upper((b.registrering).timeperiod)='infinity'::TIMESTAMPTZ 
			WHERE
				(
					attrEgenskaberTypeObj.brugervendtnoegle IS NULL
					OR 
					a.brugervendtnoegle = attrEgenskaberTypeObj.brugervendtnoegle 
				)
				AND
				(
					attrEgenskaberTypeObj.aktivitetnavn IS NULL
					OR 
					a.aktivitetnavn = attrEgenskaberTypeObj.aktivitetnavn 
				)
				AND
				(
					attrEgenskaberTypeObj.beskrivelse IS NULL
					OR 
					a.beskrivelse = attrEgenskaberTypeObj.beskrivelse 
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
					a.formaal = attrEgenskaberTypeObj.formaal 
				)
				AND b.aktivitet_id = ANY (aktivitet_candidates)
				AND (a.virkning).TimePeriod @> actual_virkning 
			);
			
		END LOOP;
	END IF;
END IF;
--RAISE DEBUG 'aktivitet_candidates_is_initialized step 3:%',aktivitet_candidates_is_initialized;
--RAISE DEBUG 'aktivitet_candidates step 3:%',aktivitet_candidates;

--RAISE DEBUG 'registrering,%',registreringObj;


--/**********************************************************//
--Filtration on state: Status
--/**********************************************************//
IF registreringObj IS NULL OR (registreringObj).tilsStatus IS NULL THEN
	--RAISE DEBUG 'as_search_aktivitet: skipping filtration on tilsStatus';
ELSE
	IF coalesce(array_length(aktivitet_candidates,1),0)>0 THEN 

		FOREACH tilsStatusTypeObj IN ARRAY registreringObj.tilsStatus
		LOOP
			aktivitet_candidates:=array(
			SELECT DISTINCT
			b.aktivitet_id 
			FROM  aktivitet_tils_status a
			JOIN aktivitet_registrering b on a.aktivitet_registrering_id=b.id and upper((b.registrering).timeperiod)='infinity'::TIMESTAMPTZ 
			WHERE
				(
					tilsStatusTypeObj.status IS NULL
					OR
					tilsStatusTypeObj.status = a.status
				)
				AND b.aktivitet_id = ANY (aktivitet_candidates)
				AND (a.virkning).TimePeriod @> actual_virkning
	);
			
		END LOOP;
	END IF;
END IF;
--/**********************************************************//
--Filtration on state: Publiceret
--/**********************************************************//
IF registreringObj IS NULL OR (registreringObj).tilsPubliceret IS NULL THEN
	--RAISE DEBUG 'as_search_aktivitet: skipping filtration on tilsPubliceret';
ELSE
	IF coalesce(array_length(aktivitet_candidates,1),0)>0 THEN 

		FOREACH tilsPubliceretTypeObj IN ARRAY registreringObj.tilsPubliceret
		LOOP
			aktivitet_candidates:=array(
			SELECT DISTINCT
			b.aktivitet_id 
			FROM  aktivitet_tils_publiceret a
			JOIN aktivitet_registrering b on a.aktivitet_registrering_id=b.id and upper((b.registrering).timeperiod)='infinity'::TIMESTAMPTZ 
			WHERE
				(
					tilsPubliceretTypeObj.publiceret IS NULL
					OR
					tilsPubliceretTypeObj.publiceret = a.publiceret
				)
				AND b.aktivitet_id = ANY (aktivitet_candidates)
				AND (a.virkning).TimePeriod @> actual_virkning
	);
			
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


IF registreringObj IS NULL OR (registreringObj).relationer IS NULL OR coalesce(array_length((registreringObj).relationer,1),0)=0 THEN
	--RAISE DEBUG 'as_search_aktivitet: skipping filtration on relationer';
ELSE
	IF coalesce(array_length(aktivitet_candidates,1),0)>0 THEN
		FOREACH relationTypeObj IN ARRAY registreringObj.relationer
		LOOP
			aktivitet_candidates:=array(
			SELECT DISTINCT
			b.aktivitet_id 
			FROM  aktivitet_relation a
			JOIN aktivitet_registrering b on a.aktivitet_registrering_id=b.id and upper((b.registrering).timeperiod)='infinity'::TIMESTAMPTZ
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
				AND b.aktivitet_id = ANY (aktivitet_candidates)
				AND (a.virkning).TimePeriod @> actual_virkning 
	);
		END LOOP;
	END IF;
END IF;
--/**********************//

--RAISE DEBUG 'aktivitet_candidates_is_initialized step 5:%',aktivitet_candidates_is_initialized;
--RAISE DEBUG 'aktivitet_candidates step 5:%',aktivitet_candidates;

aktivitet_passed_auth_filter:=array(
SELECT
a.id 
FROM
unnest (aktivitet_passed_auth_filter) a(id)
UNION
SELECT
b.id
FROM
unnest (aktivitet_candidates) b(id)
);

--optimization 
IF coalesce(array_length(aktivitet_passed_auth_filter,1),0)=coalesce(array_length(aktivitet_uuids,1),0) AND aktivitet_passed_auth_filter @>aktivitet_uuids THEN
	RETURN aktivitet_passed_auth_filter;
END IF;


END LOOP; --LOOP registreringObj


RETURN aktivitet_passed_auth_filter;


END;
$$ LANGUAGE plpgsql STABLE; 





