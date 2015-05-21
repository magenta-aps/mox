
SELECT * from actual_state_create_or_import_facet(
    ROW (
        ROW ( 
            NULL, 
            '{{ life_cycle_code }}' :: Livscykluskode,
            '{{ user_ref }}', 
            '{{ note }}'
            ) :: RegistreringBase,
        {% for s, state_periods in states.iteritems() -%}
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
        ),
        {% endfor -%}
        ] :: {{ s }}TilsType[],
        {% endfor -%}
        {% for a, attribute_periods in attributes.iteritems() -%}
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
        )
        {% endfor -%}
    ] :: {{ a }}AttrType[],
    {% endfor %}
    ARRAY[
    {% for r, relation_periods in relations.iteritems() -%}
    {% for rel in relation_periods -%}
    ROW(
        '{{ r }}' :: FacetRelationKode,
        ROW(
            '[{{ rel.Virkning.From }}, {{ rel.Virkning.To }})',
             '{{ rel.Virkning.AktoerRef }}',
             '{{ rel.Virkning.AktoerTypeKode }}',
             '{{ rel.Virkning.NoteTekst }}'
            ) :: Virkning,
        '{{ rel.uuid }}'
    )
    {% endfor -%}
    {% endfor -%}
    ] :: FacetRelationType[]
    ) :: FacetRegistreringType{% if uuid != None %},
    '{{uuid}}' :: uuid
    {% endif -%}
);
