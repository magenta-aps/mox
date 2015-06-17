        ARRAY[
        {% for state_value in state_periods -%}
        ROW(
            {% if state_value.virkning %}
            ROW(
                '[{{ state_value.virkning.from }}, {{ state_value.virkning.to }})',
                {{ state_value.virkning.aktoerref|adapt }},
                {{ state_value.virkning.aktoertypekode|adapt }},
                {{ state_value.virkning.notetekst|adapt }}
            )
            {% else -%}
            NULL
            {% endif -%}
            :: Virkning,
            {{ state_value.publiceretstatus|adapt }}
        ){% if not loop.last %},{% endif %}
        {% endfor -%}
        ] :: {{ state_name }}TilsType[]
