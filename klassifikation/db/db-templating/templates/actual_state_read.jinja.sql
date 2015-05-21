{% extends "basis.jinja.sql" %}
-- Copyright (C) 2015 Magenta ApS, http://magenta.dk.
-- Contact: info@magenta.dk.
--
-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at http://mozilla.org/MPL/2.0/.
{% block body %}
CREATE OR REPLACE FUNCTION actual_state_read_{{oio_type}}({{oio_type}}_uuid uuid,
  registrering_tstzrange tstzrange,
  virkning_tstzrange tstzrange)
  RETURNS {{oio_type|title}}Type AS
  $BODY$
SELECT 
*
FROM actual_state_list_{{oio_type}}(ARRAY[{{oio_type}}_uuid],registrering_tstzrange,virkning_tstzrange)
LIMIT 1
--TODO: Verify and test!
 	$BODY$
LANGUAGE sql STABLE
;

{% endblock %}