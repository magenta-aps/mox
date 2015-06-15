    ARRAY[
    {% for r, relation_periods in relations.iteritems() -%}
    {% set outer_loop = loop %}
    {% for rel in relation_periods -%}
    ROW(
        {{ r|adapt }} :: {{ class_name }}RelationKode,
        ROW(
            '[{{ rel.Virkning.From }}, {{ rel.Virkning.To }})',
             {{ rel.Virkning.AktoerRef|adapt }},
             {{ rel.Virkning.AktoerTypeKode|adapt }},
             {{ rel.Virkning.NoteTekst|adapt }}
            ) :: Virkning,
        {{ rel.uuid|adapt }}
    ){% if not (outer_loop.last and loop.last) -%},{% endif -%}
    {% endfor -%}
    {% endfor -%}
    ] :: {{ class_name }}RelationType[]
