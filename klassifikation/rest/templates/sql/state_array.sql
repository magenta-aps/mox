        ARRAY[
        {% for state_value in state_periods -%}
        ROW(
            ROW(
                '[{{ state_value.Virkning.From }}, {{ state_value.Virkning.To }})',
                {{ state_value.Virkning.AktoerRef|adapt }},
                {{ state_value.Virkning.AktoerTypeKode|adapt }},
                {{ state_value.Virkning.NoteTekst|adapt }}
            ) :: Virkning,
            {{ state_value.PubliceretStatus|adapt }}
        ){% if not loop.last %},{% endif %}
        {% endfor -%}
        ] :: {{ state_name }}TilsType[]
