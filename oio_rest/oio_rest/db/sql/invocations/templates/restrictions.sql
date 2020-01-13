    -- SPDX-FileCopyrightText: 2015-2020 Magenta ApS
    -- SPDX-License-Identifier: MPL-2.0
    -- restrictions
    ARRAY[
    {% for r in restrictions %}
    {{ r }}{% if not loop.last %},{% endif %}
    {% endfor %}
    ]
