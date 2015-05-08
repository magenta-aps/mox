CREATE OR REPLACE FUNCTION actual_state_list_facet(facet_uuids uuid[],
  registrering_tstzrange tstzrange,
  virkning_tstzrange tstzrange)
  RETURNS setof FacetType AS
  $BODY$

	SELECT
		ROW(
		f.facet_id,
		array_agg(
				ROW (
					f.registrering,
					f.FacetTilsPubliceretArr,
					f.FacetAttrEgenskaberArr,
					f.FacetRelationTypeArr
				)::FacetRegistreringType		
			) 
		):: FacetType
	FROM
	(

			SELECT
				h.*,
				array_agg(
					ROW (
  						e.rel_type,
  						e.virkning,
  						e.rel_maal 
						):: FacetRelationType
					) FacetRelationTypeArr
			FROM

				(
					SELECT 	g.*,
							array_agg(
								ROW (
									 	d.virkning, 
    									d.publiceret_status
									)::FacetTilsPubliceretType
								) FacetTilsPubliceretArr
					FROM
					(
						SELECT
						a.id facet_id,
						b.id facet_registrering_id,
						b.registrering,
						array_agg(
							ROW(
						 		c.brugervendt_noegle,
						   		c.facetbeskrivelse,
						   		c.facetplan,
						  		c.facetopbygning,
						   		c.facetophavsret,
						   		c.facetsupplement,
						   		c.retskilde,
						   		c.virkning 
								)::FacetAttrEgenskaberType
						) FacetAttrEgenskaberArr
						FROM
						facet a
						JOIN facet_registrering b on b.facet_id=a.id
						LEFT JOIN facet_attr_egenskaber c on c.facet_registrering_id=b.id 
									AND 
									(
										--filter on virkning_tstzrange if given
										(virkning_tstzrange is null or isempty(virkning_tstzrange))
										or
									 	(c.virkning).TimePeriod && virkning_tstzrange
									)			
						WHERE a.id = ANY (facet_uuids)
						--filter on registrering_tstzrange
						AND 
							(
								((registrering_tstzrange is null or isempty(registrering_tstzrange)) and upper_inf((b.registrering).timeperiod))
							OR
								registrering_tstzrange && (b.registrering).timeperiod
							)
						group by --we need to group at this level, to get the number of rows down to 1 each facet id * facet registrations
						a.id,
						b.id,b.registrering
					) as g 		
				LEFT JOIN facet_tils_publiceret d on d.facet_registrering_id=g.facet_registrering_id
					AND
					(
						--filter on virkning_tstzrange if given
						(virkning_tstzrange is null or isempty(virkning_tstzrange))
						or
					 	(d.virkning).TimePeriod && virkning_tstzrange
					)
				group by --we need to group at this level, to get the number of rows down to 1 each facet id * facet registrations
				g.facet_id, 
				g.facet_registrering_id, 
				g.registrering, 
				g.FacetAttrEgenskaberArr
			) as h
		LEFT JOIN facet_relation e on e.facet_registrering_id=h.facet_registrering_id
					AND
					(
						--filter on virkning_tstzrange if given
						(virkning_tstzrange is null or isempty(virkning_tstzrange))
						or
					 	(e.virkning).TimePeriod && virkning_tstzrange
					)
		group by
		h.facet_id, 
		h.facet_registrering_id, 
		h.registrering, 
		h.FacetAttrEgenskaberArr,			
		h.FacetTilsPubliceretArr
	) as f
	group by f.facet_id


$BODY$
LANGUAGE sql STABLE
;