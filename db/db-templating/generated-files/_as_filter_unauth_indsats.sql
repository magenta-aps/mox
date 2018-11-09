-- Copyright (C) 2015 Magenta ApS, http://magenta.dk.
-- Contact: info@magenta.dk.
--
-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at http://mozilla.org/MPL/2.0/.

/*
NOTICE: This file is auto-generated using the script: apply-template.py indsats _as_filter_unauth.jinja.sql
*/


CREATE OR REPLACE FUNCTION _as_filter_unauth_indsats(
	indsats_uuids uuid[],
	registreringObjArr IndsatsRegistreringType[]
	)
  RETURNS uuid[] AS 
$$
DECLARE
	indsats_passed_auth_filter uuid[]:=ARRAY[]::uuid[];
	indsats_candidates uuid[];
	--to_be_applyed_filter_uuids uuid[]; 
	attrEgenskaberTypeObj IndsatsEgenskaberAttrType;
	
  	tilsPubliceretTypeObj IndsatsPubliceretTilsType;
  	tilsFremdriftTypeObj IndsatsFremdriftTilsType;
	relationTypeObj IndsatsRelationType;
	registreringObj IndsatsRegistreringType;
	actual_virkning TIMESTAMPTZ:=current_timestamp;
BEGIN

--RAISE DEBUG 'step 0:registreringObj:%',registreringObj;

IF registreringObjArr IS NULL THEN
	RETURN indsats_uuids; --special case: All is allowed, no criteria present
END IF;

IF coalesce(array_length(registreringObjArr,1),0)=0 THEN
	RETURN ARRAY[]::uuid[]; --special case: Nothing is allowed. Empty list of criteria where at least one has to be met.				
END IF; 

IF indsats_uuids IS NULL OR  coalesce(array_length(indsats_uuids,1),0)=0 THEN
	RETURN ARRAY[]::uuid[]; --special case: No candidates given to filter.
END IF;



FOREACH registreringObj IN ARRAY registreringObjArr
LOOP

indsats_candidates:= indsats_uuids;



--RAISE DEBUG 'indsats_candidates_is_initialized step 1:%',indsats_candidates_is_initialized;
--RAISE DEBUG 'indsats_candidates step 1:%',indsats_candidates;
--/****************************//

--filter on attributes 
--/**********************************************************//
--Filtration on attribute: Egenskaber
--/**********************************************************//
IF registreringObj IS NULL OR (registreringObj).attrEgenskaber IS NULL THEN
	--RAISE DEBUG 'as_search_indsats: skipping filtration on attrEgenskaber';
ELSE
	IF coalesce(array_length(indsats_candidates,1),0)>0 THEN
		FOREACH attrEgenskaberTypeObj IN ARRAY registreringObj.attrEgenskaber
		LOOP
			indsats_candidates:=array(
			SELECT DISTINCT
			b.indsats_id 
			FROM  indsats_attr_egenskaber a 
			JOIN indsats_registrering b on a.indsats_registrering_id=b.id and upper((b.registrering).timeperiod)='infinity'::TIMESTAMPTZ 
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
				AND b.indsats_id = ANY (indsats_candidates)
				AND (a.virkning).TimePeriod @> actual_virkning 
			);
			
		END LOOP;
	END IF;
END IF;
--RAISE DEBUG 'indsats_candidates_is_initialized step 3:%',indsats_candidates_is_initialized;
--RAISE DEBUG 'indsats_candidates step 3:%',indsats_candidates;

--RAISE DEBUG 'registrering,%',registreringObj;


--/**********************************************************//
--Filtration on state: Publiceret
--/**********************************************************//
IF registreringObj IS NULL OR (registreringObj).tilsPubliceret IS NULL THEN
	--RAISE DEBUG 'as_search_indsats: skipping filtration on tilsPubliceret';
ELSE
	IF coalesce(array_length(indsats_candidates,1),0)>0 THEN 

		FOREACH tilsPubliceretTypeObj IN ARRAY registreringObj.tilsPubliceret
		LOOP
			indsats_candidates:=array(
			SELECT DISTINCT
			b.indsats_id 
			FROM  indsats_tils_publiceret a
			JOIN indsats_registrering b on a.indsats_registrering_id=b.id and upper((b.registrering).timeperiod)='infinity'::TIMESTAMPTZ 
			WHERE
				(
					tilsPubliceretTypeObj.publiceret IS NULL
					OR
					tilsPubliceretTypeObj.publiceret = a.publiceret
				)
				AND b.indsats_id = ANY (indsats_candidates)
				AND (a.virkning).TimePeriod @> actual_virkning
	);
			
		END LOOP;
	END IF;
END IF;
--/**********************************************************//
--Filtration on state: Fremdrift
--/**********************************************************//
IF registreringObj IS NULL OR (registreringObj).tilsFremdrift IS NULL THEN
	--RAISE DEBUG 'as_search_indsats: skipping filtration on tilsFremdrift';
ELSE
	IF coalesce(array_length(indsats_candidates,1),0)>0 THEN 

		FOREACH tilsFremdriftTypeObj IN ARRAY registreringObj.tilsFremdrift
		LOOP
			indsats_candidates:=array(
			SELECT DISTINCT
			b.indsats_id 
			FROM  indsats_tils_fremdrift a
			JOIN indsats_registrering b on a.indsats_registrering_id=b.id and upper((b.registrering).timeperiod)='infinity'::TIMESTAMPTZ 
			WHERE
				(
					tilsFremdriftTypeObj.fremdrift IS NULL
					OR
					tilsFremdriftTypeObj.fremdrift = a.fremdrift
				)
				AND b.indsats_id = ANY (indsats_candidates)
				AND (a.virkning).TimePeriod @> actual_virkning
	);
			
		END LOOP;
	END IF;
END IF;

/*
--relationer IndsatsRelationType[]
*/


--RAISE DEBUG 'indsats_candidates_is_initialized step 4:%',indsats_candidates_is_initialized;
--RAISE DEBUG 'indsats_candidates step 4:%',indsats_candidates;

--/**********************************************************//
--Filtration on relations
--/**********************************************************//


IF registreringObj IS NULL OR (registreringObj).relationer IS NULL OR coalesce(array_length((registreringObj).relationer,1),0)=0 THEN
	--RAISE DEBUG 'as_search_indsats: skipping filtration on relationer';
ELSE
	IF coalesce(array_length(indsats_candidates,1),0)>0 THEN
		FOREACH relationTypeObj IN ARRAY registreringObj.relationer
		LOOP
			indsats_candidates:=array(
			SELECT DISTINCT
			b.indsats_id 
			FROM  indsats_relation a
			JOIN indsats_registrering b on a.indsats_registrering_id=b.id and upper((b.registrering).timeperiod)='infinity'::TIMESTAMPTZ
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
				AND b.indsats_id = ANY (indsats_candidates)
				AND (a.virkning).TimePeriod @> actual_virkning 
	);
		END LOOP;
	END IF;
END IF;
--/**********************//

--RAISE DEBUG 'indsats_candidates_is_initialized step 5:%',indsats_candidates_is_initialized;
--RAISE DEBUG 'indsats_candidates step 5:%',indsats_candidates;

indsats_passed_auth_filter:=array(
SELECT
a.id 
FROM
unnest (indsats_passed_auth_filter) a(id)
UNION
SELECT
b.id
FROM
unnest (indsats_candidates) b(id)
);

--optimization 
IF coalesce(array_length(indsats_passed_auth_filter,1),0)=coalesce(array_length(indsats_uuids,1),0) AND indsats_passed_auth_filter @>indsats_uuids THEN
	RETURN indsats_passed_auth_filter;
END IF;


END LOOP; --LOOP registreringObj


RETURN indsats_passed_auth_filter;


END;
$$ LANGUAGE plpgsql STABLE; 





