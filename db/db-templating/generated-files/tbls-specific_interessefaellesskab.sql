-- Copyright (C) 2015 Magenta ApS, http://magenta.dk.
-- Contact: info@magenta.dk.
--
-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at http://mozilla.org/MPL/2.0/.

/*
NOTICE: This file is auto-generated using the script: apply-template.py interessefaellesskab tbls-specific.jinja.sql
*/

/******************** FUNCTIONS (NEEDED FOR TABLE/INDEX-DEFS) DEFS ***********************************/

CREATE or replace FUNCTION _as_convert_interessefaellesskab_relation_kode_to_txt (
  InteressefaellesskabRelationKode
    ) 
RETURNS TEXT 
LANGUAGE sql STRICT IMMUTABLE 
AS $$
        SELECT $1::text;
   $$;

/******************** TBLS DEFS ***********************************/


CREATE TABLE interessefaellesskab
(
 id uuid NOT NULL,
  CONSTRAINT interessefaellesskab_pkey PRIMARY KEY (id)
)
WITH (
  OIDS=FALSE
);
ALTER TABLE interessefaellesskab
  OWNER TO mox;

/****************************************************************************************************/
CREATE SEQUENCE interessefaellesskab_registrering_id_seq
  INCREMENT 1
  MINVALUE 1
  MAXVALUE 9223372036854775807
  START 1
  CACHE 1;
ALTER TABLE interessefaellesskab_registrering_id_seq
  OWNER TO mox;


CREATE TABLE interessefaellesskab_registrering
(
 id bigint NOT NULL DEFAULT nextval('interessefaellesskab_registrering_id_seq'::regclass),
 interessefaellesskab_id uuid NOT NULL ,
 registrering RegistreringBase NOT NULL CHECK( (registrering).TimePeriod IS NOT NULL AND not isempty((registrering).timeperiod) ),
  CONSTRAINT interessefaellesskab_registrering_pkey PRIMARY KEY (id),
  CONSTRAINT interessefaellesskab_registrering_interessefaellesskab_fkey FOREIGN KEY (interessefaellesskab_id)
      REFERENCES interessefaellesskab (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT interessefaellesskab_registrering__uuid_to_text_timeperiod_excl EXCLUDE 
  USING gist (_uuid_to_text(interessefaellesskab_id) WITH =, _composite_type_to_time_range(registrering) WITH &&)
)
WITH (
  OIDS=FALSE
);
ALTER TABLE interessefaellesskab_registrering
  OWNER TO mox;

CREATE INDEX interessefaellesskab_registrering_idx_livscykluskode
  ON interessefaellesskab_registrering
  USING btree
  (((registrering).livscykluskode));

CREATE INDEX interessefaellesskab_registrering_idx_brugerref
  ON interessefaellesskab_registrering
  USING btree
  (((registrering).brugerref));

CREATE INDEX interessefaellesskab_registrering_idx_note
  ON interessefaellesskab_registrering
  USING btree
  (((registrering).note));

CREATE INDEX interessefaellesskab_registrering_pat_note
  ON interessefaellesskab_registrering
  USING  gin
  (((registrering).note) gin_trgm_ops);



/****************************************************************************************************/


CREATE SEQUENCE interessefaellesskab_attr_egenskaber_id_seq
  INCREMENT 1
  MINVALUE 1
  MAXVALUE 9223372036854775807
  START 1
  CACHE 1;
ALTER TABLE interessefaellesskab_attr_egenskaber_id_seq
  OWNER TO mox;




CREATE TABLE interessefaellesskab_attr_egenskaber
(
  id bigint NOT NULL DEFAULT nextval('interessefaellesskab_attr_egenskaber_id_seq'::regclass), 
   brugervendtnoegle text null, 
   interessefaellesskabsnavn text null, 
   interessefaellesskabstype text null, 
   virkning Virkning not null CHECK( (virkning).TimePeriod IS NOT NULL AND not isempty((virkning).TimePeriod) ),
  interessefaellesskab_registrering_id bigint not null,
CONSTRAINT interessefaellesskab_attr_egenskaber_pkey PRIMARY KEY (id),
CONSTRAINT interessefaellesskab_attr_egenskaber_forkey_interessefaellesskabregistrering  FOREIGN KEY (interessefaellesskab_registrering_id) REFERENCES interessefaellesskab_registrering (id) MATCH SIMPLE ON UPDATE NO ACTION ON DELETE NO ACTION,
CONSTRAINT interessefaellesskab_attr_egenskaber_exclude_virkning_overlap EXCLUDE USING gist (interessefaellesskab_registrering_id WITH =, _composite_type_to_time_range(virkning) WITH &&)
)
WITH (
  OIDS=FALSE
);
ALTER TABLE interessefaellesskab_attr_egenskaber
  OWNER TO mox;

 
CREATE INDEX interessefaellesskab_attr_egenskaber_pat_brugervendtnoegle
  ON interessefaellesskab_attr_egenskaber
  USING gin
  (brugervendtnoegle gin_trgm_ops);

CREATE INDEX interessefaellesskab_attr_egenskaber_idx_brugervendtnoegle
  ON interessefaellesskab_attr_egenskaber
  USING btree
  (brugervendtnoegle); 

 
CREATE INDEX interessefaellesskab_attr_egenskaber_pat_interessefaellesskabsnavn
  ON interessefaellesskab_attr_egenskaber
  USING gin
  (interessefaellesskabsnavn gin_trgm_ops);

CREATE INDEX interessefaellesskab_attr_egenskaber_idx_interessefaellesskabsnavn
  ON interessefaellesskab_attr_egenskaber
  USING btree
  (interessefaellesskabsnavn); 

 
CREATE INDEX interessefaellesskab_attr_egenskaber_pat_interessefaellesskabstype
  ON interessefaellesskab_attr_egenskaber
  USING gin
  (interessefaellesskabstype gin_trgm_ops);

CREATE INDEX interessefaellesskab_attr_egenskaber_idx_interessefaellesskabstype
  ON interessefaellesskab_attr_egenskaber
  USING btree
  (interessefaellesskabstype); 




CREATE INDEX interessefaellesskab_attr_egenskaber_idx_virkning_aktoerref
  ON interessefaellesskab_attr_egenskaber
  USING btree
  (((virkning).aktoerref));

CREATE INDEX interessefaellesskab_attr_egenskaber_idx_virkning_aktoertypekode
  ON interessefaellesskab_attr_egenskaber
  USING btree
  (((virkning).aktoertypekode));

CREATE INDEX interessefaellesskab_attr_egenskaber_idx_virkning_notetekst
  ON interessefaellesskab_attr_egenskaber
  USING btree
  (((virkning).notetekst));

CREATE INDEX interessefaellesskab_attr_egenskaber_pat_virkning_notetekst
  ON interessefaellesskab_attr_egenskaber
  USING gin
  (((virkning).notetekst) gin_trgm_ops);



/****************************************************************************************************/



CREATE SEQUENCE interessefaellesskab_tils_gyldighed_id_seq
  INCREMENT 1
  MINVALUE 1
  MAXVALUE 9223372036854775807
  START 1
  CACHE 1;
ALTER TABLE interessefaellesskab_tils_gyldighed_id_seq
  OWNER TO mox;


CREATE TABLE interessefaellesskab_tils_gyldighed
(
  id bigint NOT NULL DEFAULT nextval('interessefaellesskab_tils_gyldighed_id_seq'::regclass),
  virkning Virkning  NOT NULL CHECK( (virkning).TimePeriod IS NOT NULL AND not isempty((virkning).TimePeriod) ),
  gyldighed InteressefaellesskabGyldighedTils NOT NULL, 
  interessefaellesskab_registrering_id bigint not null,
  CONSTRAINT interessefaellesskab_tils_gyldighed_pkey PRIMARY KEY (id),
  CONSTRAINT interessefaellesskab_tils_gyldighed_forkey_interessefaellesskabregistrering  FOREIGN KEY (interessefaellesskab_registrering_id) REFERENCES interessefaellesskab_registrering (id) MATCH SIMPLE ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT interessefaellesskab_tils_gyldighed_exclude_virkning_overlap EXCLUDE USING gist (interessefaellesskab_registrering_id WITH =, _composite_type_to_time_range(virkning) WITH &&)
)
 
WITH (
  OIDS=FALSE
);
ALTER TABLE interessefaellesskab_tils_gyldighed
  OWNER TO mox;

CREATE INDEX interessefaellesskab_tils_gyldighed_idx_gyldighed
  ON interessefaellesskab_tils_gyldighed
  USING btree
  (gyldighed);
  

CREATE INDEX interessefaellesskab_tils_gyldighed_idx_virkning_aktoerref
  ON interessefaellesskab_tils_gyldighed
  USING btree
  (((virkning).aktoerref));

CREATE INDEX interessefaellesskab_tils_gyldighed_idx_virkning_aktoertypekode
  ON interessefaellesskab_tils_gyldighed
  USING btree
  (((virkning).aktoertypekode));

CREATE INDEX interessefaellesskab_tils_gyldighed_idx_virkning_notetekst
  ON interessefaellesskab_tils_gyldighed
  USING btree
  (((virkning).notetekst));

CREATE INDEX interessefaellesskab_tils_gyldighed_pat_virkning_notetekst
  ON interessefaellesskab_tils_gyldighed
  USING gin
  (((virkning).notetekst) gin_trgm_ops);

  

/****************************************************************************************************/

CREATE SEQUENCE interessefaellesskab_relation_id_seq
  INCREMENT 1
  MINVALUE 1
  MAXVALUE 9223372036854775807
  START 1
  CACHE 1;
ALTER TABLE interessefaellesskab_relation_id_seq
  OWNER TO mox;


CREATE TABLE interessefaellesskab_relation
(
  id bigint NOT NULL DEFAULT nextval('interessefaellesskab_relation_id_seq'::regclass),
  interessefaellesskab_registrering_id bigint not null,
  virkning Virkning not null CHECK( (virkning).TimePeriod IS NOT NULL AND not isempty((virkning).TimePeriod) ),
  rel_maal_uuid uuid NULL, --we have to allow null values (for now at least), as it is needed to be able to clear/overrule previous registered relations.
  rel_maal_urn text null,
  rel_type InteressefaellesskabRelationKode not null,
 CONSTRAINT interessefaellesskab_relation_forkey_interessefaellesskabregistrering  FOREIGN KEY (interessefaellesskab_registrering_id) REFERENCES interessefaellesskab_registrering (id) MATCH SIMPLE ON UPDATE NO ACTION ON DELETE NO ACTION,
 CONSTRAINT interessefaellesskab_relation_pkey PRIMARY KEY (id),
 CONSTRAINT interessefaellesskab_relation_no_virkning_overlap EXCLUDE USING gist (interessefaellesskab_registrering_id WITH =, _as_convert_interessefaellesskab_relation_kode_to_txt(rel_type) WITH =, _composite_type_to_time_range(virkning) WITH &&)  WHERE ( rel_type<>('adresser'::InteressefaellesskabRelationKode ) AND rel_type<>('opgaver'::InteressefaellesskabRelationKode ) AND rel_type<>('tilknyttedebrugere'::InteressefaellesskabRelationKode ) AND rel_type<>('tilknyttedeenheder'::InteressefaellesskabRelationKode ) AND rel_type<>('tilknyttedefunktioner'::InteressefaellesskabRelationKode ) AND rel_type<>('tilknyttedeinteressefaellesskaber'::InteressefaellesskabRelationKode ) AND rel_type<>('tilknyttedeorganisationer'::InteressefaellesskabRelationKode ) AND rel_type<>('tilknyttedepersoner'::InteressefaellesskabRelationKode ) AND rel_type<>('tilknyttedeitsystemer'::InteressefaellesskabRelationKode )) ,-- no overlapping virkning except for 0..n --relations
 CONSTRAINT interessefaellesskab_relation_either_uri_or_urn CHECK (NOT (rel_maal_uuid IS NOT NULL AND (rel_maal_urn IS NOT NULL AND rel_maal_urn<>'')))
);

CREATE INDEX interessefaellesskab_relation_idx_rel_maal_uuid
  ON interessefaellesskab_relation
  USING btree
  (rel_type, rel_maal_uuid);

CREATE INDEX interessefaellesskab_relation_idx_rel_maal_uuid_isolated
  ON interessefaellesskab_relation
  USING btree
  (rel_maal_uuid);

CREATE INDEX interessefaellesskab_relation_idx_rel_maal_urn_isolated
  ON interessefaellesskab_relation
  USING btree
  (rel_maal_urn);

CREATE INDEX interessefaellesskab_relation_idx_rel_maal_urn
  ON interessefaellesskab_relation
  USING btree
  (rel_type, rel_maal_urn);

CREATE INDEX interessefaellesskab_relation_idx_virkning_aktoerref
  ON interessefaellesskab_relation
  USING btree
  (((virkning).aktoerref));

CREATE INDEX interessefaellesskab_relation_idx_virkning_aktoertypekode
  ON interessefaellesskab_relation
  USING btree
  (((virkning).aktoertypekode));

CREATE INDEX interessefaellesskab_relation_idx_virkning_notetekst
  ON interessefaellesskab_relation
  USING btree
  (((virkning).notetekst));

CREATE INDEX interessefaellesskab_relation_pat_virkning_notetekst
  ON interessefaellesskab_relation
  USING gin
  (((virkning).notetekst) gin_trgm_ops);




