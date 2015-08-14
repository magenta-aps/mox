    SELECT * FROM as_update_{{ class_name | lower }}(
        {{ uuid|adapt }},
        {{ user_ref|adapt }},
        {{ note|adapt }},
        {{ life_cycle_code|adapt }},
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
 
