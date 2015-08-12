-- Copyright (C) 2015 Magenta ApS, http://magenta.dk.
-- Contact: info@magenta.dk.
--
-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at http://mozilla.org/MPL/2.0/.

/*
NOTICE: This file is auto-generated using the script: apply-template.py interessefaellesskab as_list.jinja.sql
*/

CREATE OR REPLACE FUNCTION as_list_interessefaellesskab(interessefaellesskab_uuids uuid[],
  registrering_tstzrange tstzrange,
  virkning_tstzrange tstzrange,
  auth_criteria_arr InteressefaellesskabRegistreringType[]=null
  )
  RETURNS InteressefaellesskabType[] AS
$$
DECLARE
	auth_filtered_uuids uuid[];
	result InteressefaellesskabType[];
BEGIN


/*** Verify that the object meets the stipulated access allowed criteria  ***/
auth_filtered_uuids:=_as_filter_unauth_interessefaellesskab(interessefaellesskab_uuids,auth_criteria_arr); 
IF NOT (coalesce(array_length(auth_filtered_uuids,1),0)=coalesce(array_length(interessefaellesskab_uuids,1),0) AND auth_filtered_uuids @>interessefaellesskab_uuids) THEN
  RAISE EXCEPTION 'Unable to list interessefaellesskab with uuids [%]. All objects do not fullfill the stipulated criteria:%',interessefaellesskab_uuids,to_json(auth_criteria_arr)  USING ERRCODE = MO401; 
END IF;
/*********************/

SELECT 
array_agg( x.interessefaellesskabObj) into result
FROM
(
SELECT
ROW(
	a.interessefaellesskab_id,
	array_agg(
		ROW (
			a.registrering,
			a.InteressefaellesskabTilsGyldighedArr,
			a.InteressefaellesskabAttrEgenskaberArr,
			a.InteressefaellesskabRelationArr
		)::InteressefaellesskabRegistreringType
		order by upper((a.registrering).TimePeriod) DESC		
	) 
):: InteressefaellesskabType  interessefaellesskabObj
FROM
(
	SELECT
	a.interessefaellesskab_id,
	a.interessefaellesskab_registrering_id,
	a.registrering,
	a.InteressefaellesskabAttrEgenskaberArr,
	a.InteressefaellesskabTilsGyldighedArr,
	_remove_nulls_in_array(array_agg(
		CASE
		WHEN b.id is not null THEN
		ROW (
				b.rel_type,
				b.virkning,
				b.rel_maal_uuid,
				b.rel_maal_urn,
				b.objekt_type 
			):: InteressefaellesskabRelationType
		ELSE
		NULL
		END
		order by b.rel_maal_uuid,b.rel_maal_urn,b.rel_type,b.objekt_type,b.virkning
	)) InteressefaellesskabRelationArr
	FROM
	(
			SELECT
			a.interessefaellesskab_id,
			a.interessefaellesskab_registrering_id,
			a.registrering,
			a.InteressefaellesskabAttrEgenskaberArr,
			_remove_nulls_in_array(array_agg
				(
					CASE
					WHEN b.id is not null THEN 
					ROW(
						b.virkning,
						b.gyldighed
						) ::InteressefaellesskabGyldighedTilsType
					ELSE NULL
					END
					order by b.gyldighed,b.virkning
				)) InteressefaellesskabTilsGyldighedArr		
			FROM
			(
					SELECT
					a.interessefaellesskab_id,
					a.interessefaellesskab_registrering_id,
					a.registrering,
					_remove_nulls_in_array(array_agg(
						CASE 
						WHEN b.id is not null THEN
						ROW(
					 		b.brugervendtnoegle,
					 		b.interessefaellesskabsnavn,
					 		b.interessefaellesskabstype,
					   		b.virkning 
							)::InteressefaellesskabEgenskaberAttrType
						ELSE
						NULL
						END
						order by b.brugervendtnoegle,b.interessefaellesskabsnavn,b.interessefaellesskabstype,b.virkning
					)) InteressefaellesskabAttrEgenskaberArr 
					FROM
					(
					SELECT
					a.id interessefaellesskab_id,
					b.id interessefaellesskab_registrering_id,
					b.registrering			
					FROM		interessefaellesskab a
					JOIN 		interessefaellesskab_registrering b 	ON b.interessefaellesskab_id=a.id
					WHERE a.id = ANY (interessefaellesskab_uuids) AND ((registrering_tstzrange is null AND upper((b.registrering).timeperiod)='infinity'::TIMESTAMPTZ) OR registrering_tstzrange && (b.registrering).timeperiod)--filter ON registrering_tstzrange
					) as a
					LEFT JOIN interessefaellesskab_attr_egenskaber as b ON b.interessefaellesskab_registrering_id=a.interessefaellesskab_registrering_id AND (virkning_tstzrange is null OR (b.virkning).TimePeriod && virkning_tstzrange) --filter ON virkning_tstzrange if given			
					GROUP BY 
					a.interessefaellesskab_id,
					a.interessefaellesskab_registrering_id,
					a.registrering	
			) as a
			LEFT JOIN interessefaellesskab_tils_gyldighed as b ON b.interessefaellesskab_registrering_id=a.interessefaellesskab_registrering_id AND (virkning_tstzrange is null OR (b.virkning).TimePeriod && virkning_tstzrange) --filter ON virkning_tstzrange if given			
			GROUP BY 
			a.interessefaellesskab_id,
			a.interessefaellesskab_registrering_id,
			a.registrering,
			a.InteressefaellesskabAttrEgenskaberArr
	) as a
	LEFT JOIN interessefaellesskab_relation b ON b.interessefaellesskab_registrering_id=a.interessefaellesskab_registrering_id AND (virkning_tstzrange is null OR (b.virkning).TimePeriod && virkning_tstzrange) --filter ON virkning_tstzrange if given
	GROUP BY
	a.interessefaellesskab_id,
	a.interessefaellesskab_registrering_id,
	a.registrering,
	a.InteressefaellesskabAttrEgenskaberArr,
	a.InteressefaellesskabTilsGyldighedArr
) as a
WHERE a.interessefaellesskab_id IS NOT NULL
GROUP BY 
a.interessefaellesskab_id
order by a.interessefaellesskab_id
) as x
;



RETURN result;

END;
$$ LANGUAGE plpgsql STABLE;



