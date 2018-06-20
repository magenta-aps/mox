-- Copyright (C) 2015 Magenta ApS, http://magenta.dk.
-- Contact: info@magenta.dk.
--
-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at http://mozilla.org/MPL/2.0/.

/*
NOTICE: This file is auto-generated using the script: apply-template.py klasse tbls-specific.jinja.sql AND applying a patch (tbls-specific_klasse.sql.diff)
*/

/******************** FUNCTIONS (NEEDED FOR TABLE/INDEX-DEFS) DEFS ***********************************/

CREATE or replace FUNCTION _as_convert_klasse_relation_kode_to_txt (
  KlasseRelationKode
    ) 
RETURNS TEXT 
LANGUAGE sql STRICT IMMUTABLE 
AS $$
        SELECT $1::text;
   $$;

/******************** TBLS DEFS ***********************************/


CREATE TABLE klasse
(
 id uuid NOT NULL,
  CONSTRAINT klasse_pkey PRIMARY KEY (id)
)
WITH (
  OIDS=FALSE
);
ALTER TABLE klasse
  OWNER TO mox;

/****************************************************************************************************/
CREATE SEQUENCE klasse_registrering_id_seq
  INCREMENT 1
  MINVALUE 1
  MAXVALUE 9223372036854775807
  START 1
  CACHE 1;
ALTER TABLE klasse_registrering_id_seq
  OWNER TO mox;


CREATE TABLE klasse_registrering
(
 id bigint NOT NULL DEFAULT nextval('klasse_registrering_id_seq'::regclass),
 klasse_id uuid NOT NULL ,
 registrering RegistreringBase NOT NULL CHECK( (registrering).TimePeriod IS NOT NULL AND not isempty((registrering).timeperiod) ),
  CONSTRAINT klasse_registrering_pkey PRIMARY KEY (id),
  CONSTRAINT klasse_registrering_klasse_fkey FOREIGN KEY (klasse_id)
      REFERENCES klasse (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT klasse_registrering__uuid_to_text_timeperiod_excl EXCLUDE 
  USING gist (_uuid_to_text(klasse_id) WITH =, _composite_type_to_time_range(registrering) WITH &&)
)
WITH (
  OIDS=FALSE
);
ALTER TABLE klasse_registrering
  OWNER TO mox;

CREATE INDEX klasse_registrering_idx_livscykluskode
  ON klasse_registrering
  USING btree
  (((registrering).livscykluskode));

CREATE INDEX klasse_registrering_idx_brugerref
  ON klasse_registrering
  USING btree
  (((registrering).brugerref));

CREATE INDEX klasse_registrering_idx_note
  ON klasse_registrering
  USING btree
  (((registrering).note));

CREATE INDEX klasse_registrering_pat_note
  ON klasse_registrering
  USING  gin
  (((registrering).note) gin_trgm_ops);

CREATE INDEX klasse_id_idx
   ON klasse_registrering (klasse_id)


/****************************************************************************************************/


CREATE SEQUENCE klasse_attr_egenskaber_id_seq
  INCREMENT 1
  MINVALUE 1
  MAXVALUE 9223372036854775807
  START 1
  CACHE 1;
ALTER TABLE klasse_attr_egenskaber_id_seq
  OWNER TO mox;




CREATE TABLE klasse_attr_egenskaber
(
  id bigint NOT NULL DEFAULT nextval('klasse_attr_egenskaber_id_seq'::regclass), 
   brugervendtnoegle text null, 
   beskrivelse text null, 
   eksempel text null, 
   omfang text null, 
   titel text null, 
   retskilde text null, 
   aendringsnotat text null, 
   virkning Virkning not null CHECK( (virkning).TimePeriod IS NOT NULL AND not isempty((virkning).TimePeriod) ),
  klasse_registrering_id bigint not null,
CONSTRAINT klasse_attr_egenskaber_pkey PRIMARY KEY (id),
CONSTRAINT klasse_attr_egenskaber_forkey_klasseregistrering  FOREIGN KEY (klasse_registrering_id) REFERENCES klasse_registrering (id) MATCH SIMPLE ON UPDATE NO ACTION ON DELETE NO ACTION,
CONSTRAINT klasse_attr_egenskaber_exclude_virkning_overlap EXCLUDE USING gist (klasse_registrering_id WITH =, _composite_type_to_time_range(virkning) WITH &&)
)
WITH (
  OIDS=FALSE
);
ALTER TABLE klasse_attr_egenskaber
  OWNER TO mox;

 
CREATE INDEX klasse_attr_egenskaber_pat_brugervendtnoegle
  ON klasse_attr_egenskaber
  USING gin
  (brugervendtnoegle gin_trgm_ops);

CREATE INDEX klasse_attr_egenskaber_idx_brugervendtnoegle
  ON klasse_attr_egenskaber
  USING btree
  (brugervendtnoegle); 

 
CREATE INDEX klasse_attr_egenskaber_pat_beskrivelse
  ON klasse_attr_egenskaber
  USING gin
  (beskrivelse gin_trgm_ops);

CREATE INDEX klasse_attr_egenskaber_idx_beskrivelse
  ON klasse_attr_egenskaber
  USING btree
  (beskrivelse); 

 
CREATE INDEX klasse_attr_egenskaber_pat_eksempel
  ON klasse_attr_egenskaber
  USING gin
  (eksempel gin_trgm_ops);

CREATE INDEX klasse_attr_egenskaber_idx_eksempel
  ON klasse_attr_egenskaber
  USING btree
  (eksempel); 

 
CREATE INDEX klasse_attr_egenskaber_pat_omfang
  ON klasse_attr_egenskaber
  USING gin
  (omfang gin_trgm_ops);

CREATE INDEX klasse_attr_egenskaber_idx_omfang
  ON klasse_attr_egenskaber
  USING btree
  (omfang); 

 
CREATE INDEX klasse_attr_egenskaber_pat_titel
  ON klasse_attr_egenskaber
  USING gin
  (titel gin_trgm_ops);

CREATE INDEX klasse_attr_egenskaber_idx_titel
  ON klasse_attr_egenskaber
  USING btree
  (titel); 

 
CREATE INDEX klasse_attr_egenskaber_pat_retskilde
  ON klasse_attr_egenskaber
  USING gin
  (retskilde gin_trgm_ops);

CREATE INDEX klasse_attr_egenskaber_idx_retskilde
  ON klasse_attr_egenskaber
  USING btree
  (retskilde); 

 
CREATE INDEX klasse_attr_egenskaber_pat_aendringsnotat
  ON klasse_attr_egenskaber
  USING gin
  (aendringsnotat gin_trgm_ops);

CREATE INDEX klasse_attr_egenskaber_idx_aendringsnotat
  ON klasse_attr_egenskaber
  USING btree
  (aendringsnotat); 




CREATE INDEX klasse_attr_egenskaber_idx_virkning_aktoerref
  ON klasse_attr_egenskaber
  USING btree
  (((virkning).aktoerref));

CREATE INDEX klasse_attr_egenskaber_idx_virkning_aktoertypekode
  ON klasse_attr_egenskaber
  USING btree
  (((virkning).aktoertypekode));

CREATE INDEX klasse_attr_egenskaber_idx_virkning_notetekst
  ON klasse_attr_egenskaber
  USING btree
  (((virkning).notetekst));

CREATE INDEX klasse_attr_egenskaber_pat_virkning_notetekst
  ON klasse_attr_egenskaber
  USING gin
  (((virkning).notetekst) gin_trgm_ops);

/**********************************************/

CREATE SEQUENCE klasse_attr_egenskaber_soegeord_id_seq
  INCREMENT 1
  MINVALUE 1
  MAXVALUE 9223372036854775807
  START 1
  CACHE 1;
ALTER TABLE klasse_attr_egenskaber_soegeord_id_seq
  OWNER TO mox;


CREATE TABLE klasse_attr_egenskaber_soegeord
(
  id bigint NOT NULL DEFAULT nextval('klasse_attr_egenskaber_soegeord_id_seq'::regclass),
    soegeordidentifikator text null,
    beskrivelse text null,
    soegeordskategori text null,
    klasse_attr_egenskaber_id bigint not null,
CONSTRAINT klasse_attr_egenskaber_soegeord_pkey PRIMARY KEY (id),
CONSTRAINT klasse_attr_egenskaber_soegeord_forkey_klasse_attr_egenskaber  FOREIGN KEY (klasse_attr_egenskaber_id) REFERENCES klasse_attr_egenskaber (id) MATCH SIMPLE ON UPDATE NO ACTION ON DELETE NO ACTION
,CONSTRAINT klasse_attr_egenskaber_soegeord_chk_not_all_null CHECK (NOT  (soegeordidentifikator IS NULL AND beskrivelse IS NULL AND soegeordskategori IS NULL))
)
WITH (
  OIDS=FALSE
);
ALTER TABLE klasse_attr_egenskaber_soegeord
  OWNER TO mox;


CREATE INDEX klasse_attr_egenskaber_soegeord_idx_soegeordidentifikator
  ON klasse_attr_egenskaber_soegeord
  USING btree
  (soegeordidentifikator);

CREATE INDEX klasse_attr_egenskaber_soegeord_pat_soegeordidentifikator
  ON klasse_attr_egenskaber_soegeord
  USING gin
  (soegeordidentifikator gin_trgm_ops);

CREATE INDEX klasse_attr_egenskaber_soegeord_idx_beskrivelse
  ON klasse_attr_egenskaber_soegeord
  USING btree
  (beskrivelse);

CREATE INDEX klasse_attr_egenskaber_soegeord_pat_beskrivelse
  ON klasse_attr_egenskaber_soegeord
  USING gin
  (beskrivelse gin_trgm_ops);

CREATE INDEX klasse_attr_egenskaber_soegeord_idx_soegeordskategori
  ON klasse_attr_egenskaber_soegeord
  USING btree
  (soegeordskategori);

CREATE INDEX klasse_attr_egenskaber_soegeord_pat_soegeordskategori
  ON klasse_attr_egenskaber_soegeord
  USING gin
  (soegeordskategori gin_trgm_ops);

/****************************************************************************************************/



CREATE SEQUENCE klasse_tils_publiceret_id_seq
  INCREMENT 1
  MINVALUE 1
  MAXVALUE 9223372036854775807
  START 1
  CACHE 1;
ALTER TABLE klasse_tils_publiceret_id_seq
  OWNER TO mox;


CREATE TABLE klasse_tils_publiceret
(
  id bigint NOT NULL DEFAULT nextval('klasse_tils_publiceret_id_seq'::regclass),
  virkning Virkning  NOT NULL CHECK( (virkning).TimePeriod IS NOT NULL AND not isempty((virkning).TimePeriod) ),
  publiceret KlassePubliceretTils NOT NULL, 
  klasse_registrering_id bigint not null,
  CONSTRAINT klasse_tils_publiceret_pkey PRIMARY KEY (id),
  CONSTRAINT klasse_tils_publiceret_forkey_klasseregistrering  FOREIGN KEY (klasse_registrering_id) REFERENCES klasse_registrering (id) MATCH SIMPLE ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT klasse_tils_publiceret_exclude_virkning_overlap EXCLUDE USING gist (klasse_registrering_id WITH =, _composite_type_to_time_range(virkning) WITH &&)
)
 
WITH (
  OIDS=FALSE
);
ALTER TABLE klasse_tils_publiceret
  OWNER TO mox;

CREATE INDEX klasse_tils_publiceret_idx_publiceret
  ON klasse_tils_publiceret
  USING btree
  (publiceret);
  

CREATE INDEX klasse_tils_publiceret_idx_virkning_aktoerref
  ON klasse_tils_publiceret
  USING btree
  (((virkning).aktoerref));

CREATE INDEX klasse_tils_publiceret_idx_virkning_aktoertypekode
  ON klasse_tils_publiceret
  USING btree
  (((virkning).aktoertypekode));

CREATE INDEX klasse_tils_publiceret_idx_virkning_notetekst
  ON klasse_tils_publiceret
  USING btree
  (((virkning).notetekst));

CREATE INDEX klasse_tils_publiceret_pat_virkning_notetekst
  ON klasse_tils_publiceret
  USING gin
  (((virkning).notetekst) gin_trgm_ops);

  

/****************************************************************************************************/

CREATE SEQUENCE klasse_relation_id_seq
  INCREMENT 1
  MINVALUE 1
  MAXVALUE 9223372036854775807
  START 1
  CACHE 1;
ALTER TABLE klasse_relation_id_seq
  OWNER TO mox;


CREATE TABLE klasse_relation
(
  id bigint NOT NULL DEFAULT nextval('klasse_relation_id_seq'::regclass),
  klasse_registrering_id bigint not null,
  virkning Virkning not null CHECK( (virkning).TimePeriod IS NOT NULL AND not isempty((virkning).TimePeriod) ),
  rel_maal_uuid uuid NULL, --we have to allow null values (for now at least), as it is needed to be able to clear/overrule previous registered relations.
  rel_maal_urn text null,
  rel_type KlasseRelationKode not null,
  objekt_type text null,
 CONSTRAINT klasse_relation_forkey_klasseregistrering  FOREIGN KEY (klasse_registrering_id) REFERENCES klasse_registrering (id) MATCH SIMPLE ON UPDATE NO ACTION ON DELETE NO ACTION,
 CONSTRAINT klasse_relation_pkey PRIMARY KEY (id),
 CONSTRAINT klasse_relation_no_virkning_overlap EXCLUDE USING gist (klasse_registrering_id WITH =, _as_convert_klasse_relation_kode_to_txt(rel_type) WITH =, _composite_type_to_time_range(virkning) WITH &&)  WHERE ( rel_type<>('redaktoerer'::KlasseRelationKode ) AND rel_type<>('sideordnede'::KlasseRelationKode ) AND rel_type<>('mapninger'::KlasseRelationKode ) AND rel_type<>('tilfoejelser'::KlasseRelationKode ) AND rel_type<>('erstatter'::KlasseRelationKode ) AND rel_type<>('lovligekombinationer'::KlasseRelationKode )) ,-- no overlapping virkning except for 0..n --relations
 CONSTRAINT klasse_relation_either_uri_or_urn CHECK (NOT (rel_maal_uuid IS NOT NULL AND (rel_maal_urn IS NOT NULL AND rel_maal_urn<>'')))
);


CREATE INDEX klasse_relation_idx_rel_maal_obj_uuid
  ON klasse_relation
  USING btree
  (rel_type,objekt_type,rel_maal_uuid);

CREATE INDEX klasse_relation_idx_rel_maal_obj_urn
  ON klasse_relation
  USING btree
  (rel_type,objekt_type,rel_maal_urn);

CREATE INDEX klasse_relation_idx_rel_maal_uuid
  ON klasse_relation
  USING btree
  (rel_type, rel_maal_uuid);

CREATE INDEX klasse_relation_idx_rel_maal_uuid_isolated
  ON klasse_relation
  USING btree
  (rel_maal_uuid);

CREATE INDEX klasse_relation_idx_rel_maal_urn_isolated
  ON klasse_relation
  USING btree
  (rel_maal_urn);

CREATE INDEX klasse_relation_idx_rel_maal_urn
  ON klasse_relation
  USING btree
  (rel_type, rel_maal_urn);

CREATE INDEX klasse_relation_idx_virkning_aktoerref
  ON klasse_relation
  USING btree
  (((virkning).aktoerref));

CREATE INDEX klasse_relation_idx_virkning_aktoertypekode
  ON klasse_relation
  USING btree
  (((virkning).aktoertypekode));

CREATE INDEX klasse_relation_idx_virkning_notetekst
  ON klasse_relation
  USING btree
  (((virkning).notetekst));

CREATE INDEX klasse_relation_pat_virkning_notetekst
  ON klasse_relation
  USING gin
  (((virkning).notetekst) gin_trgm_ops);




