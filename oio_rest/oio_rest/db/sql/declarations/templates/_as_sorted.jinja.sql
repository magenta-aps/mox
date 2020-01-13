{% extends "basis.jinja.sql" %}

-- SPDX-FileCopyrightText: 2018-2020 Magenta ApS
-- SPDX-License-Identifier: MPL-2.0


{% block body %}

CREATE OR REPLACE FUNCTION _as_sorted_{{oio_type}}(
    {{oio_type}}_uuids uuid[],
    virkningSoeg TSTZRANGE,
    registreringObj    {{oio_type|title}}RegistreringType,
    firstResult int,
    maxResults int
) RETURNS uuid[] AS $$
DECLARE
    {{oio_type}}_sorted_uuid uuid[];
    registreringSoeg TSTZRANGE;
BEGIN
    IF registreringObj IS NULL OR (registreringObj.registrering).timePeriod IS NULL THEN
        registreringSoeg = TSTZRANGE(current_timestamp, current_timestamp, '[]');
    ELSE
        registreringSoeg = (registreringObj.registrering).timePeriod;
    END IF;

    {{oio_type}}_sorted_uuid:=array(
          SELECT b.{{oio_type}}_id
            FROM {{oio_type}}_registrering b
            JOIN {{oio_type}}_attr_egenskaber a ON a.{{oio_type}}_registrering_id=b.id
           WHERE b.{{oio_type}}_id = ANY ({{oio_type}}_uuids)
             AND (b.registrering).timeperiod && registreringSoeg
             AND (a.virkning).timePeriod && virkningSoeg
        GROUP BY b.{{oio_type}}_id
        ORDER BY array_agg(DISTINCT a.brugervendtnoegle), b.{{oio_type}}_id
           LIMIT maxResults OFFSET firstResult
    );

    RETURN {{oio_type}}_sorted_uuid;
END;
$$ LANGUAGE plpgsql STABLE;

{% endblock %}
