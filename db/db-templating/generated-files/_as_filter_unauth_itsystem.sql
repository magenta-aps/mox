-- Copyright (C) 2015 Magenta ApS, http://magenta.dk.
-- Contact: info@magenta.dk.
--
-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at http://mozilla.org/MPL/2.0/.

/*
NOTICE: This file is auto-generated using the script: oio_rest/apply-templates.py
*/


CREATE OR REPLACE FUNCTION _as_filter_unauth_itsystem(
	itsystem_uuids uuid[],
	registreringObjArr ItsystemRegistreringType[]
	)
  RETURNS uuid[] AS 
$$
DECLARE
	itsystem_passed_auth_filter uuid[]:=ARRAY[]::uuid[];
	itsystem_candidates uuid[];
	--to_be_applyed_filter_uuids uuid[]; 
	attrEgenskaberTypeObj ItsystemEgenskaberAttrType;
	
  	tilsGyldighedTypeObj ItsystemGyldighedTilsType;
	relationTypeObj ItsystemRelationType;
	registreringObj ItsystemRegistreringType;
	actual_virkning TIMESTAMPTZ:=current_timestamp;
BEGIN

--RAISE DEBUG 'step 0:registreringObj:%',registreringObj;

IF registreringObjArr IS NULL THEN
	RETURN itsystem_uuids; --special case: All is allowed, no criteria present
END IF;

IF coalesce(array_length(registreringObjArr,1),0)=0 THEN
	RETURN ARRAY[]::uuid[]; --special case: Nothing is allowed. Empty list of criteria where at least one has to be met.				
END IF; 

IF itsystem_uuids IS NULL OR  coalesce(array_length(itsystem_uuids,1),0)=0 THEN
	RETURN ARRAY[]::uuid[]; --special case: No candidates given to filter.
END IF;



FOREACH registreringObj IN ARRAY registreringObjArr
LOOP

itsystem_candidates:= itsystem_uuids;



--RAISE DEBUG 'itsystem_candidates_is_initialized step 1:%',itsystem_candidates_is_initialized;
--RAISE DEBUG 'itsystem_candidates step 1:%',itsystem_candidates;
--/****************************//

--filter on attributes 
--/**********************************************************//
--Filtration on attribute: Egenskaber
--/**********************************************************//
IF registreringObj IS NULL OR (registreringObj).attrEgenskaber IS NULL THEN
	--RAISE DEBUG 'as_search_itsystem: skipping filtration on attrEgenskaber';
ELSE
	IF coalesce(array_length(itsystem_candidates,1),0)>0 THEN
		FOREACH attrEgenskaberTypeObj IN ARRAY registreringObj.attrEgenskaber
		LOOP
			itsystem_candidates:=array(
			SELECT DISTINCT
			b.itsystem_id 
			FROM  itsystem_attr_egenskaber a 
			JOIN itsystem_registrering b on a.itsystem_registrering_id=b.id and upper((b.registrering).timeperiod)='infinity'::TIMESTAMPTZ 
			WHERE
				(
					attrEgenskaberTypeObj.brugervendtnoegle IS NULL
					OR 
					a.brugervendtnoegle = attrEgenskaberTypeObj.brugervendtnoegle 
				)
				AND
				(
					attrEgenskaberTypeObj.itsystemnavn IS NULL
					OR 
					a.itsystemnavn = attrEgenskaberTypeObj.itsystemnavn 
				)
				AND
				(
					attrEgenskaberTypeObj.itsystemtype IS NULL
					OR 
					a.itsystemtype = attrEgenskaberTypeObj.itsystemtype 
				)
				AND
				(
					attrEgenskaberTypeObj.konfigurationreference IS NULL
					OR
						((coalesce(array_length(attrEgenskaberTypeObj.konfigurationreference,1),0)=0 AND coalesce(array_length(a.konfigurationreference,1),0)=0 ) OR (attrEgenskaberTypeObj.konfigurationreference @> a.konfigurationreference AND a.konfigurationreference @>attrEgenskaberTypeObj.konfigurationreference  )) 
				)
				AND b.itsystem_id = ANY (itsystem_candidates)
				AND (a.virkning).TimePeriod @> actual_virkning 
			);
			
		END LOOP;
	END IF;
END IF;
--RAISE DEBUG 'itsystem_candidates_is_initialized step 3:%',itsystem_candidates_is_initialized;
--RAISE DEBUG 'itsystem_candidates step 3:%',itsystem_candidates;

--RAISE DEBUG 'registrering,%',registreringObj;


--/**********************************************************//
--Filtration on state: Gyldighed
--/**********************************************************//
IF registreringObj IS NULL OR (registreringObj).tilsGyldighed IS NULL THEN
	--RAISE DEBUG 'as_search_itsystem: skipping filtration on tilsGyldighed';
ELSE
	IF coalesce(array_length(itsystem_candidates,1),0)>0 THEN 

		FOREACH tilsGyldighedTypeObj IN ARRAY registreringObj.tilsGyldighed
		LOOP
			itsystem_candidates:=array(
			SELECT DISTINCT
			b.itsystem_id 
			FROM  itsystem_tils_gyldighed a
			JOIN itsystem_registrering b on a.itsystem_registrering_id=b.id and upper((b.registrering).timeperiod)='infinity'::TIMESTAMPTZ 
			WHERE
				(
					tilsGyldighedTypeObj.gyldighed IS NULL
					OR
					tilsGyldighedTypeObj.gyldighed = a.gyldighed
				)
				AND b.itsystem_id = ANY (itsystem_candidates)
				AND (a.virkning).TimePeriod @> actual_virkning
	);
			
		END LOOP;
	END IF;
END IF;

/*
--relationer ItsystemRelationType[]
*/


--RAISE DEBUG 'itsystem_candidates_is_initialized step 4:%',itsystem_candidates_is_initialized;
--RAISE DEBUG 'itsystem_candidates step 4:%',itsystem_candidates;

--/**********************************************************//
--Filtration on relations
--/**********************************************************//


IF registreringObj IS NULL OR (registreringObj).relationer IS NULL OR coalesce(array_length((registreringObj).relationer,1),0)=0 THEN
	--RAISE DEBUG 'as_search_itsystem: skipping filtration on relationer';
ELSE
	IF coalesce(array_length(itsystem_candidates,1),0)>0 THEN
		FOREACH relationTypeObj IN ARRAY registreringObj.relationer
		LOOP
			itsystem_candidates:=array(
			SELECT DISTINCT
			b.itsystem_id 
			FROM  itsystem_relation a
			JOIN itsystem_registrering b on a.itsystem_registrering_id=b.id and upper((b.registrering).timeperiod)='infinity'::TIMESTAMPTZ
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
				AND b.itsystem_id = ANY (itsystem_candidates)
				AND (a.virkning).TimePeriod @> actual_virkning 
	);
		END LOOP;
	END IF;
END IF;
--/**********************//

--RAISE DEBUG 'itsystem_candidates_is_initialized step 5:%',itsystem_candidates_is_initialized;
--RAISE DEBUG 'itsystem_candidates step 5:%',itsystem_candidates;

itsystem_passed_auth_filter:=array(
SELECT
a.id 
FROM
unnest (itsystem_passed_auth_filter) a(id)
UNION
SELECT
b.id
FROM
unnest (itsystem_candidates) b(id)
);

--optimization 
IF coalesce(array_length(itsystem_passed_auth_filter,1),0)=coalesce(array_length(itsystem_uuids,1),0) AND itsystem_passed_auth_filter @>itsystem_uuids THEN
	RETURN itsystem_passed_auth_filter;
END IF;


END LOOP; --LOOP registreringObj


RETURN itsystem_passed_auth_filter;


END;
$$ LANGUAGE plpgsql STABLE; 




