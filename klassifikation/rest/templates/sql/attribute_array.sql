        ARRAY[
        {% for attribute_value in attribute_periods -%}
        ROW({% for value in attribute_value -%}
            {% if loop.last -%}
            ROW(
                '[{{ value.From }}, {{ value.To }})',
            {{ value.AktoerRef|adapt }},
            {{ value.AktoerTypeKode|adapt }},
            {{ value.NoteTekst|adapt }}
        ) :: Virkning
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
