SELECT COUNT(DISTINCT Entry)
FROM {{cls}} as Entry
  JOIN {{cls}}_registrering Reg
    ON Reg.{{cls}}_id = Entry.id

{#- For now, we join in the relevant tables once per relation -- that's rather
    slow, but reliable #}
{%- for rel_kind in reg['relations'] %}
  JOIN {{cls}}_relation Rel_{{rel_kind}}
    ON Rel_{{rel_kind}}.{{cls}}_registrering_id = Reg.id
{%- endfor %}

{%- for attr_kind in reg['attributes'] %}
  {%- set attr_kind_short = attr_kind[cls|length:] %}
  JOIN {{cls}}_attr_{{attr_kind_short}} Prop_{{attr_kind}}
    ON Prop_{{attr_kind}}.{{cls}}_registrering_id = Reg.id
{%- endfor %}

{%- for state_kind in reg['states'] %}
  JOIN {{cls}}_tils_{{state_kind}} State_{{state_kind}}
    ON State_{{state_kind}}.{{cls}}_registrering_id = Reg.id
{%- endfor %}

WHERE
  -- prerequisites
  (Reg.registrering).livscykluskode <> 'Slettet'::Livscykluskode
  AND
  (Reg.registrering).timeperiod @> now()
  AND

{%- for rel_kind, rel_values in reg['relations'].items() %}
  -- {{rel_kind}} -> {{rel_value}}
  Rel_{{rel_kind}}.rel_type = {{cls}}relationkode('{{rel_kind}}')
  AND
  (Rel_{{rel_kind}}.virkning).timeperiod @> now()
  AND
  {%- for rel_value in rel_values %}
    {%- if rel_value.objekttype %}
    Rel_{{rel_kind}}.objekt_type = '{{rel_value.objekttype}}'
    AND
    {%- endif %}
    {%- if rel_value.uuid %}
    Rel_{{rel_kind}}.rel_maal_uuid = uuid('{{rel_value.uuid}}')
    AND
    {%- endif %}
    {%- if rel_value.urn %}
    Rel_{{rel_kind}}.rel_maal_urn = '{{rel_value.urn}}'
    AND
    {%- endif %}
  {%- endfor %}
{%- endfor %}

{%- for attr_kind, attr_values in reg['attributes'].items() %}
  {%- for prop_value in attr_values %}
    -- {{attr_kind}} -> {{prop_value}}
    (Prop_{{attr_kind}}.virkning).timeperiod @> now()
    AND
    {%- for k, v in prop_value.items() %}
    Prop_{{attr_kind}}.{{k}} ILIKE '{{v}}'
    AND
    {%- endfor %}
  {%- endfor %}
{%- endfor %}

{%- for state_kind, state_values in reg['states'].items() %}
  {%- for state_value in state_values %}
    -- {{state_kind}} -> {{state_value}}
    (State_{{state_kind}}.virkning).timeperiod @> now()
    AND
    {%- for k, v in state_value.items() %}
      State_{{state_kind}}.{{k}} = '{{v}}'
      AND
    {%- endfor %}
  {%- endfor %}
{%- endfor %}

{#- avoid the need for checking for the last clause #}
TRUE
