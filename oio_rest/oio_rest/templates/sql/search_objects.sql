
SELECT to_json(a.*) from as_search_{{ class_name|lower }}(
    {{first_result|adapt}},
    {{uuid|adapt}}::uuid,
    {{registration}},
    {{virkning_soeg|adapt}},
    {{max_results|adapt}},
    {{any_attr_value_arr|adapt}} :: text[],
    {{any_rel_uuid_arr|adapt}} :: uuid[]
) a;
