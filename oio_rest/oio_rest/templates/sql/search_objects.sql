
SELECT to_json(a.*) from as_search_{{ class_name|lower }}(
    {{first_result|adapt}},
    {{uuid|adapt}}::uuid,
    {{registration}},
    {{virkning_soeg|adapt}},
    {{max_results|adapt}}{% if any_attr_value_arr -%},
    {{any_attr_value_arr|adapt}} :: text[]
    {% endif -%}
    {% if any_rel_uuid_arr -%},
    {{any_rel_uuid_arr|adapt}} :: uuid[]
    {% endif -%}
) a;
