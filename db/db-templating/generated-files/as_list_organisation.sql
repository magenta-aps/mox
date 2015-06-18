-- Copyright (C) 2015 Magenta ApS, http://magenta.dk.
-- Contact: info@magenta.dk.
--
-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at http://mozilla.org/MPL/2.0/.

/*
NOTICE: This file is auto-generated using the script: apply-template.py organisation as_list.jinja.sql
*/

CREATE OR REPLACE FUNCTION as_list_organisation(organisation_uuids uuid[],
  registrering_tstzrange tstzrange,
  virkning_tstzrange tstzrange)
  RETURNS setof OrganisationType AS
  $BODY$

SELECT
ROW(
	a.organisation_id,
	array_agg(
		ROW (
			a.registrering,
			a.OrganisationTilsGyldighedArr,
			a.OrganisationAttrEgenskaberArr,
			a.OrganisationRelationArr
		)::OrganisationRegistreringType
		order by upper((a.registrering).TimePeriod) DESC		
	) 
):: OrganisationType
FROM
(
	SELECT
	a.organisation_id,
	a.organisation_registrering_id,
	a.registrering,
	a.OrganisationAttrEgenskaberArr,
	a.OrganisationTilsGyldighedArr,
	_remove_nulls_in_array(array_agg(
		CASE
		WHEN b.id is not null THEN
		ROW (
				b.rel_type,
				b.virkning,
				b.rel_maal 
			):: OrganisationRelationType
		ELSE
		NULL
		END
		order by b.rel_maal,b.rel_type,b.virkning
	)) OrganisationRelationArr
	FROM
	(
			SELECT
			a.organisation_id,
			a.organisation_registrering_id,
			a.registrering,
			a.OrganisationAttrEgenskaberArr,
			_remove_nulls_in_array(array_agg
				(
					CASE
					WHEN b.id is not null THEN 
					ROW(
						b.virkning,
						b.gyldighed
						) ::OrganisationGyldighedTilsType
					ELSE NULL
					END
					order by b.gyldighed,b.virkning
				)) OrganisationTilsGyldighedArr		
			FROM
			(
					SELECT
					a.organisation_id,
					a.organisation_registrering_id,
					a.registrering,
					_remove_nulls_in_array(array_agg(
						CASE 
						WHEN b.id is not null THEN
						ROW(
					 		b.brugervendtnoegle,
					 		b.organisationsnavn,
					   		b.virkning 
							)::OrganisationEgenskaberAttrType
						ELSE
						NULL
						END
						order by b.brugervendtnoegle,b.organisationsnavn,b.virkning
					)) OrganisationAttrEgenskaberArr 
					FROM
					(
					SELECT
					a.id organisation_id,
					b.id organisation_registrering_id,
					b.registrering			
					FROM		organisation a
					JOIN 		organisation_registrering b 	ON b.organisation_id=a.id
					WHERE a.id = ANY (organisation_uuids) AND (((registrering_tstzrange is null OR isempty(registrering_tstzrange)) AND upper((b.registrering).timeperiod)='infinity'::TIMESTAMPTZ) OR registrering_tstzrange && (b.registrering).timeperiod)--filter ON registrering_tstzrange
					) as a
					LEFT JOIN organisation_attr_egenskaber as b ON b.organisation_registrering_id=a.organisation_registrering_id AND ((virkning_tstzrange is null OR isempty(virkning_tstzrange)) OR (b.virkning).TimePeriod && virkning_tstzrange) --filter ON virkning_tstzrange if given			
					GROUP BY 
					a.organisation_id,
					a.organisation_registrering_id,
					a.registrering	
			) as a
			LEFT JOIN organisation_tils_gyldighed as b ON b.organisation_registrering_id=a.organisation_registrering_id AND ((virkning_tstzrange is null OR isempty(virkning_tstzrange)) OR (b.virkning).TimePeriod && virkning_tstzrange) --filter ON virkning_tstzrange if given			
			GROUP BY 
			a.organisation_id,
			a.organisation_registrering_id,
			a.registrering,
			a.OrganisationAttrEgenskaberArr
	) as a
	LEFT JOIN organisation_relation b ON b.organisation_registrering_id=a.organisation_registrering_id AND ((virkning_tstzrange is null OR isempty(virkning_tstzrange)) OR (b.virkning).TimePeriod && virkning_tstzrange) --filter ON virkning_tstzrange if given
	GROUP BY
	a.organisation_id,
	a.organisation_registrering_id,
	a.registrering,
	a.OrganisationAttrEgenskaberArr,
	a.OrganisationTilsGyldighedArr
) as a
GROUP BY 
a.organisation_id
order by a.organisation_id

$BODY$
LANGUAGE sql STABLE
;


