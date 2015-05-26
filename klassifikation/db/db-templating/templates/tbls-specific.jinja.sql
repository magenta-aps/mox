{% extends "basis.jinja.sql" %}
-- Copyright (C) 2015 Magenta ApS, http://magenta.dk.
-- Contact: info@magenta.dk.
--
-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at http://mozilla.org/MPL/2.0/.
{% block body %}
/******************** FUNCTIONS (NEEDED FOR TABLE/INDEX-DEFS) DEFS ***********************************/

CREATE or replace FUNCTION _as_convert_{{oio_type}}_relation_kode_to_txt (
  {{oio_type|title}}RelationKode
    ) 
RETURNS TEXT 
LANGUAGE sql STRICT IMMUTABLE 
AS $$
        SELECT $1::text;
   $$;

/******************** TBLS DEFS ***********************************/


CREATE TABLE {{oio_type}}
(
 id uuid NOT NULL,
  CONSTRAINT {{oio_type}}_pkey PRIMARY KEY (id)
)
WITH (
  OIDS=FALSE
);
ALTER TABLE {{oio_type}}
  OWNER TO mox;

/****************************************************************************************************/
CREATE SEQUENCE {{oio_type}}_registrering_id_seq
  INCREMENT 1
  MINVALUE 1
  MAXVALUE 9223372036854775807
  START 1
  CACHE 1;
ALTER TABLE {{oio_type}}_registrering_id_seq
  OWNER TO mox;


CREATE TABLE {{oio_type}}_registrering
(
 id bigint NOT NULL DEFAULT nextval('{{oio_type}}_registrering_id_seq'::regclass),
 {{oio_type}}_id uuid NOT NULL ,
 registrering RegistreringBase NOT NULL CHECK( (registrering).TimePeriod IS NOT NULL AND not isempty((registrering).timeperiod) ),
  CONSTRAINT {{oio_type}}_registrering_pkey PRIMARY KEY (id),
  CONSTRAINT {{oio_type}}_registrering_{{oio_type}}_fkey FOREIGN KEY ({{oio_type}}_id)
      REFERENCES {{oio_type}} (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT {{oio_type}}_registrering__uuid_to_text_timeperiod_excl EXCLUDE 
  USING gist (_uuid_to_text({{oio_type}}_id) WITH =, _composite_type_to_time_range(registrering) WITH &&)
)
WITH (
  OIDS=FALSE
);
ALTER TABLE {{oio_type}}_registrering
  OWNER TO mox;

CREATE INDEX {{oio_type}}_registrering_idx_livscykluskode
  ON {{oio_type}}_registrering
  USING btree
  (((registrering).livscykluskode));

CREATE INDEX {{oio_type}}_registrering_idx_brugerref
  ON {{oio_type}}_registrering
  USING btree
  (((registrering).brugerref));

CREATE INDEX {{oio_type}}_registrering_idx_note
  ON {{oio_type}}_registrering
  USING btree
  (((registrering).note));



/****************************************************************************************************/
{%for attribut , attribut_fields in attributter.iteritems() %}

CREATE SEQUENCE {{oio_type}}_attr_{{attribut}}_id_seq
  INCREMENT 1
  MINVALUE 1
  MAXVALUE 9223372036854775807
  START 1
  CACHE 1;
ALTER TABLE {{oio_type}}_attr_{{attribut}}_id_seq
  OWNER TO mox;




CREATE TABLE {{oio_type}}_attr_{{attribut}}
(
  id bigint NOT NULL DEFAULT nextval('{{oio_type}}_attr_{{attribut}}_id_seq'::regclass),
   {% for field in attribut_fields %} {{field}} text null,
   {% endfor %} virkning Virkning not null CHECK( (virkning).TimePeriod IS NOT NULL AND not isempty((virkning).TimePeriod) ),
  {{oio_type}}_registrering_id bigint not null,
CONSTRAINT {{oio_type}}_attr_{{attribut}}_pkey PRIMARY KEY (id),
CONSTRAINT {{oio_type}}_attr_{{attribut}}_forkey_{{oio_type}}registrering  FOREIGN KEY ({{oio_type}}_registrering_id) REFERENCES {{oio_type}}_registrering (id) MATCH SIMPLE ON UPDATE NO ACTION ON DELETE NO ACTION,
CONSTRAINT {{oio_type}}_attr_{{attribut}}_exclude_virkning_overlap EXCLUDE USING gist ({{oio_type}}_registrering_id WITH =, _composite_type_to_time_range(virkning) WITH &&)
)
WITH (
  OIDS=FALSE
);
ALTER TABLE {{oio_type}}_attr_{{attribut}}
  OWNER TO mox;

{% for field in attribut_fields %} 

CREATE INDEX {{oio_type}}_attr_{{attribut}}_idx_{{field}}
  ON {{oio_type}}_attr_{{attribut}}
  USING btree
  ({{field}});
{% endfor %}

CREATE INDEX {{oio_type}}_attr_{{attribut}}_idx_virkning_aktoerref
  ON {{oio_type}}_attr_{{attribut}}
  USING btree
  (((virkning).aktoerref));

CREATE INDEX {{oio_type}}_attr_{{attribut}}_idx_virkning_aktoertypekode
  ON {{oio_type}}_attr_{{attribut}}
  USING btree
  (((virkning).aktoertypekode));

CREATE INDEX {{oio_type}}_attr_{{attribut}}_idx_virkning_notetekst
  ON {{oio_type}}_attr_{{attribut}}
  USING btree
  (((virkning).notetekst));

{% endfor %}
/****************************************************************************************************/

{% for tilstand, tilstand_values in tilstande.iteritems() %}

CREATE SEQUENCE {{oio_type}}_tils_{{tilstand}}_id_seq
  INCREMENT 1
  MINVALUE 1
  MAXVALUE 9223372036854775807
  START 1
  CACHE 1;
ALTER TABLE {{oio_type}}_tils_{{tilstand}}_id_seq
  OWNER TO mox;


CREATE TABLE {{oio_type}}_tils_{{tilstand}}
(
  id bigint NOT NULL DEFAULT nextval('{{oio_type}}_tils_{{tilstand}}_id_seq'::regclass),
  virkning Virkning  NOT NULL CHECK( (virkning).TimePeriod IS NOT NULL AND not isempty((virkning).TimePeriod) ),
  {{tilstand}} {{oio_type|title}}{{tilstand|title}}Tils NOT NULL, 
  {{oio_type}}_registrering_id bigint not null,
  CONSTRAINT {{oio_type}}_tils_{{tilstand}}_pkey PRIMARY KEY (id),
  CONSTRAINT {{oio_type}}_tils_{{tilstand}}_forkey_{{oio_type}}registrering  FOREIGN KEY ({{oio_type}}_registrering_id) REFERENCES {{oio_type}}_registrering (id) MATCH SIMPLE ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT {{oio_type}}_tils_{{tilstand}}_exclude_virkning_overlap EXCLUDE USING gist ({{oio_type}}_registrering_id WITH =, _composite_type_to_time_range(virkning) WITH &&)
)
 
WITH (
  OIDS=FALSE
);
ALTER TABLE {{oio_type}}_tils_{{tilstand}}
  OWNER TO mox;

CREATE INDEX {{oio_type}}_tils_{{tilstand}}_idx_{{tilstand}}
  ON {{oio_type}}_tils_{{tilstand}}
  USING btree
  ({{tilstand}});
  

CREATE INDEX {{oio_type}}_tils_{{tilstand}}_idx_virkning_aktoerref
  ON {{oio_type}}_tils_{{tilstand}}
  USING btree
  (((virkning).aktoerref));

CREATE INDEX {{oio_type}}_tils_{{tilstand}}_idx_virkning_aktoertypekode
  ON {{oio_type}}_tils_{{tilstand}}
  USING btree
  (((virkning).aktoertypekode));

CREATE INDEX {{oio_type}}_tils_{{tilstand}}_idx_virkning_notetekst
  ON {{oio_type}}_tils_{{tilstand}}
  USING btree
  (((virkning).notetekst));

  {% endfor %}

/****************************************************************************************************/

CREATE SEQUENCE {{oio_type}}_relation_id_seq
  INCREMENT 1
  MINVALUE 1
  MAXVALUE 9223372036854775807
  START 1
  CACHE 1;
ALTER TABLE {{oio_type}}_relation_id_seq
  OWNER TO mox;


CREATE TABLE {{oio_type}}_relation
(
  id bigint NOT NULL DEFAULT nextval('{{oio_type}}_relation_id_seq'::regclass),
  {{oio_type}}_registrering_id bigint not null,
  virkning Virkning not null CHECK( (virkning).TimePeriod IS NOT NULL AND not isempty((virkning).TimePeriod) ),
  rel_maal uuid NULL, --we have to allow null values (for now at least), as it is needed to be able to clear/overrule previous registered relations.
  rel_type {{oio_type|title}}RelationKode not null,
 CONSTRAINT {{oio_type}}_relation_forkey_{{oio_type}}registrering  FOREIGN KEY ({{oio_type}}_registrering_id) REFERENCES {{oio_type}}_registrering (id) MATCH SIMPLE ON UPDATE NO ACTION ON DELETE NO ACTION,
 CONSTRAINT {{oio_type}}_relation_pkey PRIMARY KEY (id),
 CONSTRAINT {{oio_type}}_relation_no_virkning_overlap EXCLUDE USING gist ({{oio_type}}_registrering_id WITH =, _as_convert_{{oio_type}}_relation_kode_to_txt(rel_type) WITH =, _composite_type_to_time_range(virkning) WITH &&) {% if relationer_nul_til_mange %} WHERE ({% for nul_til_mange_rel in relationer_nul_til_mange %} rel_type<>('{{nul_til_mange_rel}}'::{{oio_type|title}}RelationKode ){% if not loop.last %} AND{% endif %}{% endfor %}) {% endif %}-- no overlapping virkning except for 0..n --relations
);

CREATE INDEX {{oio_type}}_relation_idx_rel_maal
  ON {{oio_type}}_relation
  USING btree
  (rel_type, rel_maal);

CREATE INDEX {{oio_type}}_relation_idx_virkning_aktoerref
  ON {{oio_type}}_relation
  USING btree
  (((virkning).aktoerref));

CREATE INDEX {{oio_type}}_relation_idx_virkning_aktoertypekode
  ON {{oio_type}}_relation
  USING btree
  (((virkning).aktoertypekode));

CREATE INDEX {{oio_type}}_relation_idx_virkning_notetekst
  ON {{oio_type}}_relation
  USING btree
  (((virkning).notetekst));

{% endblock %}