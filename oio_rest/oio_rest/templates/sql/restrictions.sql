    -- restrictions
    ARRAY[
    {% for r in restrictions %}
    {{ r }}{% if not loop.last %},{% endif %}
    {% endfor %}
    ]
