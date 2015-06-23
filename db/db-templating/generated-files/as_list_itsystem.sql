-- Copyright (C) 2015 Magenta ApS, http://magenta.dk.
-- Contact: info@magenta.dk.
--
-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at http://mozilla.org/MPL/2.0/.

/*
NOTICE: This file is auto-generated using the script: apply-template.py itsystem as_list.jinja.sql
*/

CREATE OR REPLACE FUNCTION as_list_itsystem(itsystem_uuids uuid[],
  registrering_tstzrange tstzrange,
  virkning_tstzrange tstzrange)
  RETURNS setof ItsystemType AS
  $BODY$

SELECT
ROW(
	a.itsystem_id,
	array_agg(
		ROW (
			a.registrering,
			a.ItsystemTilsGyldighedArr,
			a.ItsystemAttrEgenskaberArr,
			a.ItsystemRelationArr
		)::ItsystemRegistreringType
		order by upper((a.registrering).TimePeriod) DESC		
	) 
):: ItsystemType
FROM
(
	SELECT
	a.itsystem_id,
	a.itsystem_registrering_id,
	a.registrering,
	a.ItsystemAttrEgenskaberArr,
	a.ItsystemTilsGyldighedArr,
	_remove_nulls_in_array(array_agg(
		CASE
		WHEN b.id is not null THEN
		ROW (
				b.rel_type,
				b.virkning,
				b.rel_maal_uuid,
				b.rel_maal_urn,
				b.objekt_type 
			):: ItsystemRelationType
		ELSE
		NULL
		END
		order by b.rel_maal_uuid,b.rel_maal_urn,b.rel_type,b.objekt_type,b.virkning
	)) ItsystemRelationArr
	FROM
	(
			SELECT
			a.itsystem_id,
			a.itsystem_registrering_id,
			a.registrering,
			a.ItsystemAttrEgenskaberArr,
			_remove_nulls_in_array(array_agg
				(
					CASE
					WHEN b.id is not null THEN 
					ROW(
						b.virkning,
						b.gyldighed
						) ::ItsystemGyldighedTilsType
					ELSE NULL
					END
					order by b.gyldighed,b.virkning
				)) ItsystemTilsGyldighedArr		
			FROM
			(
					SELECT
					a.itsystem_id,
					a.itsystem_registrering_id,
					a.registrering,
					_remove_nulls_in_array(array_agg(
						CASE 
						WHEN b.id is not null THEN
						ROW(
					 		b.brugervendtnoegle,
					 		b.itsystemnavn,
					 		b.itsystemtype,
					 		b.konfigurationreference,
					   		b.virkning 
							)::ItsystemEgenskaberAttrType
						ELSE
						NULL
						END
						order by b.brugervendtnoegle,b.itsystemnavn,b.itsystemtype,b.konfigurationreference,b.virkning
					)) ItsystemAttrEgenskaberArr 
					FROM
					(
					SELECT
					a.id itsystem_id,
					b.id itsystem_registrering_id,
					b.registrering			
					FROM		itsystem a
					JOIN 		itsystem_registrering b 	ON b.itsystem_id=a.id
					WHERE a.id = ANY (itsystem_uuids) AND ((registrering_tstzrange is null AND upper((b.registrering).timeperiod)='infinity'::TIMESTAMPTZ) OR registrering_tstzrange && (b.registrering).timeperiod)--filter ON registrering_tstzrange
					) as a
					LEFT JOIN itsystem_attr_egenskaber as b ON b.itsystem_registrering_id=a.itsystem_registrering_id AND (virkning_tstzrange is null OR (b.virkning).TimePeriod && virkning_tstzrange) --filter ON virkning_tstzrange if given			
					GROUP BY 
					a.itsystem_id,
					a.itsystem_registrering_id,
					a.registrering	
			) as a
			LEFT JOIN itsystem_tils_gyldighed as b ON b.itsystem_registrering_id=a.itsystem_registrering_id AND (virkning_tstzrange is null OR (b.virkning).TimePeriod && virkning_tstzrange) --filter ON virkning_tstzrange if given			
			GROUP BY 
			a.itsystem_id,
			a.itsystem_registrering_id,
			a.registrering,
			a.ItsystemAttrEgenskaberArr
	) as a
	LEFT JOIN itsystem_relation b ON b.itsystem_registrering_id=a.itsystem_registrering_id AND (virkning_tstzrange is null OR (b.virkning).TimePeriod && virkning_tstzrange) --filter ON virkning_tstzrange if given
	GROUP BY
	a.itsystem_id,
	a.itsystem_registrering_id,
	a.registrering,
	a.ItsystemAttrEgenskaberArr,
	a.ItsystemTilsGyldighedArr
) as a
WHERE a.itsystem_id IS NOT NULL
GROUP BY 
a.itsystem_id
order by a.itsystem_id

$BODY$
LANGUAGE sql STABLE
;


