{% if relations is none -%}
NULL
{% else -%}
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
            {% if rel.uuid is defined %}{{ rel.uuid|adapt }}{% else %}NULL{% endif %},
            {% if rel.urn is defined %}{{ rel.urn|adapt }}{% else %}NULL{% endif %},
            {% if rel.objekttype is defined %}{{ rel.objekttype|adapt }}{% else %}NULL{% endif %}
        {% if class_name == "Sag" %}
        ,        {{ rel.indeks|adapt }},
            {% if rel.journalpostkode is defined %}{{ rel.journalpostkode|adapt }}{% else %}NULL{% endif %},
            {% if rel.journalnotat is defined %}{{ rel.journalnotat|adapt }}{% else %}NULL{% endif %},
            {% if rel.journaldokument is defined %}{{ rel.journaldokument|adapt }}{% else %}NULL{% endif %}
        {% endif %}
    ){% if not (outer_loop.last and loop.last) -%},{% endif -%}
    {% endfor -%}
    {% endfor -%}
    ] :: {{ class_name }}RelationType[]
{% endif -%}
