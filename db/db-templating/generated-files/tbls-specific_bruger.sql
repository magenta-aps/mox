-- Copyright (C) 2015 Magenta ApS, http://magenta.dk.
-- Contact: info@magenta.dk.
--
-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at http://mozilla.org/MPL/2.0/.

/*
NOTICE: This file is auto-generated using the script: apply-template.py bruger tbls-specific.jinja.sql
*/

/******************** FUNCTIONS (NEEDED FOR TABLE/INDEX-DEFS) DEFS ***********************************/

CREATE or replace FUNCTION _as_convert_bruger_relation_kode_to_txt (
  BrugerRelationKode
    ) 
RETURNS TEXT 
LANGUAGE sql STRICT IMMUTABLE 
AS $$
        SELECT $1::text;
   $$;

/******************** TBLS DEFS ***********************************/


CREATE TABLE bruger
(
 id uuid NOT NULL,
  CONSTRAINT bruger_pkey PRIMARY KEY (id)
)
WITH (
  OIDS=FALSE
);
ALTER TABLE bruger
  OWNER TO mox;

/****************************************************************************************************/
CREATE SEQUENCE bruger_registrering_id_seq
  INCREMENT 1
  MINVALUE 1
  MAXVALUE 9223372036854775807
  START 1
  CACHE 1;
ALTER TABLE bruger_registrering_id_seq
  OWNER TO mox;


CREATE TABLE bruger_registrering
(
 id bigint NOT NULL DEFAULT nextval('bruger_registrering_id_seq'::regclass),
 bruger_id uuid NOT NULL ,
 registrering RegistreringBase NOT NULL CHECK( (registrering).TimePeriod IS NOT NULL AND not isempty((registrering).timeperiod) ),
  CONSTRAINT bruger_registrering_pkey PRIMARY KEY (id),
  CONSTRAINT bruger_registrering_bruger_fkey FOREIGN KEY (bruger_id)
      REFERENCES bruger (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT bruger_registrering__uuid_to_text_timeperiod_excl EXCLUDE 
  USING gist (_uuid_to_text(bruger_id) WITH =, _composite_type_to_time_range(registrering) WITH &&)
)
WITH (
  OIDS=FALSE
);
ALTER TABLE bruger_registrering
  OWNER TO mox;

CREATE INDEX bruger_registrering_idx_livscykluskode
  ON bruger_registrering
  USING btree
  (((registrering).livscykluskode));

CREATE INDEX bruger_registrering_idx_brugerref
  ON bruger_registrering
  USING btree
  (((registrering).brugerref));

CREATE INDEX bruger_registrering_idx_note
  ON bruger_registrering
  USING btree
  (((registrering).note));

CREATE INDEX bruger_registrering_pat_note
  ON bruger_registrering
  USING  gin
  (((registrering).note) gin_trgm_ops);

CREATE INDEX bruger_id_idx
   ON bruger_registrering (bruger_id);


/****************************************************************************************************/


CREATE SEQUENCE bruger_attr_egenskaber_id_seq
  INCREMENT 1
  MINVALUE 1
  MAXVALUE 9223372036854775807
  START 1
  CACHE 1;
ALTER TABLE bruger_attr_egenskaber_id_seq
  OWNER TO mox;




CREATE TABLE bruger_attr_egenskaber
(
  id bigint NOT NULL DEFAULT nextval('bruger_attr_egenskaber_id_seq'::regclass), 
   brugervendtnoegle text null, 
   brugernavn text null, 
   brugertype text null, 
   virkning Virkning not null CHECK( (virkning).TimePeriod IS NOT NULL AND not isempty((virkning).TimePeriod) ),
  bruger_registrering_id bigint not null,
CONSTRAINT bruger_attr_egenskaber_pkey PRIMARY KEY (id),
CONSTRAINT bruger_attr_egenskaber_forkey_brugerregistrering  FOREIGN KEY (bruger_registrering_id) REFERENCES bruger_registrering (id) MATCH SIMPLE ON UPDATE NO ACTION ON DELETE NO ACTION,
CONSTRAINT bruger_attr_egenskaber_exclude_virkning_overlap EXCLUDE USING gist (bruger_registrering_id WITH =, _composite_type_to_time_range(virkning) WITH &&)
)
WITH (
  OIDS=FALSE
);
ALTER TABLE bruger_attr_egenskaber
  OWNER TO mox;

 
CREATE INDEX bruger_attr_egenskaber_pat_brugervendtnoegle
  ON bruger_attr_egenskaber
  USING gin
  (brugervendtnoegle gin_trgm_ops);

CREATE INDEX bruger_attr_egenskaber_idx_brugervendtnoegle
  ON bruger_attr_egenskaber
  USING btree
  (brugervendtnoegle); 

 
CREATE INDEX bruger_attr_egenskaber_pat_brugernavn
  ON bruger_attr_egenskaber
  USING gin
  (brugernavn gin_trgm_ops);

CREATE INDEX bruger_attr_egenskaber_idx_brugernavn
  ON bruger_attr_egenskaber
  USING btree
  (brugernavn); 

 
CREATE INDEX bruger_attr_egenskaber_pat_brugertype
  ON bruger_attr_egenskaber
  USING gin
  (brugertype gin_trgm_ops);

CREATE INDEX bruger_attr_egenskaber_idx_brugertype
  ON bruger_attr_egenskaber
  USING btree
  (brugertype); 




CREATE INDEX bruger_attr_egenskaber_idx_virkning_aktoerref
  ON bruger_attr_egenskaber
  USING btree
  (((virkning).aktoerref));

CREATE INDEX bruger_attr_egenskaber_idx_virkning_aktoertypekode
  ON bruger_attr_egenskaber
  USING btree
  (((virkning).aktoertypekode));

CREATE INDEX bruger_attr_egenskaber_idx_virkning_notetekst
  ON bruger_attr_egenskaber
  USING btree
  (((virkning).notetekst));

CREATE INDEX bruger_attr_egenskaber_pat_virkning_notetekst
  ON bruger_attr_egenskaber
  USING gin
  (((virkning).notetekst) gin_trgm_ops);



/****************************************************************************************************/



CREATE SEQUENCE bruger_tils_gyldighed_id_seq
  INCREMENT 1
  MINVALUE 1
  MAXVALUE 9223372036854775807
  START 1
  CACHE 1;
ALTER TABLE bruger_tils_gyldighed_id_seq
  OWNER TO mox;


CREATE TABLE bruger_tils_gyldighed
(
  id bigint NOT NULL DEFAULT nextval('bruger_tils_gyldighed_id_seq'::regclass),
  virkning Virkning  NOT NULL CHECK( (virkning).TimePeriod IS NOT NULL AND not isempty((virkning).TimePeriod) ),
  gyldighed BrugerGyldighedTils NOT NULL, 
  bruger_registrering_id bigint not null,
  CONSTRAINT bruger_tils_gyldighed_pkey PRIMARY KEY (id),
  CONSTRAINT bruger_tils_gyldighed_forkey_brugerregistrering  FOREIGN KEY (bruger_registrering_id) REFERENCES bruger_registrering (id) MATCH SIMPLE ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT bruger_tils_gyldighed_exclude_virkning_overlap EXCLUDE USING gist (bruger_registrering_id WITH =, _composite_type_to_time_range(virkning) WITH &&)
)
 
WITH (
  OIDS=FALSE
);
ALTER TABLE bruger_tils_gyldighed
  OWNER TO mox;

CREATE INDEX bruger_tils_gyldighed_idx_gyldighed
  ON bruger_tils_gyldighed
  USING btree
  (gyldighed);
  

CREATE INDEX bruger_tils_gyldighed_idx_virkning_aktoerref
  ON bruger_tils_gyldighed
  USING btree
  (((virkning).aktoerref));

CREATE INDEX bruger_tils_gyldighed_idx_virkning_aktoertypekode
  ON bruger_tils_gyldighed
  USING btree
  (((virkning).aktoertypekode));

CREATE INDEX bruger_tils_gyldighed_idx_virkning_notetekst
  ON bruger_tils_gyldighed
  USING btree
  (((virkning).notetekst));

CREATE INDEX bruger_tils_gyldighed_pat_virkning_notetekst
  ON bruger_tils_gyldighed
  USING gin
  (((virkning).notetekst) gin_trgm_ops);

  

/****************************************************************************************************/

CREATE SEQUENCE bruger_relation_id_seq
  INCREMENT 1
  MINVALUE 1
  MAXVALUE 9223372036854775807
  START 1
  CACHE 1;
ALTER TABLE bruger_relation_id_seq
  OWNER TO mox;


CREATE TABLE bruger_relation
(
  id bigint NOT NULL DEFAULT nextval('bruger_relation_id_seq'::regclass),
  bruger_registrering_id bigint not null,
  virkning Virkning not null CHECK( (virkning).TimePeriod IS NOT NULL AND not isempty((virkning).TimePeriod) ),
  rel_maal_uuid uuid NULL, --we have to allow null values (for now at least), as it is needed to be able to clear/overrule previous registered relations.
  rel_maal_urn text null,
  rel_type BrugerRelationKode not null,
  objekt_type text null,
 CONSTRAINT bruger_relation_forkey_brugerregistrering  FOREIGN KEY (bruger_registrering_id) REFERENCES bruger_registrering (id) MATCH SIMPLE ON UPDATE NO ACTION ON DELETE NO ACTION,
 CONSTRAINT bruger_relation_pkey PRIMARY KEY (id),
 CONSTRAINT bruger_relation_no_virkning_overlap EXCLUDE USING gist (bruger_registrering_id WITH =, _as_convert_bruger_relation_kode_to_txt(rel_type) WITH =, _composite_type_to_time_range(virkning) WITH &&)  WHERE ( rel_type<>('adresser'::BrugerRelationKode ) AND rel_type<>('brugertyper'::BrugerRelationKode ) AND rel_type<>('opgaver'::BrugerRelationKode ) AND rel_type<>('tilknyttedeenheder'::BrugerRelationKode ) AND rel_type<>('tilknyttedefunktioner'::BrugerRelationKode ) AND rel_type<>('tilknyttedeinteressefaellesskaber'::BrugerRelationKode ) AND rel_type<>('tilknyttedeorganisationer'::BrugerRelationKode ) AND rel_type<>('tilknyttedepersoner'::BrugerRelationKode ) AND rel_type<>('tilknyttedeitsystemer'::BrugerRelationKode )) ,-- no overlapping virkning except for 0..n --relations
 CONSTRAINT bruger_relation_either_uri_or_urn CHECK (NOT (rel_maal_uuid IS NOT NULL AND (rel_maal_urn IS NOT NULL AND rel_maal_urn<>'')))
);


CREATE INDEX bruger_relation_idx_rel_maal_obj_uuid
  ON bruger_relation
  USING btree
  (rel_type,objekt_type,rel_maal_uuid);

CREATE INDEX bruger_relation_idx_rel_maal_obj_urn
  ON bruger_relation
  USING btree
  (rel_type,objekt_type,rel_maal_urn);

CREATE INDEX bruger_relation_idx_rel_maal_uuid
  ON bruger_relation
  USING btree
  (rel_type, rel_maal_uuid);

CREATE INDEX bruger_relation_idx_rel_maal_uuid_isolated
  ON bruger_relation
  USING btree
  (rel_maal_uuid);

CREATE INDEX bruger_relation_idx_rel_maal_urn_isolated
  ON bruger_relation
  USING btree
  (rel_maal_urn);

CREATE INDEX bruger_relation_idx_rel_maal_urn
  ON bruger_relation
  USING btree
  (rel_type, rel_maal_urn);

CREATE INDEX bruger_relation_idx_virkning_aktoerref
  ON bruger_relation
  USING btree
  (((virkning).aktoerref));

CREATE INDEX bruger_relation_idx_virkning_aktoertypekode
  ON bruger_relation
  USING btree
  (((virkning).aktoertypekode));

CREATE INDEX bruger_relation_idx_virkning_notetekst
  ON bruger_relation
  USING btree
  (((virkning).notetekst));

CREATE INDEX bruger_relation_pat_virkning_notetekst
  ON bruger_relation
  USING gin
  (((virkning).notetekst) gin_trgm_ops);




