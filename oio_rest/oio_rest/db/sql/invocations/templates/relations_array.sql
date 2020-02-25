-- SPDX-FileCopyrightText: 2015-2020 Magenta ApS
-- SPDX-License-Identifier: MPL-2.0
{% if not relations -%}
NULL
{% else -%}
    ARRAY[
    {% for r, relation_periods in relations.items() -%}
    {% set outer_loop = loop %}
    {% for rel in relation_periods -%}
    ROW(
        {{ r|adapt }} :: {{ class_name }}RelationKode,
        {% if rel.virkning -%}
        ROW(
            '[{{ rel.virkning.from }}, {{ rel.virkning.to }})',
             {% if rel.virkning.aktoerref %}{{ rel.virkning.aktoerref|adapt }}{% else %}NULL{% endif %},
             {% if rel.virkning.aktoertypekode %}{{ rel.virkning.aktoertypekode|adapt }}{% else %}NULL{% endif %},
             {% if rel.virkning.notetekst %}{{ rel.virkning.notetekst|adapt }}{% else %}''{% endif %}
            )
            {% else -%}
            NULL
            {% endif -%}:: Virkning,
            {% if rel.uuid is defined  and rel.uuid %}{{ rel.uuid|adapt }}{% else %}NULL{% endif %},
            {% if rel.urn is defined  and rel.urn %}{{ rel.urn|adapt }}{% else %}NULL{% endif %},
            {% if rel.objekttype is defined %}{{ rel.objekttype|adapt }}{% else %}NULL{% endif %}
        {% if class_name == "Sag" -%}
        ,        {% if rel.indeks is defined %}{{ rel.indeks|adapt }}{% else%}NULL{% endif %},
            {% if rel.journalpostkode is defined %}{{ rel.journalpostkode|adapt }}{% else %}NULL{% endif %},
            {% if rel.journalnotat is defined %}{{ rel.journalnotat|adapt }}{% else %}NULL{% endif %},
            {% if rel.journaldokument is defined %}{{ rel.journaldokument|adapt }}{% else %}NULL{% endif %}
        {% endif -%}
        {% if class_name == "Aktivitet" -%}
        ,        {% if rel.indeks is defined %}{{ rel.indeks|adapt }}{% else%}NULL{% endif %},
            {% if rel.aktoerattr is defined %}{{ rel.aktoerattr|adapt }}{% else %}NULL{% endif %}
        {% endif %}
        {% if class_name == "Indsats" -%}
        ,        {% if rel.indeks is defined %}{{ rel.indeks|adapt }}{% else%}NULL{% endif %}
        {% endif %}
        {% if class_name == "Tilstand" -%}
        , {% if rel.indeks is defined %}{{ rel.indeks|adapt }}{% else%}NULL{% endif %},
        {% if rel.tilstandsvaerdiattr is defined %}{{ rel.tilstandsvaerdiattr|adapt }}{% else %}NULL{% endif %}
        {% endif %}
    ){% if not (outer_loop.last and loop.last) -%},{% endif -%}
    {% endfor -%}
    {% endfor -%}
    ] :: {{ class_name }}RelationType[]
{% endif -%}
