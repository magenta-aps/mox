-- Copyright (C) 2015 Magenta ApS, http://magenta.dk.
-- Contact: info@magenta.dk.
--
-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at http://mozilla.org/MPL/2.0/.

/*
NOTICE: This file is auto-generated using the script: apply-template.py organisationenhed _as_filter_unauth.jinja.sql
*/


CREATE OR REPLACE FUNCTION _as_filter_unauth_organisationenhed(
	organisationenhed_uuids uuid[],
	registreringObjArr OrganisationenhedRegistreringType[]
	)
  RETURNS uuid[] AS 
$$
DECLARE
	organisationenhed_passed_auth_filter uuid[]:=ARRAY[]::uuid[];
	organisationenhed_candidates uuid[];
	--to_be_applyed_filter_uuids uuid[]; 
	attrEgenskaberTypeObj OrganisationenhedEgenskaberAttrType;
	
  	tilsGyldighedTypeObj OrganisationenhedGyldighedTilsType;
	relationTypeObj OrganisationenhedRelationType;
	registreringObj OrganisationenhedRegistreringType;
	actual_virkning TIMESTAMPTZ:=current_timestamp;
BEGIN

--RAISE DEBUG 'step 0:registreringObj:%',registreringObj;

IF registreringObjArr IS NULL THEN
	RETURN organisationenhed_uuids; --special case: All is allowed, no criteria present
END IF;

IF coalesce(array_length(registreringObjArr,1),0)=0 THEN
	RETURN ARRAY[]::uuid[]; --special case: Nothing is allowed. Empty list of criteria where at least one has to be met.				
END IF; 

IF organisationenhed_uuids IS NULL OR  coalesce(array_length(organisationenhed_uuids,1),0)=0 THEN
	RETURN ARRAY[]::uuid[]; --special case: No candidates given to filter.
END IF;



FOREACH registreringObj IN ARRAY registreringObjArr
LOOP

organisationenhed_candidates:= organisationenhed_uuids;



--RAISE DEBUG 'organisationenhed_candidates_is_initialized step 1:%',organisationenhed_candidates_is_initialized;
--RAISE DEBUG 'organisationenhed_candidates step 1:%',organisationenhed_candidates;
--/****************************//

--filter on attributes 
--/**********************************************************//
--Filtration on attribute: Egenskaber
--/**********************************************************//
IF registreringObj IS NULL OR (registreringObj).attrEgenskaber IS NULL THEN
	--RAISE DEBUG 'as_search_organisationenhed: skipping filtration on attrEgenskaber';
ELSE
	IF coalesce(array_length(organisationenhed_candidates,1),0)>0 THEN
		FOREACH attrEgenskaberTypeObj IN ARRAY registreringObj.attrEgenskaber
		LOOP
			organisationenhed_candidates:=array(
			SELECT DISTINCT
			b.organisationenhed_id 
			FROM  organisationenhed_attr_egenskaber a 
			JOIN organisationenhed_registrering b on a.organisationenhed_registrering_id=b.id and upper((b.registrering).timeperiod)='infinity'::TIMESTAMPTZ 
			WHERE
				(
					attrEgenskaberTypeObj.brugervendtnoegle IS NULL
					OR 
					a.brugervendtnoegle = attrEgenskaberTypeObj.brugervendtnoegle 
				)
				AND
				(
					attrEgenskaberTypeObj.enhedsnavn IS NULL
					OR 
					a.enhedsnavn = attrEgenskaberTypeObj.enhedsnavn 
				)
				AND b.organisationenhed_id = ANY (organisationenhed_candidates)
				AND (a.virkning).TimePeriod @> actual_virkning 
			);
			
		END LOOP;
	END IF;
END IF;
--RAISE DEBUG 'organisationenhed_candidates_is_initialized step 3:%',organisationenhed_candidates_is_initialized;
--RAISE DEBUG 'organisationenhed_candidates step 3:%',organisationenhed_candidates;

--RAISE DEBUG 'registrering,%',registreringObj;


--/**********************************************************//
--Filtration on state: Gyldighed
--/**********************************************************//
IF registreringObj IS NULL OR (registreringObj).tilsGyldighed IS NULL THEN
	--RAISE DEBUG 'as_search_organisationenhed: skipping filtration on tilsGyldighed';
ELSE
	IF coalesce(array_length(organisationenhed_candidates,1),0)>0 THEN 

		FOREACH tilsGyldighedTypeObj IN ARRAY registreringObj.tilsGyldighed
		LOOP
			organisationenhed_candidates:=array(
			SELECT DISTINCT
			b.organisationenhed_id 
			FROM  organisationenhed_tils_gyldighed a
			JOIN organisationenhed_registrering b on a.organisationenhed_registrering_id=b.id and upper((b.registrering).timeperiod)='infinity'::TIMESTAMPTZ 
			WHERE
				(
					tilsGyldighedTypeObj.gyldighed IS NULL
					OR
					tilsGyldighedTypeObj.gyldighed = a.gyldighed
				)
				AND b.organisationenhed_id = ANY (organisationenhed_candidates)
				AND (a.virkning).TimePeriod @> actual_virkning
	);
			
		END LOOP;
	END IF;
END IF;

/*
--relationer OrganisationenhedRelationType[]
*/


--RAISE DEBUG 'organisationenhed_candidates_is_initialized step 4:%',organisationenhed_candidates_is_initialized;
--RAISE DEBUG 'organisationenhed_candidates step 4:%',organisationenhed_candidates;

--/**********************************************************//
--Filtration on relations
--/**********************************************************//


IF registreringObj IS NULL OR (registreringObj).relationer IS NULL OR coalesce(array_length((registreringObj).relationer,1),0)=0 THEN
	--RAISE DEBUG 'as_search_organisationenhed: skipping filtration on relationer';
ELSE
	IF coalesce(array_length(organisationenhed_candidates,1),0)>0 THEN
		FOREACH relationTypeObj IN ARRAY registreringObj.relationer
		LOOP
			organisationenhed_candidates:=array(
			SELECT DISTINCT
			b.organisationenhed_id 
			FROM  organisationenhed_relation a
			JOIN organisationenhed_registrering b on a.organisationenhed_registrering_id=b.id and upper((b.registrering).timeperiod)='infinity'::TIMESTAMPTZ
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
				AND b.organisationenhed_id = ANY (organisationenhed_candidates)
				AND (a.virkning).TimePeriod @> actual_virkning 
	);
		END LOOP;
	END IF;
END IF;
--/**********************//

--RAISE DEBUG 'organisationenhed_candidates_is_initialized step 5:%',organisationenhed_candidates_is_initialized;
--RAISE DEBUG 'organisationenhed_candidates step 5:%',organisationenhed_candidates;

organisationenhed_passed_auth_filter:=array(
SELECT
a.id 
FROM
unnest (organisationenhed_passed_auth_filter) a(id)
UNION
SELECT
b.id
FROM
unnest (organisationenhed_candidates) b(id)
);

--optimization 
IF coalesce(array_length(organisationenhed_passed_auth_filter,1),0)=coalesce(array_length(organisationenhed_uuids,1),0) AND organisationenhed_passed_auth_filter @>organisationenhed_uuids THEN
	RETURN organisationenhed_passed_auth_filter;
END IF;


END LOOP; --LOOP registreringObj


RETURN organisationenhed_passed_auth_filter;


END;
$$ LANGUAGE plpgsql STABLE; 





