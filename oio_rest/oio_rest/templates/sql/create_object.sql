
SELECT * from as_create_or_import_{{ class_name|lower }}(
    {{registration}}{% if uuid != None %},
    '{{uuid}}' :: uuid
    {% endif -%}
);
