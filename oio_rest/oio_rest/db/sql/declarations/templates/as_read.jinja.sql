{% extends "basis.jinja.sql" %}

-- SPDX-FileCopyrightText: 2018-2020 Magenta ApS
-- SPDX-License-Identifier: MPL-2.0


{% block body %}

CREATE OR REPLACE FUNCTION as_read_{{oio_type}}(
    {{oio_type}}_uuid uuid,
    registrering_tstzrange tstzrange,
    virkning_tstzrange tstzrange,
    auth_criteria_arr      {{oio_type|title}}RegistreringType[]=null
) RETURNS {{oio_type|title}}Type AS $$
DECLARE
	resArr {{oio_type|title}}Type[];
BEGIN
    resArr := as_list_{{oio_type}}(ARRAY[{{oio_type}}_uuid], registrering_tstzrange, virkning_tstzrange, auth_criteria_arr);
    IF resArr is not null and coalesce(array_length(resArr, 1), 0) = 1 THEN
	    RETURN resArr[1];
    ELSE
        RETURN null;
    END IF;
END;
$$ LANGUAGE plpgsql STABLE;

{% endblock %}
