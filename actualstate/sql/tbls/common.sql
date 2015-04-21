
CREATE TYPE RegistreringBasis AS (
timeperiod tstzrange,
livscykluskode livscykluskode,
brugerref uuid,
note text
)