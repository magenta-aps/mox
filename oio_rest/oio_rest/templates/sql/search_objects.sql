
SELECT to_json(a.*) from as_search_{{ class_name|lower }}(
    {{first_result|adapt}},
    {{uuid|adapt}}::uuid,
    {{registration}},
    %(virkning_soeg)s,
    {{max_results|adapt}}
    {% if any_attr_value_array -%},
    '{{any_attr_value_array|adapt}}' :: text[]
    {% endif -%}
    {% if any_rel_uuid_array -%},
    '{{any_rel_uuid_array|adapt}}' :: uuid[]
    {% endif -%}
) a;
