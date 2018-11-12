-- Copyright (C) 2015 Magenta ApS, http://magenta.dk.
-- Contact: info@magenta.dk.
--
-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at http://mozilla.org/MPL/2.0/.

/*
NOTICE: This file is auto-generated using the script: oio_rest/apply-templates.py
*/

CREATE OR REPLACE FUNCTION as_list_dokument(dokument_uuids uuid[],
  registrering_tstzrange tstzrange,
  virkning_tstzrange tstzrange,
  auth_criteria_arr DokumentRegistreringType[]=null
  )
  RETURNS DokumentType[] AS
$$
DECLARE
	auth_filtered_uuids uuid[];
	result DokumentType[];
BEGIN


/*** Verify that the object meets the stipulated access allowed criteria  ***/
auth_filtered_uuids:=_as_filter_unauth_dokument(dokument_uuids,auth_criteria_arr); 
IF NOT (coalesce(array_length(auth_filtered_uuids,1),0)=coalesce(array_length(dokument_uuids,1),0) AND auth_filtered_uuids @>dokument_uuids) THEN
  RAISE EXCEPTION 'Unable to list dokument with uuids [%]. All objects do not fullfill the stipulated criteria:%',dokument_uuids,to_json(auth_criteria_arr)  USING ERRCODE = 'MO401'; 
END IF;
/*********************/

SELECT 
array_agg( x.dokumentObj) into result
FROM
(
SELECT
ROW(
	a.dokument_id,
	array_agg(
		ROW (
			a.registrering,
			a.DokumentTilsFremdriftArr,
			a.DokumentAttrEgenskaberArr,
			a.DokumentRelationArr,
            b.varianter
		)::DokumentRegistreringType
		order by upper((a.registrering).TimePeriod) DESC		
	) 
):: DokumentType  dokumentObj
FROM
(
	SELECT
	a.dokument_id,
	a.dokument_registrering_id,
	a.registrering,
	a.DokumentAttrEgenskaberArr,
	a.DokumentTilsFremdriftArr,
	_remove_nulls_in_array(array_agg(
		CASE
		WHEN b.id is not null THEN
		ROW (
				b.rel_type,
				b.virkning,
				b.rel_maal_uuid,
				b.rel_maal_urn,
				b.objekt_type
			):: DokumentRelationType
		ELSE
		NULL
		END
        
		order by b.rel_maal_uuid,b.rel_maal_urn,b.rel_type,b.objekt_type,b.virkning
        
	)) DokumentRelationArr
	FROM
	(
			SELECT
			a.dokument_id,
			a.dokument_registrering_id,
			a.registrering,
			a.DokumentAttrEgenskaberArr,
			_remove_nulls_in_array(array_agg
				(
					CASE
					WHEN b.id is not null THEN 
					ROW(
						b.virkning,
						b.fremdrift
						) ::DokumentFremdriftTilsType
					ELSE NULL
					END
					order by b.fremdrift,b.virkning
				)) DokumentTilsFremdriftArr		
			FROM
			(
					SELECT
					a.dokument_id,
					a.dokument_registrering_id,
					a.registrering,
					_remove_nulls_in_array(array_agg(
						CASE
                        
						WHEN b.id is not null THEN
                        
						ROW(
                            
					 		b.brugervendtnoegle,
					 		b.beskrivelse,
					 		b.brevdato,
					 		b.kassationskode,
					 		b.major,
					 		b.minor,
					 		b.offentlighedundtaget,
					 		b.titel,
					 		b.dokumenttype,
					   		b.virkning
                            
							)::DokumentEgenskaberAttrType
						ELSE
						NULL
						END
                        
						order by b.brugervendtnoegle,b.beskrivelse,b.brevdato,b.kassationskode,b.major,b.minor,b.offentlighedundtaget,b.titel,b.dokumenttype,b.virkning
                        
					)) DokumentAttrEgenskaberArr
                    
					FROM
					(
					SELECT
					a.id dokument_id,
					b.id dokument_registrering_id,
					b.registrering			
					FROM		dokument a
					JOIN 		dokument_registrering b 	ON b.dokument_id=a.id
					WHERE a.id = ANY (dokument_uuids) AND ((registrering_tstzrange is null AND upper((b.registrering).timeperiod)='infinity'::TIMESTAMPTZ) OR registrering_tstzrange && (b.registrering).timeperiod)--filter ON registrering_tstzrange
					) as a
					LEFT JOIN dokument_attr_egenskaber as b ON b.dokument_registrering_id=a.dokument_registrering_id AND (virkning_tstzrange is null OR (b.virkning).TimePeriod && virkning_tstzrange) --filter ON virkning_tstzrange if given
                    
					GROUP BY 
					a.dokument_id,
					a.dokument_registrering_id,
					a.registrering	
			) as a
			LEFT JOIN dokument_tils_fremdrift as b ON b.dokument_registrering_id=a.dokument_registrering_id AND (virkning_tstzrange is null OR (b.virkning).TimePeriod && virkning_tstzrange) --filter ON virkning_tstzrange if given			
			GROUP BY 
			a.dokument_id,
			a.dokument_registrering_id,
			a.registrering,
			a.DokumentAttrEgenskaberArr
	) as a
	LEFT JOIN dokument_relation b ON b.dokument_registrering_id=a.dokument_registrering_id AND (virkning_tstzrange is null OR (b.virkning).TimePeriod && virkning_tstzrange) --filter ON virkning_tstzrange if given
	GROUP BY
	a.dokument_id,
	a.dokument_registrering_id,
	a.registrering,
	a.DokumentAttrEgenskaberArr,
	a.DokumentTilsFremdriftArr
) as a

LEFT JOIN _as_list_dokument_varianter(dokument_uuids,registrering_tstzrange,virkning_tstzrange) b on a.dokument_registrering_id=b.dokument_registrering_id

WHERE a.dokument_id IS NOT NULL
GROUP BY 
a.dokument_id
order by a.dokument_id
) as x
;



RETURN result;

END;
$$ LANGUAGE plpgsql STABLE;


