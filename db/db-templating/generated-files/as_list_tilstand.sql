-- Copyright (C) 2015 Magenta ApS, http://magenta.dk.
-- Contact: info@magenta.dk.
--
-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at http://mozilla.org/MPL/2.0/.

/*
NOTICE: This file is auto-generated using the script: apply-template.py tilstand as_list.jinja.sql
*/

CREATE OR REPLACE FUNCTION as_list_tilstand(tilstand_uuids uuid[],
  registrering_tstzrange tstzrange,
  virkning_tstzrange tstzrange,
  auth_criteria_arr TilstandRegistreringType[]=null
  )
  RETURNS TilstandType[] AS
$$
DECLARE
	auth_filtered_uuids uuid[];
	result TilstandType[];
BEGIN


/*** Verify that the object meets the stipulated access allowed criteria  ***/
auth_filtered_uuids:=_as_filter_unauth_tilstand(tilstand_uuids,auth_criteria_arr); 
IF NOT (coalesce(array_length(auth_filtered_uuids,1),0)=coalesce(array_length(tilstand_uuids,1),0) AND auth_filtered_uuids @>tilstand_uuids) THEN
  RAISE EXCEPTION 'Unable to list tilstand with uuids [%]. All objects do not fullfill the stipulated criteria:%',tilstand_uuids,to_json(auth_criteria_arr)  USING ERRCODE = 'MO401'; 
END IF;
/*********************/

SELECT 
array_agg( x.tilstandObj) into result
FROM
(
SELECT
ROW(
	a.tilstand_id,
	array_agg(
		ROW (
			a.registrering,
			a.TilstandTilsStatusArr,
			a.TilstandTilsPubliceretArr,
			a.TilstandAttrEgenskaberArr,
			a.TilstandRelationArr
		)::TilstandRegistreringType
		order by upper((a.registrering).TimePeriod) DESC		
	) 
):: TilstandType  tilstandObj
FROM
(
	SELECT
	a.tilstand_id,
	a.tilstand_registrering_id,
	a.registrering,
	a.TilstandAttrEgenskaberArr,
	a.TilstandTilsStatusArr,
	a.TilstandTilsPubliceretArr,
	_remove_nulls_in_array(array_agg(
		CASE
		WHEN b.id is not null THEN
		ROW (
				b.rel_type,
				b.virkning,
				b.rel_maal_uuid,
				b.rel_maal_urn,
				b.objekt_type,
 				b.rel_index,
				b.tilstand_vaerdi_attr  
			):: TilstandRelationType
		ELSE
		NULL
		END
		order by b.rel_maal_uuid,b.rel_maal_urn,b.rel_type,b.objekt_type,b.rel_index,b.tilstand_vaerdi_attr,b.virkning
	)) TilstandRelationArr
	FROM
	(
			SELECT
			a.tilstand_id,
			a.tilstand_registrering_id,
			a.registrering,
			a.TilstandAttrEgenskaberArr,
			a.TilstandTilsPubliceretArr,
			_remove_nulls_in_array(array_agg
				(
					CASE
					WHEN b.id is not null THEN 
					ROW(
						b.virkning,
						b.status
						) ::TilstandStatusTilsType
					ELSE NULL
					END
					order by b.status,b.virkning
				)) TilstandTilsStatusArr		
			FROM
			(
			SELECT
			a.tilstand_id,
			a.tilstand_registrering_id,
			a.registrering,
			a.TilstandAttrEgenskaberArr,
			_remove_nulls_in_array(array_agg
				(
					CASE
					WHEN b.id is not null THEN 
					ROW(
						b.virkning,
						b.publiceret
						) ::TilstandPubliceretTilsType
					ELSE NULL
					END
					order by b.publiceret,b.virkning
				)) TilstandTilsPubliceretArr		
			FROM
			(
					SELECT
					a.tilstand_id,
					a.tilstand_registrering_id,
					a.registrering,
					_remove_nulls_in_array(array_agg(
						CASE 
						WHEN b.id is not null THEN
						ROW(
					 		b.brugervendtnoegle,
					 		b.beskrivelse,
					   		b.virkning 
							)::TilstandEgenskaberAttrType
						ELSE
						NULL
						END
						order by b.brugervendtnoegle,b.beskrivelse,b.virkning
					)) TilstandAttrEgenskaberArr 
					FROM
					(
					SELECT
					a.id tilstand_id,
					b.id tilstand_registrering_id,
					b.registrering			
					FROM		tilstand a
					JOIN 		tilstand_registrering b 	ON b.tilstand_id=a.id
					WHERE a.id = ANY (tilstand_uuids) AND ((registrering_tstzrange is null AND upper((b.registrering).timeperiod)='infinity'::TIMESTAMPTZ) OR registrering_tstzrange && (b.registrering).timeperiod)--filter ON registrering_tstzrange
					) as a
					LEFT JOIN tilstand_attr_egenskaber as b ON b.tilstand_registrering_id=a.tilstand_registrering_id AND (virkning_tstzrange is null OR (b.virkning).TimePeriod && virkning_tstzrange) --filter ON virkning_tstzrange if given			
					GROUP BY 
					a.tilstand_id,
					a.tilstand_registrering_id,
					a.registrering	
			) as a
			LEFT JOIN tilstand_tils_publiceret as b ON b.tilstand_registrering_id=a.tilstand_registrering_id AND (virkning_tstzrange is null OR (b.virkning).TimePeriod && virkning_tstzrange) --filter ON virkning_tstzrange if given			
			GROUP BY 
			a.tilstand_id,
			a.tilstand_registrering_id,
			a.registrering,
			a.TilstandAttrEgenskaberArr	
			) as a
			LEFT JOIN tilstand_tils_status as b ON b.tilstand_registrering_id=a.tilstand_registrering_id AND (virkning_tstzrange is null OR (b.virkning).TimePeriod && virkning_tstzrange) --filter ON virkning_tstzrange if given			
			GROUP BY 
			a.tilstand_id,
			a.tilstand_registrering_id,
			a.registrering,
			a.TilstandAttrEgenskaberArr,
			a.TilstandTilsPubliceretArr
	) as a
	LEFT JOIN tilstand_relation b ON b.tilstand_registrering_id=a.tilstand_registrering_id AND (virkning_tstzrange is null OR (b.virkning).TimePeriod && virkning_tstzrange) --filter ON virkning_tstzrange if given
	GROUP BY
	a.tilstand_id,
	a.tilstand_registrering_id,
	a.registrering,
	a.TilstandAttrEgenskaberArr,
	a.TilstandTilsPubliceretArr,
	a.TilstandTilsStatusArr
) as a
WHERE a.tilstand_id IS NOT NULL
GROUP BY 
a.tilstand_id
order by a.tilstand_id
) as x
;



RETURN result;

END;
$$ LANGUAGE plpgsql STABLE;



