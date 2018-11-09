-- Copyright (C) 2015 Magenta ApS, http://magenta.dk.
-- Contact: info@magenta.dk.
--
-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at http://mozilla.org/MPL/2.0/.

/*
NOTICE: This file is auto-generated using the script: apply-template.py sag as_list.jinja.sql
*/

CREATE OR REPLACE FUNCTION as_list_sag(sag_uuids uuid[],
  registrering_tstzrange tstzrange,
  virkning_tstzrange tstzrange,
  auth_criteria_arr SagRegistreringType[]=null
  )
  RETURNS SagType[] AS
$$
DECLARE
	auth_filtered_uuids uuid[];
	result SagType[];
BEGIN


/*** Verify that the object meets the stipulated access allowed criteria  ***/
auth_filtered_uuids:=_as_filter_unauth_sag(sag_uuids,auth_criteria_arr); 
IF NOT (coalesce(array_length(auth_filtered_uuids,1),0)=coalesce(array_length(sag_uuids,1),0) AND auth_filtered_uuids @>sag_uuids) THEN
  RAISE EXCEPTION 'Unable to list sag with uuids [%]. All objects do not fullfill the stipulated criteria:%',sag_uuids,to_json(auth_criteria_arr)  USING ERRCODE = 'MO401'; 
END IF;
/*********************/

SELECT 
array_agg( x.sagObj) into result
FROM
(
SELECT
ROW(
	a.sag_id,
	array_agg(
		ROW (
			a.registrering,
			a.SagTilsFremdriftArr,
			a.SagAttrEgenskaberArr,
			a.SagRelationArr
		)::SagRegistreringType
		order by upper((a.registrering).TimePeriod) DESC		
	) 
):: SagType  sagObj
FROM
(
	SELECT
	a.sag_id,
	a.sag_registrering_id,
	a.registrering,
	a.SagAttrEgenskaberArr,
	a.SagTilsFremdriftArr,
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
				b.rel_type_spec,
				b.journal_notat,
				b.journal_dokument_attr
			):: SagRelationType
		ELSE
		NULL
		END
		order by b.rel_type,b.rel_index,b.rel_maal_uuid,b.rel_maal_urn,b.objekt_type,b.rel_type_spec,b.journal_notat,b.journal_dokument_attr,b.virkning
	)) SagRelationArr
	FROM
	(
			SELECT
			a.sag_id,
			a.sag_registrering_id,
			a.registrering,
			a.SagAttrEgenskaberArr,
			_remove_nulls_in_array(array_agg
				(
					CASE
					WHEN b.id is not null THEN 
					ROW(
						b.virkning,
						b.fremdrift
						) ::SagFremdriftTilsType
					ELSE NULL
					END
					order by b.fremdrift,b.virkning
				)) SagTilsFremdriftArr		
			FROM
			(
					SELECT
					a.sag_id,
					a.sag_registrering_id,
					a.registrering,
					_remove_nulls_in_array(array_agg(
						CASE 
						WHEN b.id is not null THEN
						ROW(
					 		b.brugervendtnoegle,
					 		b.afleveret,
					 		b.beskrivelse,
					 		b.hjemmel,
					 		b.kassationskode,
					 		b.offentlighedundtaget,
					 		b.principiel,
					 		b.sagsnummer,
					 		b.titel,
					   		b.virkning 
							)::SagEgenskaberAttrType
						ELSE
						NULL
						END
						order by b.brugervendtnoegle,b.afleveret,b.beskrivelse,b.hjemmel,b.kassationskode,b.offentlighedundtaget,b.principiel,b.sagsnummer,b.titel,b.virkning
					)) SagAttrEgenskaberArr 
					FROM
					(
					SELECT
					a.id sag_id,
					b.id sag_registrering_id,
					b.registrering			
					FROM		sag a
					JOIN 		sag_registrering b 	ON b.sag_id=a.id
					WHERE a.id = ANY (sag_uuids) AND ((registrering_tstzrange is null AND upper((b.registrering).timeperiod)='infinity'::TIMESTAMPTZ) OR registrering_tstzrange && (b.registrering).timeperiod)--filter ON registrering_tstzrange
					) as a
					LEFT JOIN sag_attr_egenskaber as b ON b.sag_registrering_id=a.sag_registrering_id AND (virkning_tstzrange is null OR (b.virkning).TimePeriod && virkning_tstzrange) --filter ON virkning_tstzrange if given			
					GROUP BY 
					a.sag_id,
					a.sag_registrering_id,
					a.registrering	
			) as a
			LEFT JOIN sag_tils_fremdrift as b ON b.sag_registrering_id=a.sag_registrering_id AND (virkning_tstzrange is null OR (b.virkning).TimePeriod && virkning_tstzrange) --filter ON virkning_tstzrange if given			
			GROUP BY 
			a.sag_id,
			a.sag_registrering_id,
			a.registrering,
			a.SagAttrEgenskaberArr
	) as a
	LEFT JOIN sag_relation b ON b.sag_registrering_id=a.sag_registrering_id AND (virkning_tstzrange is null OR (b.virkning).TimePeriod && virkning_tstzrange) --filter ON virkning_tstzrange if given
	GROUP BY
	a.sag_id,
	a.sag_registrering_id,
	a.registrering,
	a.SagAttrEgenskaberArr,
	a.SagTilsFremdriftArr
) as a
WHERE a.sag_id IS NOT NULL
GROUP BY 
a.sag_id
order by a.sag_id
) as x
;



RETURN result;

END;
$$ LANGUAGE plpgsql STABLE;



