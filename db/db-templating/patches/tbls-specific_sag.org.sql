-- Copyright (C) 2015 Magenta ApS, http://magenta.dk.
-- Contact: info@magenta.dk.
--
-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at http://mozilla.org/MPL/2.0/.

/*
NOTICE: This file is auto-generated using the script: apply-template.py sag tbls-specific.jinja.sql
*/

/******************** FUNCTIONS (NEEDED FOR TABLE/INDEX-DEFS) DEFS ***********************************/

CREATE or replace FUNCTION _as_convert_sag_relation_kode_to_txt (
  SagRelationKode
    ) 
RETURNS TEXT 
LANGUAGE sql STRICT IMMUTABLE 
AS $$
        SELECT $1::text;
   $$;

/******************** TBLS DEFS ***********************************/


CREATE TABLE sag
(
 id uuid NOT NULL,
  CONSTRAINT sag_pkey PRIMARY KEY (id)
)
WITH (
  OIDS=FALSE
);
ALTER TABLE sag
  OWNER TO mox;

/****************************************************************************************************/
CREATE SEQUENCE sag_registrering_id_seq
  INCREMENT 1
  MINVALUE 1
  MAXVALUE 9223372036854775807
  START 1
  CACHE 1;
ALTER TABLE sag_registrering_id_seq
  OWNER TO mox;


CREATE TABLE sag_registrering
(
 id bigint NOT NULL DEFAULT nextval('sag_registrering_id_seq'::regclass),
 sag_id uuid NOT NULL ,
 registrering RegistreringBase NOT NULL CHECK( (registrering).TimePeriod IS NOT NULL AND not isempty((registrering).timeperiod) ),
  CONSTRAINT sag_registrering_pkey PRIMARY KEY (id),
  CONSTRAINT sag_registrering_sag_fkey FOREIGN KEY (sag_id)
      REFERENCES sag (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT sag_registrering__uuid_to_text_timeperiod_excl EXCLUDE 
  USING gist (_uuid_to_text(sag_id) WITH =, _composite_type_to_time_range(registrering) WITH &&)
)
WITH (
  OIDS=FALSE
);
ALTER TABLE sag_registrering
  OWNER TO mox;

CREATE INDEX sag_registrering_idx_livscykluskode
  ON sag_registrering
  USING btree
  (((registrering).livscykluskode));

CREATE INDEX sag_registrering_idx_brugerref
  ON sag_registrering
  USING btree
  (((registrering).brugerref));

CREATE INDEX sag_registrering_idx_note
  ON sag_registrering
  USING btree
  (((registrering).note));

CREATE INDEX sag_registrering_pat_note
  ON sag_registrering
  USING  gin
  (((registrering).note) gin_trgm_ops);



/****************************************************************************************************/


CREATE SEQUENCE sag_attr_egenskaber_id_seq
  INCREMENT 1
  MINVALUE 1
  MAXVALUE 9223372036854775807
  START 1
  CACHE 1;
ALTER TABLE sag_attr_egenskaber_id_seq
  OWNER TO mox;




CREATE TABLE sag_attr_egenskaber
(
  id bigint NOT NULL DEFAULT nextval('sag_attr_egenskaber_id_seq'::regclass), 
   brugervendtnoegle text null, 
   afleveret boolean null, 
   beskrivelse text null, 
   hjemmel text null, 
   kassationskode text null, 
   offentlighedundtaget OffentlighedundtagetType null, 
   principiel boolean null, 
   sagsnummer text null, 
   titel text null, 
   virkning Virkning not null CHECK( (virkning).TimePeriod IS NOT NULL AND not isempty((virkning).TimePeriod) ),
  sag_registrering_id bigint not null,
CONSTRAINT sag_attr_egenskaber_pkey PRIMARY KEY (id),
CONSTRAINT sag_attr_egenskaber_forkey_sagregistrering  FOREIGN KEY (sag_registrering_id) REFERENCES sag_registrering (id) MATCH SIMPLE ON UPDATE NO ACTION ON DELETE NO ACTION,
CONSTRAINT sag_attr_egenskaber_exclude_virkning_overlap EXCLUDE USING gist (sag_registrering_id WITH =, _composite_type_to_time_range(virkning) WITH &&)
)
WITH (
  OIDS=FALSE
);
ALTER TABLE sag_attr_egenskaber
  OWNER TO mox;

 
CREATE INDEX sag_attr_egenskaber_pat_brugervendtnoegle
  ON sag_attr_egenskaber
  USING gin
  (brugervendtnoegle gin_trgm_ops);

CREATE INDEX sag_attr_egenskaber_idx_brugervendtnoegle
  ON sag_attr_egenskaber
  USING btree
  (brugervendtnoegle); 

 

CREATE INDEX sag_attr_egenskaber_idx_afleveret
  ON sag_attr_egenskaber
  USING btree
  (afleveret); 

 
CREATE INDEX sag_attr_egenskaber_pat_beskrivelse
  ON sag_attr_egenskaber
  USING gin
  (beskrivelse gin_trgm_ops);

CREATE INDEX sag_attr_egenskaber_idx_beskrivelse
  ON sag_attr_egenskaber
  USING btree
  (beskrivelse); 

 
CREATE INDEX sag_attr_egenskaber_pat_hjemmel
  ON sag_attr_egenskaber
  USING gin
  (hjemmel gin_trgm_ops);

CREATE INDEX sag_attr_egenskaber_idx_hjemmel
  ON sag_attr_egenskaber
  USING btree
  (hjemmel); 

 
CREATE INDEX sag_attr_egenskaber_pat_kassationskode
  ON sag_attr_egenskaber
  USING gin
  (kassationskode gin_trgm_ops);

CREATE INDEX sag_attr_egenskaber_idx_kassationskode
  ON sag_attr_egenskaber
  USING btree
  (kassationskode); 

 

CREATE INDEX sag_attr_egenskaber_idx_offentlighedundtaget
  ON sag_attr_egenskaber
  USING btree
  (offentlighedundtaget); 

 

CREATE INDEX sag_attr_egenskaber_idx_principiel
  ON sag_attr_egenskaber
  USING btree
  (principiel); 

 
CREATE INDEX sag_attr_egenskaber_pat_sagsnummer
  ON sag_attr_egenskaber
  USING gin
  (sagsnummer gin_trgm_ops);

CREATE INDEX sag_attr_egenskaber_idx_sagsnummer
  ON sag_attr_egenskaber
  USING btree
  (sagsnummer); 

 
CREATE INDEX sag_attr_egenskaber_pat_titel
  ON sag_attr_egenskaber
  USING gin
  (titel gin_trgm_ops);

CREATE INDEX sag_attr_egenskaber_idx_titel
  ON sag_attr_egenskaber
  USING btree
  (titel); 




CREATE INDEX sag_attr_egenskaber_idx_virkning_aktoerref
  ON sag_attr_egenskaber
  USING btree
  (((virkning).aktoerref));

CREATE INDEX sag_attr_egenskaber_idx_virkning_aktoertypekode
  ON sag_attr_egenskaber
  USING btree
  (((virkning).aktoertypekode));

CREATE INDEX sag_attr_egenskaber_idx_virkning_notetekst
  ON sag_attr_egenskaber
  USING btree
  (((virkning).notetekst));

CREATE INDEX sag_attr_egenskaber_pat_virkning_notetekst
  ON sag_attr_egenskaber
  USING gin
  (((virkning).notetekst) gin_trgm_ops);



/****************************************************************************************************/



CREATE SEQUENCE sag_tils_fremdrift_id_seq
  INCREMENT 1
  MINVALUE 1
  MAXVALUE 9223372036854775807
  START 1
  CACHE 1;
ALTER TABLE sag_tils_fremdrift_id_seq
  OWNER TO mox;


CREATE TABLE sag_tils_fremdrift
(
  id bigint NOT NULL DEFAULT nextval('sag_tils_fremdrift_id_seq'::regclass),
  virkning Virkning  NOT NULL CHECK( (virkning).TimePeriod IS NOT NULL AND not isempty((virkning).TimePeriod) ),
  fremdrift SagFremdriftTils NOT NULL, 
  sag_registrering_id bigint not null,
  CONSTRAINT sag_tils_fremdrift_pkey PRIMARY KEY (id),
  CONSTRAINT sag_tils_fremdrift_forkey_sagregistrering  FOREIGN KEY (sag_registrering_id) REFERENCES sag_registrering (id) MATCH SIMPLE ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT sag_tils_fremdrift_exclude_virkning_overlap EXCLUDE USING gist (sag_registrering_id WITH =, _composite_type_to_time_range(virkning) WITH &&)
)
 
WITH (
  OIDS=FALSE
);
ALTER TABLE sag_tils_fremdrift
  OWNER TO mox;

CREATE INDEX sag_tils_fremdrift_idx_fremdrift
  ON sag_tils_fremdrift
  USING btree
  (fremdrift);
  

CREATE INDEX sag_tils_fremdrift_idx_virkning_aktoerref
  ON sag_tils_fremdrift
  USING btree
  (((virkning).aktoerref));

CREATE INDEX sag_tils_fremdrift_idx_virkning_aktoertypekode
  ON sag_tils_fremdrift
  USING btree
  (((virkning).aktoertypekode));

CREATE INDEX sag_tils_fremdrift_idx_virkning_notetekst
  ON sag_tils_fremdrift
  USING btree
  (((virkning).notetekst));

CREATE INDEX sag_tils_fremdrift_pat_virkning_notetekst
  ON sag_tils_fremdrift
  USING gin
  (((virkning).notetekst) gin_trgm_ops);

  

/****************************************************************************************************/

CREATE SEQUENCE sag_relation_id_seq
  INCREMENT 1
  MINVALUE 1
  MAXVALUE 9223372036854775807
  START 1
  CACHE 1;
ALTER TABLE sag_relation_id_seq
  OWNER TO mox;


CREATE TABLE sag_relation
(
  id bigint NOT NULL DEFAULT nextval('sag_relation_id_seq'::regclass),
  sag_registrering_id bigint not null,
  virkning Virkning not null CHECK( (virkning).TimePeriod IS NOT NULL AND not isempty((virkning).TimePeriod) ),
  rel_maal_uuid uuid NULL, --we have to allow null values (for now at least), as it is needed to be able to clear/overrule previous registered relations.
  rel_maal_urn text null,
  rel_type SagRelationKode not null,
  objekt_type text null,
  rel_index int not null,
  rel_type_spec SagRelationJournalPostSpecifikKode null,
  journal_notat JournalNotatType null,
  journal_dokument_attr JournalPostDokumentAttrType null,
 CONSTRAINT sag_relation_forkey_sagregistrering  FOREIGN KEY (sag_registrering_id) REFERENCES sag_registrering (id) MATCH SIMPLE ON UPDATE NO ACTION ON DELETE NO ACTION,
 CONSTRAINT sag_relation_pkey PRIMARY KEY (id),
 CONSTRAINT sag_relation_no_virkning_overlap EXCLUDE USING gist (sag_registrering_id WITH =, _as_convert_sag_relation_kode_to_txt(rel_type) WITH =, _composite_type_to_time_range(virkning) WITH &&)  WHERE ( rel_type<>('andetarkiv'::SagRelationKode ) AND rel_type<>('andrebehandlere'::SagRelationKode ) AND rel_type<>('sekundaerpart'::SagRelationKode ) AND rel_type<>('andresager'::SagRelationKode ) AND rel_type<>('byggeri'::SagRelationKode ) AND rel_type<>('fredning'::SagRelationKode ) AND rel_type<>('journalpost'::SagRelationKode )) ,-- no overlapping virkning except for 0..n --relations
 CONSTRAINT sag_relation_either_uri_or_urn CHECK (NOT (rel_maal_uuid IS NOT NULL AND (rel_maal_urn IS NOT NULL AND rel_maal_urn<>'')))
);


CREATE INDEX sag_relation_idx_rel_maal_obj_uuid
  ON sag_relation
  USING btree
  (rel_type,objekt_type,rel_maal_uuid);

CREATE INDEX sag_relation_idx_rel_maal_obj_urn
  ON sag_relation
  USING btree
  (rel_type,objekt_type,rel_maal_urn);

CREATE INDEX sag_relation_idx_rel_maal_uuid
  ON sag_relation
  USING btree
  (rel_type, rel_maal_uuid);

CREATE INDEX sag_relation_idx_rel_maal_uuid_isolated
  ON sag_relation
  USING btree
  (rel_maal_uuid);

CREATE INDEX sag_relation_idx_rel_maal_urn_isolated
  ON sag_relation
  USING btree
  (rel_maal_urn);

CREATE INDEX sag_relation_idx_rel_maal_urn
  ON sag_relation
  USING btree
  (rel_type, rel_maal_urn);

CREATE INDEX sag_relation_idx_virkning_aktoerref
  ON sag_relation
  USING btree
  (((virkning).aktoerref));

CREATE INDEX sag_relation_idx_virkning_aktoertypekode
  ON sag_relation
  USING btree
  (((virkning).aktoertypekode));

CREATE INDEX sag_relation_idx_virkning_notetekst
  ON sag_relation
  USING btree
  (((virkning).notetekst));

CREATE INDEX sag_relation_pat_virkning_notetekst
  ON sag_relation
  USING gin
  (((virkning).notetekst) gin_trgm_ops);




