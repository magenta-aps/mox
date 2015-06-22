-- Copyright (C) 2015 Magenta ApS, http://magenta.dk.
-- Contact: info@magenta.dk.
--
-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at http://mozilla.org/MPL/2.0/.

/*
NOTICE: This file is auto-generated using the script: apply-template.py klasse as_list.jinja.sql
*/

CREATE OR REPLACE FUNCTION as_list_klasse(klasse_uuids uuid[],
  registrering_tstzrange tstzrange,
  virkning_tstzrange tstzrange)
  RETURNS setof KlasseType AS
  $BODY$

SELECT
ROW(
	a.klasse_id,
	array_agg(
		ROW (
			a.registrering,
			a.KlasseTilsPubliceretArr,
			a.KlasseAttrEgenskaberArr,
			a.KlasseRelationArr
		)::KlasseRegistreringType
		order by upper((a.registrering).TimePeriod) DESC		
	) 
):: KlasseType
FROM
(
	SELECT
	a.klasse_id,
	a.klasse_registrering_id,
	a.registrering,
	a.KlasseAttrEgenskaberArr,
	a.KlasseTilsPubliceretArr,
	_remove_nulls_in_array(array_agg(
		CASE
		WHEN b.id is not null THEN
		ROW (
				b.rel_type,
				b.virkning,
				b.rel_maal 
			):: KlasseRelationType
		ELSE
		NULL
		END
		order by b.rel_maal,b.rel_type,b.virkning
	)) KlasseRelationArr
	FROM
	(
			SELECT
			a.klasse_id,
			a.klasse_registrering_id,
			a.registrering,
			a.KlasseAttrEgenskaberArr,
			_remove_nulls_in_array(array_agg
				(
					CASE
					WHEN b.id is not null THEN 
					ROW(
						b.virkning,
						b.publiceret
						) ::KlassePubliceretTilsType
					ELSE NULL
					END
					order by b.publiceret,b.virkning
				)) KlasseTilsPubliceretArr		
			FROM
			(
				SELECT
				a.klasse_id,
				a.klasse_registrering_id,
				a.registrering,
					_remove_nulls_in_array(array_agg(
						CASE 
						WHEN a.attr_id is not null THEN
						ROW(
					 		a.brugervendtnoegle,
					 		a.beskrivelse,
					 		a.eksempel,
					 		a.omfang,
					 		a.titel,
					 		a.retskilde,
					 		a.aendringsnotat,
					 		a.KlasseAttrEgenskaberSoegeordTypeArr,
					   		a.virkning 
						)::KlasseEgenskaberAttrType
						ELSE
						NULL
						END
					order by  a.brugervendtnoegle,a.beskrivelse,a.eksempel,a.omfang,a.titel,a.retskilde,a.aendringsnotat,a.virkning,a.KlasseAttrEgenskaberSoegeordTypeArr
				)) KlasseAttrEgenskaberArr 
				FROM		
				(
						SELECT
						a.klasse_id,
						a.klasse_registrering_id,
						a.registrering,
						b.id attr_id,
						b.brugervendtnoegle,
						b.beskrivelse,
						b.eksempel,
						b.omfang,
						b.titel,
						b.retskilde,
						b.aendringsnotat,
						b.virkning,	
						_remove_nulls_in_array(array_agg(
							CASE 
							WHEN c.id is not null THEN
							ROW(
						 		c.soegeordidentifikator,
						 		c.beskrivelse,
						 		c.soegeordskategori 
							)::KlasseSoegeordType
						ELSE
						NULL
						END
						order by c.soegeordidentifikator,c.beskrivelse,c.soegeordskategori
					)) KlasseAttrEgenskaberSoegeordTypeArr 
					FROM
						(
								SELECT
								a.id klasse_id,
								b.id klasse_registrering_id,
								b.registrering			
								FROM		klasse a
								JOIN 		klasse_registrering b 	ON b.klasse_id=a.id
								WHERE a.id = ANY (klasse_uuids) AND ((registrering_tstzrange is null AND upper((b.registrering).timeperiod)='infinity'::TIMESTAMPTZ) OR registrering_tstzrange && (b.registrering).timeperiod)--filter ON registrering_tstzrange
							) as a
						LEFT JOIN klasse_attr_egenskaber as b ON b.klasse_registrering_id=a.klasse_registrering_id AND (virkning_tstzrange is null OR (b.virkning).TimePeriod && virkning_tstzrange) --filter ON virkning_tstzrange if given			
						LEFT JOIN klasse_attr_egenskaber_soegeord as c ON c.klasse_attr_egenskaber_id=b.id
						GROUP BY 
						a.klasse_id,
						a.klasse_registrering_id,
						a.registrering,
						b.id,
						b.brugervendtnoegle,
						b.beskrivelse,
						b.eksempel,
						b.omfang,
						b.titel,
						b.retskilde,
						b.aendringsnotat,
						b.virkning
				) as a
			GROUP BY 
			a.klasse_id,
			a.klasse_registrering_id,
			a.registrering
			) as a
			LEFT JOIN klasse_tils_publiceret as b ON b.klasse_registrering_id=a.klasse_registrering_id AND (virkning_tstzrange is null OR (b.virkning).TimePeriod && virkning_tstzrange) --filter ON virkning_tstzrange if given			
			GROUP BY 
			a.klasse_id,
			a.klasse_registrering_id,
			a.registrering,
			a.KlasseAttrEgenskaberArr
	) as a
	LEFT JOIN klasse_relation b ON b.klasse_registrering_id=a.klasse_registrering_id AND (virkning_tstzrange is null OR (b.virkning).TimePeriod && virkning_tstzrange) --filter ON virkning_tstzrange if given
	GROUP BY
	a.klasse_id,
	a.klasse_registrering_id,
	a.registrering,
	a.KlasseAttrEgenskaberArr,
	a.KlasseTilsPubliceretArr
) as a
WHERE a.klasse_id IS NOT NULL
GROUP BY 
a.klasse_id
order by a.klasse_id

$BODY$
LANGUAGE sql STABLE
;


