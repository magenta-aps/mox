-- Copyright (C) 2015 Magenta ApS, http://magenta.dk.
-- Contact: info@magenta.dk.
--
-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at http://mozilla.org/MPL/2.0/.

/*
NOTICE: This file is auto-generated using the script: apply-template.py organisation _as_filter_unauth.jinja.sql
*/


CREATE OR REPLACE FUNCTION _as_filter_unauth_organisation(
	organisation_uuids uuid[],
	registreringObjArr OrganisationRegistreringType[]
	)
  RETURNS uuid[] AS 
$$
DECLARE
	organisation_passed_auth_filter uuid[]:=ARRAY[]::uuid[];
	organisation_candidates uuid[];
	--to_be_applyed_filter_uuids uuid[]; 
	attrEgenskaberTypeObj OrganisationEgenskaberAttrType;
	
  	tilsGyldighedTypeObj OrganisationGyldighedTilsType;
	relationTypeObj OrganisationRelationType;
	registreringObj OrganisationRegistreringType;
	actual_virkning TIMESTAMPTZ:=current_timestamp;
BEGIN

--RAISE DEBUG 'step 0:registreringObj:%',registreringObj;

IF registreringObjArr IS NULL THEN
	RETURN organisation_uuids; --special case: All is allowed, no criteria present
END IF;

IF coalesce(array_length(registreringObjArr,1),0)=0 THEN
	RETURN ARRAY[]::uuid[]; --special case: Nothing is allowed. Empty list of criteria where at least one has to be met.				
END IF; 

IF organisation_uuids IS NULL OR  coalesce(array_length(organisation_uuids,1),0)=0 THEN
	RETURN ARRAY[]::uuid[]; --special case: No candidates given to filter.
END IF;



FOREACH registreringObj IN ARRAY registreringObjArr
LOOP

organisation_candidates:= organisation_uuids;



--RAISE DEBUG 'organisation_candidates_is_initialized step 1:%',organisation_candidates_is_initialized;
--RAISE DEBUG 'organisation_candidates step 1:%',organisation_candidates;
--/****************************//

--filter on attributes 
--/**********************************************************//
--Filtration on attribute: Egenskaber
--/**********************************************************//
IF registreringObj IS NULL OR (registreringObj).attrEgenskaber IS NULL THEN
	--RAISE DEBUG 'as_search_organisation: skipping filtration on attrEgenskaber';
ELSE
	IF coalesce(array_length(organisation_candidates,1),0)>0 THEN
		FOREACH attrEgenskaberTypeObj IN ARRAY registreringObj.attrEgenskaber
		LOOP
			organisation_candidates:=array(
			SELECT DISTINCT
			b.organisation_id 
			FROM  organisation_attr_egenskaber a 
			JOIN organisation_registrering b on a.organisation_registrering_id=b.id and upper((b.registrering).timeperiod)='infinity'::TIMESTAMPTZ 
			WHERE
				(
					attrEgenskaberTypeObj.brugervendtnoegle IS NULL
					OR 
					a.brugervendtnoegle = attrEgenskaberTypeObj.brugervendtnoegle 
				)
				AND
				(
					attrEgenskaberTypeObj.organisationsnavn IS NULL
					OR 
					a.organisationsnavn = attrEgenskaberTypeObj.organisationsnavn 
				)
				AND b.organisation_id = ANY (organisation_candidates)
				AND (a.virkning).TimePeriod && actual_virkning 
			);
			
		END LOOP;
	END IF;
END IF;
--RAISE DEBUG 'organisation_candidates_is_initialized step 3:%',organisation_candidates_is_initialized;
--RAISE DEBUG 'organisation_candidates step 3:%',organisation_candidates;

--RAISE DEBUG 'registrering,%',registreringObj;


--/**********************************************************//
--Filtration on state: Gyldighed
--/**********************************************************//
IF registreringObj IS NULL OR (registreringObj).tilsGyldighed IS NULL THEN
	--RAISE DEBUG 'as_search_organisation: skipping filtration on tilsGyldighed';
ELSE
	IF coalesce(array_length(organisation_candidates,1),0)>0 THEN 

		FOREACH tilsGyldighedTypeObj IN ARRAY registreringObj.tilsGyldighed
		LOOP
			organisation_candidates:=array(
			SELECT DISTINCT
			b.organisation_id 
			FROM  organisation_tils_gyldighed a
			JOIN organisation_registrering b on a.organisation_registrering_id=b.id and upper((b.registrering).timeperiod)='infinity'::TIMESTAMPTZ 
			WHERE
				(
					tilsGyldighedTypeObj.gyldighed IS NULL
					OR
					tilsGyldighedTypeObj.gyldighed = a.gyldighed
				)
				AND b.organisation_id = ANY (organisation_candidates)
				AND (a.virkning).TimePeriod && actual_virkning
	);
			
		END LOOP;
	END IF;
END IF;

/*
--relationer OrganisationRelationType[]
*/


--RAISE DEBUG 'organisation_candidates_is_initialized step 4:%',organisation_candidates_is_initialized;
--RAISE DEBUG 'organisation_candidates step 4:%',organisation_candidates;

--/**********************************************************//
--Filtration on relations
--/**********************************************************//


IF registreringObj IS NULL OR (registreringObj).relationer IS NULL OR coalesce(array_length((registreringObj).relationer,1),0)=0 THEN
	--RAISE DEBUG 'as_search_organisation: skipping filtration on relationer';
ELSE
	IF coalesce(array_length(organisation_candidates,1),0)>0 THEN
		FOREACH relationTypeObj IN ARRAY registreringObj.relationer
		LOOP
			organisation_candidates:=array(
			SELECT DISTINCT
			b.organisation_id 
			FROM  organisation_relation a
			JOIN organisation_registrering b on a.organisation_registrering_id=b.id and upper((b.registrering).timeperiod)='infinity'::TIMESTAMPTZ
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
				AND b.organisation_id = ANY (organisation_candidates)
				AND (a.virkning).TimePeriod && actual_virkning 
	);
		END LOOP;
	END IF;
END IF;
--/**********************//

--RAISE DEBUG 'organisation_candidates_is_initialized step 5:%',organisation_candidates_is_initialized;
--RAISE DEBUG 'organisation_candidates step 5:%',organisation_candidates;

organisation_passed_auth_filter:=array(
SELECT
a.id 
FROM
unnest (organisation_passed_auth_filter) a(id)
UNION
SELECT
b.id
FROM
unnest (organisation_candidates) b(id)
);

--optimization 
IF coalesce(array_length(organisation_passed_auth_filter,1),0)=coalesce(array_length(organisation_uuids,1),0) AND organisation_passed_auth_filter @>organisation_uuids THEN
	RETURN organisation_passed_auth_filter;
END IF;


END LOOP; --LOOP registreringObj


RETURN organisation_passed_auth_filter;


END;
$$ LANGUAGE plpgsql STABLE; 





