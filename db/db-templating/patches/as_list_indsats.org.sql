-- Copyright (C) 2015 Magenta ApS, http://magenta.dk.
-- Contact: info@magenta.dk.
--
-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at http://mozilla.org/MPL/2.0/.

/*
NOTICE: This file is auto-generated using the script: apply-template.py indsats as_list.jinja.sql
*/

CREATE OR REPLACE FUNCTION as_list_indsats(indsats_uuids uuid[],
  registrering_tstzrange tstzrange,
  virkning_tstzrange tstzrange,
  auth_criteria_arr IndsatsRegistreringType[]=null
  )
  RETURNS IndsatsType[] AS
$$
DECLARE
	auth_filtered_uuids uuid[];
	result IndsatsType[];
BEGIN


/*** Verify that the object meets the stipulated access allowed criteria  ***/
auth_filtered_uuids:=_as_filter_unauth_indsats(indsats_uuids,auth_criteria_arr); 
IF NOT (coalesce(array_length(auth_filtered_uuids,1),0)=coalesce(array_length(indsats_uuids,1),0) AND auth_filtered_uuids @>indsats_uuids) THEN
  RAISE EXCEPTION 'Unable to list indsats with uuids [%]. All objects do not fullfill the stipulated criteria:%',indsats_uuids,to_json(auth_criteria_arr)  USING ERRCODE = 'MO401'; 
END IF;
/*********************/

SELECT 
array_agg( x.indsatsObj) into result
FROM
(
SELECT
ROW(
	a.indsats_id,
	array_agg(
		ROW (
			a.registrering,
			a.IndsatsTilsPubliceretArr,
			a.IndsatsTilsFremdriftArr,
			a.IndsatsAttrEgenskaberArr,
			a.IndsatsRelationArr
		)::IndsatsRegistreringType
		order by upper((a.registrering).TimePeriod) DESC		
	) 
):: IndsatsType  indsatsObj
FROM
(
	SELECT
	a.indsats_id,
	a.indsats_registrering_id,
	a.registrering,
	a.IndsatsAttrEgenskaberArr,
	a.IndsatsTilsPubliceretArr,
	a.IndsatsTilsFremdriftArr,
	_remove_nulls_in_array(array_agg(
		CASE
		WHEN b.id is not null THEN
		ROW (
				b.rel_type,
				b.virkning,
				b.rel_maal_uuid,
				b.rel_maal_urn,
				b.objekt_type,
 				b.rel_index 
			):: IndsatsRelationType
		ELSE
		NULL
		END
		order by b.rel_maal_uuid,b.rel_maal_urn,b.rel_type,b.objekt_type,b.rel_index,b.virkning
	)) IndsatsRelationArr
	FROM
	(
			SELECT
			a.indsats_id,
			a.indsats_registrering_id,
			a.registrering,
			a.IndsatsAttrEgenskaberArr,
			a.IndsatsTilsFremdriftArr,
			_remove_nulls_in_array(array_agg
				(
					CASE
					WHEN b.id is not null THEN 
					ROW(
						b.virkning,
						b.publiceret
						) ::IndsatsPubliceretTilsType
					ELSE NULL
					END
					order by b.publiceret,b.virkning
				)) IndsatsTilsPubliceretArr		
			FROM
			(
			SELECT
			a.indsats_id,
			a.indsats_registrering_id,
			a.registrering,
			a.IndsatsAttrEgenskaberArr,
			_remove_nulls_in_array(array_agg
				(
					CASE
					WHEN b.id is not null THEN 
					ROW(
						b.virkning,
						b.fremdrift
						) ::IndsatsFremdriftTilsType
					ELSE NULL
					END
					order by b.fremdrift,b.virkning
				)) IndsatsTilsFremdriftArr		
			FROM
			(
					SELECT
					a.indsats_id,
					a.indsats_registrering_id,
					a.registrering,
					_remove_nulls_in_array(array_agg(
						CASE 
						WHEN b.id is not null THEN
						ROW(
					 		b.brugervendtnoegle,
					 		b.beskrivelse,
					 		b.starttidspunkt,
					 		b.sluttidspunkt,
					   		b.virkning 
							)::IndsatsEgenskaberAttrType
						ELSE
						NULL
						END
						order by b.brugervendtnoegle,b.beskrivelse,b.starttidspunkt,b.sluttidspunkt,b.virkning
					)) IndsatsAttrEgenskaberArr 
					FROM
					(
					SELECT
					a.id indsats_id,
					b.id indsats_registrering_id,
					b.registrering			
					FROM		indsats a
					JOIN 		indsats_registrering b 	ON b.indsats_id=a.id
					WHERE a.id = ANY (indsats_uuids) AND ((registrering_tstzrange is null AND upper((b.registrering).timeperiod)='infinity'::TIMESTAMPTZ) OR registrering_tstzrange && (b.registrering).timeperiod)--filter ON registrering_tstzrange
					) as a
					LEFT JOIN indsats_attr_egenskaber as b ON b.indsats_registrering_id=a.indsats_registrering_id AND (virkning_tstzrange is null OR (b.virkning).TimePeriod && virkning_tstzrange) --filter ON virkning_tstzrange if given			
					GROUP BY 
					a.indsats_id,
					a.indsats_registrering_id,
					a.registrering	
			) as a
			LEFT JOIN indsats_tils_fremdrift as b ON b.indsats_registrering_id=a.indsats_registrering_id AND (virkning_tstzrange is null OR (b.virkning).TimePeriod && virkning_tstzrange) --filter ON virkning_tstzrange if given			
			GROUP BY 
			a.indsats_id,
			a.indsats_registrering_id,
			a.registrering,
			a.IndsatsAttrEgenskaberArr	
			) as a
			LEFT JOIN indsats_tils_publiceret as b ON b.indsats_registrering_id=a.indsats_registrering_id AND (virkning_tstzrange is null OR (b.virkning).TimePeriod && virkning_tstzrange) --filter ON virkning_tstzrange if given			
			GROUP BY 
			a.indsats_id,
			a.indsats_registrering_id,
			a.registrering,
			a.IndsatsAttrEgenskaberArr,
			a.IndsatsTilsFremdriftArr
	) as a
	LEFT JOIN indsats_relation b ON b.indsats_registrering_id=a.indsats_registrering_id AND (virkning_tstzrange is null OR (b.virkning).TimePeriod && virkning_tstzrange) --filter ON virkning_tstzrange if given
	GROUP BY
	a.indsats_id,
	a.indsats_registrering_id,
	a.registrering,
	a.IndsatsAttrEgenskaberArr,
	a.IndsatsTilsFremdriftArr,
	a.IndsatsTilsPubliceretArr
) as a
WHERE a.indsats_id IS NOT NULL
GROUP BY 
a.indsats_id
order by a.indsats_id
) as x
;



RETURN result;

END;
$$ LANGUAGE plpgsql STABLE;



