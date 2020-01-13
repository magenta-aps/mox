    -- SPDX-FileCopyrightText: 2015-2020 Magenta ApS
    -- SPDX-License-Identifier: MPL-2.0

    ROW (
        ROW ( 
            {{ time_period|adapt }},
            {{ life_cycle_code|adapt }} :: Livscykluskode,
            {{ user_ref|adapt }}, 
            {{ note|adapt }}
            ) :: RegistreringBase,
        -- states
        {% for state_array in states -%}
        {{ state_array }},
        {% endfor -%}
        -- attributes
        {% for attribute_array in attributes -%}
        {{ attribute_array }},
        {% endfor %}
        -- relations
        {{ relations }}
        {% if variants -%},
        -- variants
        {{ variants }}
        {% endif -%}
    ) :: {{ class_name }}RegistreringType
