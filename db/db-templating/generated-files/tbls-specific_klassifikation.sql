-- Copyright (C) 2015 Magenta ApS, http://magenta.dk.
-- Contact: info@magenta.dk.
--
-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at http://mozilla.org/MPL/2.0/.

/*
NOTICE: This file is auto-generated using the script: oio_rest/apply-templates.py
*/



/*************** FUNCTIONS (NEEDED FOR TABLE/INDEX-DEFS) DEFS ***************/

CREATE OR REPLACE FUNCTION _as_convert_klassifikation_relation_kode_to_txt(
    KlassifikationRelationKode
) RETURNS TEXT LANGUAGE sql STRICT IMMUTABLE AS $$
    SELECT $1::text;
$$;


/****************************** TBLS DEFS ***********************************/

CREATE TABLE klassifikation (
    id uuid NOT NULL,
    CONSTRAINT klassifikation_pkey PRIMARY KEY (id)
)
WITH (
    OIDS=FALSE
);
ALTER TABLE klassifikation
    OWNER TO mox;


/****************************************************************************/

CREATE SEQUENCE klassifikation_registrering_id_seq
    INCREMENT 1
    MINVALUE 1
    MAXVALUE 9223372036854775807
    START 1
    CACHE 1;
ALTER TABLE klassifikation_registrering_id_seq
    OWNER TO mox;


CREATE TABLE klassifikation_registrering (
   id bigint NOT NULL DEFAULT nextval('klassifikation_registrering_id_seq'::regclass),
   klassifikation_id uuid NOT NULL ,
   registrering RegistreringBase NOT NULL CHECK( (registrering).TimePeriod IS NOT NULL AND not isempty((registrering).timeperiod) ),
   CONSTRAINT klassifikation_registrering_pkey PRIMARY KEY (id),
   CONSTRAINT klassifikation_registrering_klassifikation_fkey FOREIGN KEY (klassifikation_id)
       REFERENCES klassifikation (id) MATCH SIMPLE
       ON UPDATE NO ACTION ON DELETE NO ACTION,
   CONSTRAINT klassifikation_registrering__uuid_to_text_timeperiod_excl EXCLUDE 
   USING gist (_uuid_to_text(klassifikation_id) WITH =, _composite_type_to_time_range(registrering) WITH &&)
)
WITH (
  OIDS=FALSE
);

ALTER TABLE klassifikation_registrering
  OWNER TO mox;


CREATE INDEX klassifikation_registrering_idx_livscykluskode
    ON klassifikation_registrering
    USING btree
    (((registrering).livscykluskode));


CREATE INDEX klassifikation_registrering_idx_brugerref
    ON klassifikation_registrering
    USING btree
    (((registrering).brugerref));


CREATE INDEX klassifikation_registrering_idx_note
    ON klassifikation_registrering
    USING btree
    (((registrering).note));


CREATE INDEX klassifikation_registrering_pat_note
    ON klassifikation_registrering
    USING gin
    (((registrering).note) gin_trgm_ops);


CREATE INDEX klassifikation_id_idx
    ON klassifikation_registrering (klassifikation_id);


CREATE TRIGGER notify_klassifikation
    AFTER INSERT OR UPDATE OR DELETE ON klassifikation_registrering
    FOR EACH ROW EXECUTE PROCEDURE notify_event();


/****************************************************************************/



CREATE SEQUENCE klassifikation_attr_egenskaber_id_seq
    INCREMENT 1
    MINVALUE 1
    MAXVALUE 9223372036854775807
    START 1
    CACHE 1;

ALTER TABLE klassifikation_attr_egenskaber_id_seq
    OWNER TO mox;


CREATE TABLE klassifikation_attr_egenskaber (
    id bigint NOT NULL DEFAULT nextval('klassifikation_attr_egenskaber_id_seq'::regclass), 
       brugervendtnoegle text null, 
       beskrivelse text null, 
       kaldenavn text null, 
       ophavsret text null, 
    virkning Virkning not null CHECK( (virkning).TimePeriod IS NOT NULL AND not isempty((virkning).TimePeriod) ),
    klassifikation_registrering_id bigint not null,
    CONSTRAINT klassifikation_attr_egenskaber_pkey PRIMARY KEY (id),
    CONSTRAINT klassifikation_attr_egenskaber_forkey_klassifikationregistrering FOREIGN KEY (klassifikation_registrering_id) REFERENCES klassifikation_registrering (id) MATCH SIMPLE ON UPDATE NO ACTION ON DELETE NO ACTION,
    CONSTRAINT klassifikation_attr_egenskaber_exclude_virkning_overlap EXCLUDE USING gist (klassifikation_registrering_id WITH =, _composite_type_to_time_range(virkning) WITH &&)
)
WITH (
    OIDS=FALSE
);

ALTER TABLE klassifikation_attr_egenskaber
  OWNER TO mox;


 
     
        CREATE INDEX klassifikation_attr_egenskaber_pat_brugervendtnoegle
            ON klassifikation_attr_egenskaber
            USING gin
            (brugervendtnoegle gin_trgm_ops);

        CREATE INDEX klassifikation_attr_egenskaber_idx_brugervendtnoegle
            ON klassifikation_attr_egenskaber
            USING btree
            (brugervendtnoegle); 
 
     
        CREATE INDEX klassifikation_attr_egenskaber_pat_beskrivelse
            ON klassifikation_attr_egenskaber
            USING gin
            (beskrivelse gin_trgm_ops);

        CREATE INDEX klassifikation_attr_egenskaber_idx_beskrivelse
            ON klassifikation_attr_egenskaber
            USING btree
            (beskrivelse); 
 
     
        CREATE INDEX klassifikation_attr_egenskaber_pat_kaldenavn
            ON klassifikation_attr_egenskaber
            USING gin
            (kaldenavn gin_trgm_ops);

        CREATE INDEX klassifikation_attr_egenskaber_idx_kaldenavn
            ON klassifikation_attr_egenskaber
            USING btree
            (kaldenavn); 
 
     
        CREATE INDEX klassifikation_attr_egenskaber_pat_ophavsret
            ON klassifikation_attr_egenskaber
            USING gin
            (ophavsret gin_trgm_ops);

        CREATE INDEX klassifikation_attr_egenskaber_idx_ophavsret
            ON klassifikation_attr_egenskaber
            USING btree
            (ophavsret); 



CREATE INDEX klassifikation_attr_egenskaber_idx_virkning_aktoerref
    ON klassifikation_attr_egenskaber
    USING btree
    (((virkning).aktoerref));

CREATE INDEX klassifikation_attr_egenskaber_idx_virkning_aktoertypekode
    ON klassifikation_attr_egenskaber
    USING btree
    (((virkning).aktoertypekode));

CREATE INDEX klassifikation_attr_egenskaber_idx_virkning_notetekst
    ON klassifikation_attr_egenskaber
    USING btree
    (((virkning).notetekst));

CREATE INDEX klassifikation_attr_egenskaber_pat_virkning_notetekst
    ON klassifikation_attr_egenskaber
    USING gin
    (((virkning).notetekst) gin_trgm_ops);







/****************************************************************************/



CREATE SEQUENCE klassifikation_tils_publiceret_id_seq
    INCREMENT 1
    MINVALUE 1
    MAXVALUE 9223372036854775807
    START 1
    CACHE 1;
ALTER TABLE klassifikation_tils_publiceret_id_seq
    OWNER TO mox;


CREATE TABLE klassifikation_tils_publiceret (
    id bigint NOT NULL DEFAULT nextval('klassifikation_tils_publiceret_id_seq'::regclass),
    virkning Virkning NOT NULL CHECK( (virkning).TimePeriod IS NOT NULL AND not isempty((virkning).TimePeriod) ),
    publiceret KlassifikationPubliceretTils NOT NULL, 
    klassifikation_registrering_id bigint not null,
    CONSTRAINT klassifikation_tils_publiceret_pkey PRIMARY KEY (id),
    CONSTRAINT klassifikation_tils_publiceret_forkey_klassifikationregistrering FOREIGN KEY (klassifikation_registrering_id) REFERENCES klassifikation_registrering (id) MATCH SIMPLE ON UPDATE NO ACTION ON DELETE NO ACTION,
    CONSTRAINT klassifikation_tils_publiceret_exclude_virkning_overlap EXCLUDE USING gist (klassifikation_registrering_id WITH =, _composite_type_to_time_range(virkning) WITH &&)
)
WITH (
    OIDS=FALSE
);

ALTER TABLE klassifikation_tils_publiceret
    OWNER TO mox;


CREATE INDEX klassifikation_tils_publiceret_idx_publiceret
    ON klassifikation_tils_publiceret
    USING btree
    (publiceret);
  
CREATE INDEX klassifikation_tils_publiceret_idx_virkning_aktoerref
    ON klassifikation_tils_publiceret
    USING btree
    (((virkning).aktoerref));

CREATE INDEX klassifikation_tils_publiceret_idx_virkning_aktoertypekode
    ON klassifikation_tils_publiceret
    USING btree
    (((virkning).aktoertypekode));

CREATE INDEX klassifikation_tils_publiceret_idx_virkning_notetekst
    ON klassifikation_tils_publiceret
    USING btree
    (((virkning).notetekst));

CREATE INDEX klassifikation_tils_publiceret_pat_virkning_notetekst
    ON klassifikation_tils_publiceret
    USING gin
    (((virkning).notetekst) gin_trgm_ops);



/****************************************************************************/

CREATE SEQUENCE klassifikation_relation_id_seq
    INCREMENT 1
    MINVALUE 1
    MAXVALUE 9223372036854775807
    START 1
    CACHE 1;
ALTER TABLE klassifikation_relation_id_seq
    OWNER TO mox;


CREATE TABLE klassifikation_relation (
    id bigint NOT NULL DEFAULT nextval('klassifikation_relation_id_seq'::regclass),
    klassifikation_registrering_id bigint not null,
    virkning Virkning not null CHECK((virkning).TimePeriod IS NOT NULL AND not isempty((virkning).TimePeriod) ),
    --we have to allow null values (for now at least), as it is needed to be able to clear/overrule previous registered relations.
    rel_maal_uuid uuid NULL,
    rel_maal_urn text null,
    rel_type KlassifikationRelationKode not null,
    objekt_type text null,

    

    CONSTRAINT klassifikation_relation_forkey_klassifikationregistrering FOREIGN KEY (klassifikation_registrering_id) REFERENCES klassifikation_registrering (id) MATCH SIMPLE ON UPDATE NO ACTION ON DELETE NO ACTION,
    CONSTRAINT klassifikation_relation_pkey PRIMARY KEY (id),
    CONSTRAINT klassifikation_relation_no_virkning_overlap EXCLUDE USING gist (klassifikation_registrering_id WITH =, _as_convert_klassifikation_relation_kode_to_txt(rel_type) WITH =, _composite_type_to_time_range(virkning) WITH &&) ,-- no overlapping virkning except for 0..n --relations
    CONSTRAINT klassifikation_relation_either_uri_or_urn CHECK (NOT (rel_maal_uuid IS NOT NULL AND (rel_maal_urn IS NOT NULL AND rel_maal_urn<>'')))
);





CREATE INDEX klassifikation_relation_idx_rel_maal_obj_uuid
    ON klassifikation_relation
    USING btree
    (rel_type,objekt_type,rel_maal_uuid);



CREATE INDEX klassifikation_relation_idx_rel_maal_obj_urn
    ON klassifikation_relation
    USING btree
    (rel_type,objekt_type,rel_maal_urn);

CREATE INDEX klassifikation_relation_idx_rel_maal_uuid
    ON klassifikation_relation
    USING btree
    (rel_type, rel_maal_uuid);

CREATE INDEX klassifikation_relation_idx_rel_maal_uuid_isolated
    ON klassifikation_relation
    USING btree
    (rel_maal_uuid);

CREATE INDEX klassifikation_relation_idx_rel_maal_urn_isolated
    ON klassifikation_relation
    USING btree
    (rel_maal_urn);

CREATE INDEX klassifikation_relation_idx_rel_maal_urn
    ON klassifikation_relation
    USING btree
    (rel_type, rel_maal_urn);

CREATE INDEX klassifikation_relation_idx_virkning_aktoerref
    ON klassifikation_relation
    USING btree
    (((virkning).aktoerref));

CREATE INDEX klassifikation_relation_idx_virkning_aktoertypekode
    ON klassifikation_relation
    USING btree
    (((virkning).aktoertypekode));

CREATE INDEX klassifikation_relation_idx_virkning_notetekst
    ON klassifikation_relation
    USING btree
    (((virkning).notetekst));

CREATE INDEX klassifikation_relation_pat_virkning_notetekst
    ON klassifikation_relation
    USING gin
    (((virkning).notetekst) gin_trgm_ops);




