
CREATE OR REPLACE FUNCTION _actual_state_get_prev_facet_registrering(facet_registrering)
  RETURNS facet_registrering AS
  $BODY$
  SELECT  * FROM facet_registrering as a WHERE
    facet_id = $1.facet_id 
    AND UPPER((a.registrering).TimePeriod) = LOWER(($1.registrering).TimePeriod) 
    AND UPPER_INC((a.registrering).TimePeriod) <> LOWER_INC(($1.registrering).TimePeriod)
    LIMIT 1 --constraints on timeperiod will also ensure max 1 hit
    $BODY$
  LANGUAGE sql STABLE
;