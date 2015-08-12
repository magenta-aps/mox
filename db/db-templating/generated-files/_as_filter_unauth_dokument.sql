-- Copyright (C) 2015 Magenta ApS, http://magenta.dk.
-- Contact: info@magenta.dk.
--
-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at http://mozilla.org/MPL/2.0/.

/*
NOTICE: This file is auto-generated using the script: apply-template.py dokument _as_filter_unauth.jinja.sql
*/


CREATE OR REPLACE FUNCTION _as_filter_unauth_dokument(
	dokument_uuids uuid[],
	registreringObjArr DokumentRegistreringType[]
	)
  RETURNS uuid[] AS 
$$
DECLARE
	dokument_passed_auth_filter uuid[]:=ARRAY[]::uuid[];
	dokument_candidates uuid[];
	--to_be_applyed_filter_uuids uuid[]; 
	attrEgenskaberTypeObj DokumentEgenskaberAttrType;
	
  	tilsFremdriftTypeObj DokumentFremdriftTilsType;
	relationTypeObj DokumentRelationType;
	registreringObj DokumentRegistreringType;
	actual_virkning TIMESTAMPTZ:=current_timestamp;
BEGIN

--RAISE DEBUG 'step 0:registreringObj:%',registreringObj;

IF registreringObjArr IS NULL THEN
	RETURN dokument_uuids; --special case: All is allowed, no criteria present
END IF;

IF coalesce(array_length(registreringObjArr,1),0)=0 THEN
	RETURN ARRAY[]::uuid[]; --special case: Nothing is allowed. Empty list of criteria where at least one has to be met.				
END IF; 

IF dokument_uuids IS NULL OR  coalesce(array_length(dokument_uuids,1),0)=0 THEN
	RETURN ARRAY[]::uuid[]; --special case: No candidates given to filter.
END IF;



FOREACH registreringObj IN ARRAY registreringObjArr
LOOP

dokument_candidates:= dokument_uuids;



--RAISE DEBUG 'dokument_candidates_is_initialized step 1:%',dokument_candidates_is_initialized;
--RAISE DEBUG 'dokument_candidates step 1:%',dokument_candidates;
--/****************************//

--filter on attributes 
--/**********************************************************//
--Filtration on attribute: Egenskaber
--/**********************************************************//
IF registreringObj IS NULL OR (registreringObj).attrEgenskaber IS NULL THEN
	--RAISE DEBUG 'as_search_dokument: skipping filtration on attrEgenskaber';
ELSE
	IF coalesce(array_length(dokument_candidates,1),0)>0 THEN
		FOREACH attrEgenskaberTypeObj IN ARRAY registreringObj.attrEgenskaber
		LOOP
			dokument_candidates:=array(
			SELECT DISTINCT
			b.dokument_id 
			FROM  dokument_attr_egenskaber a 
			JOIN dokument_registrering b on a.dokument_registrering_id=b.id and upper((b.registrering).timeperiod)='infinity'::TIMESTAMPTZ 
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
					attrEgenskaberTypeObj.brevdato IS NULL
					OR 
					a.brevdato = attrEgenskaberTypeObj.brevdato 
				)
				AND
				(
					attrEgenskaberTypeObj.kassationskode IS NULL
					OR 
					a.kassationskode = attrEgenskaberTypeObj.kassationskode 
				)
				AND
				(
					attrEgenskaberTypeObj.major IS NULL
					OR 
					a.major = attrEgenskaberTypeObj.major 
				)
				AND
				(
					attrEgenskaberTypeObj.minor IS NULL
					OR 
					a.minor = attrEgenskaberTypeObj.minor 
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
					attrEgenskaberTypeObj.titel IS NULL
					OR 
					a.titel = attrEgenskaberTypeObj.titel 
				)
				AND
				(
					attrEgenskaberTypeObj.dokumenttype IS NULL
					OR 
					a.dokumenttype = attrEgenskaberTypeObj.dokumenttype 
				)
				AND b.dokument_id = ANY (dokument_candidates)
				AND (a.virkning).TimePeriod @> actual_virkning 
			);
			
		END LOOP;
	END IF;
END IF;
--RAISE DEBUG 'dokument_candidates_is_initialized step 3:%',dokument_candidates_is_initialized;
--RAISE DEBUG 'dokument_candidates step 3:%',dokument_candidates;

--RAISE DEBUG 'registrering,%',registreringObj;


--/**********************************************************//
--Filtration on state: Fremdrift
--/**********************************************************//
IF registreringObj IS NULL OR (registreringObj).tilsFremdrift IS NULL THEN
	--RAISE DEBUG 'as_search_dokument: skipping filtration on tilsFremdrift';
ELSE
	IF coalesce(array_length(dokument_candidates,1),0)>0 THEN 

		FOREACH tilsFremdriftTypeObj IN ARRAY registreringObj.tilsFremdrift
		LOOP
			dokument_candidates:=array(
			SELECT DISTINCT
			b.dokument_id 
			FROM  dokument_tils_fremdrift a
			JOIN dokument_registrering b on a.dokument_registrering_id=b.id and upper((b.registrering).timeperiod)='infinity'::TIMESTAMPTZ 
			WHERE
				(
					tilsFremdriftTypeObj.fremdrift IS NULL
					OR
					tilsFremdriftTypeObj.fremdrift = a.fremdrift
				)
				AND b.dokument_id = ANY (dokument_candidates)
				AND (a.virkning).TimePeriod @> actual_virkning
	);
			
		END LOOP;
	END IF;
END IF;

/*
--relationer DokumentRelationType[]
*/


--RAISE DEBUG 'dokument_candidates_is_initialized step 4:%',dokument_candidates_is_initialized;
--RAISE DEBUG 'dokument_candidates step 4:%',dokument_candidates;

--/**********************************************************//
--Filtration on relations
--/**********************************************************//


IF registreringObj IS NULL OR (registreringObj).relationer IS NULL OR coalesce(array_length((registreringObj).relationer,1),0)=0 THEN
	--RAISE DEBUG 'as_search_dokument: skipping filtration on relationer';
ELSE
	IF coalesce(array_length(dokument_candidates,1),0)>0 THEN
		FOREACH relationTypeObj IN ARRAY registreringObj.relationer
		LOOP
			dokument_candidates:=array(
			SELECT DISTINCT
			b.dokument_id 
			FROM  dokument_relation a
			JOIN dokument_registrering b on a.dokument_registrering_id=b.id and upper((b.registrering).timeperiod)='infinity'::TIMESTAMPTZ
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
				AND b.dokument_id = ANY (dokument_candidates)
				AND (a.virkning).TimePeriod @> actual_virkning 
	);
		END LOOP;
	END IF;
END IF;
--/**********************//

--RAISE DEBUG 'dokument_candidates_is_initialized step 5:%',dokument_candidates_is_initialized;
--RAISE DEBUG 'dokument_candidates step 5:%',dokument_candidates;

dokument_passed_auth_filter:=array(
SELECT
a.id 
FROM
unnest (dokument_passed_auth_filter) a(id)
UNION
SELECT
b.id
FROM
unnest (dokument_candidates) b(id)
);

--optimization 
IF coalesce(array_length(dokument_passed_auth_filter,1),0)=coalesce(array_length(dokument_uuids,1),0) AND dokument_passed_auth_filter @>dokument_uuids THEN
	RETURN dokument_passed_auth_filter;
END IF;


END LOOP; --LOOP registreringObj


RETURN dokument_passed_auth_filter;


END;
$$ LANGUAGE plpgsql STABLE; 





