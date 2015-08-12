-- Copyright (C) 2015 Magenta ApS, http://magenta.dk.
-- Contact: info@magenta.dk.
--
-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at http://mozilla.org/MPL/2.0/.

/*
NOTICE: This file is auto-generated using the script: apply-template.py sag _as_filter_unauth.jinja.sql
*/


CREATE OR REPLACE FUNCTION _as_filter_unauth_sag(
	sag_uuids uuid[],
	registreringObjArr SagRegistreringType[]
	)
  RETURNS uuid[] AS 
$$
DECLARE
	sag_passed_auth_filter uuid[]:=ARRAY[]::uuid[];
	sag_candidates uuid[];
	--to_be_applyed_filter_uuids uuid[]; 
	attrEgenskaberTypeObj SagEgenskaberAttrType;
	
  	tilsFremdriftTypeObj SagFremdriftTilsType;
	relationTypeObj SagRelationType;
	registreringObj SagRegistreringType;
	actual_virkning TIMESTAMPTZ:=current_timestamp;
BEGIN

--RAISE DEBUG 'step 0:registreringObj:%',registreringObj;

IF registreringObjArr IS NULL THEN
	RETURN sag_uuids; --special case: All is allowed, no criteria present
END IF;

IF coalesce(array_length(registreringObjArr,1),0)=0 THEN
	RETURN ARRAY[]::uuid[]; --special case: Nothing is allowed. Empty list of criteria where at least one has to be met.				
END IF; 

IF sag_uuids IS NULL OR  coalesce(array_length(sag_uuids,1),0)=0 THEN
	RETURN ARRAY[]::uuid[]; --special case: No candidates given to filter.
END IF;



FOREACH registreringObj IN ARRAY registreringObjArr
LOOP

sag_candidates:= sag_uuids;



--RAISE DEBUG 'sag_candidates_is_initialized step 1:%',sag_candidates_is_initialized;
--RAISE DEBUG 'sag_candidates step 1:%',sag_candidates;
--/****************************//

--filter on attributes 
--/**********************************************************//
--Filtration on attribute: Egenskaber
--/**********************************************************//
IF registreringObj IS NULL OR (registreringObj).attrEgenskaber IS NULL THEN
	--RAISE DEBUG 'as_search_sag: skipping filtration on attrEgenskaber';
ELSE
	IF coalesce(array_length(sag_candidates,1),0)>0 THEN
		FOREACH attrEgenskaberTypeObj IN ARRAY registreringObj.attrEgenskaber
		LOOP
			sag_candidates:=array(
			SELECT DISTINCT
			b.sag_id 
			FROM  sag_attr_egenskaber a 
			JOIN sag_registrering b on a.sag_registrering_id=b.id and upper((b.registrering).timeperiod)='infinity'::TIMESTAMPTZ 
			WHERE
				(
					attrEgenskaberTypeObj.brugervendtnoegle IS NULL
					OR 
					a.brugervendtnoegle = attrEgenskaberTypeObj.brugervendtnoegle 
				)
				AND
				(
					attrEgenskaberTypeObj.afleveret IS NULL
					OR 
					a.afleveret = attrEgenskaberTypeObj.afleveret 
				)
				AND
				(
					attrEgenskaberTypeObj.beskrivelse IS NULL
					OR 
					a.beskrivelse = attrEgenskaberTypeObj.beskrivelse 
				)
				AND
				(
					attrEgenskaberTypeObj.hjemmel IS NULL
					OR 
					a.hjemmel = attrEgenskaberTypeObj.hjemmel 
				)
				AND
				(
					attrEgenskaberTypeObj.kassationskode IS NULL
					OR 
					a.kassationskode = attrEgenskaberTypeObj.kassationskode 
				)
				AND
				(
					attrEgenskaberTypeObj.offentlighedundtaget IS NULL
					OR
						(
							(
								(attrEgenskaberTypeObj.offentlighedundtaget).AlternativTitel IS NULL
								OR
								(a.offentlighedundtaget).AlternativTitel = (attrEgenskaberTypeObj.offentlighedundtaget).AlternativTitel 
							)
							AND
							(
								(attrEgenskaberTypeObj.offentlighedundtaget).Hjemmel IS NULL
								OR
								(a.offentlighedundtaget).Hjemmel = (attrEgenskaberTypeObj.offentlighedundtaget).Hjemmel
							)
						) 
				)
				AND
				(
					attrEgenskaberTypeObj.principiel IS NULL
					OR 
					a.principiel = attrEgenskaberTypeObj.principiel 
				)
				AND
				(
					attrEgenskaberTypeObj.sagsnummer IS NULL
					OR 
					a.sagsnummer = attrEgenskaberTypeObj.sagsnummer 
				)
				AND
				(
					attrEgenskaberTypeObj.titel IS NULL
					OR 
					a.titel = attrEgenskaberTypeObj.titel 
				)
				AND b.sag_id = ANY (sag_candidates)
				AND (a.virkning).TimePeriod && actual_virkning 
			);
			
		END LOOP;
	END IF;
END IF;
--RAISE DEBUG 'sag_candidates_is_initialized step 3:%',sag_candidates_is_initialized;
--RAISE DEBUG 'sag_candidates step 3:%',sag_candidates;

--RAISE DEBUG 'registrering,%',registreringObj;


--/**********************************************************//
--Filtration on state: Fremdrift
--/**********************************************************//
IF registreringObj IS NULL OR (registreringObj).tilsFremdrift IS NULL THEN
	--RAISE DEBUG 'as_search_sag: skipping filtration on tilsFremdrift';
ELSE
	IF coalesce(array_length(sag_candidates,1),0)>0 THEN 

		FOREACH tilsFremdriftTypeObj IN ARRAY registreringObj.tilsFremdrift
		LOOP
			sag_candidates:=array(
			SELECT DISTINCT
			b.sag_id 
			FROM  sag_tils_fremdrift a
			JOIN sag_registrering b on a.sag_registrering_id=b.id and upper((b.registrering).timeperiod)='infinity'::TIMESTAMPTZ 
			WHERE
				(
					tilsFremdriftTypeObj.fremdrift IS NULL
					OR
					tilsFremdriftTypeObj.fremdrift = a.fremdrift
				)
				AND b.sag_id = ANY (sag_candidates)
				AND (a.virkning).TimePeriod && actual_virkning
	);
			
		END LOOP;
	END IF;
END IF;

/*
--relationer SagRelationType[]
*/


--RAISE DEBUG 'sag_candidates_is_initialized step 4:%',sag_candidates_is_initialized;
--RAISE DEBUG 'sag_candidates step 4:%',sag_candidates;

--/**********************************************************//
--Filtration on relations
--/**********************************************************//


IF registreringObj IS NULL OR (registreringObj).relationer IS NULL OR coalesce(array_length((registreringObj).relationer,1),0)=0 THEN
	--RAISE DEBUG 'as_search_sag: skipping filtration on relationer';
ELSE
	IF coalesce(array_length(sag_candidates,1),0)>0 THEN
		FOREACH relationTypeObj IN ARRAY registreringObj.relationer
		LOOP
			sag_candidates:=array(
			SELECT DISTINCT
			b.sag_id 
			FROM  sag_relation a
			JOIN sag_registrering b on a.sag_registrering_id=b.id and upper((b.registrering).timeperiod)='infinity'::TIMESTAMPTZ
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
				AND b.sag_id = ANY (sag_candidates)
				AND (a.virkning).TimePeriod && actual_virkning 
	);
		END LOOP;
	END IF;
END IF;
--/**********************//

--RAISE DEBUG 'sag_candidates_is_initialized step 5:%',sag_candidates_is_initialized;
--RAISE DEBUG 'sag_candidates step 5:%',sag_candidates;

sag_passed_auth_filter:=array(
SELECT
a.id 
FROM
unnest (sag_passed_auth_filter) a(id)
UNION
SELECT
b.id
FROM
unnest (sag_candidates) b(id)
);

--optimization 
IF coalesce(array_length(sag_passed_auth_filter,1),0)=coalesce(array_length(sag_uuids,1),0) AND sag_passed_auth_filter @>sag_uuids THEN
	RETURN sag_passed_auth_filter;
END IF;


END LOOP; --LOOP registreringObj


RETURN sag_passed_auth_filter;


END;
$$ LANGUAGE plpgsql STABLE; 





