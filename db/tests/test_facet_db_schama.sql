-- Copyright (C) 2015 Magenta ApS, http://magenta.dk.
-- Contact: info@magenta.dk.
--
-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at http://mozilla.org/MPL/2.0/.

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

	RETURN NEXT has_column( 'facet_attr_egenskaber',   'brugervendtnoegle' );
	RETURN NEXT has_column( 'facet_attr_egenskaber',   'beskrivelse' );
	RETURN NEXT has_column( 'facet_attr_egenskaber',   'plan' );
	RETURN NEXT has_column( 'facet_attr_egenskaber',   'opbygning');
	RETURN NEXT has_column( 'facet_attr_egenskaber',   'ophavsret');
	RETURN NEXT has_column( 'facet_attr_egenskaber',   'supplement');
	RETURN NEXT has_column( 'facet_attr_egenskaber',   'retskilde');

	RETURN NEXT has_column( 'facet_tils_publiceret',   'publiceret');

	RETURN NEXT has_column( 'facet_relation',   'rel_maal_uuid');
	RETURN NEXT has_column( 'facet_relation',   'rel_maal_urn');
	RETURN NEXT has_column( 'facet_relation',   'rel_type');
	RETURN NEXT has_column( 'facet_relation',   'objekt_type');



END;
$$;