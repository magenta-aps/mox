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

CREATE OR REPLACE FUNCTION _as_convert_dokument_relation_kode_to_txt(
    DokumentRelationKode
) RETURNS TEXT LANGUAGE sql STRICT IMMUTABLE AS $$
    SELECT $1::text;
$$;


/****************************** TBLS DEFS ***********************************/

CREATE TABLE dokument (
    id uuid NOT NULL,
    CONSTRAINT dokument_pkey PRIMARY KEY (id)
)
WITH (
    OIDS=FALSE
);
ALTER TABLE dokument
    OWNER TO mox;


/****************************************************************************/

CREATE SEQUENCE dokument_registrering_id_seq
    INCREMENT 1
    MINVALUE 1
    MAXVALUE 9223372036854775807
    START 1
    CACHE 1;
ALTER TABLE dokument_registrering_id_seq
    OWNER TO mox;


CREATE TABLE dokument_registrering (
   id bigint NOT NULL DEFAULT nextval('dokument_registrering_id_seq'::regclass),
   dokument_id uuid NOT NULL ,
   registrering RegistreringBase NOT NULL CHECK( (registrering).TimePeriod IS NOT NULL AND not isempty((registrering).timeperiod) ),
   CONSTRAINT dokument_registrering_pkey PRIMARY KEY (id),
   CONSTRAINT dokument_registrering_dokument_fkey FOREIGN KEY (dokument_id)
       REFERENCES dokument (id) MATCH SIMPLE
       ON UPDATE NO ACTION ON DELETE NO ACTION,
   CONSTRAINT dokument_registrering__uuid_to_text_timeperiod_excl EXCLUDE 
   USING gist (_uuid_to_text(dokument_id) WITH =, _composite_type_to_time_range(registrering) WITH &&)
)
WITH (
  OIDS=FALSE
);

ALTER TABLE dokument_registrering
  OWNER TO mox;


CREATE INDEX dokument_registrering_idx_livscykluskode
    ON dokument_registrering
    USING btree
    (((registrering).livscykluskode));


CREATE INDEX dokument_registrering_idx_brugerref
    ON dokument_registrering
    USING btree
    (((registrering).brugerref));


CREATE INDEX dokument_registrering_idx_note
    ON dokument_registrering
    USING btree
    (((registrering).note));


CREATE INDEX dokument_registrering_pat_note
    ON dokument_registrering
    USING gin
    (((registrering).note) gin_trgm_ops);


CREATE INDEX dokument_id_idx
    ON dokument_registrering (dokument_id);


CREATE TRIGGER notify_dokument
    AFTER INSERT OR UPDATE OR DELETE ON dokument_registrering
    FOR EACH ROW EXECUTE PROCEDURE notify_event();


/****************************************************************************/



CREATE SEQUENCE dokument_attr_egenskaber_id_seq
    INCREMENT 1
    MINVALUE 1
    MAXVALUE 9223372036854775807
    START 1
    CACHE 1;

ALTER TABLE dokument_attr_egenskaber_id_seq
    OWNER TO mox;


CREATE TABLE dokument_attr_egenskaber (
    id bigint NOT NULL DEFAULT nextval('dokument_attr_egenskaber_id_seq'::regclass), 
       brugervendtnoegle text null, 
       beskrivelse text null, 
       brevdato 
           date
        null, 
       kassationskode text null, 
       major 
           int
        null, 
       minor 
           int
        null, 
       offentlighedundtaget 
           offentlighedundtagettype
        null, 
       titel text null, 
       dokumenttype text null, 
    virkning Virkning not null CHECK( (virkning).TimePeriod IS NOT NULL AND not isempty((virkning).TimePeriod) ),
    dokument_registrering_id bigint not null,
    CONSTRAINT dokument_attr_egenskaber_pkey PRIMARY KEY (id),
    CONSTRAINT dokument_attr_egenskaber_forkey_dokumentregistrering FOREIGN KEY (dokument_registrering_id) REFERENCES dokument_registrering (id) MATCH SIMPLE ON UPDATE NO ACTION ON DELETE NO ACTION,
    CONSTRAINT dokument_attr_egenskaber_exclude_virkning_overlap EXCLUDE USING gist (dokument_registrering_id WITH =, _composite_type_to_time_range(virkning) WITH &&)
)
WITH (
    OIDS=FALSE
);

ALTER TABLE dokument_attr_egenskaber
  OWNER TO mox;


 
     
        CREATE INDEX dokument_attr_egenskaber_pat_brugervendtnoegle
            ON dokument_attr_egenskaber
            USING gin
            (brugervendtnoegle gin_trgm_ops);

        CREATE INDEX dokument_attr_egenskaber_idx_brugervendtnoegle
            ON dokument_attr_egenskaber
            USING btree
            (brugervendtnoegle); 
 
     
        CREATE INDEX dokument_attr_egenskaber_pat_beskrivelse
            ON dokument_attr_egenskaber
            USING gin
            (beskrivelse gin_trgm_ops);

        CREATE INDEX dokument_attr_egenskaber_idx_beskrivelse
            ON dokument_attr_egenskaber
            USING btree
            (beskrivelse); 
 
    
         
             
                CREATE INDEX dokument_attr_egenskaber_idx_brevdato
                    ON dokument_attr_egenskaber
                    USING btree
                    (brevdato);

            
         
     
 
     
        CREATE INDEX dokument_attr_egenskaber_pat_kassationskode
            ON dokument_attr_egenskaber
            USING gin
            (kassationskode gin_trgm_ops);

        CREATE INDEX dokument_attr_egenskaber_idx_kassationskode
            ON dokument_attr_egenskaber
            USING btree
            (kassationskode); 
 
    
         
             
                CREATE INDEX dokument_attr_egenskaber_idx_major
                    ON dokument_attr_egenskaber
                    USING btree
                    (major);

            
         
     
 
    
         
             
                CREATE INDEX dokument_attr_egenskaber_idx_minor
                    ON dokument_attr_egenskaber
                    USING btree
                    (minor);

            
         
     
 
    
         
             
                CREATE INDEX dokument_attr_egenskaber_pat_AlternativTitel_offentlighedundtaget
                    ON dokument_attr_egenskaber
                    USING gin
                    ( ((offentlighedundtaget).AlternativTitel) gin_trgm_ops);

                CREATE INDEX dokument_attr_egenskaber_idx_AlternativTitel_offentlighedundtaget
                    ON dokument_attr_egenskaber
                    USING btree
                    (((offentlighedundtaget).AlternativTitel));

                CREATE INDEX dokument_attr_egenskaber_pat_Hjemmel_offentlighedundtaget
                    ON dokument_attr_egenskaber
                    USING gin
                    (((offentlighedundtaget).Hjemmel) gin_trgm_ops);

                CREATE INDEX dokument_attr_egenskaber_idx_Hjemmel_offentlighedundtaget
                    ON dokument_attr_egenskaber
                    USING btree
                    (((offentlighedundtaget).Hjemmel));
            
         
     
 
     
        CREATE INDEX dokument_attr_egenskaber_pat_titel
            ON dokument_attr_egenskaber
            USING gin
            (titel gin_trgm_ops);

        CREATE INDEX dokument_attr_egenskaber_idx_titel
            ON dokument_attr_egenskaber
            USING btree
            (titel); 
 
     
        CREATE INDEX dokument_attr_egenskaber_pat_dokumenttype
            ON dokument_attr_egenskaber
            USING gin
            (dokumenttype gin_trgm_ops);

        CREATE INDEX dokument_attr_egenskaber_idx_dokumenttype
            ON dokument_attr_egenskaber
            USING btree
            (dokumenttype); 



CREATE INDEX dokument_attr_egenskaber_idx_virkning_aktoerref
    ON dokument_attr_egenskaber
    USING btree
    (((virkning).aktoerref));

CREATE INDEX dokument_attr_egenskaber_idx_virkning_aktoertypekode
    ON dokument_attr_egenskaber
    USING btree
    (((virkning).aktoertypekode));

CREATE INDEX dokument_attr_egenskaber_idx_virkning_notetekst
    ON dokument_attr_egenskaber
    USING btree
    (((virkning).notetekst));

CREATE INDEX dokument_attr_egenskaber_pat_virkning_notetekst
    ON dokument_attr_egenskaber
    USING gin
    (((virkning).notetekst) gin_trgm_ops);







/****************************************************************************/



CREATE SEQUENCE dokument_tils_fremdrift_id_seq
    INCREMENT 1
    MINVALUE 1
    MAXVALUE 9223372036854775807
    START 1
    CACHE 1;
ALTER TABLE dokument_tils_fremdrift_id_seq
    OWNER TO mox;


CREATE TABLE dokument_tils_fremdrift (
    id bigint NOT NULL DEFAULT nextval('dokument_tils_fremdrift_id_seq'::regclass),
    virkning Virkning NOT NULL CHECK( (virkning).TimePeriod IS NOT NULL AND not isempty((virkning).TimePeriod) ),
    fremdrift DokumentFremdriftTils NOT NULL, 
    dokument_registrering_id bigint not null,
    CONSTRAINT dokument_tils_fremdrift_pkey PRIMARY KEY (id),
    CONSTRAINT dokument_tils_fremdrift_forkey_dokumentregistrering FOREIGN KEY (dokument_registrering_id) REFERENCES dokument_registrering (id) MATCH SIMPLE ON UPDATE NO ACTION ON DELETE NO ACTION,
    CONSTRAINT dokument_tils_fremdrift_exclude_virkning_overlap EXCLUDE USING gist (dokument_registrering_id WITH =, _composite_type_to_time_range(virkning) WITH &&)
)
WITH (
    OIDS=FALSE
);

ALTER TABLE dokument_tils_fremdrift
    OWNER TO mox;


CREATE INDEX dokument_tils_fremdrift_idx_fremdrift
    ON dokument_tils_fremdrift
    USING btree
    (fremdrift);
  
CREATE INDEX dokument_tils_fremdrift_idx_virkning_aktoerref
    ON dokument_tils_fremdrift
    USING btree
    (((virkning).aktoerref));

CREATE INDEX dokument_tils_fremdrift_idx_virkning_aktoertypekode
    ON dokument_tils_fremdrift
    USING btree
    (((virkning).aktoertypekode));

CREATE INDEX dokument_tils_fremdrift_idx_virkning_notetekst
    ON dokument_tils_fremdrift
    USING btree
    (((virkning).notetekst));

CREATE INDEX dokument_tils_fremdrift_pat_virkning_notetekst
    ON dokument_tils_fremdrift
    USING gin
    (((virkning).notetekst) gin_trgm_ops);



/****************************************************************************/

CREATE SEQUENCE dokument_relation_id_seq
    INCREMENT 1
    MINVALUE 1
    MAXVALUE 9223372036854775807
    START 1
    CACHE 1;
ALTER TABLE dokument_relation_id_seq
    OWNER TO mox;


CREATE TABLE dokument_relation (
    id bigint NOT NULL DEFAULT nextval('dokument_relation_id_seq'::regclass),
    dokument_registrering_id bigint not null,
    virkning Virkning not null CHECK((virkning).TimePeriod IS NOT NULL AND not isempty((virkning).TimePeriod) ),
    --we have to allow null values (for now at least), as it is needed to be able to clear/overrule previous registered relations.
    rel_maal_uuid uuid NULL,
    rel_maal_urn text null,
    rel_type DokumentRelationKode not null,
    objekt_type text null,

    

    CONSTRAINT dokument_relation_forkey_dokumentregistrering FOREIGN KEY (dokument_registrering_id) REFERENCES dokument_registrering (id) MATCH SIMPLE ON UPDATE NO ACTION ON DELETE NO ACTION,
    CONSTRAINT dokument_relation_pkey PRIMARY KEY (id),
    CONSTRAINT dokument_relation_no_virkning_overlap EXCLUDE USING gist (dokument_registrering_id WITH =, _as_convert_dokument_relation_kode_to_txt(rel_type) WITH =, _composite_type_to_time_range(virkning) WITH &&)  WHERE ( rel_type<>('arkiver'::DokumentRelationKode ) AND rel_type<>('besvarelser'::DokumentRelationKode ) AND rel_type<>('udgangspunkter'::DokumentRelationKode ) AND rel_type<>('kommentarer'::DokumentRelationKode ) AND rel_type<>('bilag'::DokumentRelationKode ) AND rel_type<>('andredokumenter'::DokumentRelationKode ) AND rel_type<>('andreklasser'::DokumentRelationKode ) AND rel_type<>('andrebehandlere'::DokumentRelationKode ) AND rel_type<>('parter'::DokumentRelationKode ) AND rel_type<>('kopiparter'::DokumentRelationKode ) AND rel_type<>('tilknyttedesager'::DokumentRelationKode )) ,-- no overlapping virkning except for 0..n --relations
    CONSTRAINT dokument_relation_either_uri_or_urn CHECK (NOT (rel_maal_uuid IS NOT NULL AND (rel_maal_urn IS NOT NULL AND rel_maal_urn<>'')))
);





CREATE INDEX dokument_relation_idx_rel_maal_obj_uuid
    ON dokument_relation
    USING btree
    (rel_type,objekt_type,rel_maal_uuid);



CREATE INDEX dokument_relation_idx_rel_maal_obj_urn
    ON dokument_relation
    USING btree
    (rel_type,objekt_type,rel_maal_urn);

CREATE INDEX dokument_relation_idx_rel_maal_uuid
    ON dokument_relation
    USING btree
    (rel_type, rel_maal_uuid);

CREATE INDEX dokument_relation_idx_rel_maal_uuid_isolated
    ON dokument_relation
    USING btree
    (rel_maal_uuid);

CREATE INDEX dokument_relation_idx_rel_maal_urn_isolated
    ON dokument_relation
    USING btree
    (rel_maal_urn);

CREATE INDEX dokument_relation_idx_rel_maal_urn
    ON dokument_relation
    USING btree
    (rel_type, rel_maal_urn);

CREATE INDEX dokument_relation_idx_virkning_aktoerref
    ON dokument_relation
    USING btree
    (((virkning).aktoerref));

CREATE INDEX dokument_relation_idx_virkning_aktoertypekode
    ON dokument_relation
    USING btree
    (((virkning).aktoertypekode));

CREATE INDEX dokument_relation_idx_virkning_notetekst
    ON dokument_relation
    USING btree
    (((virkning).notetekst));

CREATE INDEX dokument_relation_pat_virkning_notetekst
    ON dokument_relation
    USING gin
    (((virkning).notetekst) gin_trgm_ops);



/**********************************************************************/
/*                        dokument variant                            */
/**********************************************************************/

CREATE SEQUENCE dokument_variant_id_seq
    INCREMENT 1
    MINVALUE 1
    MAXVALUE 9223372036854775807
    START 1
    CACHE 1;
ALTER TABLE dokument_variant_id_seq
    OWNER TO mox;


CREATE TABLE dokument_variant(
    id bigint not null DEFAULT nextval('dokument_variant_id_seq'::regclass),
    varianttekst text NOT NULL,
    dokument_registrering_id bigint not null,
    UNIQUE(dokument_registrering_id,varianttekst),
    CONSTRAINT dokument_variant_pkey PRIMARY KEY (id),
    CONSTRAINT dokument_variant_forkey_dokumentregistrering  FOREIGN KEY (dokument_registrering_id) REFERENCES dokument_registrering (id) MATCH SIMPLE ON UPDATE NO ACTION ON DELETE NO ACTION
)
WITH (
  OIDS=FALSE
);

ALTER TABLE dokument_variant
  OWNER TO mox;


CREATE SEQUENCE dokument_variant_egenskaber_id_seq
    INCREMENT 1
    MINVALUE 1
    MAXVALUE 9223372036854775807
    START 1
    CACHE 1;
ALTER TABLE dokument_variant_egenskaber_id_seq
    OWNER TO mox;


CREATE TABLE dokument_variant_egenskaber(
    id bigint NOT NULL DEFAULT nextval('dokument_variant_egenskaber_id_seq'::regclass), 
    variant_id bigint not null, 
    arkivering boolean null, 
    delvisscannet boolean null, 
    offentliggoerelse boolean null, 
    produktion boolean null, 
    virkning Virkning not null CHECK( (virkning).TimePeriod IS NOT NULL AND not isempty((virkning).TimePeriod) ),
    CONSTRAINT dokument_variant_egenskaber_pkey PRIMARY KEY (id),
    CONSTRAINT dokument_variant_egenskaber_forkey_dokumentvariant FOREIGN KEY (variant_id) REFERENCES dokument_variant (id) MATCH SIMPLE ON UPDATE NO ACTION ON DELETE NO ACTION,
    CONSTRAINT dokument_variant_egenskaber_exclude_virkning_overlap EXCLUDE USING gist (variant_id WITH =, _composite_type_to_time_range(virkning) WITH &&)
)
WITH (
  OIDS=FALSE
);
ALTER TABLE dokument_variant_egenskaber
    OWNER TO mox;

 
CREATE INDEX dokument_variant_egenskaber_idx_arkivering
    ON dokument_variant_egenskaber
    USING btree
    (arkivering); 

CREATE INDEX dokument_variant_egenskaber_idx_delvisscannet
    ON dokument_variant_egenskaber
    USING btree
    (delvisscannet); 
 
CREATE INDEX dokument_variant_egenskaber_idx_offentliggoerelse
    ON dokument_variant_egenskaber
    USING btree
    (offentliggoerelse); 
 
CREATE INDEX dokument_variant_egenskaber_idx_produktion
    ON dokument_variant_egenskaber
    USING btree
    (produktion); 

CREATE INDEX dokument_variant_egenskaber_idx_virkning_aktoerref
    ON dokument_variant_egenskaber
    USING btree
    (((virkning).aktoerref));

CREATE INDEX dokument_variant_egenskaber_idx_virkning_aktoertypekode
    ON dokument_variant_egenskaber
    USING btree
    (((virkning).aktoertypekode));

CREATE INDEX dokument_variant_egenskaber_idx_virkning_notetekst
    ON dokument_variant_egenskaber
    USING btree
    (((virkning).notetekst));

CREATE INDEX dokument_variant_egenskaber_pat_virkning_notetekst
    ON dokument_variant_egenskaber
    USING gin
    (((virkning).notetekst) gin_trgm_ops);


/**********************************************************************/
/*                        dokument del                                */
/**********************************************************************/

CREATE SEQUENCE dokument_del_id_seq
    INCREMENT 1
    MINVALUE 1
    MAXVALUE 9223372036854775807
    START 1
    CACHE 1;
ALTER TABLE dokument_del_id_seq
    OWNER TO mox;


CREATE TABLE dokument_del(
    id bigint not null DEFAULT nextval('dokument_del_id_seq'::regclass),
    deltekst text NOT NULL,
    variant_id bigint not null,
    UNIQUE (variant_id, deltekst),
    CONSTRAINT dokument_del_forkey_variant_id FOREIGN KEY (variant_id) REFERENCES dokument_variant (id) MATCH SIMPLE ON UPDATE NO ACTION ON DELETE NO ACTION,
    CONSTRAINT dokument_del_pkey PRIMARY KEY (id)
)
WITH (
    OIDS=FALSE
);

ALTER TABLE dokument_del
    OWNER TO mox;


CREATE SEQUENCE dokument_del_egenskaber_id_seq
    INCREMENT 1
    MINVALUE 1
    MAXVALUE 9223372036854775807
    START 1
    CACHE 1;
ALTER TABLE dokument_del_egenskaber_id_seq
    OWNER TO mox;


CREATE TABLE dokument_del_egenskaber(
    id bigint NOT NULL DEFAULT nextval('dokument_del_egenskaber_id_seq'::regclass), 
    del_id bigint NOT NULL,
    indeks int null, 
    indhold text null, 
    lokation text null, 
    mimetype text null, 
    virkning Virkning not null CHECK( (virkning).TimePeriod IS NOT NULL AND not isempty((virkning).TimePeriod) ),
    CONSTRAINT dokument_del_egenskaber_pkey PRIMARY KEY (id),
    CONSTRAINT dokument_del_egenskaber_forkey_dokument_del FOREIGN KEY (del_id) REFERENCES dokument_del (id) MATCH SIMPLE ON UPDATE NO ACTION ON DELETE NO ACTION,
    CONSTRAINT dokument_del_egenskaber_exclude_virkning_overlap EXCLUDE USING gist (del_id WITH =, _composite_type_to_time_range(virkning) WITH &&)
)
WITH (
    OIDS=FALSE
);

ALTER TABLE dokument_del_egenskaber
    OWNER TO mox;

CREATE INDEX dokument_del_egenskaber_idx_indeks
    ON dokument_del_egenskaber
    USING btree
    (indeks); 
 
CREATE INDEX dokument_del_egenskaber_pat_indhold
    ON dokument_del_egenskaber
    USING gin
    (indhold gin_trgm_ops);

CREATE INDEX dokument_del_egenskaber_idx_indhold
    ON dokument_del_egenskaber
    USING btree
    (indhold); 
 
CREATE INDEX dokument_del_egenskaber_pat_lokation
    ON dokument_del_egenskaber
    USING gin
    (lokation gin_trgm_ops);

CREATE INDEX dokument_del_egenskaber_idx_lokation
    ON dokument_del_egenskaber
    USING btree
    (lokation); 
 
CREATE INDEX dokument_del_egenskaber_pat_mimetype
    ON dokument_del_egenskaber
    USING gin
    (mimetype gin_trgm_ops);

CREATE INDEX dokument_del_egenskaber_idx_mimetype
    ON dokument_del_egenskaber
    USING btree
    (mimetype); 

CREATE INDEX dokument_del_egenskaber_idx_virkning_aktoerref
    ON dokument_del_egenskaber
    USING btree
    (((virkning).aktoerref));

CREATE INDEX dokument_del_egenskaber_idx_virkning_aktoertypekode
    ON dokument_del_egenskaber
    USING btree
    (((virkning).aktoertypekode));

CREATE INDEX dokument_del_egenskaber_idx_virkning_notetekst
    ON dokument_del_egenskaber
    USING btree
    (((virkning).notetekst));

CREATE INDEX dokument_del_egenskaber_pat_virkning_notetekst
    ON dokument_del_egenskaber
    USING gin
    (((virkning).notetekst) gin_trgm_ops);

CREATE SEQUENCE dokument_del_relation_id_seq
  INCREMENT 1
  MINVALUE 1
  MAXVALUE 9223372036854775807
  START 1
  CACHE 1;

ALTER TABLE dokument_del_relation_id_seq
  OWNER TO mox;


CREATE TABLE dokument_del_relation (
    id bigint NOT NULL DEFAULT nextval('dokument_del_relation_id_seq'::regclass),
    del_id bigint not null,
    virkning Virkning not null CHECK( (virkning).TimePeriod IS NOT NULL AND not isempty((virkning).TimePeriod) ),
    rel_maal_uuid uuid NULL, 
    rel_maal_urn text null,
    rel_type DokumentdelRelationKode not null,
    objekt_type text null,
    CONSTRAINT dokument_del_relation_forkey_dokument_del FOREIGN KEY (del_id) REFERENCES dokument_del (id) MATCH SIMPLE ON UPDATE NO ACTION ON DELETE NO ACTION,
    CONSTRAINT dokument_del_relation_pkey PRIMARY KEY (id),
    -- CONSTRAINT dokument_del_relation_no_virkning_overlap EXCLUDE USING gist (dokument_del_registrering_id WITH =, _as_convert_dokument_del_relation_kode_to_txt(rel_type) WITH =, _composite_type_to_time_range(virkning) WITH &&)  WHERE ( rel_type<>('underredigeringaf'::dokument_delRelationKode )) ,-- no overlapping virkning except for 0..n --relations
    CONSTRAINT dokument_del_relation_either_uri_or_urn CHECK (NOT (rel_maal_uuid IS NOT NULL AND (rel_maal_urn IS NOT NULL AND rel_maal_urn<>'')))
);


CREATE INDEX dokument_del_relation_idx_rel_maal_obj_uuid
    ON dokument_del_relation
    USING btree
    (rel_type,objekt_type,rel_maal_uuid);

CREATE INDEX dokument_del_relation_idx_rel_maal_obj_urn
    ON dokument_del_relation
    USING btree
    (rel_type,objekt_type,rel_maal_urn);

CREATE INDEX dokument_del_relation_idx_rel_maal_uuid
    ON dokument_del_relation
    USING btree
    (rel_type, rel_maal_uuid);

CREATE INDEX dokument_del_relation_idx_rel_maal_uuid_isolated
    ON dokument_del_relation
    USING btree
    (rel_maal_uuid);

CREATE INDEX dokument_del_relation_idx_rel_maal_urn_isolated
    ON dokument_del_relation
    USING btree
    (rel_maal_urn);

CREATE INDEX dokument_del_relation_idx_rel_maal_urn
    ON dokument_del_relation
    USING btree
    (rel_type, rel_maal_urn);

CREATE INDEX dokument_del_relation_idx_virkning_aktoerref
    ON dokument_del_relation
    USING btree
    (((virkning).aktoerref));

CREATE INDEX dokument_del_relation_idx_virkning_aktoertypekode
    ON dokument_del_relation
    USING btree
    (((virkning).aktoertypekode));

CREATE INDEX dokument_del_relation_idx_virkning_notetekst
    ON dokument_del_relation
    USING btree
    (((virkning).notetekst));

CREATE INDEX dokument_del_relation_pat_virkning_notetekst
    ON dokument_del_relation
    USING gin
    (((virkning).notetekst) gin_trgm_ops);


