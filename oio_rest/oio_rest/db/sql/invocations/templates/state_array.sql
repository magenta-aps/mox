-- SPDX-FileCopyrightText: 2015-2020 Magenta ApS
-- SPDX-License-Identifier: MPL-2.0

{% if state_periods is none -%}
NULL
{% else -%}
        ARRAY[
        {% for state_value in state_periods -%}
        ROW(
            {% if state_value.virkning %}
            ROW(
                '[{{ state_value.virkning.from }}, {{ state_value.virkning.to }})',
                {% if state_value.virkning.aktoerref %}{{ state_value.virkning.aktoerref|adapt }}{% else %}NULL{% endif %},
                {% if state_value.virkning.aktoertypekode %}{{ state_value.virkning.aktoertypekode|adapt }}{% else %}NULL{% endif %},
                {% if state_value.virkning.notetekst %}{{ state_value.virkning.notetekst|adapt }}{% else %}''{% endif %}
            )
            {% else -%}
            NULL
            {% endif -%}
            :: Virkning,
            {{ state_value[state_name]|adapt }}
        ){% if not loop.last %},{% endif %}
        {% endfor -%}
        ] :: {{ class_name}}{{ state_name }}TilsType[]
{% endif -%}

