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
        {% if variants -%}
        -- variants
        ,
        {% for variant_array in variants -%}
        {{ variant_array }},
        {% endfor -%}
        {% endif -%}
    ) :: {{ class_name }}RegistreringType
