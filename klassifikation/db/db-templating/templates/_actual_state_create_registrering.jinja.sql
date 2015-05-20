{% extends "basis.jinja.sql" %}
-- Copyright (C) 2015 Magenta ApS, http://magenta.dk.
-- Contact: info@magenta.dk.
--
-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at http://mozilla.org/MPL/2.0/.
{% block body %}

CREATE OR REPLACE FUNCTION _actual_state_create_{{oio_type}}_registrering(
  {{oio_type}}_uuid uuid,
  livscykluskode Livscykluskode, 
  brugerref uuid, 
  note text DEFAULT ''::text
	)
  RETURNS {{oio_type}}_registrering AS 
$$
DECLARE
registreringTime        TIMESTAMPTZ := clock_timestamp();
registreringObj RegistreringBase;
{{oio_type}}_registrering_id bigint;
{{oio_type}}_registrering {{oio_type}}_registrering;
BEGIN

--limit the scope of the current unlimited registrering

UPDATE {{oio_type}}_registrering as a
    SET registrering.timeperiod =
      TSTZRANGE(lower((registrering).timeperiod), registreringTime, 
    concat(
            CASE WHEN lower_inc((registrering).timeperiod) THEN '[' ELSE '(' END,
            ')'
        ))
    WHERE {{oio_type}}_id = {{oio_type}}_uuid 
    AND upper((registrering).timeperiod)='infinity'::TIMESTAMPTZ
    AND _actual_state_valid_registrering_livscyklus_transition((registrering).livscykluskode,livscykluskode)  --we'll only limit the scope of the old registrering, if we're dealing with a valid transition. Faliure to move, will result in a constraint violation. A more explicit check on the validity of the state change should be considered.     

;
--create a new {{oio_type}} registrering
 
{{oio_type}}_registrering_id :=  nextval('{{oio_type}}_registrering_id_seq'::regclass);

 registreringObj := ROW (
      TSTZRANGE(registreringTime,'infinity'::TIMESTAMPTZ,'[)'),
      livscykluskode,
      brugerref,
      note
  ) :: RegistreringBase
 ;



{{oio_type}}_registrering := ROW(
    {{oio_type}}_registrering_id,
    {{oio_type}}_uuid,
    registreringObj
)::{{oio_type}}_registrering
;


INSERT INTO {{oio_type}}_registrering SELECT {{oio_type}}_registrering.*;


RETURN {{oio_type}}_registrering;

END;
$$ LANGUAGE plpgsql VOLATILE;
{% endblock %}