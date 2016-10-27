-- Copyright (C) 2015 Magenta ApS, http://magenta.dk.
-- Contact: info@magenta.dk.
--
-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at http://mozilla.org/MPL/2.0/.

/*
NOTICE: This file is auto-generated using the script: apply-template.py loghaendelse as_list.jinja.sql
*/

CREATE OR REPLACE FUNCTION as_list_loghaendelse(loghaendelse_uuids uuid[],
  registrering_tstzrange tstzrange,
  virkning_tstzrange tstzrange,
  auth_criteria_arr LoghaendelseRegistreringType[]=null
  )
  RETURNS LoghaendelseType[] AS
$$
DECLARE
	auth_filtered_uuids uuid[];
	result LoghaendelseType[];
BEGIN


/*** Verify that the object meets the stipulated access allowed criteria  ***/
auth_filtered_uuids:=_as_filter_unauth_loghaendelse(loghaendelse_uuids,auth_criteria_arr); 
IF NOT (coalesce(array_length(auth_filtered_uuids,1),0)=coalesce(array_length(loghaendelse_uuids,1),0) AND auth_filtered_uuids @>loghaendelse_uuids) THEN
  RAISE EXCEPTION 'Unable to list loghaendelse with uuids [%]. All objects do not fullfill the stipulated criteria:%',loghaendelse_uuids,to_json(auth_criteria_arr)  USING ERRCODE = 'MO401'; 
END IF;
/*********************/

SELECT 
array_agg( x.loghaendelseObj) into result
FROM
(
SELECT
ROW(
	a.loghaendelse_id,
	array_agg(
		ROW (
			a.registrering,
			a.LoghaendelseTilsGyldighedArr,
			a.LoghaendelseAttrEgenskaberArr,
			a.LoghaendelseRelationArr
		)::LoghaendelseRegistreringType
		order by upper((a.registrering).TimePeriod) DESC		
	) 
):: LoghaendelseType  loghaendelseObj
FROM
(
	SELECT
	a.loghaendelse_id,
	a.loghaendelse_registrering_id,
	a.registrering,
	a.LoghaendelseAttrEgenskaberArr,
	a.LoghaendelseTilsGyldighedArr,
	_remove_nulls_in_array(array_agg(
		CASE
		WHEN b.id is not null THEN
		ROW (
				b.rel_type,
				b.virkning,
				b.rel_maal_uuid,
				b.rel_maal_urn,
				b.objekt_type 
			):: LoghaendelseRelationType
		ELSE
		NULL
		END
		order by b.rel_maal_uuid,b.rel_maal_urn,b.rel_type,b.objekt_type,b.virkning
	)) LoghaendelseRelationArr
	FROM
	(
			SELECT
			a.loghaendelse_id,
			a.loghaendelse_registrering_id,
			a.registrering,
			a.LoghaendelseAttrEgenskaberArr,
			_remove_nulls_in_array(array_agg
				(
					CASE
					WHEN b.id is not null THEN 
					ROW(
						b.virkning,
						b.gyldighed
						) ::LoghaendelseGyldighedTilsType
					ELSE NULL
					END
					order by b.gyldighed,b.virkning
				)) LoghaendelseTilsGyldighedArr		
			FROM
			(
					SELECT
					a.loghaendelse_id,
					a.loghaendelse_registrering_id,
					a.registrering,
					_remove_nulls_in_array(array_agg(
						CASE 
						WHEN b.id is not null THEN
						ROW(
					 		b.service,
					 		b.klasse,
					 		b.tidspunkt,
					 		b.operation,
					 		b.objekttype,
					 		b.returkode,
					 		b.returtekst,
					 		b.note,
					   		b.virkning 
							)::LoghaendelseEgenskaberAttrType
						ELSE
						NULL
						END
						order by b.service,b.klasse,b.tidspunkt,b.operation,b.objekttype,b.returkode,b.returtekst,b.note,b.virkning
					)) LoghaendelseAttrEgenskaberArr 
					FROM
					(
					SELECT
					a.id loghaendelse_id,
					b.id loghaendelse_registrering_id,
					b.registrering			
					FROM		loghaendelse a
					JOIN 		loghaendelse_registrering b 	ON b.loghaendelse_id=a.id
					WHERE a.id = ANY (loghaendelse_uuids) AND ((registrering_tstzrange is null AND upper((b.registrering).timeperiod)='infinity'::TIMESTAMPTZ) OR registrering_tstzrange && (b.registrering).timeperiod)--filter ON registrering_tstzrange
					) as a
					LEFT JOIN loghaendelse_attr_egenskaber as b ON b.loghaendelse_registrering_id=a.loghaendelse_registrering_id AND (virkning_tstzrange is null OR (b.virkning).TimePeriod && virkning_tstzrange) --filter ON virkning_tstzrange if given			
					GROUP BY 
					a.loghaendelse_id,
					a.loghaendelse_registrering_id,
					a.registrering	
			) as a
			LEFT JOIN loghaendelse_tils_gyldighed as b ON b.loghaendelse_registrering_id=a.loghaendelse_registrering_id AND (virkning_tstzrange is null OR (b.virkning).TimePeriod && virkning_tstzrange) --filter ON virkning_tstzrange if given			
			GROUP BY 
			a.loghaendelse_id,
			a.loghaendelse_registrering_id,
			a.registrering,
			a.LoghaendelseAttrEgenskaberArr
	) as a
	LEFT JOIN loghaendelse_relation b ON b.loghaendelse_registrering_id=a.loghaendelse_registrering_id AND (virkning_tstzrange is null OR (b.virkning).TimePeriod && virkning_tstzrange) --filter ON virkning_tstzrange if given
	GROUP BY
	a.loghaendelse_id,
	a.loghaendelse_registrering_id,
	a.registrering,
	a.LoghaendelseAttrEgenskaberArr,
	a.LoghaendelseTilsGyldighedArr
) as a
WHERE a.loghaendelse_id IS NOT NULL
GROUP BY 
a.loghaendelse_id
order by a.loghaendelse_id
) as x
;



RETURN result;

END;
$$ LANGUAGE plpgsql STABLE;



