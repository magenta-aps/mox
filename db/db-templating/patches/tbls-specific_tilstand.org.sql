-- Copyright (C) 2015 Magenta ApS, http://magenta.dk.
-- Contact: info@magenta.dk.
--
-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at http://mozilla.org/MPL/2.0/.

/*
NOTICE: This file is auto-generated using the script: apply-template.py tilstand tbls-specific.jinja.sql
*/

/******************** FUNCTIONS (NEEDED FOR TABLE/INDEX-DEFS) DEFS ***********************************/

CREATE or replace FUNCTION _as_convert_tilstand_relation_kode_to_txt (
  TilstandRelationKode
    ) 
RETURNS TEXT 
LANGUAGE sql STRICT IMMUTABLE 
AS $$
        SELECT $1::text;
   $$;

/******************** TBLS DEFS ***********************************/


CREATE TABLE tilstand
(
 id uuid NOT NULL,
  CONSTRAINT tilstand_pkey PRIMARY KEY (id)
)
WITH (
  OIDS=FALSE
);
ALTER TABLE tilstand
  OWNER TO mox;

/****************************************************************************************************/
CREATE SEQUENCE tilstand_registrering_id_seq
  INCREMENT 1
  MINVALUE 1
  MAXVALUE 9223372036854775807
  START 1
  CACHE 1;
ALTER TABLE tilstand_registrering_id_seq
  OWNER TO mox;


CREATE TABLE tilstand_registrering
(
 id bigint NOT NULL DEFAULT nextval('tilstand_registrering_id_seq'::regclass),
 tilstand_id uuid NOT NULL ,
 registrering RegistreringBase NOT NULL CHECK( (registrering).TimePeriod IS NOT NULL AND not isempty((registrering).timeperiod) ),
  CONSTRAINT tilstand_registrering_pkey PRIMARY KEY (id),
  CONSTRAINT tilstand_registrering_tilstand_fkey FOREIGN KEY (tilstand_id)
      REFERENCES tilstand (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT tilstand_registrering__uuid_to_text_timeperiod_excl EXCLUDE 
  USING gist (_uuid_to_text(tilstand_id) WITH =, _composite_type_to_time_range(registrering) WITH &&)
)
WITH (
  OIDS=FALSE
);
ALTER TABLE tilstand_registrering
  OWNER TO mox;

CREATE INDEX tilstand_registrering_idx_livscykluskode
  ON tilstand_registrering
  USING btree
  (((registrering).livscykluskode));

CREATE INDEX tilstand_registrering_idx_brugerref
  ON tilstand_registrering
  USING btree
  (((registrering).brugerref));

CREATE INDEX tilstand_registrering_idx_note
  ON tilstand_registrering
  USING btree
  (((registrering).note));

CREATE INDEX tilstand_registrering_pat_note
  ON tilstand_registrering
  USING  gin
  (((registrering).note) gin_trgm_ops);



/****************************************************************************************************/


CREATE SEQUENCE tilstand_attr_egenskaber_id_seq
  INCREMENT 1
  MINVALUE 1
  MAXVALUE 9223372036854775807
  START 1
  CACHE 1;
ALTER TABLE tilstand_attr_egenskaber_id_seq
  OWNER TO mox;




CREATE TABLE tilstand_attr_egenskaber
(
  id bigint NOT NULL DEFAULT nextval('tilstand_attr_egenskaber_id_seq'::regclass), 
   brugervendtnoegle text null, 
   beskrivelse text null, 
   virkning Virkning not null CHECK( (virkning).TimePeriod IS NOT NULL AND not isempty((virkning).TimePeriod) ),
  tilstand_registrering_id bigint not null,
CONSTRAINT tilstand_attr_egenskaber_pkey PRIMARY KEY (id),
CONSTRAINT tilstand_attr_egenskaber_forkey_tilstandregistrering  FOREIGN KEY (tilstand_registrering_id) REFERENCES tilstand_registrering (id) MATCH SIMPLE ON UPDATE NO ACTION ON DELETE NO ACTION,
CONSTRAINT tilstand_attr_egenskaber_exclude_virkning_overlap EXCLUDE USING gist (tilstand_registrering_id WITH =, _composite_type_to_time_range(virkning) WITH &&)
)
WITH (
  OIDS=FALSE
);
ALTER TABLE tilstand_attr_egenskaber
  OWNER TO mox;

 
CREATE INDEX tilstand_attr_egenskaber_pat_brugervendtnoegle
  ON tilstand_attr_egenskaber
  USING gin
  (brugervendtnoegle gin_trgm_ops);

CREATE INDEX tilstand_attr_egenskaber_idx_brugervendtnoegle
  ON tilstand_attr_egenskaber
  USING btree
  (brugervendtnoegle); 

 
CREATE INDEX tilstand_attr_egenskaber_pat_beskrivelse
  ON tilstand_attr_egenskaber
  USING gin
  (beskrivelse gin_trgm_ops);

CREATE INDEX tilstand_attr_egenskaber_idx_beskrivelse
  ON tilstand_attr_egenskaber
  USING btree
  (beskrivelse); 




CREATE INDEX tilstand_attr_egenskaber_idx_virkning_aktoerref
  ON tilstand_attr_egenskaber
  USING btree
  (((virkning).aktoerref));

CREATE INDEX tilstand_attr_egenskaber_idx_virkning_aktoertypekode
  ON tilstand_attr_egenskaber
  USING btree
  (((virkning).aktoertypekode));

CREATE INDEX tilstand_attr_egenskaber_idx_virkning_notetekst
  ON tilstand_attr_egenskaber
  USING btree
  (((virkning).notetekst));

CREATE INDEX tilstand_attr_egenskaber_pat_virkning_notetekst
  ON tilstand_attr_egenskaber
  USING gin
  (((virkning).notetekst) gin_trgm_ops);



/****************************************************************************************************/



CREATE SEQUENCE tilstand_tils_status_id_seq
  INCREMENT 1
  MINVALUE 1
  MAXVALUE 9223372036854775807
  START 1
  CACHE 1;
ALTER TABLE tilstand_tils_status_id_seq
  OWNER TO mox;


CREATE TABLE tilstand_tils_status
(
  id bigint NOT NULL DEFAULT nextval('tilstand_tils_status_id_seq'::regclass),
  virkning Virkning  NOT NULL CHECK( (virkning).TimePeriod IS NOT NULL AND not isempty((virkning).TimePeriod) ),
  status TilstandStatusTils NOT NULL, 
  tilstand_registrering_id bigint not null,
  CONSTRAINT tilstand_tils_status_pkey PRIMARY KEY (id),
  CONSTRAINT tilstand_tils_status_forkey_tilstandregistrering  FOREIGN KEY (tilstand_registrering_id) REFERENCES tilstand_registrering (id) MATCH SIMPLE ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT tilstand_tils_status_exclude_virkning_overlap EXCLUDE USING gist (tilstand_registrering_id WITH =, _composite_type_to_time_range(virkning) WITH &&)
)
 
WITH (
  OIDS=FALSE
);
ALTER TABLE tilstand_tils_status
  OWNER TO mox;

CREATE INDEX tilstand_tils_status_idx_status
  ON tilstand_tils_status
  USING btree
  (status);
  

CREATE INDEX tilstand_tils_status_idx_virkning_aktoerref
  ON tilstand_tils_status
  USING btree
  (((virkning).aktoerref));

CREATE INDEX tilstand_tils_status_idx_virkning_aktoertypekode
  ON tilstand_tils_status
  USING btree
  (((virkning).aktoertypekode));

CREATE INDEX tilstand_tils_status_idx_virkning_notetekst
  ON tilstand_tils_status
  USING btree
  (((virkning).notetekst));

CREATE INDEX tilstand_tils_status_pat_virkning_notetekst
  ON tilstand_tils_status
  USING gin
  (((virkning).notetekst) gin_trgm_ops);

  

CREATE SEQUENCE tilstand_tils_publiceret_id_seq
  INCREMENT 1
  MINVALUE 1
  MAXVALUE 9223372036854775807
  START 1
  CACHE 1;
ALTER TABLE tilstand_tils_publiceret_id_seq
  OWNER TO mox;


CREATE TABLE tilstand_tils_publiceret
(
  id bigint NOT NULL DEFAULT nextval('tilstand_tils_publiceret_id_seq'::regclass),
  virkning Virkning  NOT NULL CHECK( (virkning).TimePeriod IS NOT NULL AND not isempty((virkning).TimePeriod) ),
  publiceret TilstandPubliceretTils NOT NULL, 
  tilstand_registrering_id bigint not null,
  CONSTRAINT tilstand_tils_publiceret_pkey PRIMARY KEY (id),
  CONSTRAINT tilstand_tils_publiceret_forkey_tilstandregistrering  FOREIGN KEY (tilstand_registrering_id) REFERENCES tilstand_registrering (id) MATCH SIMPLE ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT tilstand_tils_publiceret_exclude_virkning_overlap EXCLUDE USING gist (tilstand_registrering_id WITH =, _composite_type_to_time_range(virkning) WITH &&)
)
 
WITH (
  OIDS=FALSE
);
ALTER TABLE tilstand_tils_publiceret
  OWNER TO mox;

CREATE INDEX tilstand_tils_publiceret_idx_publiceret
  ON tilstand_tils_publiceret
  USING btree
  (publiceret);
  

CREATE INDEX tilstand_tils_publiceret_idx_virkning_aktoerref
  ON tilstand_tils_publiceret
  USING btree
  (((virkning).aktoerref));

CREATE INDEX tilstand_tils_publiceret_idx_virkning_aktoertypekode
  ON tilstand_tils_publiceret
  USING btree
  (((virkning).aktoertypekode));

CREATE INDEX tilstand_tils_publiceret_idx_virkning_notetekst
  ON tilstand_tils_publiceret
  USING btree
  (((virkning).notetekst));

CREATE INDEX tilstand_tils_publiceret_pat_virkning_notetekst
  ON tilstand_tils_publiceret
  USING gin
  (((virkning).notetekst) gin_trgm_ops);

  

/****************************************************************************************************/

CREATE SEQUENCE tilstand_relation_id_seq
  INCREMENT 1
  MINVALUE 1
  MAXVALUE 9223372036854775807
  START 1
  CACHE 1;
ALTER TABLE tilstand_relation_id_seq
  OWNER TO mox;


CREATE TABLE tilstand_relation
(
  id bigint NOT NULL DEFAULT nextval('tilstand_relation_id_seq'::regclass),
  tilstand_registrering_id bigint not null,
  virkning Virkning not null CHECK( (virkning).TimePeriod IS NOT NULL AND not isempty((virkning).TimePeriod) ),
  rel_maal_uuid uuid NULL, --we have to allow null values (for now at least), as it is needed to be able to clear/overrule previous registered relations.
  rel_maal_urn text null,
  rel_type TilstandRelationKode not null,
  objekt_type text null,
  rel_index int null,
  tilstand_vaerdi_attr TilstandVaerdiRelationAttrType null,
 CONSTRAINT tilstand_relation_forkey_tilstandregistrering  FOREIGN KEY (tilstand_registrering_id) REFERENCES tilstand_registrering (id) MATCH SIMPLE ON UPDATE NO ACTION ON DELETE NO ACTION,
 CONSTRAINT tilstand_relation_pkey PRIMARY KEY (id),
 CONSTRAINT tilstand_relation_no_virkning_overlap EXCLUDE USING gist (tilstand_registrering_id WITH =, _as_convert_tilstand_relation_kode_to_txt(rel_type) WITH =, _composite_type_to_time_range(virkning) WITH &&)  WHERE ( rel_type<>('tilstandsvaerdi'::TilstandRelationKode ) AND rel_type<>('begrundelse'::TilstandRelationKode ) AND rel_type<>('tilstandskvalitet'::TilstandRelationKode ) AND rel_type<>('tilstandsvurdering'::TilstandRelationKode ) AND rel_type<>('tilstandsaktoer'::TilstandRelationKode ) AND rel_type<>('tilstandsudstyr'::TilstandRelationKode ) AND rel_type<>('samtykke'::TilstandRelationKode ) AND rel_type<>('tilstandsdokument'::TilstandRelationKode )) ,-- no overlapping virkning except for 0..n --relations
 CONSTRAINT tilstand_relation_either_uri_or_urn CHECK (NOT (rel_maal_uuid IS NOT NULL AND (rel_maal_urn IS NOT NULL AND rel_maal_urn<>''))),
 CONSTRAINT tilstand_relation_nominel_vaerdi_relevant_null_check CHECK (tilstand_vaerdi_attr IS NULL OR rel_type='tilstandsvaerdi')
);

CREATE UNIQUE INDEX tilstand_relation_unique_index_within_type  ON tilstand_relation (tilstand_registrering_id,rel_type,rel_index) WHERE ( rel_type IN ('tilstandsvaerdi'::TilstandRelationKode,'begrundelse'::TilstandRelationKode,'tilstandskvalitet'::TilstandRelationKode,'tilstandsvurdering'::TilstandRelationKode,'tilstandsaktoer'::TilstandRelationKode,'tilstandsudstyr'::TilstandRelationKode,'samtykke'::TilstandRelationKode,'tilstandsdokument'::TilstandRelationKode));

CREATE INDEX tilstand_relation_idx_rel_maal_obj_uuid
  ON tilstand_relation
  USING btree
  (rel_type,objekt_type,rel_maal_uuid);

CREATE INDEX tilstand_relation_idx_rel_maal_obj_urn
  ON tilstand_relation
  USING btree
  (rel_type,objekt_type,rel_maal_urn);

CREATE INDEX tilstand_relation_idx_rel_maal_uuid
  ON tilstand_relation
  USING btree
  (rel_type, rel_maal_uuid);

CREATE INDEX tilstand_relation_idx_rel_maal_uuid_isolated
  ON tilstand_relation
  USING btree
  (rel_maal_uuid);

CREATE INDEX tilstand_relation_idx_rel_maal_urn_isolated
  ON tilstand_relation
  USING btree
  (rel_maal_urn);

CREATE INDEX tilstand_relation_idx_rel_maal_urn
  ON tilstand_relation
  USING btree
  (rel_type, rel_maal_urn);

CREATE INDEX tilstand_relation_idx_virkning_aktoerref
  ON tilstand_relation
  USING btree
  (((virkning).aktoerref));

CREATE INDEX tilstand_relation_idx_virkning_aktoertypekode
  ON tilstand_relation
  USING btree
  (((virkning).aktoertypekode));

CREATE INDEX tilstand_relation_idx_virkning_notetekst
  ON tilstand_relation
  USING btree
  (((virkning).notetekst));

CREATE INDEX tilstand_relation_pat_virkning_notetekst
  ON tilstand_relation
  USING gin
  (((virkning).notetekst) gin_trgm_ops);




