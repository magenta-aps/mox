
SELECT * from actual_state_update_facet(
    '{{ uuid }}' :: uuid,
    '{{ user_ref }}' :: uuid,
    '{{ note }}',
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
