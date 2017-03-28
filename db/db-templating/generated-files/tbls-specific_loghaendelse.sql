-- Copyright (C) 2015 Magenta ApS, http://magenta.dk.
-- Contact: info@magenta.dk.
--
-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at http://mozilla.org/MPL/2.0/.

/*
NOTICE: This file is auto-generated using the script: apply-template.py loghaendelse tbls-specific.jinja.sql
*/

/******************** FUNCTIONS (NEEDED FOR TABLE/INDEX-DEFS) DEFS ***********************************/

CREATE or replace FUNCTION _as_convert_loghaendelse_relation_kode_to_txt (
  LoghaendelseRelationKode
    ) 
RETURNS TEXT 
LANGUAGE sql STRICT IMMUTABLE 
AS $$
        SELECT $1::text;
   $$;

/******************** TBLS DEFS ***********************************/


CREATE TABLE loghaendelse
(
 id uuid NOT NULL,
  CONSTRAINT loghaendelse_pkey PRIMARY KEY (id)
)
WITH (
  OIDS=FALSE
);
ALTER TABLE loghaendelse
  OWNER TO mox;

/****************************************************************************************************/
CREATE SEQUENCE loghaendelse_registrering_id_seq
  INCREMENT 1
  MINVALUE 1
  MAXVALUE 9223372036854775807
  START 1
  CACHE 1;
ALTER TABLE loghaendelse_registrering_id_seq
  OWNER TO mox;


CREATE TABLE loghaendelse_registrering
(
 id bigint NOT NULL DEFAULT nextval('loghaendelse_registrering_id_seq'::regclass),
 loghaendelse_id uuid NOT NULL ,
 registrering RegistreringBase NOT NULL CHECK( (registrering).TimePeriod IS NOT NULL AND not isempty((registrering).timeperiod) ),
  CONSTRAINT loghaendelse_registrering_pkey PRIMARY KEY (id),
  CONSTRAINT loghaendelse_registrering_loghaendelse_fkey FOREIGN KEY (loghaendelse_id)
      REFERENCES loghaendelse (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT loghaendelse_registrering__uuid_to_text_timeperiod_excl EXCLUDE 
  USING gist (_uuid_to_text(loghaendelse_id) WITH =, _composite_type_to_time_range(registrering) WITH &&)
)
WITH (
  OIDS=FALSE
);
ALTER TABLE loghaendelse_registrering
  OWNER TO mox;

CREATE INDEX loghaendelse_registrering_idx_livscykluskode
  ON loghaendelse_registrering
  USING btree
  (((registrering).livscykluskode));

CREATE INDEX loghaendelse_registrering_idx_brugerref
  ON loghaendelse_registrering
  USING btree
  (((registrering).brugerref));

CREATE INDEX loghaendelse_registrering_idx_note
  ON loghaendelse_registrering
  USING btree
  (((registrering).note));

CREATE INDEX loghaendelse_registrering_pat_note
  ON loghaendelse_registrering
  USING  gin
  (((registrering).note) gin_trgm_ops);



/****************************************************************************************************/


CREATE SEQUENCE loghaendelse_attr_egenskaber_id_seq
  INCREMENT 1
  MINVALUE 1
  MAXVALUE 9223372036854775807
  START 1
  CACHE 1;
ALTER TABLE loghaendelse_attr_egenskaber_id_seq
  OWNER TO mox;




CREATE TABLE loghaendelse_attr_egenskaber
(
  id bigint NOT NULL DEFAULT nextval('loghaendelse_attr_egenskaber_id_seq'::regclass), 
   service text null, 
   klasse text null, 
   tidspunkt text null, 
   operation text null, 
   objekttype text null, 
   returkode text null, 
   returtekst text null, 
   note text null, 
   virkning Virkning not null CHECK( (virkning).TimePeriod IS NOT NULL AND not isempty((virkning).TimePeriod) ),
  loghaendelse_registrering_id bigint not null,
CONSTRAINT loghaendelse_attr_egenskaber_pkey PRIMARY KEY (id),
CONSTRAINT loghaendelse_attr_egenskaber_forkey_loghaendelseregistrering  FOREIGN KEY (loghaendelse_registrering_id) REFERENCES loghaendelse_registrering (id) MATCH SIMPLE ON UPDATE NO ACTION ON DELETE NO ACTION,
CONSTRAINT loghaendelse_attr_egenskaber_exclude_virkning_overlap EXCLUDE USING gist (loghaendelse_registrering_id WITH =, _composite_type_to_time_range(virkning) WITH &&)
)
WITH (
  OIDS=FALSE
);
ALTER TABLE loghaendelse_attr_egenskaber
  OWNER TO mox;

 
CREATE INDEX loghaendelse_attr_egenskaber_pat_service
  ON loghaendelse_attr_egenskaber
  USING gin
  (service gin_trgm_ops);

CREATE INDEX loghaendelse_attr_egenskaber_idx_service
  ON loghaendelse_attr_egenskaber
  USING btree
  (service); 

 
CREATE INDEX loghaendelse_attr_egenskaber_pat_klasse
  ON loghaendelse_attr_egenskaber
  USING gin
  (klasse gin_trgm_ops);

CREATE INDEX loghaendelse_attr_egenskaber_idx_klasse
  ON loghaendelse_attr_egenskaber
  USING btree
  (klasse); 

 
CREATE INDEX loghaendelse_attr_egenskaber_pat_tidspunkt
  ON loghaendelse_attr_egenskaber
  USING gin
  (tidspunkt gin_trgm_ops);

CREATE INDEX loghaendelse_attr_egenskaber_idx_tidspunkt
  ON loghaendelse_attr_egenskaber
  USING btree
  (tidspunkt); 

 
CREATE INDEX loghaendelse_attr_egenskaber_pat_operation
  ON loghaendelse_attr_egenskaber
  USING gin
  (operation gin_trgm_ops);

CREATE INDEX loghaendelse_attr_egenskaber_idx_operation
  ON loghaendelse_attr_egenskaber
  USING btree
  (operation); 

 
CREATE INDEX loghaendelse_attr_egenskaber_pat_objekttype
  ON loghaendelse_attr_egenskaber
  USING gin
  (objekttype gin_trgm_ops);

CREATE INDEX loghaendelse_attr_egenskaber_idx_objekttype
  ON loghaendelse_attr_egenskaber
  USING btree
  (objekttype); 

 
CREATE INDEX loghaendelse_attr_egenskaber_pat_returkode
  ON loghaendelse_attr_egenskaber
  USING gin
  (returkode gin_trgm_ops);

CREATE INDEX loghaendelse_attr_egenskaber_idx_returkode
  ON loghaendelse_attr_egenskaber
  USING btree
  (returkode); 

 
CREATE INDEX loghaendelse_attr_egenskaber_pat_returtekst
  ON loghaendelse_attr_egenskaber
  USING gin
  (returtekst gin_trgm_ops);

CREATE INDEX loghaendelse_attr_egenskaber_idx_returtekst
  ON loghaendelse_attr_egenskaber
  USING btree
  (returtekst); 

 
CREATE INDEX loghaendelse_attr_egenskaber_pat_note
  ON loghaendelse_attr_egenskaber
  USING gin
  (note gin_trgm_ops);

CREATE INDEX loghaendelse_attr_egenskaber_idx_note
  ON loghaendelse_attr_egenskaber
  USING btree
  (note); 




CREATE INDEX loghaendelse_attr_egenskaber_idx_virkning_aktoerref
  ON loghaendelse_attr_egenskaber
  USING btree
  (((virkning).aktoerref));

CREATE INDEX loghaendelse_attr_egenskaber_idx_virkning_aktoertypekode
  ON loghaendelse_attr_egenskaber
  USING btree
  (((virkning).aktoertypekode));

CREATE INDEX loghaendelse_attr_egenskaber_idx_virkning_notetekst
  ON loghaendelse_attr_egenskaber
  USING btree
  (((virkning).notetekst));

CREATE INDEX loghaendelse_attr_egenskaber_pat_virkning_notetekst
  ON loghaendelse_attr_egenskaber
  USING gin
  (((virkning).notetekst) gin_trgm_ops);



/****************************************************************************************************/



CREATE SEQUENCE loghaendelse_tils_gyldighed_id_seq
  INCREMENT 1
  MINVALUE 1
  MAXVALUE 9223372036854775807
  START 1
  CACHE 1;
ALTER TABLE loghaendelse_tils_gyldighed_id_seq
  OWNER TO mox;


CREATE TABLE loghaendelse_tils_gyldighed
(
  id bigint NOT NULL DEFAULT nextval('loghaendelse_tils_gyldighed_id_seq'::regclass),
  virkning Virkning  NOT NULL CHECK( (virkning).TimePeriod IS NOT NULL AND not isempty((virkning).TimePeriod) ),
  gyldighed LoghaendelseGyldighedTils NOT NULL, 
  loghaendelse_registrering_id bigint not null,
  CONSTRAINT loghaendelse_tils_gyldighed_pkey PRIMARY KEY (id),
  CONSTRAINT loghaendelse_tils_gyldighed_forkey_loghaendelseregistrering  FOREIGN KEY (loghaendelse_registrering_id) REFERENCES loghaendelse_registrering (id) MATCH SIMPLE ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT loghaendelse_tils_gyldighed_exclude_virkning_overlap EXCLUDE USING gist (loghaendelse_registrering_id WITH =, _composite_type_to_time_range(virkning) WITH &&)
)
 
WITH (
  OIDS=FALSE
);
ALTER TABLE loghaendelse_tils_gyldighed
  OWNER TO mox;

CREATE INDEX loghaendelse_tils_gyldighed_idx_gyldighed
  ON loghaendelse_tils_gyldighed
  USING btree
  (gyldighed);
  

CREATE INDEX loghaendelse_tils_gyldighed_idx_virkning_aktoerref
  ON loghaendelse_tils_gyldighed
  USING btree
  (((virkning).aktoerref));

CREATE INDEX loghaendelse_tils_gyldighed_idx_virkning_aktoertypekode
  ON loghaendelse_tils_gyldighed
  USING btree
  (((virkning).aktoertypekode));

CREATE INDEX loghaendelse_tils_gyldighed_idx_virkning_notetekst
  ON loghaendelse_tils_gyldighed
  USING btree
  (((virkning).notetekst));

CREATE INDEX loghaendelse_tils_gyldighed_pat_virkning_notetekst
  ON loghaendelse_tils_gyldighed
  USING gin
  (((virkning).notetekst) gin_trgm_ops);

  

/****************************************************************************************************/

CREATE SEQUENCE loghaendelse_relation_id_seq
  INCREMENT 1
  MINVALUE 1
  MAXVALUE 9223372036854775807
  START 1
  CACHE 1;
ALTER TABLE loghaendelse_relation_id_seq
  OWNER TO mox;


CREATE TABLE loghaendelse_relation
(
  id bigint NOT NULL DEFAULT nextval('loghaendelse_relation_id_seq'::regclass),
  loghaendelse_registrering_id bigint not null,
  virkning Virkning not null CHECK( (virkning).TimePeriod IS NOT NULL AND not isempty((virkning).TimePeriod) ),
  rel_maal_uuid uuid NULL, --we have to allow null values (for now at least), as it is needed to be able to clear/overrule previous registered relations.
  rel_maal_urn text null,
  rel_type LoghaendelseRelationKode not null,
  objekt_type text null,
 CONSTRAINT loghaendelse_relation_forkey_loghaendelseregistrering  FOREIGN KEY (loghaendelse_registrering_id) REFERENCES loghaendelse_registrering (id) MATCH SIMPLE ON UPDATE NO ACTION ON DELETE NO ACTION,
 CONSTRAINT loghaendelse_relation_pkey PRIMARY KEY (id),
 CONSTRAINT loghaendelse_relation_no_virkning_overlap EXCLUDE USING gist (loghaendelse_registrering_id WITH =, _as_convert_loghaendelse_relation_kode_to_txt(rel_type) WITH =, _composite_type_to_time_range(virkning) WITH &&) ,-- no overlapping virkning except for 0..n --relations
 CONSTRAINT loghaendelse_relation_either_uri_or_urn CHECK (NOT (rel_maal_uuid IS NOT NULL AND (rel_maal_urn IS NOT NULL AND rel_maal_urn<>'')))
);


CREATE INDEX loghaendelse_relation_idx_rel_maal_obj_uuid
  ON loghaendelse_relation
  USING btree
  (rel_type,objekt_type,rel_maal_uuid);

CREATE INDEX loghaendelse_relation_idx_rel_maal_obj_urn
  ON loghaendelse_relation
  USING btree
  (rel_type,objekt_type,rel_maal_urn);

CREATE INDEX loghaendelse_relation_idx_rel_maal_uuid
  ON loghaendelse_relation
  USING btree
  (rel_type, rel_maal_uuid);

CREATE INDEX loghaendelse_relation_idx_rel_maal_uuid_isolated
  ON loghaendelse_relation
  USING btree
  (rel_maal_uuid);

CREATE INDEX loghaendelse_relation_idx_rel_maal_urn_isolated
  ON loghaendelse_relation
  USING btree
  (rel_maal_urn);

CREATE INDEX loghaendelse_relation_idx_rel_maal_urn
  ON loghaendelse_relation
  USING btree
  (rel_type, rel_maal_urn);

CREATE INDEX loghaendelse_relation_idx_virkning_aktoerref
  ON loghaendelse_relation
  USING btree
  (((virkning).aktoerref));

CREATE INDEX loghaendelse_relation_idx_virkning_aktoertypekode
  ON loghaendelse_relation
  USING btree
  (((virkning).aktoertypekode));

CREATE INDEX loghaendelse_relation_idx_virkning_notetekst
  ON loghaendelse_relation
  USING btree
  (((virkning).notetekst));

CREATE INDEX loghaendelse_relation_pat_virkning_notetekst
  ON loghaendelse_relation
  USING gin
  (((virkning).notetekst) gin_trgm_ops);




