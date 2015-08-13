        ARRAY[
        {% for variant in variants -%}
        ROW(
            {{ variant.varianttekst|adapt }},
            {{ variant.egenskaber|adapt }},
            {{ variant.dele|adapt }}
        ){% if not loop.last %},{% endif %}
        {% endfor -%}
        ] :: {{ class_name }}VariantType[]