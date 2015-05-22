        ARRAY[
        {% for attribute_value in attribute_periods -%}
        ROW({% for value in attribute_value -%}
            {% if loop.last -%}
            ROW(
                '[{{ value.From }}, {{ value.To }})',
            '{{ value.AktoerRef }}',
            '{{ value.AktoerTypeKode }}',
            '{{ value.NoteTekst }}'
        ) :: Virkning
            {% else -%}
            {% if value != None -%}
            '{{ value }}',
            {% else -%}
            NULL,
            {% endif -%}
            {% endif -%}
            {% endfor -%}
        ){% if not loop.last %},{% endif %}
        {% endfor -%}
    ] :: {{ attribute_name }}AttrType[]
