
-- Copyright (C) 2015 Magenta ApS, http://magenta.dk.
-- Contact: info@magenta.dk.
--
-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at http://mozilla.org/MPL/2.0/.


CREATE OR REPLACE FUNCTION _actual_state_create_facet_registrering(
  facet_uuid uuid,
  livscykluskode Livscykluskode, 
  brugerref uuid, 
  note text DEFAULT ''::text
	)
  RETURNS facet_registrering AS 
$$
DECLARE
registreringTime        TIMESTAMPTZ := clock_timestamp();
registreringObj RegistreringBase;
facet_registrering_id bigint;
facet_registrering facet_registrering;
BEGIN

--limit the scope of the current unlimited registrering

UPDATE facet_registrering as a
    SET registrering.timeperiod =
      TSTZRANGE(lower((registrering).timeperiod), registreringTime, 
    concat(
            CASE WHEN lower_inc((registrering).timeperiod) THEN '[' ELSE '(' END,
            ')'
        ))
    WHERE facet_id = facet_uuid 
    AND upper((registrering).timeperiod)='infinity'::TIMESTAMPTZ
    AND _actual_state_valid_registrering_livscyklus_transition((registrering).livscykluskode,livscykluskode)  --we'll only limit the scope of the old registrering, if we're dealing with a valid transition. Faliure to move, will result in a constraint violation. A more explicit check on the validity of the state change should be considered.     

;
--create a new facet registrering
 
facet_registrering_id :=  nextval('facet_registrering_id_seq'::regclass);

 registreringObj := ROW (
      TSTZRANGE(registreringTime,'infinity'::TIMESTAMPTZ,'[)'),
      livscykluskode,
      brugerref,
      note
  ) :: RegistreringBase
 ;



facet_registrering := ROW(
    facet_registrering_id,
    facet_uuid,
    registreringObj
)::facet_registrering
;


INSERT INTO facet_registrering SELECT facet_registrering.*;


RETURN facet_registrering;

END;
$$ LANGUAGE plpgsql VOLATILE;