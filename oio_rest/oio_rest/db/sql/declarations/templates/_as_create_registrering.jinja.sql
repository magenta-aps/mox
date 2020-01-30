{% extends "basis.jinja.sql" %}

-- SPDX-FileCopyrightText: 2018-2020 Magenta ApS
-- SPDX-License-Identifier: MPL-2.0


{% block body %}

CREATE OR REPLACE FUNCTION _as_create_{{oio_type}}_registrering(
    {{oio_type}}_uuid uuid,
    livscykluskode Livscykluskode,
    brugerref uuid,
    note text DEFAULT ''::text
) RETURNS {{oio_type}}_registrering AS $$
DECLARE
    registreringTime TIMESTAMPTZ := clock_timestamp();
    registreringObj RegistreringBase;
    rows_affected int;
    {{oio_type}}_registrering_id bigint;
    {{oio_type}}_registrering    {{oio_type}}_registrering;
BEGIN
    --limit the scope of the current unlimited registrering
    UPDATE {{oio_type}}_registrering as a
        SET registrering.timeperiod = TSTZRANGE(
            lower((registrering).timeperiod),
            registreringTime,
            concat(
                CASE WHEN lower_inc((registrering).timeperiod) THEN '[' ELSE '(' END,
                ')'
            ))
        WHERE {{oio_type}}_id = {{oio_type}}_uuid
        AND upper((registrering).timeperiod)='infinity'::TIMESTAMPTZ
        AND _as_valid_registrering_livscyklus_transition((registrering).livscykluskode,livscykluskode)  --we'll only limit the scope of the old registrering, if we're dealing with a valid transition. Faliure to move, will result in a constraint violation. A more explicit check on the validity of the state change should be considered.
    ;

    GET DIAGNOSTICS rows_affected = ROW_COUNT;

    IF rows_affected=0 THEN
      RAISE EXCEPTION 'Error updating {{oio_type}} with uuid [%], Invalid [livscyklus] transition to [%]',{{oio_type}}_uuid,livscykluskode USING ERRCODE = 'MO400';
    END IF;

    --create a new {{oio_type}} registrering

    {{oio_type}}_registrering_id := nextval('{{oio_type}}_registrering_id_seq'::regclass);

    registreringObj := ROW (
        TSTZRANGE(registreringTime,'infinity'::TIMESTAMPTZ,'[)'),
        livscykluskode,
        brugerref,
        note
    ) :: RegistreringBase;

    {{oio_type}}_registrering := ROW(
        {{oio_type}}_registrering_id,
        {{oio_type}}_uuid,
        registreringObj
    )::{{oio_type}}_registrering;

    INSERT INTO {{oio_type}}_registrering SELECT {{oio_type}}_registrering.*;

    RETURN {{oio_type}}_registrering;
END;
$$ LANGUAGE plpgsql VOLATILE;

{% endblock %}
