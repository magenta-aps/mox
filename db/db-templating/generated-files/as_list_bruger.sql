-- Copyright (C) 2015 Magenta ApS, http://magenta.dk.
-- Contact: info@magenta.dk.
--
-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at http://mozilla.org/MPL/2.0/.

/*
NOTICE: This file is auto-generated using the script: oio_rest/apply-templates.py
*/

CREATE OR REPLACE FUNCTION as_list_bruger(bruger_uuids uuid[],
  registrering_tstzrange tstzrange,
  virkning_tstzrange tstzrange,
  auth_criteria_arr BrugerRegistreringType[]=null
  )
  RETURNS BrugerType[] AS
$$
DECLARE
	auth_filtered_uuids uuid[];
	result BrugerType[];
BEGIN


/*** Verify that the object meets the stipulated access allowed criteria  ***/
auth_filtered_uuids:=_as_filter_unauth_bruger(bruger_uuids,auth_criteria_arr); 
IF NOT (coalesce(array_length(auth_filtered_uuids,1),0)=coalesce(array_length(bruger_uuids,1),0) AND auth_filtered_uuids @>bruger_uuids) THEN
  RAISE EXCEPTION 'Unable to list bruger with uuids [%]. All objects do not fullfill the stipulated criteria:%',bruger_uuids,to_json(auth_criteria_arr)  USING ERRCODE = 'MO401'; 
END IF;
/*********************/

SELECT 
array_agg( x.brugerObj) into result
FROM
(
SELECT
ROW(
	a.bruger_id,
	array_agg(
		ROW (
			a.registrering,
			a.BrugerTilsGyldighedArr,
			a.BrugerAttrEgenskaberArr,
			a.BrugerRelationArr
		)::BrugerRegistreringType
		order by upper((a.registrering).TimePeriod) DESC		
	) 
):: BrugerType  brugerObj
FROM
(
	SELECT
	a.bruger_id,
	a.bruger_registrering_id,
	a.registrering,
	a.BrugerAttrEgenskaberArr,
	a.BrugerTilsGyldighedArr,
	_remove_nulls_in_array(array_agg(
		CASE
		WHEN b.id is not null THEN
		ROW (
				b.rel_type,
				b.virkning,
				b.rel_maal_uuid,
				b.rel_maal_urn,
				b.objekt_type
			):: BrugerRelationType
		ELSE
		NULL
		END
        
		order by b.rel_maal_uuid,b.rel_maal_urn,b.rel_type,b.objekt_type,b.virkning
        
	)) BrugerRelationArr
	FROM
	(
			SELECT
			a.bruger_id,
			a.bruger_registrering_id,
			a.registrering,
			a.BrugerAttrEgenskaberArr,
			_remove_nulls_in_array(array_agg
				(
					CASE
					WHEN b.id is not null THEN 
					ROW(
						b.virkning,
						b.gyldighed
						) ::BrugerGyldighedTilsType
					ELSE NULL
					END
					order by b.gyldighed,b.virkning
				)) BrugerTilsGyldighedArr		
			FROM
			(
					SELECT
					a.bruger_id,
					a.bruger_registrering_id,
					a.registrering,
					_remove_nulls_in_array(array_agg(
						CASE
                        
						WHEN b.id is not null THEN
                        
						ROW(
                            
					 		b.brugervendtnoegle,
					 		b.brugernavn,
					 		b.brugertype,
					   		b.virkning
                            
							)::BrugerEgenskaberAttrType
						ELSE
						NULL
						END
                        
						order by b.brugervendtnoegle,b.brugernavn,b.brugertype,b.virkning
                        
					)) BrugerAttrEgenskaberArr
                    
					FROM
					(
					SELECT
					a.id bruger_id,
					b.id bruger_registrering_id,
					b.registrering			
					FROM		bruger a
					JOIN 		bruger_registrering b 	ON b.bruger_id=a.id
					WHERE a.id = ANY (bruger_uuids) AND ((registrering_tstzrange is null AND upper((b.registrering).timeperiod)='infinity'::TIMESTAMPTZ) OR registrering_tstzrange && (b.registrering).timeperiod)--filter ON registrering_tstzrange
					) as a
					LEFT JOIN bruger_attr_egenskaber as b ON b.bruger_registrering_id=a.bruger_registrering_id AND (virkning_tstzrange is null OR (b.virkning).TimePeriod && virkning_tstzrange) --filter ON virkning_tstzrange if given
                    
					GROUP BY 
					a.bruger_id,
					a.bruger_registrering_id,
					a.registrering	
			) as a
			LEFT JOIN bruger_tils_gyldighed as b ON b.bruger_registrering_id=a.bruger_registrering_id AND (virkning_tstzrange is null OR (b.virkning).TimePeriod && virkning_tstzrange) --filter ON virkning_tstzrange if given			
			GROUP BY 
			a.bruger_id,
			a.bruger_registrering_id,
			a.registrering,
			a.BrugerAttrEgenskaberArr
	) as a
	LEFT JOIN bruger_relation b ON b.bruger_registrering_id=a.bruger_registrering_id AND (virkning_tstzrange is null OR (b.virkning).TimePeriod && virkning_tstzrange) --filter ON virkning_tstzrange if given
	GROUP BY
	a.bruger_id,
	a.bruger_registrering_id,
	a.registrering,
	a.BrugerAttrEgenskaberArr,
	a.BrugerTilsGyldighedArr
) as a

WHERE a.bruger_id IS NOT NULL
GROUP BY 
a.bruger_id
order by a.bruger_id
) as x
;



RETURN result;

END;
$$ LANGUAGE plpgsql STABLE;


