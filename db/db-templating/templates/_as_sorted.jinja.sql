{% extends "basis.jinja.sql" %}
-- Copyright (C) 2015 Magenta ApS, http://magenta.dk.
-- Contact: info@magenta.dk.
--
-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at http://mozilla.org/MPL/2.0/.
{% block body %}

CREATE OR REPLACE FUNCTION _as_sorted_{{oio_type}}(
        {{oio_type}}_uuids uuid[],
	    firstResult int,
	    maxResults int
        )
  RETURNS uuid[] AS
  $$
  DECLARE
          {{oio_type}}_sorted_uuid uuid[];
  BEGIN

{{oio_type}}_sorted_uuid:=array(
SELECT b.{{oio_type}}_id
    FROM  {{oio_type}}_attr_egenskaber a
    JOIN (SELECT DISTINCT ON ({{oio_type}}_id) {{oio_type}}_id, id FROM {{oio_type}}_registrering) b ON a.{{oio_type}}_registrering_id=b.id
    WHERE b.{{oio_type}}_id = ANY ({{oio_type}}_uuids)
    ORDER BY a.brugervendtnoegle
         LIMIT maxResults OFFSET firstResult
);

RETURN {{oio_type}}_sorted_uuid;

END;
$$ LANGUAGE plpgsql STABLE;


{% endblock %}
