-- Copyright (C) 2015 Magenta ApS, http://magenta.dk.
-- Contact: info@magenta.dk.
--
-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at http://mozilla.org/MPL/2.0/.

/*
NOTICE: This file is auto-generated using the script: apply-template.py indsats tbls-specific.jinja.sql
*/

/******************** FUNCTIONS (NEEDED FOR TABLE/INDEX-DEFS) DEFS ***********************************/

CREATE or replace FUNCTION _as_convert_indsats_relation_kode_to_txt (
  IndsatsRelationKode
    ) 
RETURNS TEXT 
LANGUAGE sql STRICT IMMUTABLE 
AS $$
        SELECT $1::text;
   $$;

/******************** TBLS DEFS ***********************************/


CREATE TABLE indsats
(
 id uuid NOT NULL,
  CONSTRAINT indsats_pkey PRIMARY KEY (id)
)
WITH (
  OIDS=FALSE
);
ALTER TABLE indsats
  OWNER TO mox;

/****************************************************************************************************/
CREATE SEQUENCE indsats_registrering_id_seq
  INCREMENT 1
  MINVALUE 1
  MAXVALUE 9223372036854775807
  START 1
  CACHE 1;
ALTER TABLE indsats_registrering_id_seq
  OWNER TO mox;


CREATE TABLE indsats_registrering
(
 id bigint NOT NULL DEFAULT nextval('indsats_registrering_id_seq'::regclass),
 indsats_id uuid NOT NULL ,
 registrering RegistreringBase NOT NULL CHECK( (registrering).TimePeriod IS NOT NULL AND not isempty((registrering).timeperiod) ),
  CONSTRAINT indsats_registrering_pkey PRIMARY KEY (id),
  CONSTRAINT indsats_registrering_indsats_fkey FOREIGN KEY (indsats_id)
      REFERENCES indsats (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT indsats_registrering__uuid_to_text_timeperiod_excl EXCLUDE 
  USING gist (_uuid_to_text(indsats_id) WITH =, _composite_type_to_time_range(registrering) WITH &&)
)
WITH (
  OIDS=FALSE
);
ALTER TABLE indsats_registrering
  OWNER TO mox;

CREATE INDEX indsats_registrering_idx_livscykluskode
  ON indsats_registrering
  USING btree
  (((registrering).livscykluskode));

CREATE INDEX indsats_registrering_idx_brugerref
  ON indsats_registrering
  USING btree
  (((registrering).brugerref));

CREATE INDEX indsats_registrering_idx_note
  ON indsats_registrering
  USING btree
  (((registrering).note));

CREATE INDEX indsats_registrering_pat_note
  ON indsats_registrering
  USING  gin
  (((registrering).note) gin_trgm_ops);



/****************************************************************************************************/


CREATE SEQUENCE indsats_attr_egenskaber_id_seq
  INCREMENT 1
  MINVALUE 1
  MAXVALUE 9223372036854775807
  START 1
  CACHE 1;
ALTER TABLE indsats_attr_egenskaber_id_seq
  OWNER TO mox;




CREATE TABLE indsats_attr_egenskaber
(
  id bigint NOT NULL DEFAULT nextval('indsats_attr_egenskaber_id_seq'::regclass), 
   brugervendtnoegle text null, 
   beskrivelse text null, 
   starttidspunkt timestamptz null, 
   sluttidspunkt timestamptz null, 
   virkning Virkning not null CHECK( (virkning).TimePeriod IS NOT NULL AND not isempty((virkning).TimePeriod) ),
  indsats_registrering_id bigint not null,
CONSTRAINT indsats_attr_egenskaber_pkey PRIMARY KEY (id),
CONSTRAINT indsats_attr_egenskaber_forkey_indsatsregistrering  FOREIGN KEY (indsats_registrering_id) REFERENCES indsats_registrering (id) MATCH SIMPLE ON UPDATE NO ACTION ON DELETE NO ACTION,
CONSTRAINT indsats_attr_egenskaber_exclude_virkning_overlap EXCLUDE USING gist (indsats_registrering_id WITH =, _composite_type_to_time_range(virkning) WITH &&)
)
WITH (
  OIDS=FALSE
);
ALTER TABLE indsats_attr_egenskaber
  OWNER TO mox;

 
CREATE INDEX indsats_attr_egenskaber_pat_brugervendtnoegle
  ON indsats_attr_egenskaber
  USING gin
  (brugervendtnoegle gin_trgm_ops);

CREATE INDEX indsats_attr_egenskaber_idx_brugervendtnoegle
  ON indsats_attr_egenskaber
  USING btree
  (brugervendtnoegle); 

 
CREATE INDEX indsats_attr_egenskaber_pat_beskrivelse
  ON indsats_attr_egenskaber
  USING gin
  (beskrivelse gin_trgm_ops);

CREATE INDEX indsats_attr_egenskaber_idx_beskrivelse
  ON indsats_attr_egenskaber
  USING btree
  (beskrivelse); 

 

CREATE INDEX indsats_attr_egenskaber_idx_starttidspunkt
  ON indsats_attr_egenskaber
  USING btree
  (starttidspunkt); 

 

CREATE INDEX indsats_attr_egenskaber_idx_sluttidspunkt
  ON indsats_attr_egenskaber
  USING btree
  (sluttidspunkt); 




CREATE INDEX indsats_attr_egenskaber_idx_virkning_aktoerref
  ON indsats_attr_egenskaber
  USING btree
  (((virkning).aktoerref));

CREATE INDEX indsats_attr_egenskaber_idx_virkning_aktoertypekode
  ON indsats_attr_egenskaber
  USING btree
  (((virkning).aktoertypekode));

CREATE INDEX indsats_attr_egenskaber_idx_virkning_notetekst
  ON indsats_attr_egenskaber
  USING btree
  (((virkning).notetekst));

CREATE INDEX indsats_attr_egenskaber_pat_virkning_notetekst
  ON indsats_attr_egenskaber
  USING gin
  (((virkning).notetekst) gin_trgm_ops);



/****************************************************************************************************/



CREATE SEQUENCE indsats_tils_publiceret_id_seq
  INCREMENT 1
  MINVALUE 1
  MAXVALUE 9223372036854775807
  START 1
  CACHE 1;
ALTER TABLE indsats_tils_publiceret_id_seq
  OWNER TO mox;


CREATE TABLE indsats_tils_publiceret
(
  id bigint NOT NULL DEFAULT nextval('indsats_tils_publiceret_id_seq'::regclass),
  virkning Virkning  NOT NULL CHECK( (virkning).TimePeriod IS NOT NULL AND not isempty((virkning).TimePeriod) ),
  publiceret IndsatsPubliceretTils NOT NULL, 
  indsats_registrering_id bigint not null,
  CONSTRAINT indsats_tils_publiceret_pkey PRIMARY KEY (id),
  CONSTRAINT indsats_tils_publiceret_forkey_indsatsregistrering  FOREIGN KEY (indsats_registrering_id) REFERENCES indsats_registrering (id) MATCH SIMPLE ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT indsats_tils_publiceret_exclude_virkning_overlap EXCLUDE USING gist (indsats_registrering_id WITH =, _composite_type_to_time_range(virkning) WITH &&)
)
 
WITH (
  OIDS=FALSE
);
ALTER TABLE indsats_tils_publiceret
  OWNER TO mox;

CREATE INDEX indsats_tils_publiceret_idx_publiceret
  ON indsats_tils_publiceret
  USING btree
  (publiceret);
  

CREATE INDEX indsats_tils_publiceret_idx_virkning_aktoerref
  ON indsats_tils_publiceret
  USING btree
  (((virkning).aktoerref));

CREATE INDEX indsats_tils_publiceret_idx_virkning_aktoertypekode
  ON indsats_tils_publiceret
  USING btree
  (((virkning).aktoertypekode));

CREATE INDEX indsats_tils_publiceret_idx_virkning_notetekst
  ON indsats_tils_publiceret
  USING btree
  (((virkning).notetekst));

CREATE INDEX indsats_tils_publiceret_pat_virkning_notetekst
  ON indsats_tils_publiceret
  USING gin
  (((virkning).notetekst) gin_trgm_ops);

  

CREATE SEQUENCE indsats_tils_fremdrift_id_seq
  INCREMENT 1
  MINVALUE 1
  MAXVALUE 9223372036854775807
  START 1
  CACHE 1;
ALTER TABLE indsats_tils_fremdrift_id_seq
  OWNER TO mox;


CREATE TABLE indsats_tils_fremdrift
(
  id bigint NOT NULL DEFAULT nextval('indsats_tils_fremdrift_id_seq'::regclass),
  virkning Virkning  NOT NULL CHECK( (virkning).TimePeriod IS NOT NULL AND not isempty((virkning).TimePeriod) ),
  fremdrift IndsatsFremdriftTils NOT NULL, 
  indsats_registrering_id bigint not null,
  CONSTRAINT indsats_tils_fremdrift_pkey PRIMARY KEY (id),
  CONSTRAINT indsats_tils_fremdrift_forkey_indsatsregistrering  FOREIGN KEY (indsats_registrering_id) REFERENCES indsats_registrering (id) MATCH SIMPLE ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT indsats_tils_fremdrift_exclude_virkning_overlap EXCLUDE USING gist (indsats_registrering_id WITH =, _composite_type_to_time_range(virkning) WITH &&)
)
 
WITH (
  OIDS=FALSE
);
ALTER TABLE indsats_tils_fremdrift
  OWNER TO mox;

CREATE INDEX indsats_tils_fremdrift_idx_fremdrift
  ON indsats_tils_fremdrift
  USING btree
  (fremdrift);
  

CREATE INDEX indsats_tils_fremdrift_idx_virkning_aktoerref
  ON indsats_tils_fremdrift
  USING btree
  (((virkning).aktoerref));

CREATE INDEX indsats_tils_fremdrift_idx_virkning_aktoertypekode
  ON indsats_tils_fremdrift
  USING btree
  (((virkning).aktoertypekode));

CREATE INDEX indsats_tils_fremdrift_idx_virkning_notetekst
  ON indsats_tils_fremdrift
  USING btree
  (((virkning).notetekst));

CREATE INDEX indsats_tils_fremdrift_pat_virkning_notetekst
  ON indsats_tils_fremdrift
  USING gin
  (((virkning).notetekst) gin_trgm_ops);

  

/****************************************************************************************************/

CREATE SEQUENCE indsats_relation_id_seq
  INCREMENT 1
  MINVALUE 1
  MAXVALUE 9223372036854775807
  START 1
  CACHE 1;
ALTER TABLE indsats_relation_id_seq
  OWNER TO mox;


CREATE TABLE indsats_relation
(
  id bigint NOT NULL DEFAULT nextval('indsats_relation_id_seq'::regclass),
  indsats_registrering_id bigint not null,
  virkning Virkning not null CHECK( (virkning).TimePeriod IS NOT NULL AND not isempty((virkning).TimePeriod) ),
  rel_maal_uuid uuid NULL, --we have to allow null values (for now at least), as it is needed to be able to clear/overrule previous registered relations.
  rel_maal_urn text null,
  rel_type IndsatsRelationKode not null,
  objekt_type text null,
 rel_index int null,
 CONSTRAINT indsats_relation_forkey_indsatsregistrering  FOREIGN KEY (indsats_registrering_id) REFERENCES indsats_registrering (id) MATCH SIMPLE ON UPDATE NO ACTION ON DELETE NO ACTION,
 CONSTRAINT indsats_relation_pkey PRIMARY KEY (id),
 CONSTRAINT indsats_relation_no_virkning_overlap EXCLUDE USING gist (indsats_registrering_id WITH =, _as_convert_indsats_relation_kode_to_txt(rel_type) WITH =, _composite_type_to_time_range(virkning) WITH &&)  WHERE ( rel_type<>('indsatskvalitet'::IndsatsRelationKode ) AND rel_type<>('indsatsaktoer'::IndsatsRelationKode ) AND rel_type<>('samtykke'::IndsatsRelationKode ) AND rel_type<>('indsatssag'::IndsatsRelationKode ) AND rel_type<>('indsatsdokument'::IndsatsRelationKode )) ,-- no overlapping virkning except for 0..n --relations
 CONSTRAINT indsats_relation_either_uri_or_urn CHECK (NOT (rel_maal_uuid IS NOT NULL AND (rel_maal_urn IS NOT NULL AND rel_maal_urn<>'')))
);

CREATE UNIQUE INDEX indsats_relation_unique_index_within_type  ON indsats_relation (indsats_registrering_id,rel_type,rel_index) WHERE ( rel_type IN ('indsatskvalitet'::IndsatsRelationKode,'indsatsaktoer'::IndsatsRelationKode,'samtykke'::IndsatsRelationKode,'indsatssag'::IndsatsRelationKode,'indsatsdokument'::IndsatsRelationKode));

CREATE INDEX indsats_relation_idx_rel_maal_obj_uuid
  ON indsats_relation
  USING btree
  (rel_type,objekt_type,rel_maal_uuid);

CREATE INDEX indsats_relation_idx_rel_maal_obj_urn
  ON indsats_relation
  USING btree
  (rel_type,objekt_type,rel_maal_urn);

CREATE INDEX indsats_relation_idx_rel_maal_uuid
  ON indsats_relation
  USING btree
  (rel_type, rel_maal_uuid);

CREATE INDEX indsats_relation_idx_rel_maal_uuid_isolated
  ON indsats_relation
  USING btree
  (rel_maal_uuid);

CREATE INDEX indsats_relation_idx_rel_maal_urn_isolated
  ON indsats_relation
  USING btree
  (rel_maal_urn);

CREATE INDEX indsats_relation_idx_rel_maal_urn
  ON indsats_relation
  USING btree
  (rel_type, rel_maal_urn);

CREATE INDEX indsats_relation_idx_virkning_aktoerref
  ON indsats_relation
  USING btree
  (((virkning).aktoerref));

CREATE INDEX indsats_relation_idx_virkning_aktoertypekode
  ON indsats_relation
  USING btree
  (((virkning).aktoertypekode));

CREATE INDEX indsats_relation_idx_virkning_notetekst
  ON indsats_relation
  USING btree
  (((virkning).notetekst));

CREATE INDEX indsats_relation_pat_virkning_notetekst
  ON indsats_relation
  USING gin
  (((virkning).notetekst) gin_trgm_ops);




