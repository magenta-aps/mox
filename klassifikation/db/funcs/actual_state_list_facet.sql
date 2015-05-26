CREATE OR REPLACE FUNCTION actual_state_list_facet(facet_uuids uuid[],
  registrering_tstzrange tstzrange,
  virkning_tstzrange tstzrange)
  RETURNS setof FacetType AS
  $BODY$

	SELECT
	ROW(
		a3.facet_id,
		array_agg(
			ROW (
				a3.registrering,
				a3.FacetTilsPubliceretArr,
				a3.FacetAttrEgenskaberArr,
				a3.FacetRelationTypeArr
			)::FacetRegistreringType
			order by a3.facet_registrering_id		
		) 
	):: FacetType
	FROM
	(
		SELECT
		a2.*,
		array_agg(
			ROW (
					b2.rel_type,
					b2.virkning,
					b2.rel_maal 
				):: FacetRelationType
			order by b2.id
		) FacetRelationTypeArr
		FROM
		(
			SELECT 	
			a1.*,
			array_agg(
				ROW (
				 	b1.virkning, 
					b1.publiceret
				)::FacetTilsPubliceretType
				order by b1.id
			) FacetTilsPubliceretArr
			FROM
			(
				SELECT
				a.facet_id,
				a.facet_registrering_id,
				a.registrering,
				array_agg(
					ROW(
				 		b.brugervendtnoegle,
				   		b.beskrivelse,
				   		b.opbygning,
				  		b.ophavsret,
				   		b.plan,
				   		b.supplement,
				   		b.retskilde,
				   		b.virkning 
						)::FacetAttrEgenskaberType
					order by b.id
				) FacetAttrEgenskaberArr 
				FROM
					(
						SELECT
						a.id facet_id,
						b.id facet_registrering_id,
						b.registrering			
						FROM		facet a
						JOIN 		facet_registrering b 	ON b.facet_id=a.id
						WHERE a.id = ANY (facet_uuids) AND (((registrering_tstzrange is null OR isempty(registrering_tstzrange)) AND upper((b.registrering).timeperiod)='infinity'::TIMESTAMPTZ) OR registrering_tstzrange && (b.registrering).timeperiod)--filter ON registrering_tstzrange
					) as a 
				LEFT JOIN 	facet_attr_egenskaber b ON b.facet_registrering_id=a.facet_registrering_id AND ((virkning_tstzrange is null OR isempty(virkning_tstzrange)) OR (b.virkning).TimePeriod && virkning_tstzrange) --filter ON virkning_tstzrange if given			
				GROUP BY 
				a.facet_id,
				a.facet_registrering_id,
				a.registrering
			) as a1 		
			LEFT JOIN facet_tils_publiceret b1 ON b1.facet_registrering_id=a1.facet_registrering_id AND ((virkning_tstzrange is null OR isempty(virkning_tstzrange)) OR (b1.virkning).TimePeriod && virkning_tstzrange) --filter ON virkning_tstzrange if given
			GROUP BY 
			a1.facet_id, 
			a1.facet_registrering_id, 
			a1.registrering, 
			a1.FacetAttrEgenskaberArr
		) as a2
	LEFT JOIN facet_relation b2 ON b2.facet_registrering_id=a2.facet_registrering_id AND ((virkning_tstzrange is null OR isempty(virkning_tstzrange)) OR (b2.virkning).TimePeriod && virkning_tstzrange) --filter ON virkning_tstzrange if given
	GROUP BY
	a2.facet_id, 
	a2.facet_registrering_id, 
	a2.registrering, 
	a2.FacetAttrEgenskaberArr,			
	a2.FacetTilsPubliceretArr
	) as a3
	GROUP BY 
	a3.facet_id
	order by facet_id

$BODY$
LANGUAGE sql STABLE
;