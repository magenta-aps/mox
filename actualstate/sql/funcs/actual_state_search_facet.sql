
-- Copyright (C) 2015 Magenta ApS, http://magenta.dk.
-- Contact: info@magenta.dk.
--
-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at http://mozilla.org/MPL/2.0/.


CREATE OR REPLACE FUNCTION actual_state_search_facet(
	maxResults int,
	firstResult int,--TOOD ??
	facet_uuid uuid,
	registrering FacetRegistreringType
	)
  RETURNS uuid[] AS 
$$
DECLARE
	facet_candidates uuid[];
	facet_candidates_is_initialized boolean;
	to_be_applyed_filter_uuids uuid[];
  	attrEgenskaberTypeObj FacetAttrEgenskaberType;
  	tilsPubliceretStatusTypeObj FacetTilsPubliceretType;
	relationTypeObj FacetRelationType;
BEGIN



facet_candidates_is_initialized := false;


IF facet_uuid is not NULL THEN
	facet_candidates:= ARRAY[facet_uuid];
	facet_candidates_is_initialized:=true;
END IF;


--/****************************//
--filter on registration
IF registrering.registrering IS NOT NULL AND 
										(
											(registrering.registrering).timeperiod IS NOT NULL AND NOT isempty((registrering.registrering).timeperiod)  
											OR
											(registrering.registrering).livscykluskode IS NOT NULL
											OR
											(registrering.registrering).brugerref IS NOT NULL
											OR
											(registrering.registrering).note IS NOT NULL
										) 
										THEN
	to_be_applyed_filter_uuids:=array(
	SELECT 
		facet_uuid
	FROM
		facet_registrering b
	WHERE
		(
			(
				(registrering.registrering).timeperiod IS NULL OR isempty((registrering.registrering).timeperiod)
			)
			OR
			(registrering.registrering).timeperiod && (b.registrering).timeperiod
		)
		AND
		(
			(registrering.registrering).livscykluskode IS NULL 
			OR
			(registrering.registrering).livscykluskode = (b.registrering).livscykluskode 		
		) 
		AND
		(
			(registrering.registrering).brugerref IS NULL
			OR
			(registrering.registrering).brugerref = (b.registrering).brugerref
		)
		AND
		(
			(registrering.registrering).note IS NULL
			OR
			(registrering.registrering).note = (b.registrering).note
		)
	);


	IF facet_candidates_is_initialized THEN
		facet_candidates:= array(SELECT id from unnest(facet_candidates) as a(id) INTERSECT SELECT id from unnest(to_be_applyed_filter_uuids) as b(id) );
	ELSE
		facet_candidates:=to_be_applyed_filter_uuids;
		facet_candidates_is_initialized:=true;
	END IF;

END IF;


--/****************************//
--filter on attr - egenskaber
IF array_length(facet_candidates)>0 OR NOT facet_candidates_is_initialized THEN
	FOREACH attrEgenskaberTypeObj IN ARRAY registrering.attrEgenskaber
	LOOP
		to_be_applyed_filter_uuids:=array(
		SELECT
		b.facet_id 
		FROM  facet_attr_egenskaber a
		JOIN facet_registrering b on a.registrering_id=b.id
		WHERE
			(
				(attrEgenskaberTypeObj.virkning IS NULL OR isempty((attrEgenskaberTypeObj.virkning).TimePeriod))
				OR
				((attrEgenskaberTypeObj.virkning).TimePeriod) && (a.virkning).TimePeriod
			)
			AND
			(
				attrEgenskaberTypeObj.brugervendt_noegle IS NULL
				OR
				attrEgenskaberTypeObj.brugervendt_noegle = a.brugervendt_noegle
			)
			AND
			(
				attrEgenskaberTypeObj.facetbeskrivelse IS NULL
				OR
				attrEgenskaberTypeObj.facetbeskrivelse = a.facetbeskrivelse
			)
			AND
			(
				attrEgenskaberTypeObj.facetplan IS NULL
				OR
				attrEgenskaberTypeObj.facetplan = a.facetplan
			)
			AND
			(
				attrEgenskaberTypeObj.facetopbygning IS NULL
				OR
				attrEgenskaberTypeObj.facetopbygning = a.facetopbygning
			)
			AND
			(
				attrEgenskaberTypeObj.facetophavsret IS NULL
				OR
				attrEgenskaberTypeObj.facetophavsret = a.facetophavsret
			)
			AND
			(
				attrEgenskaberTypeObj.facetsupplement IS NULL
				OR
				attrEgenskaberTypeObj.facetsupplement = a.facetsupplement
			)
			AND
			(
				attrEgenskaberTypeObj.retskilde IS NULL
				OR
				attrEgenskaberTypeObj.retskilde = a.retskilde
			)
		);
		

		IF facet_candidates_is_initialized THEN
			facet_candidates:= array(SELECT id from unnest(facet_candidates) as a(id) INTERSECT SELECT b.id from unnest(to_be_applyed_filter_uuids) as b(id) );
		ELSE
			facet_candidates:=to_be_applyed_filter_uuids;
			facet_candidates_is_initialized:=true;
		END IF;

	END LOOP;
END IF;

--/****************************//
--filter on states -- publiceret
IF array_length(facet_candidates)>0 OR NOT facet_candidates_is_initialized THEN
	FOREACH tilsPubliceretStatusTypeObj IN ARRAY registrering.tilsPubliceretStatus
	LOOP
		to_be_applyed_filter_uuids:=array(
		SELECT
		b.facet_id 
		FROM  facet_tils_publiceret a
		JOIN facet_registrering b on a.registrering_id=b.id
		WHERE
			(
				(tilsPubliceretStatusTypeObj.virkning IS NULL OR isempty((tilsPubliceretStatusTypeObj.virkning).TimePeriod))
				OR
				((tilsPubliceretStatusTypeObj.virkning).TimePeriod) && (a.virkning).TimePeriod
			)
			AND
			(
				tilsPubliceretStatusTypeObj.status IS NULL
				OR
				tilsPubliceretStatusTypeObj.status = a.status
			)
);
		

		IF facet_candidates_is_initialized THEN
			facet_candidates:= array(SELECT id from unnest(facet_candidates) as a(id) INTERSECT SELECT b.id from unnest(to_be_applyed_filter_uuids) as b(id) );
		ELSE
			facet_candidates:=to_be_applyed_filter_uuids;
			facet_candidates_is_initialized:=true;
		END IF;

	END LOOP;
END IF;

/*
--relationer FacetRelationType[]
*/

--/****************************//
--filter on relations

IF array_length(facet_candidates)>0 OR NOT facet_candidates_is_initialized THEN
	FOREACH relationTypeObj IN ARRAY registrering.relationer
	LOOP
		to_be_applyed_filter_uuids:=array(
		SELECT
		b.facet_id 
		FROM  facet_relation a
		JOIN facet_registrering b on a.registrering_id=b.id
		WHERE
			(
				(relationTypeObj.virkning IS NULL OR isempty((relationTypeObj.virkning).TimePeriod))
				OR
				((relationTypeObj.virkning).TimePeriod) && (a.virkning).TimePeriod
			)
			AND
			(	
				relationTypeObj.relType IS NULL
				OR
				relationTypeObj.relType = a.relType
			)
			AND
			(
				relationTypeObj.relMaal IS NULL
				OR
				relationTypeObj.relMaal = a.relMaal	
			)
);
		

		IF facet_candidates_is_initialized THEN
			facet_candidates:= array(SELECT id from unnest(facet_candidates) as a(id) INTERSECT SELECT b.id from unnest(to_be_applyed_filter_uuids) as b(id) );
		ELSE
			facet_candidates:=to_be_applyed_filter_uuids;
			facet_candidates_is_initialized:=true;
		END IF;

	END LOOP;
END IF;


--/**********************//
IF maxResults IS NOT NULL THEN
	facet_candidates:=array(
		SELECT id FROM unnest(facet_candidates) as a(id) LIMIT maxResults
	);
END IF;



return facet_candidates;

--TODO: Test and verify!


END;
$$ LANGUAGE plpgsql STABLE; 