-- SPDX-FileCopyrightText: 2015-2020 Magenta ApS
-- SPDX-License-Identifier: MPL-2.0

SELECT * from as_update_{{ class_name|lower }}(
    {{ uuid|adapt }} :: uuid,
    {{ user_ref|adapt }} :: uuid,
    {{ note|adapt }},
    {{ life_cycle_code|adapt }} ::livscykluskode,
    -- attributes
    {% for attribute_array in attributes -%}
    {{ attribute_array }},
    {% endfor %}
    -- states
    {% for state_array in states -%}
    {{ state_array }},
    {% endfor -%}
    -- relations
    {{ relations }}
    {% if variants -%},
    -- variants
    {{ variants }}
    {% endif -%}
    {% if restrictions -%},
        {{restrictions}}
            {% endif %}
);
