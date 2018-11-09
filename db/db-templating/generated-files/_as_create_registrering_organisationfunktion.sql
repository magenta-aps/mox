-- Copyright (C) 2015 Magenta ApS, http://magenta.dk.
-- Contact: info@magenta.dk.
--
-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at http://mozilla.org/MPL/2.0/.

/*
NOTICE: This file is auto-generated using the script: apply-template.py organisationfunktion _as_create_registrering.jinja.sql
*/


CREATE OR REPLACE FUNCTION _as_create_organisationfunktion_registrering(
  organisationfunktion_uuid uuid,
  livscykluskode Livscykluskode, 
  brugerref uuid, 
  note text DEFAULT ''::text
	)
  RETURNS organisationfunktion_registrering AS 
$$
DECLARE
registreringTime        TIMESTAMPTZ := clock_timestamp();
registreringObj RegistreringBase;
rows_affected int;
organisationfunktion_registrering_id bigint;
organisationfunktion_registrering organisationfunktion_registrering;
BEGIN

--limit the scope of the current unlimited registrering

UPDATE organisationfunktion_registrering as a
    SET registrering.timeperiod =
      TSTZRANGE(lower((registrering).timeperiod), registreringTime, 
    concat(
            CASE WHEN lower_inc((registrering).timeperiod) THEN '[' ELSE '(' END,
            ')'
        ))
    WHERE organisationfunktion_id = organisationfunktion_uuid 
    AND upper((registrering).timeperiod)='infinity'::TIMESTAMPTZ
    AND _as_valid_registrering_livscyklus_transition((registrering).livscykluskode,livscykluskode)  --we'll only limit the scope of the old registrering, if we're dealing with a valid transition. Faliure to move, will result in a constraint violation. A more explicit check on the validity of the state change should be considered.     

;


GET DIAGNOSTICS rows_affected = ROW_COUNT;

IF rows_affected=0 THEN
  RAISE EXCEPTION 'Error updating organisationfunktion with uuid [%], Invalid [livscyklus] transition to [%]',organisationfunktion_uuid,livscykluskode USING ERRCODE = 'MO400';
END IF;

--create a new organisationfunktion registrering
 
organisationfunktion_registrering_id :=  nextval('organisationfunktion_registrering_id_seq'::regclass);

 registreringObj := ROW (
      TSTZRANGE(registreringTime,'infinity'::TIMESTAMPTZ,'[)'),
      livscykluskode,
      brugerref,
      note
  ) :: RegistreringBase
 ;



organisationfunktion_registrering := ROW(
    organisationfunktion_registrering_id,
    organisationfunktion_uuid,
    registreringObj
)::organisationfunktion_registrering
;


INSERT INTO organisationfunktion_registrering SELECT organisationfunktion_registrering.*;


RETURN organisationfunktion_registrering;

END;
$$ LANGUAGE plpgsql VOLATILE;


