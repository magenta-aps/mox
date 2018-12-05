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

CREATE OR REPLACE FUNCTION _as_convert_itsystem_relation_kode_to_txt(
    ItsystemRelationKode
) RETURNS TEXT LANGUAGE sql STRICT IMMUTABLE AS $$
    SELECT $1::text;
$$;


/****************************** TBLS DEFS ***********************************/

CREATE TABLE itsystem (
    id uuid NOT NULL,
    CONSTRAINT itsystem_pkey PRIMARY KEY (id)
)
WITH (
    OIDS=FALSE
);
ALTER TABLE itsystem
    OWNER TO mox;


/****************************************************************************/

CREATE SEQUENCE itsystem_registrering_id_seq
    INCREMENT 1
    MINVALUE 1
    MAXVALUE 9223372036854775807
    START 1
    CACHE 1;
ALTER TABLE itsystem_registrering_id_seq
    OWNER TO mox;


CREATE TABLE itsystem_registrering (
   id bigint NOT NULL DEFAULT nextval('itsystem_registrering_id_seq'::regclass),
   itsystem_id uuid NOT NULL ,
   registrering RegistreringBase NOT NULL CHECK( (registrering).TimePeriod IS NOT NULL AND not isempty((registrering).timeperiod) ),
   CONSTRAINT itsystem_registrering_pkey PRIMARY KEY (id),
   CONSTRAINT itsystem_registrering_itsystem_fkey FOREIGN KEY (itsystem_id)
       REFERENCES itsystem (id) MATCH SIMPLE
       ON UPDATE NO ACTION ON DELETE NO ACTION,
   CONSTRAINT itsystem_registrering__uuid_to_text_timeperiod_excl EXCLUDE 
   USING gist (_uuid_to_text(itsystem_id) WITH =, _composite_type_to_time_range(registrering) WITH &&)
)
WITH (
  OIDS=FALSE
);

ALTER TABLE itsystem_registrering
  OWNER TO mox;


CREATE INDEX itsystem_registrering_idx_livscykluskode
    ON itsystem_registrering
    USING btree
    (((registrering).livscykluskode));


CREATE INDEX itsystem_registrering_idx_brugerref
    ON itsystem_registrering
    USING btree
    (((registrering).brugerref));


CREATE INDEX itsystem_registrering_idx_note
    ON itsystem_registrering
    USING btree
    (((registrering).note));


CREATE INDEX itsystem_registrering_pat_note
    ON itsystem_registrering
    USING gin
    (((registrering).note) gin_trgm_ops);


CREATE INDEX itsystem_id_idx
    ON itsystem_registrering (itsystem_id);


CREATE TRIGGER notify_itsystem
    AFTER INSERT OR UPDATE OR DELETE ON itsystem_registrering
    FOR EACH ROW EXECUTE PROCEDURE notify_event();


/****************************************************************************/



CREATE SEQUENCE itsystem_attr_egenskaber_id_seq
    INCREMENT 1
    MINVALUE 1
    MAXVALUE 9223372036854775807
    START 1
    CACHE 1;

ALTER TABLE itsystem_attr_egenskaber_id_seq
    OWNER TO mox;


CREATE TABLE itsystem_attr_egenskaber (
    id bigint NOT NULL DEFAULT nextval('itsystem_attr_egenskaber_id_seq'::regclass), 
       brugervendtnoegle text null, 
       itsystemnavn text null, 
       itsystemtype text null, 
       konfigurationreference 
           text[]
        null, 
    virkning Virkning not null CHECK( (virkning).TimePeriod IS NOT NULL AND not isempty((virkning).TimePeriod) ),
    itsystem_registrering_id bigint not null,
    CONSTRAINT itsystem_attr_egenskaber_pkey PRIMARY KEY (id),
    CONSTRAINT itsystem_attr_egenskaber_forkey_itsystemregistrering FOREIGN KEY (itsystem_registrering_id) REFERENCES itsystem_registrering (id) MATCH SIMPLE ON UPDATE NO ACTION ON DELETE NO ACTION,
    CONSTRAINT itsystem_attr_egenskaber_exclude_virkning_overlap EXCLUDE USING gist (itsystem_registrering_id WITH =, _composite_type_to_time_range(virkning) WITH &&)
)
WITH (
    OIDS=FALSE
);

ALTER TABLE itsystem_attr_egenskaber
  OWNER TO mox;


 
     
        CREATE INDEX itsystem_attr_egenskaber_pat_brugervendtnoegle
            ON itsystem_attr_egenskaber
            USING gin
            (brugervendtnoegle gin_trgm_ops);

        CREATE INDEX itsystem_attr_egenskaber_idx_brugervendtnoegle
            ON itsystem_attr_egenskaber
            USING btree
            (brugervendtnoegle); 
 
     
        CREATE INDEX itsystem_attr_egenskaber_pat_itsystemnavn
            ON itsystem_attr_egenskaber
            USING gin
            (itsystemnavn gin_trgm_ops);

        CREATE INDEX itsystem_attr_egenskaber_idx_itsystemnavn
            ON itsystem_attr_egenskaber
            USING btree
            (itsystemnavn); 
 
     
        CREATE INDEX itsystem_attr_egenskaber_pat_itsystemtype
            ON itsystem_attr_egenskaber
            USING gin
            (itsystemtype gin_trgm_ops);

        CREATE INDEX itsystem_attr_egenskaber_idx_itsystemtype
            ON itsystem_attr_egenskaber
            USING btree
            (itsystemtype); 
 
    
        
            CREATE INDEX itsystem_attr_egenskaber_pat_konfigurationreference
            ON itsystem_attr_egenskaber
            USING gin
            (konfigurationreference _text_ops);
         
     



CREATE INDEX itsystem_attr_egenskaber_idx_virkning_aktoerref
    ON itsystem_attr_egenskaber
    USING btree
    (((virkning).aktoerref));

CREATE INDEX itsystem_attr_egenskaber_idx_virkning_aktoertypekode
    ON itsystem_attr_egenskaber
    USING btree
    (((virkning).aktoertypekode));

CREATE INDEX itsystem_attr_egenskaber_idx_virkning_notetekst
    ON itsystem_attr_egenskaber
    USING btree
    (((virkning).notetekst));

CREATE INDEX itsystem_attr_egenskaber_pat_virkning_notetekst
    ON itsystem_attr_egenskaber
    USING gin
    (((virkning).notetekst) gin_trgm_ops);







/****************************************************************************/



CREATE SEQUENCE itsystem_tils_gyldighed_id_seq
    INCREMENT 1
    MINVALUE 1
    MAXVALUE 9223372036854775807
    START 1
    CACHE 1;
ALTER TABLE itsystem_tils_gyldighed_id_seq
    OWNER TO mox;


CREATE TABLE itsystem_tils_gyldighed (
    id bigint NOT NULL DEFAULT nextval('itsystem_tils_gyldighed_id_seq'::regclass),
    virkning Virkning NOT NULL CHECK( (virkning).TimePeriod IS NOT NULL AND not isempty((virkning).TimePeriod) ),
    gyldighed ItsystemGyldighedTils NOT NULL, 
    itsystem_registrering_id bigint not null,
    CONSTRAINT itsystem_tils_gyldighed_pkey PRIMARY KEY (id),
    CONSTRAINT itsystem_tils_gyldighed_forkey_itsystemregistrering FOREIGN KEY (itsystem_registrering_id) REFERENCES itsystem_registrering (id) MATCH SIMPLE ON UPDATE NO ACTION ON DELETE NO ACTION,
    CONSTRAINT itsystem_tils_gyldighed_exclude_virkning_overlap EXCLUDE USING gist (itsystem_registrering_id WITH =, _composite_type_to_time_range(virkning) WITH &&)
)
WITH (
    OIDS=FALSE
);

ALTER TABLE itsystem_tils_gyldighed
    OWNER TO mox;


CREATE INDEX itsystem_tils_gyldighed_idx_gyldighed
    ON itsystem_tils_gyldighed
    USING btree
    (gyldighed);
  
CREATE INDEX itsystem_tils_gyldighed_idx_virkning_aktoerref
    ON itsystem_tils_gyldighed
    USING btree
    (((virkning).aktoerref));

CREATE INDEX itsystem_tils_gyldighed_idx_virkning_aktoertypekode
    ON itsystem_tils_gyldighed
    USING btree
    (((virkning).aktoertypekode));

CREATE INDEX itsystem_tils_gyldighed_idx_virkning_notetekst
    ON itsystem_tils_gyldighed
    USING btree
    (((virkning).notetekst));

CREATE INDEX itsystem_tils_gyldighed_pat_virkning_notetekst
    ON itsystem_tils_gyldighed
    USING gin
    (((virkning).notetekst) gin_trgm_ops);



/****************************************************************************/

CREATE SEQUENCE itsystem_relation_id_seq
    INCREMENT 1
    MINVALUE 1
    MAXVALUE 9223372036854775807
    START 1
    CACHE 1;
ALTER TABLE itsystem_relation_id_seq
    OWNER TO mox;


CREATE TABLE itsystem_relation (
    id bigint NOT NULL DEFAULT nextval('itsystem_relation_id_seq'::regclass),
    itsystem_registrering_id bigint not null,
    virkning Virkning not null CHECK((virkning).TimePeriod IS NOT NULL AND not isempty((virkning).TimePeriod) ),
    --we have to allow null values (for now at least), as it is needed to be able to clear/overrule previous registered relations.
    rel_maal_uuid uuid NULL,
    rel_maal_urn text null,
    rel_type ItsystemRelationKode not null,
    objekt_type text null,

    

    CONSTRAINT itsystem_relation_forkey_itsystemregistrering FOREIGN KEY (itsystem_registrering_id) REFERENCES itsystem_registrering (id) MATCH SIMPLE ON UPDATE NO ACTION ON DELETE NO ACTION,
    CONSTRAINT itsystem_relation_pkey PRIMARY KEY (id),
    CONSTRAINT itsystem_relation_no_virkning_overlap EXCLUDE USING gist (itsystem_registrering_id WITH =, _as_convert_itsystem_relation_kode_to_txt(rel_type) WITH =, _composite_type_to_time_range(virkning) WITH &&)  WHERE ( rel_type<>('tilknyttedeorganisationer'::ItsystemRelationKode ) AND rel_type<>('tilknyttedeenheder'::ItsystemRelationKode ) AND rel_type<>('tilknyttedefunktioner'::ItsystemRelationKode ) AND rel_type<>('tilknyttedebrugere'::ItsystemRelationKode ) AND rel_type<>('tilknyttedeinteressefaellesskaber'::ItsystemRelationKode ) AND rel_type<>('tilknyttedeitsystemer'::ItsystemRelationKode ) AND rel_type<>('tilknyttedepersoner'::ItsystemRelationKode ) AND rel_type<>('systemtyper'::ItsystemRelationKode ) AND rel_type<>('opgaver'::ItsystemRelationKode ) AND rel_type<>('adresser'::ItsystemRelationKode )) ,-- no overlapping virkning except for 0..n --relations
    CONSTRAINT itsystem_relation_either_uri_or_urn CHECK (NOT (rel_maal_uuid IS NOT NULL AND (rel_maal_urn IS NOT NULL AND rel_maal_urn<>'')))
);





CREATE INDEX itsystem_relation_idx_rel_maal_obj_uuid
    ON itsystem_relation
    USING btree
    (rel_type,objekt_type,rel_maal_uuid);



CREATE INDEX itsystem_relation_idx_rel_maal_obj_urn
    ON itsystem_relation
    USING btree
    (rel_type,objekt_type,rel_maal_urn);

CREATE INDEX itsystem_relation_idx_rel_maal_uuid
    ON itsystem_relation
    USING btree
    (rel_type, rel_maal_uuid);

CREATE INDEX itsystem_relation_idx_rel_maal_uuid_isolated
    ON itsystem_relation
    USING btree
    (rel_maal_uuid);

CREATE INDEX itsystem_relation_idx_rel_maal_urn_isolated
    ON itsystem_relation
    USING btree
    (rel_maal_urn);

CREATE INDEX itsystem_relation_idx_rel_maal_urn
    ON itsystem_relation
    USING btree
    (rel_type, rel_maal_urn);

CREATE INDEX itsystem_relation_idx_virkning_aktoerref
    ON itsystem_relation
    USING btree
    (((virkning).aktoerref));

CREATE INDEX itsystem_relation_idx_virkning_aktoertypekode
    ON itsystem_relation
    USING btree
    (((virkning).aktoertypekode));

CREATE INDEX itsystem_relation_idx_virkning_notetekst
    ON itsystem_relation
    USING btree
    (((virkning).notetekst));

CREATE INDEX itsystem_relation_pat_virkning_notetekst
    ON itsystem_relation
    USING gin
    (((virkning).notetekst) gin_trgm_ops);




