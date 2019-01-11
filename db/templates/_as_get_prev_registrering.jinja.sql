{% extends "basis.jinja.sql" %}

-- Copyright (C) 2015 Magenta ApS, https://magenta.dk.
-- Contact: info@magenta.dk.
--
-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at http://mozilla.org/MPL/2.0/.


{% block body %}

CREATE OR REPLACE FUNCTION _as_get_prev_{{oio_type}}_registrering(
    {{oio_type}}_registrering
) RETURNS {{oio_type}}_registrering AS $BODY$
  SELECT * FROM {{oio_type}}_registrering as a WHERE
    {{oio_type}}_id = $1.{{oio_type}}_id 
    AND UPPER((a.registrering).TimePeriod) = LOWER(($1.registrering).TimePeriod) 
    AND UPPER_INC((a.registrering).TimePeriod) <> LOWER_INC(($1.registrering).TimePeriod)
    LIMIT 1 --constraints on timeperiod will also ensure max 1 hit
$BODY$ LANGUAGE sql STABLE;

{% endblock %}
