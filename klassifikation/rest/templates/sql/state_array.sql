        ARRAY[
        {% for state_value in state_periods -%}
        ROW(
            ROW(
                '[{{ state_value.Virkning.From }}, {{ state_value.Virkning.To }})',
                '{{ state_value.Virkning.AktoerRef }}',
                '{{ state_value.Virkning.AktoerTypeKode }}',
                '{{ state_value.Virkning.NoteTekst }}'
            ) :: Virkning,
            '{{ state_value.FacetPubliceretStatus }}'
        ){% if not loop.last %},{% endif %}
        {% endfor -%}
        ] :: {{ state_name }}TilsType[]
