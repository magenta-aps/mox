    SELECT * FROM as_update_{{ class_name | lower }}(
        {{ uuid|adapt }},
        {{ user_ref|adapt }},
        {{ note|adapt }},
        {{ life_cycle_code|adapt }},
        null,
        null,
        null);
 
