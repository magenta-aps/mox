-- Copyright (C) 2015 Magenta ApS, http://magenta.dk.
-- Contact: info@magenta.dk.
--
-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at http://mozilla.org/MPL/2.0/.

/*
NOTICE: This file is auto-generated using the script: apply-template.py dokument _as_create_registrering.jinja.sql
*/


CREATE OR REPLACE FUNCTION _as_create_dokument_registrering(
  dokument_uuid uuid,
  livscykluskode Livscykluskode, 
  brugerref uuid, 
  note text DEFAULT ''::text
	)
  RETURNS dokument_registrering AS 
$$
DECLARE
registreringTime        TIMESTAMPTZ := clock_timestamp();
registreringObj RegistreringBase;
rows_affected int;
dokument_registrering_id bigint;
dokument_registrering dokument_registrering;
BEGIN

--limit the scope of the current unlimited registrering

UPDATE dokument_registrering as a
    SET registrering.timeperiod =
      TSTZRANGE(lower((registrering).timeperiod), registreringTime, 
    concat(
            CASE WHEN lower_inc((registrering).timeperiod) THEN '[' ELSE '(' END,
            ')'
        ))
    WHERE dokument_id = dokument_uuid 
    AND upper((registrering).timeperiod)='infinity'::TIMESTAMPTZ
    AND _as_valid_registrering_livscyklus_transition((registrering).livscykluskode,livscykluskode)  --we'll only limit the scope of the old registrering, if we're dealing with a valid transition. Faliure to move, will result in a constraint violation. A more explicit check on the validity of the state change should be considered.     

;


GET DIAGNOSTICS rows_affected = ROW_COUNT;

IF rows_affected=0 THEN
  RAISE EXCEPTION 'Error updating dokument with uuid [%], Invalid [livscyklus] transition to [%]',dokument_uuid,livscykluskode USING ERRCODE = 22000;
END IF;

--create a new dokument registrering
 
dokument_registrering_id :=  nextval('dokument_registrering_id_seq'::regclass);

 registreringObj := ROW (
      TSTZRANGE(registreringTime,'infinity'::TIMESTAMPTZ,'[)'),
      livscykluskode,
      brugerref,
      note
  ) :: RegistreringBase
 ;



dokument_registrering := ROW(
    dokument_registrering_id,
    dokument_uuid,
    registreringObj
)::dokument_registrering
;


INSERT INTO dokument_registrering SELECT dokument_registrering.*;


RETURN dokument_registrering;

END;
$$ LANGUAGE plpgsql VOLATILE;


