-- Copyright (C) 2015 Magenta ApS, http://magenta.dk.
-- Contact: info@magenta.dk.
--
-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at http://mozilla.org/MPL/2.0/.

/*
NOTICE: This file is auto-generated using the script: apply-template.py klassifikation actual_state_list.jinja.sql
*/

CREATE OR REPLACE FUNCTION actual_state_list_klassifikation(klassifikation_uuids uuid[],
  registrering_tstzrange tstzrange,
  virkning_tstzrange tstzrange)
  RETURNS setof KlassifikationType AS
  $BODY$

SELECT
ROW(
	a.klassifikation_id,
	array_agg(
		ROW (
			a.registrering,
			a.KlassifikationTilsPubliceretArr,
			a.KlassifikationAttrEgenskaberArr,
			a.KlassifikationRelationArr
		)::KlassifikationRegistreringType
		order by a.klassifikation_registrering_id		
	) 
):: KlassifikationType
FROM
(
	SELECT
	a.klassifikation_id,
	a.klassifikation_registrering_id,
	a.registrering,
	a.KlassifikationAttrEgenskaberArr,
	a.KlassifikationTilsPubliceretArr,
	array_agg(
		ROW (
				b.rel_type,
				b.virkning,
				b.rel_maal 
			):: KlassifikationRelationType
		order by b.id
	) KlassifikationRelationArr
	FROM
	(
			SELECT
			a.klassifikation_id,
			a.klassifikation_registrering_id,
			a.registrering,
			a.KlassifikationAttrEgenskaberArr,
			array_agg
				(
					ROW(
						b.virkning,
						b.publiceret
						) ::KlassifikationTilsPubliceretType
					order by b.id
				) KlassifikationTilsPubliceretArr		
			FROM
			(
					SELECT
					a.klassifikation_id,
					a.klassifikation_registrering_id,
					a.registrering,
					array_agg(
						ROW(
					 		b.brugervendtnoegle,
					 		b.beskrivelse,
					 		b.kaldenavn,
					 		b.ophavsret,
					   		b.virkning 
							)::KlassifikationAttrEgenskaberType
						order by b.id
					) KlassifikationAttrEgenskaberArr 
					FROM
					(
					SELECT
					a.id klassifikation_id,
					b.id klassifikation_registrering_id,
					b.registrering			
					FROM		klassifikation a
					JOIN 		klassifikation_registrering b 	ON b.klassifikation_id=a.id
					WHERE a.id = ANY (klassifikation_uuids) AND (((registrering_tstzrange is null OR isempty(registrering_tstzrange)) AND upper((b.registrering).timeperiod)='infinity'::TIMESTAMPTZ) OR registrering_tstzrange && (b.registrering).timeperiod)--filter ON registrering_tstzrange
					) as a
					LEFT JOIN klassifikation_attr_egenskaber as b ON b.klassifikation_registrering_id=a.klassifikation_registrering_id AND ((virkning_tstzrange is null OR isempty(virkning_tstzrange)) OR (b.virkning).TimePeriod && virkning_tstzrange) --filter ON virkning_tstzrange if given			
					GROUP BY 
					a.klassifikation_id,
					a.klassifikation_registrering_id,
					a.registrering	
			) as a
			LEFT JOIN klassifikation_tils_publiceret as b ON b.klassifikation_registrering_id=a.klassifikation_registrering_id AND ((virkning_tstzrange is null OR isempty(virkning_tstzrange)) OR (b.virkning).TimePeriod && virkning_tstzrange) --filter ON virkning_tstzrange if given			
			GROUP BY 
			a.klassifikation_id,
			a.klassifikation_registrering_id,
			a.registrering,
			a.KlassifikationAttrEgenskaberArr
	) as a
	LEFT JOIN klassifikation_relation b ON b.klassifikation_registrering_id=a.klassifikation_registrering_id AND ((virkning_tstzrange is null OR isempty(virkning_tstzrange)) OR (b.virkning).TimePeriod && virkning_tstzrange) --filter ON virkning_tstzrange if given
	GROUP BY
	a.klassifikation_id,
	a.klassifikation_registrering_id,
	a.registrering,
	a.KlassifikationAttrEgenskaberArr,
	a.KlassifikationTilsPubliceretArr
) as a
GROUP BY 
a.klassifikation_id
order by a.klassifikation_id

$BODY$
LANGUAGE sql STABLE
;


