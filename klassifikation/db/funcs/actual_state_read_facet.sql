CREATE OR REPLACE FUNCTION actual_state_read_facet(facet_uuid uuid,
  registrering_tstzrange tstzrange,
  virkning_tstzrange tstzrange)
  RETURNS FacetType AS
  $BODY$
SELECT 
*
FROM actual_state_list_facet(ARRAY[facet_uuid],registrering_tstzrange,virkning_tstzrange)
LIMIT 1
--TODO: Verify and test!
 	$BODY$
LANGUAGE sql STABLE
;

