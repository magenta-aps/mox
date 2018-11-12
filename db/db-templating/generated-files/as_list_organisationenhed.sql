-- Copyright (C) 2015 Magenta ApS, http://magenta.dk.
-- Contact: info@magenta.dk.
--
-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at http://mozilla.org/MPL/2.0/.

/*
NOTICE: This file is auto-generated using the script: oio_rest/apply-templates.py
*/

CREATE OR REPLACE FUNCTION as_list_organisationenhed(organisationenhed_uuids uuid[],
  registrering_tstzrange tstzrange,
  virkning_tstzrange tstzrange,
  auth_criteria_arr OrganisationenhedRegistreringType[]=null
  )
  RETURNS OrganisationenhedType[] AS
$$
DECLARE
	auth_filtered_uuids uuid[];
	result OrganisationenhedType[];
BEGIN


/*** Verify that the object meets the stipulated access allowed criteria  ***/
auth_filtered_uuids:=_as_filter_unauth_organisationenhed(organisationenhed_uuids,auth_criteria_arr); 
IF NOT (coalesce(array_length(auth_filtered_uuids,1),0)=coalesce(array_length(organisationenhed_uuids,1),0) AND auth_filtered_uuids @>organisationenhed_uuids) THEN
  RAISE EXCEPTION 'Unable to list organisationenhed with uuids [%]. All objects do not fullfill the stipulated criteria:%',organisationenhed_uuids,to_json(auth_criteria_arr)  USING ERRCODE = 'MO401'; 
END IF;
/*********************/

SELECT 
array_agg( x.organisationenhedObj) into result
FROM
(
SELECT
ROW(
	a.organisationenhed_id,
	array_agg(
		ROW (
			a.registrering,
			a.OrganisationenhedTilsGyldighedArr,
			a.OrganisationenhedAttrEgenskaberArr,
			a.OrganisationenhedRelationArr
		)::OrganisationenhedRegistreringType
		order by upper((a.registrering).TimePeriod) DESC		
	) 
):: OrganisationenhedType  organisationenhedObj
FROM
(
	SELECT
	a.organisationenhed_id,
	a.organisationenhed_registrering_id,
	a.registrering,
	a.OrganisationenhedAttrEgenskaberArr,
	a.OrganisationenhedTilsGyldighedArr,
	_remove_nulls_in_array(array_agg(
		CASE
		WHEN b.id is not null THEN
		ROW (
				b.rel_type,
				b.virkning,
				b.rel_maal_uuid,
				b.rel_maal_urn,
				b.objekt_type
			):: OrganisationenhedRelationType
		ELSE
		NULL
		END
        
		order by b.rel_maal_uuid,b.rel_maal_urn,b.rel_type,b.objekt_type,b.virkning
        
	)) OrganisationenhedRelationArr
	FROM
	(
			SELECT
			a.organisationenhed_id,
			a.organisationenhed_registrering_id,
			a.registrering,
			a.OrganisationenhedAttrEgenskaberArr,
			_remove_nulls_in_array(array_agg
				(
					CASE
					WHEN b.id is not null THEN 
					ROW(
						b.virkning,
						b.gyldighed
						) ::OrganisationenhedGyldighedTilsType
					ELSE NULL
					END
					order by b.gyldighed,b.virkning
				)) OrganisationenhedTilsGyldighedArr		
			FROM
			(
					SELECT
					a.organisationenhed_id,
					a.organisationenhed_registrering_id,
					a.registrering,
					_remove_nulls_in_array(array_agg(
						CASE
                        
						WHEN b.id is not null THEN
                        
						ROW(
                            
					 		b.brugervendtnoegle,
					 		b.enhedsnavn,
					   		b.virkning
                            
							)::OrganisationenhedEgenskaberAttrType
						ELSE
						NULL
						END
                        
						order by b.brugervendtnoegle,b.enhedsnavn,b.virkning
                        
					)) OrganisationenhedAttrEgenskaberArr
                    
					FROM
					(
					SELECT
					a.id organisationenhed_id,
					b.id organisationenhed_registrering_id,
					b.registrering			
					FROM		organisationenhed a
					JOIN 		organisationenhed_registrering b 	ON b.organisationenhed_id=a.id
					WHERE a.id = ANY (organisationenhed_uuids) AND ((registrering_tstzrange is null AND upper((b.registrering).timeperiod)='infinity'::TIMESTAMPTZ) OR registrering_tstzrange && (b.registrering).timeperiod)--filter ON registrering_tstzrange
					) as a
					LEFT JOIN organisationenhed_attr_egenskaber as b ON b.organisationenhed_registrering_id=a.organisationenhed_registrering_id AND (virkning_tstzrange is null OR (b.virkning).TimePeriod && virkning_tstzrange) --filter ON virkning_tstzrange if given
                    
					GROUP BY 
					a.organisationenhed_id,
					a.organisationenhed_registrering_id,
					a.registrering	
			) as a
			LEFT JOIN organisationenhed_tils_gyldighed as b ON b.organisationenhed_registrering_id=a.organisationenhed_registrering_id AND (virkning_tstzrange is null OR (b.virkning).TimePeriod && virkning_tstzrange) --filter ON virkning_tstzrange if given			
			GROUP BY 
			a.organisationenhed_id,
			a.organisationenhed_registrering_id,
			a.registrering,
			a.OrganisationenhedAttrEgenskaberArr
	) as a
	LEFT JOIN organisationenhed_relation b ON b.organisationenhed_registrering_id=a.organisationenhed_registrering_id AND (virkning_tstzrange is null OR (b.virkning).TimePeriod && virkning_tstzrange) --filter ON virkning_tstzrange if given
	GROUP BY
	a.organisationenhed_id,
	a.organisationenhed_registrering_id,
	a.registrering,
	a.OrganisationenhedAttrEgenskaberArr,
	a.OrganisationenhedTilsGyldighedArr
) as a

WHERE a.organisationenhed_id IS NOT NULL
GROUP BY 
a.organisationenhed_id
order by a.organisationenhed_id
) as x
;



RETURN result;

END;
$$ LANGUAGE plpgsql STABLE;


