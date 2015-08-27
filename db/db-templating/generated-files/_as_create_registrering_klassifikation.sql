-- Copyright (C) 2015 Magenta ApS, http://magenta.dk.
-- Contact: info@magenta.dk.
--
-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at http://mozilla.org/MPL/2.0/.

/*
NOTICE: This file is auto-generated using the script: apply-template.py klassifikation _as_create_registrering.jinja.sql
*/


CREATE OR REPLACE FUNCTION _as_create_klassifikation_registrering(
  klassifikation_uuid uuid,
  livscykluskode Livscykluskode, 
  brugerref uuid, 
  note text DEFAULT ''::text
	)
  RETURNS klassifikation_registrering AS 
$$
DECLARE
registreringTime        TIMESTAMPTZ := clock_timestamp();
registreringObj RegistreringBase;
rows_affected int;
klassifikation_registrering_id bigint;
klassifikation_registrering klassifikation_registrering;
BEGIN

--limit the scope of the current unlimited registrering

UPDATE klassifikation_registrering as a
    SET registrering.timeperiod =
      TSTZRANGE(lower((registrering).timeperiod), registreringTime, 
    concat(
            CASE WHEN lower_inc((registrering).timeperiod) THEN '[' ELSE '(' END,
            ')'
        ))
    WHERE klassifikation_id = klassifikation_uuid 
    AND upper((registrering).timeperiod)='infinity'::TIMESTAMPTZ
    AND _as_valid_registrering_livscyklus_transition((registrering).livscykluskode,livscykluskode)  --we'll only limit the scope of the old registrering, if we're dealing with a valid transition. Faliure to move, will result in a constraint violation. A more explicit check on the validity of the state change should be considered.     

;


GET DIAGNOSTICS rows_affected = ROW_COUNT;

IF rows_affected=0 THEN
  RAISE EXCEPTION 'Error updating klassifikation with uuid [%], Invalid [livscyklus] transition to [%]',klassifikation_uuid,livscykluskode USING ERRCODE = 'MO400';
END IF;

--create a new klassifikation registrering
 
klassifikation_registrering_id :=  nextval('klassifikation_registrering_id_seq'::regclass);

 registreringObj := ROW (
      TSTZRANGE(registreringTime,'infinity'::TIMESTAMPTZ,'[)'),
      livscykluskode,
      brugerref,
      note
  ) :: RegistreringBase
 ;



klassifikation_registrering := ROW(
    klassifikation_registrering_id,
    klassifikation_uuid,
    registreringObj
)::klassifikation_registrering
;


INSERT INTO klassifikation_registrering SELECT klassifikation_registrering.*;


RETURN klassifikation_registrering;

END;
$$ LANGUAGE plpgsql VOLATILE;


