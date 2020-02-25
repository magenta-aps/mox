-- SPDX-FileCopyrightText: 2018-2020 Magenta ApS
-- SPDX-License-Identifier: MPL-2.0

SELECT * from as_create_or_import_{{ class_name|lower }}(
    {{registration}},
    {% if uuid != None %} '{{uuid}}' :: uuid {% else %}null{% endif %}{% if restrictions %},
        {{restrictions}}
            {% endif %}
);
