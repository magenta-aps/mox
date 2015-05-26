    ARRAY[
    {% for r, relation_periods in relations.iteritems() -%}
    {% set outer_loop = loop %}
    {% for rel in relation_periods -%}
    ROW(
        '{{ r }}' :: {{ class_name }}RelationKode,
        ROW(
            '[{{ rel.Virkning.From }}, {{ rel.Virkning.To }})',
             '{{ rel.Virkning.AktoerRef }}',
             '{{ rel.Virkning.AktoerTypeKode }}',
             '{{ rel.Virkning.NoteTekst }}'
            ) :: Virkning,
        '{{ rel.uuid }}'
    ){% if not (outer_loop.last and loop.last) -%},{% endif -%}
    {% endfor -%}
    {% endfor -%}
    ] :: {{ class_name }}RelationType[]
