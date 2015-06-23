-- Copyright (C) 2015 Magenta ApS, http://magenta.dk.
-- Contact: info@magenta.dk.
--
-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at http://mozilla.org/MPL/2.0/.

/*
NOTICE: This file is auto-generated using the script: apply-template.py facet as_list.jinja.sql
*/

CREATE OR REPLACE FUNCTION as_list_facet(facet_uuids uuid[],
  registrering_tstzrange tstzrange,
  virkning_tstzrange tstzrange)
  RETURNS setof FacetType AS
  $BODY$

SELECT
ROW(
	a.facet_id,
	array_agg(
		ROW (
			a.registrering,
			a.FacetTilsPubliceretArr,
			a.FacetAttrEgenskaberArr,
			a.FacetRelationArr
		)::FacetRegistreringType
		order by upper((a.registrering).TimePeriod) DESC		
	) 
):: FacetType
FROM
(
	SELECT
	a.facet_id,
	a.facet_registrering_id,
	a.registrering,
	a.FacetAttrEgenskaberArr,
	a.FacetTilsPubliceretArr,
	_remove_nulls_in_array(array_agg(
		CASE
		WHEN b.id is not null THEN
		ROW (
				b.rel_type,
				b.virkning,
				b.rel_maal_uuid,
				b.rel_maal_urn,
				b.objekt_type 
			):: FacetRelationType
		ELSE
		NULL
		END
		order by b.rel_maal_uuid,b.rel_maal_urn,b.rel_type,b.objekt_type,b.virkning
	)) FacetRelationArr
	FROM
	(
			SELECT
			a.facet_id,
			a.facet_registrering_id,
			a.registrering,
			a.FacetAttrEgenskaberArr,
			_remove_nulls_in_array(array_agg
				(
					CASE
					WHEN b.id is not null THEN 
					ROW(
						b.virkning,
						b.publiceret
						) ::FacetPubliceretTilsType
					ELSE NULL
					END
					order by b.publiceret,b.virkning
				)) FacetTilsPubliceretArr		
			FROM
			(
					SELECT
					a.facet_id,
					a.facet_registrering_id,
					a.registrering,
					_remove_nulls_in_array(array_agg(
						CASE 
						WHEN b.id is not null THEN
						ROW(
					 		b.brugervendtnoegle,
					 		b.beskrivelse,
					 		b.opbygning,
					 		b.ophavsret,
					 		b.plan,
					 		b.supplement,
					 		b.retskilde,
					   		b.virkning 
							)::FacetEgenskaberAttrType
						ELSE
						NULL
						END
						order by b.brugervendtnoegle,b.beskrivelse,b.opbygning,b.ophavsret,b.plan,b.supplement,b.retskilde,b.virkning
					)) FacetAttrEgenskaberArr 
					FROM
					(
					SELECT
					a.id facet_id,
					b.id facet_registrering_id,
					b.registrering			
					FROM		facet a
					JOIN 		facet_registrering b 	ON b.facet_id=a.id
					WHERE a.id = ANY (facet_uuids) AND ((registrering_tstzrange is null AND upper((b.registrering).timeperiod)='infinity'::TIMESTAMPTZ) OR registrering_tstzrange && (b.registrering).timeperiod)--filter ON registrering_tstzrange
					) as a
					LEFT JOIN facet_attr_egenskaber as b ON b.facet_registrering_id=a.facet_registrering_id AND (virkning_tstzrange is null OR (b.virkning).TimePeriod && virkning_tstzrange) --filter ON virkning_tstzrange if given			
					GROUP BY 
					a.facet_id,
					a.facet_registrering_id,
					a.registrering	
			) as a
			LEFT JOIN facet_tils_publiceret as b ON b.facet_registrering_id=a.facet_registrering_id AND (virkning_tstzrange is null OR (b.virkning).TimePeriod && virkning_tstzrange) --filter ON virkning_tstzrange if given			
			GROUP BY 
			a.facet_id,
			a.facet_registrering_id,
			a.registrering,
			a.FacetAttrEgenskaberArr
	) as a
	LEFT JOIN facet_relation b ON b.facet_registrering_id=a.facet_registrering_id AND (virkning_tstzrange is null OR (b.virkning).TimePeriod && virkning_tstzrange) --filter ON virkning_tstzrange if given
	GROUP BY
	a.facet_id,
	a.facet_registrering_id,
	a.registrering,
	a.FacetAttrEgenskaberArr,
	a.FacetTilsPubliceretArr
) as a
WHERE a.facet_id IS NOT NULL
GROUP BY 
a.facet_id
order by a.facet_id

$BODY$
LANGUAGE sql STABLE
;


