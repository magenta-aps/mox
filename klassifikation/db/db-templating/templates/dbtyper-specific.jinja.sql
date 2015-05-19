{% extends "basis.jinja.sql" %}
{% block body %}
{% for key, value in tilstande.iteritems() %}CREATE TYPE {{oio_type}}Tils{{key}} AS ENUM ({% for enum_val in value %}'{{enum_val}}',{% endfor %}''); --'' means undefined (which is needed to clear previous defined value in an already registered virksnings-periode)
{% endfor %}
{% endblock %}
