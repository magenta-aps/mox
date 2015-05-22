{% extends "basis.jinja.sql" %}
-- Copyright (C) 2015 Magenta ApS, http://magenta.dk.
-- Contact: info@magenta.dk.
--
-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at http://mozilla.org/MPL/2.0/.
{% block body %}
--create custom type sans db-ids to be able to do "clean" function signatures "for the outside world".

{% for tilstand, tilstand_values in tilstande.iteritems() %}CREATE TYPE {{oio_type|title}}Tils{{tilstand|title}} AS ENUM ({% for enum_val in tilstand_values %}'{{enum_val}}',{% endfor %}''); --'' means undefined (which is needed to clear previous defined tilstand_values in an already registered virksnings-periode)

CREATE TYPE {{oio_type|title}}Tils{{tilstand|title}}Type AS (
    virkning Virkning,
    {{tilstand}} {{oio_type|title}}Tils{{tilstand|title}}
)
;
{% endfor %}

{%-for attribut , attribut_fields in attributter.iteritems() %}
CREATE TYPE {{oio_type|title}}Attr{{attribut|title}}Type AS (
{%- for field in attribut_fields %}
{{field}} text,
 {%- endfor %}
 virkning Virkning
);
{% endfor %}

CREATE TYPE {{oio_type|title}}RelationKode AS ENUM  ({% for relation in relationer_nul_til_en|list + relationer_nul_til_mange|list %}'{{relation}}'{% if not loop.last %},{% endif %}{% endfor %});  --WARNING: Changes to enum names requires MANUALLY rebuilding indexes where _as_convert_{{oio_type}}_relation_kode_to_txt is invoked.

CREATE TYPE {{oio_type|title}}RelationType AS (
  relType {{oio_type|title}}RelationKode,
  virkning Virkning,
  relMaal uuid 
)
;

CREATE TYPE {{oio_type|title}}RegistreringType AS
(
registrering RegistreringBase,
{%- for tilstand, tilstand_values in tilstande.iteritems() %}
tils{{tilstand|title}} {{oio_type|title}}Tils{{tilstand|title}}Type[],{% endfor %}
{%-for attribut , attribut_fields in attributter.iteritems() %}
attr{{attribut|title}} {{oio_type|title}}Attr{{attribut|title}}Type[],{% endfor %}
relationer {{oio_type|title}}RelationType[]
);

CREATE TYPE {{oio_type|title}}Type AS
(
  id uuid,
  registrering {{oio_type|title}}RegistreringType[]
);  

{% endblock %}