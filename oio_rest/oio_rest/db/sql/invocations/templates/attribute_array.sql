-- SPDX-FileCopyrightText: 2015-2020 Magenta ApS
-- SPDX-License-Identifier: MPL-2.0

{% if attribute_periods is none -%}
NULL
{% else -%}
    ARRAY[
        {% for attribute_value in attribute_periods -%}
        ROW({% for value in attribute_value -%}
            {% if loop.last -%}
            {% if value -%}
            ROW(
                '[{{ value.from }}, {{ value.to }})',
            {% if value.aktoerref %}{{ value.aktoerref|adapt }}{% else %}NULL{% endif %},
            {% if value.aktoertypekode %}{{ value.aktoertypekode|adapt }}{% else %}NULL{% endif %},
            {% if value.notekst %}{{ value.notetekst|adapt }}{% else %}''{% endif %}
            )
         {% else -%}
            NULL
            {% endif -%}
         :: Virkning
            {% else -%}
            {% if value != None -%}
            {{ value|adapt }},
            {% else -%}
            NULL,
            {% endif -%}
            {% endif -%}
            {% endfor -%}
        ){% if not loop.last %},{% endif %}
        {% endfor -%}
    ] :: {{ attribute_name }}AttrType[]
{% endif -%}
