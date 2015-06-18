    ARRAY[
    {% for r, relation_periods in relations.iteritems() -%}
    {% set outer_loop = loop %}
    {% for rel in relation_periods -%}
    ROW(
        {{ r|adapt }} :: {{ class_name }}RelationKode,
        {% if rel.virkning -%}
        ROW(
            '[{{ rel.virkning.from }}, {{ rel.virkning.to }})',
             {{ rel.virkning.aktoerref|adapt }},
             {{ rel.virkning.aktoertypekode|adapt }},
             {{ rel.virkning.notetekst|adapt }}
            )
            {% else -%}
            NULL
            {% endif -%}:: Virkning,
        {{ rel.uuid|adapt }}
    ){% if not (outer_loop.last and loop.last) -%},{% endif -%}
    {% endfor -%}
    {% endfor -%}
    ] :: {{ class_name }}RelationType[]
