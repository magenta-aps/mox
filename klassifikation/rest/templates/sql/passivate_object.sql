    SELECT * FROM as_update_{{ class_name | lower }}(
        '{{ uuid }}',
        '{{ user_ref }}',
        '{{ note }}',
        '{{ life_cycle_code }}',
        null,
        null,
        null);
 
