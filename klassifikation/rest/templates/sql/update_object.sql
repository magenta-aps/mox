
SELECT * from as_update_{{ class_name|lower }}(
    '{{ uuid }}' :: uuid,
    '{{ user_ref }}' :: uuid,
    '{{ note }}',
    '{{ life_cycle_code }}' ::livscykluskode,
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
);
