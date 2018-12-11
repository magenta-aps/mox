-- Copyright (C) 2015 Magenta ApS, http://magenta.dk.
-- Contact: info@magenta.dk.
--
-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at http://mozilla.org/MPL/2.0/.

/*
NOTICE: This file is auto-generated using the script: oio_rest/apply-templates.py
*/

CREATE OR REPLACE FUNCTION as_list_klassifikation(klassifikation_uuids uuid[],
  registrering_tstzrange tstzrange,
  virkning_tstzrange tstzrange,
  auth_criteria_arr KlassifikationRegistreringType[]=null
  )
  RETURNS KlassifikationType[] AS
$$
DECLARE
	auth_filtered_uuids uuid[];
	result KlassifikationType[];
BEGIN


/*** Verify that the object meets the stipulated access allowed criteria  ***/
auth_filtered_uuids:=_as_filter_unauth_klassifikation(klassifikation_uuids,auth_criteria_arr); 
IF NOT (coalesce(array_length(auth_filtered_uuids,1),0)=coalesce(array_length(klassifikation_uuids,1),0) AND auth_filtered_uuids @>klassifikation_uuids) THEN
  RAISE EXCEPTION 'Unable to list klassifikation with uuids [%]. All objects do not fullfill the stipulated criteria:%',klassifikation_uuids,to_json(auth_criteria_arr)  USING ERRCODE = 'MO401'; 
END IF;
/*********************/

SELECT 
array_agg(x.klassifikationObj) into result
FROM
(
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
		order by upper((a.registrering).TimePeriod) DESC		
	) 
):: KlassifikationType  klassifikationObj
FROM
(
	SELECT
	a.klassifikation_id,
	a.klassifikation_registrering_id,
	a.registrering,
	a.KlassifikationAttrEgenskaberArr,
	a.KlassifikationTilsPubliceretArr,
	_remove_nulls_in_array(array_agg(
		CASE
		WHEN b.id is not null THEN
		ROW (
				b.rel_type,
				b.virkning,
				b.rel_maal_uuid,
				b.rel_maal_urn,
				b.objekt_type
			):: KlassifikationRelationType
		ELSE
		NULL
		END
        
		order by b.rel_maal_uuid,b.rel_maal_urn,b.rel_type,b.objekt_type,b.virkning
        
	)) KlassifikationRelationArr
	FROM
	(
			SELECT
			a.klassifikation_id,
			a.klassifikation_registrering_id,
			a.registrering,
			a.KlassifikationAttrEgenskaberArr,
			_remove_nulls_in_array(array_agg
				(
					CASE
					WHEN b.id is not null THEN 
					ROW(
						b.virkning,
						b.publiceret
						) ::KlassifikationPubliceretTilsType
					ELSE NULL
					END
					order by b.publiceret,b.virkning
				)) KlassifikationTilsPubliceretArr		
			FROM
			(
					SELECT
					a.klassifikation_id,
					a.klassifikation_registrering_id,
					a.registrering,
					_remove_nulls_in_array(array_agg(
						CASE
                        
						WHEN b.id is not null THEN
                        
						ROW(
                            
					 		b.brugervendtnoegle,
					 		b.beskrivelse,
					 		b.kaldenavn,
					 		b.ophavsret,
					   		b.virkning
                            
							)::KlassifikationEgenskaberAttrType
						ELSE
						NULL
						END
                        
						order by b.brugervendtnoegle,b.beskrivelse,b.kaldenavn,b.ophavsret,b.virkning
                        
					)) KlassifikationAttrEgenskaberArr
                    
					FROM
					(
					SELECT
					a.id klassifikation_id,
					b.id klassifikation_registrering_id,
					b.registrering			
					FROM		klassifikation a
					JOIN 		klassifikation_registrering b 	ON b.klassifikation_id=a.id
					WHERE a.id = ANY (klassifikation_uuids) AND ((registrering_tstzrange is null AND upper((b.registrering).timeperiod)='infinity'::TIMESTAMPTZ) OR registrering_tstzrange && (b.registrering).timeperiod)--filter ON registrering_tstzrange
					) as a
					LEFT JOIN klassifikation_attr_egenskaber as b ON b.klassifikation_registrering_id=a.klassifikation_registrering_id AND (virkning_tstzrange is null OR (b.virkning).TimePeriod && virkning_tstzrange) --filter ON virkning_tstzrange if given
                    
					GROUP BY 
					a.klassifikation_id,
					a.klassifikation_registrering_id,
					a.registrering	
			) as a
			LEFT JOIN klassifikation_tils_publiceret as b ON b.klassifikation_registrering_id=a.klassifikation_registrering_id AND (virkning_tstzrange is null OR (b.virkning).TimePeriod && virkning_tstzrange) --filter ON virkning_tstzrange if given			
			GROUP BY 
			a.klassifikation_id,
			a.klassifikation_registrering_id,
			a.registrering,
			a.KlassifikationAttrEgenskaberArr
	) as a
	LEFT JOIN klassifikation_relation b ON b.klassifikation_registrering_id=a.klassifikation_registrering_id AND (virkning_tstzrange is null OR (b.virkning).TimePeriod && virkning_tstzrange) --filter ON virkning_tstzrange if given
	GROUP BY
	a.klassifikation_id,
	a.klassifikation_registrering_id,
	a.registrering,
	a.KlassifikationAttrEgenskaberArr,
	a.KlassifikationTilsPubliceretArr
) as a

WHERE a.klassifikation_id IS NOT NULL
GROUP BY 
a.klassifikation_id
order by a.klassifikation_id
) as x
;



RETURN result;

END;
$$ LANGUAGE plpgsql STABLE;


