
SELECT * from actual_state_create_or_import_facet(
    ROW (
        ROW ( 
            NULL, 
            '{{ life_cycle_code }}' :: Livscykluskode,
            '{{ user_ref }}', 
            '{{ note }}'
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
    ) :: FacetRegistreringType{% if uuid != None %},
    '{{uuid}}' :: uuid
    {% endif -%}
);
