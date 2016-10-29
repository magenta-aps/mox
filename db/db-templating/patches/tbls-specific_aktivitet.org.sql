-- Copyright (C) 2015 Magenta ApS, http://magenta.dk.
-- Contact: info@magenta.dk.
--
-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at http://mozilla.org/MPL/2.0/.

/*
NOTICE: This file is auto-generated using the script: apply-template.py aktivitet tbls-specific.jinja.sql
*/

/******************** FUNCTIONS (NEEDED FOR TABLE/INDEX-DEFS) DEFS ***********************************/

CREATE or replace FUNCTION _as_convert_aktivitet_relation_kode_to_txt (
  AktivitetRelationKode
    ) 
RETURNS TEXT 
LANGUAGE sql STRICT IMMUTABLE 
AS $$
        SELECT $1::text;
   $$;

/******************** TBLS DEFS ***********************************/


CREATE TABLE aktivitet
(
 id uuid NOT NULL,
  CONSTRAINT aktivitet_pkey PRIMARY KEY (id)
)
WITH (
  OIDS=FALSE
);
ALTER TABLE aktivitet
  OWNER TO mox;

/****************************************************************************************************/
CREATE SEQUENCE aktivitet_registrering_id_seq
  INCREMENT 1
  MINVALUE 1
  MAXVALUE 9223372036854775807
  START 1
  CACHE 1;
ALTER TABLE aktivitet_registrering_id_seq
  OWNER TO mox;


CREATE TABLE aktivitet_registrering
(
 id bigint NOT NULL DEFAULT nextval('aktivitet_registrering_id_seq'::regclass),
 aktivitet_id uuid NOT NULL ,
 registrering RegistreringBase NOT NULL CHECK( (registrering).TimePeriod IS NOT NULL AND not isempty((registrering).timeperiod) ),
  CONSTRAINT aktivitet_registrering_pkey PRIMARY KEY (id),
  CONSTRAINT aktivitet_registrering_aktivitet_fkey FOREIGN KEY (aktivitet_id)
      REFERENCES aktivitet (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT aktivitet_registrering__uuid_to_text_timeperiod_excl EXCLUDE 
  USING gist (_uuid_to_text(aktivitet_id) WITH =, _composite_type_to_time_range(registrering) WITH &&)
)
WITH (
  OIDS=FALSE
);
ALTER TABLE aktivitet_registrering
  OWNER TO mox;

CREATE INDEX aktivitet_registrering_idx_livscykluskode
  ON aktivitet_registrering
  USING btree
  (((registrering).livscykluskode));

CREATE INDEX aktivitet_registrering_idx_brugerref
  ON aktivitet_registrering
  USING btree
  (((registrering).brugerref));

CREATE INDEX aktivitet_registrering_idx_note
  ON aktivitet_registrering
  USING btree
  (((registrering).note));

CREATE INDEX aktivitet_registrering_pat_note
  ON aktivitet_registrering
  USING  gin
  (((registrering).note) gin_trgm_ops);



/****************************************************************************************************/


CREATE SEQUENCE aktivitet_attr_egenskaber_id_seq
  INCREMENT 1
  MINVALUE 1
  MAXVALUE 9223372036854775807
  START 1
  CACHE 1;
ALTER TABLE aktivitet_attr_egenskaber_id_seq
  OWNER TO mox;




CREATE TABLE aktivitet_attr_egenskaber
(
  id bigint NOT NULL DEFAULT nextval('aktivitet_attr_egenskaber_id_seq'::regclass), 
   brugervendtnoegle text null, 
   aktivitetnavn text null, 
   beskrivelse text null, 
   starttidspunkt timestamptz null, 
   sluttidspunkt timestamptz null, 
   tidsforbrug interval(0) null, 
   formaal text null, 
   virkning Virkning not null CHECK( (virkning).TimePeriod IS NOT NULL AND not isempty((virkning).TimePeriod) ),
  aktivitet_registrering_id bigint not null,
CONSTRAINT aktivitet_attr_egenskaber_pkey PRIMARY KEY (id),
CONSTRAINT aktivitet_attr_egenskaber_forkey_aktivitetregistrering  FOREIGN KEY (aktivitet_registrering_id) REFERENCES aktivitet_registrering (id) MATCH SIMPLE ON UPDATE NO ACTION ON DELETE NO ACTION,
CONSTRAINT aktivitet_attr_egenskaber_exclude_virkning_overlap EXCLUDE USING gist (aktivitet_registrering_id WITH =, _composite_type_to_time_range(virkning) WITH &&)
)
WITH (
  OIDS=FALSE
);
ALTER TABLE aktivitet_attr_egenskaber
  OWNER TO mox;

 
CREATE INDEX aktivitet_attr_egenskaber_pat_brugervendtnoegle
  ON aktivitet_attr_egenskaber
  USING gin
  (brugervendtnoegle gin_trgm_ops);

CREATE INDEX aktivitet_attr_egenskaber_idx_brugervendtnoegle
  ON aktivitet_attr_egenskaber
  USING btree
  (brugervendtnoegle); 

 
CREATE INDEX aktivitet_attr_egenskaber_pat_aktivitetnavn
  ON aktivitet_attr_egenskaber
  USING gin
  (aktivitetnavn gin_trgm_ops);

CREATE INDEX aktivitet_attr_egenskaber_idx_aktivitetnavn
  ON aktivitet_attr_egenskaber
  USING btree
  (aktivitetnavn); 

 
CREATE INDEX aktivitet_attr_egenskaber_pat_beskrivelse
  ON aktivitet_attr_egenskaber
  USING gin
  (beskrivelse gin_trgm_ops);

CREATE INDEX aktivitet_attr_egenskaber_idx_beskrivelse
  ON aktivitet_attr_egenskaber
  USING btree
  (beskrivelse); 

 

CREATE INDEX aktivitet_attr_egenskaber_idx_starttidspunkt
  ON aktivitet_attr_egenskaber
  USING btree
  (starttidspunkt); 

 

CREATE INDEX aktivitet_attr_egenskaber_idx_sluttidspunkt
  ON aktivitet_attr_egenskaber
  USING btree
  (sluttidspunkt); 

 

CREATE INDEX aktivitet_attr_egenskaber_idx_tidsforbrug
  ON aktivitet_attr_egenskaber
  USING btree
  (tidsforbrug); 

 
CREATE INDEX aktivitet_attr_egenskaber_pat_formaal
  ON aktivitet_attr_egenskaber
  USING gin
  (formaal gin_trgm_ops);

CREATE INDEX aktivitet_attr_egenskaber_idx_formaal
  ON aktivitet_attr_egenskaber
  USING btree
  (formaal); 




CREATE INDEX aktivitet_attr_egenskaber_idx_virkning_aktoerref
  ON aktivitet_attr_egenskaber
  USING btree
  (((virkning).aktoerref));

CREATE INDEX aktivitet_attr_egenskaber_idx_virkning_aktoertypekode
  ON aktivitet_attr_egenskaber
  USING btree
  (((virkning).aktoertypekode));

CREATE INDEX aktivitet_attr_egenskaber_idx_virkning_notetekst
  ON aktivitet_attr_egenskaber
  USING btree
  (((virkning).notetekst));

CREATE INDEX aktivitet_attr_egenskaber_pat_virkning_notetekst
  ON aktivitet_attr_egenskaber
  USING gin
  (((virkning).notetekst) gin_trgm_ops);



/****************************************************************************************************/



CREATE SEQUENCE aktivitet_tils_status_id_seq
  INCREMENT 1
  MINVALUE 1
  MAXVALUE 9223372036854775807
  START 1
  CACHE 1;
ALTER TABLE aktivitet_tils_status_id_seq
  OWNER TO mox;


CREATE TABLE aktivitet_tils_status
(
  id bigint NOT NULL DEFAULT nextval('aktivitet_tils_status_id_seq'::regclass),
  virkning Virkning  NOT NULL CHECK( (virkning).TimePeriod IS NOT NULL AND not isempty((virkning).TimePeriod) ),
  status AktivitetStatusTils NOT NULL, 
  aktivitet_registrering_id bigint not null,
  CONSTRAINT aktivitet_tils_status_pkey PRIMARY KEY (id),
  CONSTRAINT aktivitet_tils_status_forkey_aktivitetregistrering  FOREIGN KEY (aktivitet_registrering_id) REFERENCES aktivitet_registrering (id) MATCH SIMPLE ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT aktivitet_tils_status_exclude_virkning_overlap EXCLUDE USING gist (aktivitet_registrering_id WITH =, _composite_type_to_time_range(virkning) WITH &&)
)
 
WITH (
  OIDS=FALSE
);
ALTER TABLE aktivitet_tils_status
  OWNER TO mox;

CREATE INDEX aktivitet_tils_status_idx_status
  ON aktivitet_tils_status
  USING btree
  (status);
  

CREATE INDEX aktivitet_tils_status_idx_virkning_aktoerref
  ON aktivitet_tils_status
  USING btree
  (((virkning).aktoerref));

CREATE INDEX aktivitet_tils_status_idx_virkning_aktoertypekode
  ON aktivitet_tils_status
  USING btree
  (((virkning).aktoertypekode));

CREATE INDEX aktivitet_tils_status_idx_virkning_notetekst
  ON aktivitet_tils_status
  USING btree
  (((virkning).notetekst));

CREATE INDEX aktivitet_tils_status_pat_virkning_notetekst
  ON aktivitet_tils_status
  USING gin
  (((virkning).notetekst) gin_trgm_ops);

  

CREATE SEQUENCE aktivitet_tils_publiceret_id_seq
  INCREMENT 1
  MINVALUE 1
  MAXVALUE 9223372036854775807
  START 1
  CACHE 1;
ALTER TABLE aktivitet_tils_publiceret_id_seq
  OWNER TO mox;


CREATE TABLE aktivitet_tils_publiceret
(
  id bigint NOT NULL DEFAULT nextval('aktivitet_tils_publiceret_id_seq'::regclass),
  virkning Virkning  NOT NULL CHECK( (virkning).TimePeriod IS NOT NULL AND not isempty((virkning).TimePeriod) ),
  publiceret AktivitetPubliceretTils NOT NULL, 
  aktivitet_registrering_id bigint not null,
  CONSTRAINT aktivitet_tils_publiceret_pkey PRIMARY KEY (id),
  CONSTRAINT aktivitet_tils_publiceret_forkey_aktivitetregistrering  FOREIGN KEY (aktivitet_registrering_id) REFERENCES aktivitet_registrering (id) MATCH SIMPLE ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT aktivitet_tils_publiceret_exclude_virkning_overlap EXCLUDE USING gist (aktivitet_registrering_id WITH =, _composite_type_to_time_range(virkning) WITH &&)
)
 
WITH (
  OIDS=FALSE
);
ALTER TABLE aktivitet_tils_publiceret
  OWNER TO mox;

CREATE INDEX aktivitet_tils_publiceret_idx_publiceret
  ON aktivitet_tils_publiceret
  USING btree
  (publiceret);
  

CREATE INDEX aktivitet_tils_publiceret_idx_virkning_aktoerref
  ON aktivitet_tils_publiceret
  USING btree
  (((virkning).aktoerref));

CREATE INDEX aktivitet_tils_publiceret_idx_virkning_aktoertypekode
  ON aktivitet_tils_publiceret
  USING btree
  (((virkning).aktoertypekode));

CREATE INDEX aktivitet_tils_publiceret_idx_virkning_notetekst
  ON aktivitet_tils_publiceret
  USING btree
  (((virkning).notetekst));

CREATE INDEX aktivitet_tils_publiceret_pat_virkning_notetekst
  ON aktivitet_tils_publiceret
  USING gin
  (((virkning).notetekst) gin_trgm_ops);

  

/****************************************************************************************************/

CREATE SEQUENCE aktivitet_relation_id_seq
  INCREMENT 1
  MINVALUE 1
  MAXVALUE 9223372036854775807
  START 1
  CACHE 1;
ALTER TABLE aktivitet_relation_id_seq
  OWNER TO mox;


CREATE TABLE aktivitet_relation
(
  id bigint NOT NULL DEFAULT nextval('aktivitet_relation_id_seq'::regclass),
  aktivitet_registrering_id bigint not null,
  virkning Virkning not null CHECK( (virkning).TimePeriod IS NOT NULL AND not isempty((virkning).TimePeriod) ),
  rel_maal_uuid uuid NULL, --we have to allow null values (for now at least), as it is needed to be able to clear/overrule previous registered relations.
  rel_maal_urn text null,
  rel_type AktivitetRelationKode not null,
  objekt_type text null,
  rel_index int null,
  aktoer_attr AktivitetAktoerAttr null,
 CONSTRAINT aktivitet_relation_forkey_aktivitetregistrering  FOREIGN KEY (aktivitet_registrering_id) REFERENCES aktivitet_registrering (id) MATCH SIMPLE ON UPDATE NO ACTION ON DELETE NO ACTION,
 CONSTRAINT aktivitet_relation_pkey PRIMARY KEY (id),
 CONSTRAINT aktivitet_relation_no_virkning_overlap EXCLUDE USING gist (aktivitet_registrering_id WITH =, _as_convert_aktivitet_relation_kode_to_txt(rel_type) WITH =, _composite_type_to_time_range(virkning) WITH &&)  WHERE ( rel_type<>('udfoererklasse'::AktivitetRelationKode ) AND rel_type<>('deltagerklasse'::AktivitetRelationKode ) AND rel_type<>('objektklasse'::AktivitetRelationKode ) AND rel_type<>('resultatklasse'::AktivitetRelationKode ) AND rel_type<>('grundlagklasse'::AktivitetRelationKode ) AND rel_type<>('facilitetklasse'::AktivitetRelationKode ) AND rel_type<>('adresse'::AktivitetRelationKode ) AND rel_type<>('geoobjekt'::AktivitetRelationKode ) AND rel_type<>('position'::AktivitetRelationKode ) AND rel_type<>('facilitet'::AktivitetRelationKode ) AND rel_type<>('lokale'::AktivitetRelationKode ) AND rel_type<>('aktivitetdokument'::AktivitetRelationKode ) AND rel_type<>('aktivitetgrundlag'::AktivitetRelationKode ) AND rel_type<>('aktivitetresultat'::AktivitetRelationKode ) AND rel_type<>('udfoerer'::AktivitetRelationKode ) AND rel_type<>('deltager'::AktivitetRelationKode )) ,-- no overlapping virkning except for 0..n --relations
 CONSTRAINT aktivitet_relation_either_uri_or_urn CHECK (NOT (rel_maal_uuid IS NOT NULL AND (rel_maal_urn IS NOT NULL AND rel_maal_urn<>''))),
 CONSTRAINT aktivitet_relation_check_aktoer_attr_rel_type CHECK (aktoer_attr IS NULL OR rel_type=('udfoerer'::AktivitetRelationKode)  OR rel_type=('deltager'::AktivitetRelationKode) OR rel_type=('ansvarlig'::AktivitetRelationKode)),
 CONSTRAINT aktivitet_relation_aktoer_repr_either_uri_or_urn CHECK (aktoer_attr IS NULL OR ( _aktivitet_aktoer_attr_repr_uuid_to_text(aktoer_attr) IS NULL AND _aktivitet_aktoer_attr_repr_urn_to_text(aktoer_attr) IS NULL  ) OR ((_aktivitet_aktoer_attr_repr_urn_to_text(aktoer_attr) IS NOT NULL AND _aktivitet_aktoer_attr_repr_uuid_to_text(aktoer_attr) IS NULL ) OR  (_aktivitet_aktoer_attr_repr_urn_to_text(aktoer_attr) IS NULL AND _aktivitet_aktoer_attr_repr_uuid_to_text(aktoer_attr) IS NOT NULL )))
);

CREATE UNIQUE INDEX aktivitet_relation_unique_index_within_type  ON aktivitet_relation (aktivitet_registrering_id,rel_type,rel_index) WHERE ( rel_type IN ('udfoererklasse'::AktivitetRelationKode,'deltagerklasse'::AktivitetRelationKode,'objektklasse'::AktivitetRelationKode,'resultatklasse'::AktivitetRelationKode,'grundlagklasse'::AktivitetRelationKode,'facilitetklasse'::AktivitetRelationKode,'adresse'::AktivitetRelationKode,'geoobjekt'::AktivitetRelationKode,'position'::AktivitetRelationKode,'facilitet'::AktivitetRelationKode,'lokale'::AktivitetRelationKode,'aktivitetdokument'::AktivitetRelationKode,'aktivitetgrundlag'::AktivitetRelationKode,'aktivitetresultat'::AktivitetRelationKode,'udfoerer'::AktivitetRelationKode,'deltager'::AktivitetRelationKode));

CREATE INDEX aktivitet_relation_idx_rel_maal_obj_uuid
  ON aktivitet_relation
  USING btree
  (rel_type,objekt_type,rel_maal_uuid);

  CREATE INDEX aktivitet_relation_idx_repr_uuid
  ON aktivitet_relation
  USING btree
  (((aktoer_attr).repraesentation_uuid));

CREATE INDEX aktivitet_relation_idx_repr_urn
  ON aktivitet_relation
  USING btree
  (((aktoer_attr).repraesentation_urn));

CREATE INDEX aktivitet_relation_idx_rel_maal_obj_urn
  ON aktivitet_relation
  USING btree
  (rel_type,objekt_type,rel_maal_urn);

CREATE INDEX aktivitet_relation_idx_rel_maal_uuid
  ON aktivitet_relation
  USING btree
  (rel_type, rel_maal_uuid);

CREATE INDEX aktivitet_relation_idx_rel_maal_uuid_isolated
  ON aktivitet_relation
  USING btree
  (rel_maal_uuid);

CREATE INDEX aktivitet_relation_idx_rel_maal_urn_isolated
  ON aktivitet_relation
  USING btree
  (rel_maal_urn);

CREATE INDEX aktivitet_relation_idx_rel_maal_urn
  ON aktivitet_relation
  USING btree
  (rel_type, rel_maal_urn);

CREATE INDEX aktivitet_relation_idx_virkning_aktoerref
  ON aktivitet_relation
  USING btree
  (((virkning).aktoerref));

CREATE INDEX aktivitet_relation_idx_virkning_aktoertypekode
  ON aktivitet_relation
  USING btree
  (((virkning).aktoertypekode));

CREATE INDEX aktivitet_relation_idx_virkning_notetekst
  ON aktivitet_relation
  USING btree
  (((virkning).notetekst));

CREATE INDEX aktivitet_relation_pat_virkning_notetekst
  ON aktivitet_relation
  USING gin
  (((virkning).notetekst) gin_trgm_ops);




