{% extends "basis.jinja.sql" %}
{% block body %}
--create custom type sans db-ids to be able to do "clean" function signatures "for the outside world".

{% for key, value in tilstande.iteritems() %}CREATE TYPE {{oio_type|title}}Tils{{key|title}} AS ENUM ({% for enum_val in value %}'{{enum_val}}',{% endfor %}''); --'' means undefined (which is needed to clear previous defined value in an already registered virksnings-periode)

CREATE TYPE {{oio_type|title}}Tils{{key|title}}Type AS (
    virkning Virkning,
    {{key}} {{oio_type|title}}Tils{{key|title}}
)
;
{% endfor %}

CREATE TYPE {{oio_type|title}}AttrEgenskaberType AS (
{% for egenskab in egenskaber %}{{egenskab}} text,
 {% endfor %}virkning Virkning
);

CREATE TYPE {{oio_type|title}}RelationKode AS ENUM  ({% for relation in relationer_nul_til_en|list + relationer_nul_til_mange|list %}'{{relation}}'{% if not loop.last %},{% endif %}{% endfor %});  --WARNING: Changes to enum names requires MANUALLY rebuilding indexes where _actual_state_convert_{{oio_type}}_relation_kode_to_txt is invoked.

CREATE TYPE {{oio_type|title}}RelationType AS (
  relType {{oio_type|title}}RelationKode,
  virkning Virkning,
  relMaal uuid 
)
;

CREATE TYPE {{oio_type|title}}RegistreringType AS
(
registrering RegistreringBase,{% for key, value in tilstande.iteritems() %}
tils{{key|title}} {{oio_type|title}}Tils{{key|title}}Type[],{% endfor %}
attrEgenskaber {{oio_type|title}}AttrEgenskaberType[],
relationer {{oio_type|title}}RelationType[]
);

CREATE TYPE {{oio_type|title}}Type AS
(
  id uuid,
  registrering {{oio_type|title}}RegistreringType[]
);  

{% endblock %}