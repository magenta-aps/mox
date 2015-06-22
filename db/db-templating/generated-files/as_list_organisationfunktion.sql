-- Copyright (C) 2015 Magenta ApS, http://magenta.dk.
-- Contact: info@magenta.dk.
--
-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at http://mozilla.org/MPL/2.0/.

/*
NOTICE: This file is auto-generated using the script: apply-template.py organisationfunktion as_list.jinja.sql
*/

CREATE OR REPLACE FUNCTION as_list_organisationfunktion(organisationfunktion_uuids uuid[],
  registrering_tstzrange tstzrange,
  virkning_tstzrange tstzrange)
  RETURNS setof OrganisationfunktionType AS
  $BODY$

SELECT
ROW(
	a.organisationfunktion_id,
	array_agg(
		ROW (
			a.registrering,
			a.OrganisationfunktionTilsGyldighedArr,
			a.OrganisationfunktionAttrEgenskaberArr,
			a.OrganisationfunktionRelationArr
		)::OrganisationfunktionRegistreringType
		order by upper((a.registrering).TimePeriod) DESC		
	) 
):: OrganisationfunktionType
FROM
(
	SELECT
	a.organisationfunktion_id,
	a.organisationfunktion_registrering_id,
	a.registrering,
	a.OrganisationfunktionAttrEgenskaberArr,
	a.OrganisationfunktionTilsGyldighedArr,
	_remove_nulls_in_array(array_agg(
		CASE
		WHEN b.id is not null THEN
		ROW (
				b.rel_type,
				b.virkning,
				b.rel_maal 
			):: OrganisationfunktionRelationType
		ELSE
		NULL
		END
		order by b.rel_maal,b.rel_type,b.virkning
	)) OrganisationfunktionRelationArr
	FROM
	(
			SELECT
			a.organisationfunktion_id,
			a.organisationfunktion_registrering_id,
			a.registrering,
			a.OrganisationfunktionAttrEgenskaberArr,
			_remove_nulls_in_array(array_agg
				(
					CASE
					WHEN b.id is not null THEN 
					ROW(
						b.virkning,
						b.gyldighed
						) ::OrganisationfunktionGyldighedTilsType
					ELSE NULL
					END
					order by b.gyldighed,b.virkning
				)) OrganisationfunktionTilsGyldighedArr		
			FROM
			(
					SELECT
					a.organisationfunktion_id,
					a.organisationfunktion_registrering_id,
					a.registrering,
					_remove_nulls_in_array(array_agg(
						CASE 
						WHEN b.id is not null THEN
						ROW(
					 		b.brugervendtnoegle,
					 		b.funktionsnavn,
					   		b.virkning 
							)::OrganisationfunktionEgenskaberAttrType
						ELSE
						NULL
						END
						order by b.brugervendtnoegle,b.funktionsnavn,b.virkning
					)) OrganisationfunktionAttrEgenskaberArr 
					FROM
					(
					SELECT
					a.id organisationfunktion_id,
					b.id organisationfunktion_registrering_id,
					b.registrering			
					FROM		organisationfunktion a
					JOIN 		organisationfunktion_registrering b 	ON b.organisationfunktion_id=a.id
					WHERE a.id = ANY (organisationfunktion_uuids) AND ((registrering_tstzrange is null AND upper((b.registrering).timeperiod)='infinity'::TIMESTAMPTZ) OR registrering_tstzrange && (b.registrering).timeperiod)--filter ON registrering_tstzrange
					) as a
					LEFT JOIN organisationfunktion_attr_egenskaber as b ON b.organisationfunktion_registrering_id=a.organisationfunktion_registrering_id AND (virkning_tstzrange is null OR (b.virkning).TimePeriod && virkning_tstzrange) --filter ON virkning_tstzrange if given			
					GROUP BY 
					a.organisationfunktion_id,
					a.organisationfunktion_registrering_id,
					a.registrering	
			) as a
			LEFT JOIN organisationfunktion_tils_gyldighed as b ON b.organisationfunktion_registrering_id=a.organisationfunktion_registrering_id AND (virkning_tstzrange is null OR (b.virkning).TimePeriod && virkning_tstzrange) --filter ON virkning_tstzrange if given			
			GROUP BY 
			a.organisationfunktion_id,
			a.organisationfunktion_registrering_id,
			a.registrering,
			a.OrganisationfunktionAttrEgenskaberArr
	) as a
	LEFT JOIN organisationfunktion_relation b ON b.organisationfunktion_registrering_id=a.organisationfunktion_registrering_id AND (virkning_tstzrange is null OR (b.virkning).TimePeriod && virkning_tstzrange) --filter ON virkning_tstzrange if given
	GROUP BY
	a.organisationfunktion_id,
	a.organisationfunktion_registrering_id,
	a.registrering,
	a.OrganisationfunktionAttrEgenskaberArr,
	a.OrganisationfunktionTilsGyldighedArr
) as a
WHERE a.organisationfunktion_id IS NOT NULL
GROUP BY 
a.organisationfunktion_id
order by a.organisationfunktion_id

$BODY$
LANGUAGE sql STABLE
;


