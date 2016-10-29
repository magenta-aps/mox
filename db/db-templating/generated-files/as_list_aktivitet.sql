-- Copyright (C) 2015 Magenta ApS, http://magenta.dk.
-- Contact: info@magenta.dk.
--
-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at http://mozilla.org/MPL/2.0/.

/*
NOTICE: This file is auto-generated using the script: apply-template.py aktivitet as_list.jinja.sql
*/

CREATE OR REPLACE FUNCTION as_list_aktivitet(aktivitet_uuids uuid[],
  registrering_tstzrange tstzrange,
  virkning_tstzrange tstzrange,
  auth_criteria_arr AktivitetRegistreringType[]=null
  )
  RETURNS AktivitetType[] AS
$$
DECLARE
	auth_filtered_uuids uuid[];
	result AktivitetType[];
BEGIN


/*** Verify that the object meets the stipulated access allowed criteria  ***/
auth_filtered_uuids:=_as_filter_unauth_aktivitet(aktivitet_uuids,auth_criteria_arr); 
IF NOT (coalesce(array_length(auth_filtered_uuids,1),0)=coalesce(array_length(aktivitet_uuids,1),0) AND auth_filtered_uuids @>aktivitet_uuids) THEN
  RAISE EXCEPTION 'Unable to list aktivitet with uuids [%]. All objects do not fullfill the stipulated criteria:%',aktivitet_uuids,to_json(auth_criteria_arr)  USING ERRCODE = 'MO401'; 
END IF;
/*********************/

SELECT 
array_agg( x.aktivitetObj) into result
FROM
(
SELECT
ROW(
	a.aktivitet_id,
	array_agg(
		ROW (
			a.registrering,
			a.AktivitetTilsStatusArr,
			a.AktivitetTilsPubliceretArr,
			a.AktivitetAttrEgenskaberArr,
			a.AktivitetRelationArr
		)::AktivitetRegistreringType
		order by upper((a.registrering).TimePeriod) DESC		
	) 
):: AktivitetType  aktivitetObj
FROM
(
	SELECT
	a.aktivitet_id,
	a.aktivitet_registrering_id,
	a.registrering,
	a.AktivitetAttrEgenskaberArr,
	a.AktivitetTilsStatusArr,
	a.AktivitetTilsPubliceretArr,
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
				b.aktoer_attr 
			):: AktivitetRelationType
		ELSE
		NULL
		END
		order by b.rel_maal_uuid,b.rel_maal_urn,b.rel_type,b.objekt_type,b.rel_index,b.aktoer_attr,b.virkning
	)) AktivitetRelationArr
	FROM
	(
			SELECT
			a.aktivitet_id,
			a.aktivitet_registrering_id,
			a.registrering,
			a.AktivitetAttrEgenskaberArr,
			a.AktivitetTilsPubliceretArr,
			_remove_nulls_in_array(array_agg
				(
					CASE
					WHEN b.id is not null THEN 
					ROW(
						b.virkning,
						b.status
						) ::AktivitetStatusTilsType
					ELSE NULL
					END
					order by b.status,b.virkning
				)) AktivitetTilsStatusArr		
			FROM
			(
			SELECT
			a.aktivitet_id,
			a.aktivitet_registrering_id,
			a.registrering,
			a.AktivitetAttrEgenskaberArr,
			_remove_nulls_in_array(array_agg
				(
					CASE
					WHEN b.id is not null THEN 
					ROW(
						b.virkning,
						b.publiceret
						) ::AktivitetPubliceretTilsType
					ELSE NULL
					END
					order by b.publiceret,b.virkning
				)) AktivitetTilsPubliceretArr		
			FROM
			(
					SELECT
					a.aktivitet_id,
					a.aktivitet_registrering_id,
					a.registrering,
					_remove_nulls_in_array(array_agg(
						CASE 
						WHEN b.id is not null THEN
						ROW(
					 		b.brugervendtnoegle,
					 		b.aktivitetnavn,
					 		b.beskrivelse,
					 		b.starttidspunkt,
					 		b.sluttidspunkt,
					 		b.tidsforbrug,
					 		b.formaal,
					   		b.virkning 
							)::AktivitetEgenskaberAttrType
						ELSE
						NULL
						END
						order by b.brugervendtnoegle,b.aktivitetnavn,b.beskrivelse,b.starttidspunkt,b.sluttidspunkt,b.tidsforbrug,b.formaal,b.virkning
					)) AktivitetAttrEgenskaberArr 
					FROM
					(
					SELECT
					a.id aktivitet_id,
					b.id aktivitet_registrering_id,
					b.registrering			
					FROM		aktivitet a
					JOIN 		aktivitet_registrering b 	ON b.aktivitet_id=a.id
					WHERE a.id = ANY (aktivitet_uuids) AND ((registrering_tstzrange is null AND upper((b.registrering).timeperiod)='infinity'::TIMESTAMPTZ) OR registrering_tstzrange && (b.registrering).timeperiod)--filter ON registrering_tstzrange
					) as a
					LEFT JOIN aktivitet_attr_egenskaber as b ON b.aktivitet_registrering_id=a.aktivitet_registrering_id AND (virkning_tstzrange is null OR (b.virkning).TimePeriod && virkning_tstzrange) --filter ON virkning_tstzrange if given			
					GROUP BY 
					a.aktivitet_id,
					a.aktivitet_registrering_id,
					a.registrering	
			) as a
			LEFT JOIN aktivitet_tils_publiceret as b ON b.aktivitet_registrering_id=a.aktivitet_registrering_id AND (virkning_tstzrange is null OR (b.virkning).TimePeriod && virkning_tstzrange) --filter ON virkning_tstzrange if given			
			GROUP BY 
			a.aktivitet_id,
			a.aktivitet_registrering_id,
			a.registrering,
			a.AktivitetAttrEgenskaberArr	
			) as a
			LEFT JOIN aktivitet_tils_status as b ON b.aktivitet_registrering_id=a.aktivitet_registrering_id AND (virkning_tstzrange is null OR (b.virkning).TimePeriod && virkning_tstzrange) --filter ON virkning_tstzrange if given			
			GROUP BY 
			a.aktivitet_id,
			a.aktivitet_registrering_id,
			a.registrering,
			a.AktivitetAttrEgenskaberArr,
			a.AktivitetTilsPubliceretArr
	) as a
	LEFT JOIN aktivitet_relation b ON b.aktivitet_registrering_id=a.aktivitet_registrering_id AND (virkning_tstzrange is null OR (b.virkning).TimePeriod && virkning_tstzrange) --filter ON virkning_tstzrange if given
	GROUP BY
	a.aktivitet_id,
	a.aktivitet_registrering_id,
	a.registrering,
	a.AktivitetAttrEgenskaberArr,
	a.AktivitetTilsPubliceretArr,
	a.AktivitetTilsStatusArr
) as a
WHERE a.aktivitet_id IS NOT NULL
GROUP BY 
a.aktivitet_id
order by a.aktivitet_id
) as x
;



RETURN result;

END;
$$ LANGUAGE plpgsql STABLE;



