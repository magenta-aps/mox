        ARRAY[
        {% for state_value in state_periods -%}
        ROW(
            ROW(
                '[{{ state_value.virkning.from }}, {{ state_value.virkning.to }})',
                {{ state_value.virkning.aktoerref|adapt }},
                {{ state_value.virkning.aktoertypekode|adapt }},
                {{ state_value.virkning.notetekst|adapt }}
            ) :: Virkning,
            {{ state_value.publiceretstatus|adapt }}
        ){% if not loop.last %},{% endif %}
        {% endfor -%}
        ] :: {{ state_name }}TilsType[]
