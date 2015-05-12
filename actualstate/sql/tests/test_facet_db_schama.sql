--DROP FUNCTION test.test_facet_db_schama();
CREATE OR REPLACE FUNCTION test.test_facet_db_schama()
RETURNS SETOF TEXT LANGUAGE plpgsql AS $$
BEGIN
    RETURN NEXT has_table( 'facet' );
    RETURN NEXT has_table( 'facet_registrering' );
    RETURN NEXT has_table( 'facet_attr_egenskaber' );
    RETURN NEXT has_table( 'facet_tils_publiceret' );
    RETURN NEXT has_table( 'facet_relation' );

    RETURN NEXT col_is_pk(  'facet', 'id' );
    RETURN NEXT col_is_pk(  'facet_registrering', 'id' );
    RETURN NEXT col_is_pk(  'facet_attr_egenskaber', 'id' );
    RETURN NEXT col_is_pk(  'facet_tils_publiceret', 'id' );
    RETURN NEXT col_is_pk(  'facet_relation', 'id' );


	RETURN NEXT col_is_fk('facet_registrering','facet_id');
	RETURN NEXT col_is_fk('facet_attr_egenskaber','facet_registrering_id');
	RETURN NEXT col_is_fk('facet_tils_publiceret','facet_registrering_id');
	RETURN NEXT col_is_fk('facet_relation','facet_registrering_id');

	RETURN NEXT has_column( 'facet_attr_egenskaber',   'brugervendt_noegle' );
	RETURN NEXT has_column( 'facet_attr_egenskaber',   'facetbeskrivelse' );
	RETURN NEXT has_column( 'facet_attr_egenskaber',   'facetplan' );
	RETURN NEXT has_column( 'facet_attr_egenskaber',   'facetopbygning');
	RETURN NEXT has_column( 'facet_attr_egenskaber',   'facetophavsret');
	RETURN NEXT has_column( 'facet_attr_egenskaber',   'facetsupplement');
	RETURN NEXT has_column( 'facet_attr_egenskaber',   'retskilde');

	RETURN NEXT has_column( 'facet_tils_publiceret',   'status');

	RETURN NEXT has_column( 'facet_relation',   'rel_maal');
	RETURN NEXT has_column( 'facet_relation',   'rel_type');




END;
$$;