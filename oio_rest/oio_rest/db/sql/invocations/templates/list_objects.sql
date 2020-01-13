-- SPDX-FileCopyrightText: 2015-2020 Magenta ApS
-- SPDX-License-Identifier: MPL-2.0

SELECT  as_list_{{ class_name | lower }}(
    %(uuid)s::uuid[],
    %(registrering_tstzrange)s,
    %(virkning_tstzrange)s{% if restrictions %},
        {{restrictions}}
            {% endif %}
    ) :: json[];
