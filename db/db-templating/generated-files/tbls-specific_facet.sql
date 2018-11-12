-- Copyright (C) 2015 Magenta ApS, http://magenta.dk.
-- Contact: info@magenta.dk.
--
-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at http://mozilla.org/MPL/2.0/.

/*
NOTICE: This file is auto-generated using the script: oio_rest/apply-templates.py
*/

/******************** FUNCTIONS (NEEDED FOR TABLE/INDEX-DEFS) DEFS ***********************************/

CREATE or replace FUNCTION _as_convert_facet_relation_kode_to_txt (
  FacetRelationKode
    ) 
RETURNS TEXT 
LANGUAGE sql STRICT IMMUTABLE 
AS $$
        SELECT $1::text;
   $$;

/******************** TBLS DEFS ***********************************/


CREATE TABLE facet
(
 id uuid NOT NULL,
  CONSTRAINT facet_pkey PRIMARY KEY (id)
)
WITH (
  OIDS=FALSE
);
ALTER TABLE facet
  OWNER TO mox;

/****************************************************************************************************/
CREATE SEQUENCE facet_registrering_id_seq
  INCREMENT 1
  MINVALUE 1
  MAXVALUE 9223372036854775807
  START 1
  CACHE 1;
ALTER TABLE facet_registrering_id_seq
  OWNER TO mox;


CREATE TABLE facet_registrering
(
 id bigint NOT NULL DEFAULT nextval('facet_registrering_id_seq'::regclass),
 facet_id uuid NOT NULL ,
 registrering RegistreringBase NOT NULL CHECK( (registrering).TimePeriod IS NOT NULL AND not isempty((registrering).timeperiod) ),
  CONSTRAINT facet_registrering_pkey PRIMARY KEY (id),
  CONSTRAINT facet_registrering_facet_fkey FOREIGN KEY (facet_id)
      REFERENCES facet (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT facet_registrering__uuid_to_text_timeperiod_excl EXCLUDE 
  USING gist (_uuid_to_text(facet_id) WITH =, _composite_type_to_time_range(registrering) WITH &&)
)
WITH (
  OIDS=FALSE
);
ALTER TABLE facet_registrering
  OWNER TO mox;

CREATE INDEX facet_registrering_idx_livscykluskode
  ON facet_registrering
  USING btree
  (((registrering).livscykluskode));

CREATE INDEX facet_registrering_idx_brugerref
  ON facet_registrering
  USING btree
  (((registrering).brugerref));

CREATE INDEX facet_registrering_idx_note
  ON facet_registrering
  USING btree
  (((registrering).note));

CREATE INDEX facet_registrering_pat_note
  ON facet_registrering
  USING  gin
  (((registrering).note) gin_trgm_ops);

CREATE INDEX facet_id_idx
   ON facet_registrering (facet_id);


CREATE TRIGGER notify_facet
    AFTER INSERT OR UPDATE OR DELETE ON facet_registrering
    FOR EACH ROW EXECUTE PROCEDURE notify_event();

/****************************************************************************************************/


CREATE SEQUENCE facet_attr_egenskaber_id_seq
  INCREMENT 1
  MINVALUE 1
  MAXVALUE 9223372036854775807
  START 1
  CACHE 1;
ALTER TABLE facet_attr_egenskaber_id_seq
  OWNER TO mox;




CREATE TABLE facet_attr_egenskaber
(
  id bigint NOT NULL DEFAULT nextval('facet_attr_egenskaber_id_seq'::regclass), 
   brugervendtnoegle text null, 
   beskrivelse text null, 
   opbygning text null, 
   ophavsret text null, 
   plan text null, 
   supplement text null, 
   retskilde text null, 
   virkning Virkning not null CHECK( (virkning).TimePeriod IS NOT NULL AND not isempty((virkning).TimePeriod) ),
  facet_registrering_id bigint not null,
CONSTRAINT facet_attr_egenskaber_pkey PRIMARY KEY (id),
CONSTRAINT facet_attr_egenskaber_forkey_facetregistrering  FOREIGN KEY (facet_registrering_id) REFERENCES facet_registrering (id) MATCH SIMPLE ON UPDATE NO ACTION ON DELETE NO ACTION,
CONSTRAINT facet_attr_egenskaber_exclude_virkning_overlap EXCLUDE USING gist (facet_registrering_id WITH =, _composite_type_to_time_range(virkning) WITH &&)
)
WITH (
  OIDS=FALSE
);
ALTER TABLE facet_attr_egenskaber
  OWNER TO mox;

 
CREATE INDEX facet_attr_egenskaber_pat_brugervendtnoegle
  ON facet_attr_egenskaber
  USING gin
  (brugervendtnoegle gin_trgm_ops);

CREATE INDEX facet_attr_egenskaber_idx_brugervendtnoegle
  ON facet_attr_egenskaber
  USING btree
  (brugervendtnoegle); 

 
CREATE INDEX facet_attr_egenskaber_pat_beskrivelse
  ON facet_attr_egenskaber
  USING gin
  (beskrivelse gin_trgm_ops);

CREATE INDEX facet_attr_egenskaber_idx_beskrivelse
  ON facet_attr_egenskaber
  USING btree
  (beskrivelse); 

 
CREATE INDEX facet_attr_egenskaber_pat_opbygning
  ON facet_attr_egenskaber
  USING gin
  (opbygning gin_trgm_ops);

CREATE INDEX facet_attr_egenskaber_idx_opbygning
  ON facet_attr_egenskaber
  USING btree
  (opbygning); 

 
CREATE INDEX facet_attr_egenskaber_pat_ophavsret
  ON facet_attr_egenskaber
  USING gin
  (ophavsret gin_trgm_ops);

CREATE INDEX facet_attr_egenskaber_idx_ophavsret
  ON facet_attr_egenskaber
  USING btree
  (ophavsret); 

 
CREATE INDEX facet_attr_egenskaber_pat_plan
  ON facet_attr_egenskaber
  USING gin
  (plan gin_trgm_ops);

CREATE INDEX facet_attr_egenskaber_idx_plan
  ON facet_attr_egenskaber
  USING btree
  (plan); 

 
CREATE INDEX facet_attr_egenskaber_pat_supplement
  ON facet_attr_egenskaber
  USING gin
  (supplement gin_trgm_ops);

CREATE INDEX facet_attr_egenskaber_idx_supplement
  ON facet_attr_egenskaber
  USING btree
  (supplement); 

 
CREATE INDEX facet_attr_egenskaber_pat_retskilde
  ON facet_attr_egenskaber
  USING gin
  (retskilde gin_trgm_ops);

CREATE INDEX facet_attr_egenskaber_idx_retskilde
  ON facet_attr_egenskaber
  USING btree
  (retskilde); 




CREATE INDEX facet_attr_egenskaber_idx_virkning_aktoerref
  ON facet_attr_egenskaber
  USING btree
  (((virkning).aktoerref));

CREATE INDEX facet_attr_egenskaber_idx_virkning_aktoertypekode
  ON facet_attr_egenskaber
  USING btree
  (((virkning).aktoertypekode));

CREATE INDEX facet_attr_egenskaber_idx_virkning_notetekst
  ON facet_attr_egenskaber
  USING btree
  (((virkning).notetekst));

CREATE INDEX facet_attr_egenskaber_pat_virkning_notetekst
  ON facet_attr_egenskaber
  USING gin
  (((virkning).notetekst) gin_trgm_ops);






/****************************************************************************************************/



CREATE SEQUENCE facet_tils_publiceret_id_seq
  INCREMENT 1
  MINVALUE 1
  MAXVALUE 9223372036854775807
  START 1
  CACHE 1;
ALTER TABLE facet_tils_publiceret_id_seq
  OWNER TO mox;


CREATE TABLE facet_tils_publiceret
(
  id bigint NOT NULL DEFAULT nextval('facet_tils_publiceret_id_seq'::regclass),
  virkning Virkning  NOT NULL CHECK( (virkning).TimePeriod IS NOT NULL AND not isempty((virkning).TimePeriod) ),
  publiceret FacetPubliceretTils NOT NULL, 
  facet_registrering_id bigint not null,
  CONSTRAINT facet_tils_publiceret_pkey PRIMARY KEY (id),
  CONSTRAINT facet_tils_publiceret_forkey_facetregistrering  FOREIGN KEY (facet_registrering_id) REFERENCES facet_registrering (id) MATCH SIMPLE ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT facet_tils_publiceret_exclude_virkning_overlap EXCLUDE USING gist (facet_registrering_id WITH =, _composite_type_to_time_range(virkning) WITH &&)
)
 
WITH (
  OIDS=FALSE
);
ALTER TABLE facet_tils_publiceret
  OWNER TO mox;

CREATE INDEX facet_tils_publiceret_idx_publiceret
  ON facet_tils_publiceret
  USING btree
  (publiceret);
  

CREATE INDEX facet_tils_publiceret_idx_virkning_aktoerref
  ON facet_tils_publiceret
  USING btree
  (((virkning).aktoerref));

CREATE INDEX facet_tils_publiceret_idx_virkning_aktoertypekode
  ON facet_tils_publiceret
  USING btree
  (((virkning).aktoertypekode));

CREATE INDEX facet_tils_publiceret_idx_virkning_notetekst
  ON facet_tils_publiceret
  USING btree
  (((virkning).notetekst));

CREATE INDEX facet_tils_publiceret_pat_virkning_notetekst
  ON facet_tils_publiceret
  USING gin
  (((virkning).notetekst) gin_trgm_ops);

  

/****************************************************************************************************/

CREATE SEQUENCE facet_relation_id_seq
  INCREMENT 1
  MINVALUE 1
  MAXVALUE 9223372036854775807
  START 1
  CACHE 1;
ALTER TABLE facet_relation_id_seq
  OWNER TO mox;


CREATE TABLE facet_relation
(
  id bigint NOT NULL DEFAULT nextval('facet_relation_id_seq'::regclass),
  facet_registrering_id bigint not null,
  virkning Virkning not null CHECK( (virkning).TimePeriod IS NOT NULL AND not isempty((virkning).TimePeriod) ),
  rel_maal_uuid uuid NULL, --we have to allow null values (for now at least), as it is needed to be able to clear/overrule previous registered relations.
  rel_maal_urn text null,
  rel_type FacetRelationKode not null,
  objekt_type text null,

 CONSTRAINT facet_relation_forkey_facetregistrering  FOREIGN KEY (facet_registrering_id) REFERENCES facet_registrering (id) MATCH SIMPLE ON UPDATE NO ACTION ON DELETE NO ACTION,
 CONSTRAINT facet_relation_pkey PRIMARY KEY (id),
 CONSTRAINT facet_relation_no_virkning_overlap EXCLUDE USING gist (facet_registrering_id WITH =, _as_convert_facet_relation_kode_to_txt(rel_type) WITH =, _composite_type_to_time_range(virkning) WITH &&)  WHERE ( rel_type<>('redaktoerer'::FacetRelationKode )) ,-- no overlapping virkning except for 0..n --relations
 CONSTRAINT facet_relation_either_uri_or_urn CHECK (NOT (rel_maal_uuid IS NOT NULL AND (rel_maal_urn IS NOT NULL AND rel_maal_urn<>'')))
);



CREATE INDEX facet_relation_idx_rel_maal_obj_uuid
  ON facet_relation
  USING btree
  (rel_type,objekt_type,rel_maal_uuid);



CREATE INDEX facet_relation_idx_rel_maal_obj_urn
  ON facet_relation
  USING btree
  (rel_type,objekt_type,rel_maal_urn);

CREATE INDEX facet_relation_idx_rel_maal_uuid
  ON facet_relation
  USING btree
  (rel_type, rel_maal_uuid);

CREATE INDEX facet_relation_idx_rel_maal_uuid_isolated
  ON facet_relation
  USING btree
  (rel_maal_uuid);

CREATE INDEX facet_relation_idx_rel_maal_urn_isolated
  ON facet_relation
  USING btree
  (rel_maal_urn);

CREATE INDEX facet_relation_idx_rel_maal_urn
  ON facet_relation
  USING btree
  (rel_type, rel_maal_urn);

CREATE INDEX facet_relation_idx_virkning_aktoerref
  ON facet_relation
  USING btree
  (((virkning).aktoerref));

CREATE INDEX facet_relation_idx_virkning_aktoertypekode
  ON facet_relation
  USING btree
  (((virkning).aktoertypekode));

CREATE INDEX facet_relation_idx_virkning_notetekst
  ON facet_relation
  USING btree
  (((virkning).notetekst));

CREATE INDEX facet_relation_pat_virkning_notetekst
  ON facet_relation
  USING gin
  (((virkning).notetekst) gin_trgm_ops);



