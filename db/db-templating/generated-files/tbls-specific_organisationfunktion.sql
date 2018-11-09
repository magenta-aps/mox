-- Copyright (C) 2015 Magenta ApS, http://magenta.dk.
-- Contact: info@magenta.dk.
--
-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at http://mozilla.org/MPL/2.0/.

/*
NOTICE: This file is auto-generated using the script: apply-template.py organisationfunktion tbls-specific.jinja.sql
*/

/******************** FUNCTIONS (NEEDED FOR TABLE/INDEX-DEFS) DEFS ***********************************/

CREATE or replace FUNCTION _as_convert_organisationfunktion_relation_kode_to_txt (
  OrganisationfunktionRelationKode
    ) 
RETURNS TEXT 
LANGUAGE sql STRICT IMMUTABLE 
AS $$
        SELECT $1::text;
   $$;

/******************** TBLS DEFS ***********************************/


CREATE TABLE organisationfunktion
(
 id uuid NOT NULL,
  CONSTRAINT organisationfunktion_pkey PRIMARY KEY (id)
)
WITH (
  OIDS=FALSE
);
ALTER TABLE organisationfunktion
  OWNER TO mox;

/****************************************************************************************************/
CREATE SEQUENCE organisationfunktion_registrering_id_seq
  INCREMENT 1
  MINVALUE 1
  MAXVALUE 9223372036854775807
  START 1
  CACHE 1;
ALTER TABLE organisationfunktion_registrering_id_seq
  OWNER TO mox;


CREATE TABLE organisationfunktion_registrering
(
 id bigint NOT NULL DEFAULT nextval('organisationfunktion_registrering_id_seq'::regclass),
 organisationfunktion_id uuid NOT NULL ,
 registrering RegistreringBase NOT NULL CHECK( (registrering).TimePeriod IS NOT NULL AND not isempty((registrering).timeperiod) ),
  CONSTRAINT organisationfunktion_registrering_pkey PRIMARY KEY (id),
  CONSTRAINT organisationfunktion_registrering_organisationfunktion_fkey FOREIGN KEY (organisationfunktion_id)
      REFERENCES organisationfunktion (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT organisationfunktion_registrering__uuid_to_text_timeperiod_excl EXCLUDE 
  USING gist (_uuid_to_text(organisationfunktion_id) WITH =, _composite_type_to_time_range(registrering) WITH &&)
)
WITH (
  OIDS=FALSE
);
ALTER TABLE organisationfunktion_registrering
  OWNER TO mox;

CREATE INDEX organisationfunktion_registrering_idx_livscykluskode
  ON organisationfunktion_registrering
  USING btree
  (((registrering).livscykluskode));

CREATE INDEX organisationfunktion_registrering_idx_brugerref
  ON organisationfunktion_registrering
  USING btree
  (((registrering).brugerref));

CREATE INDEX organisationfunktion_registrering_idx_note
  ON organisationfunktion_registrering
  USING btree
  (((registrering).note));

CREATE INDEX organisationfunktion_registrering_pat_note
  ON organisationfunktion_registrering
  USING  gin
  (((registrering).note) gin_trgm_ops);

CREATE INDEX organisationfunktion_id_idx
   ON organisationfunktion_registrering (organisationfunktion_id);


CREATE TRIGGER notify_organisationfunktion
    AFTER INSERT OR UPDATE OR DELETE ON organisationfunktion_registrering
    FOR EACH ROW EXECUTE PROCEDURE notify_event();

/****************************************************************************************************/


CREATE SEQUENCE organisationfunktion_attr_egenskaber_id_seq
  INCREMENT 1
  MINVALUE 1
  MAXVALUE 9223372036854775807
  START 1
  CACHE 1;
ALTER TABLE organisationfunktion_attr_egenskaber_id_seq
  OWNER TO mox;




CREATE TABLE organisationfunktion_attr_egenskaber
(
  id bigint NOT NULL DEFAULT nextval('organisationfunktion_attr_egenskaber_id_seq'::regclass), 
   brugervendtnoegle text null, 
   funktionsnavn text null, 
   virkning Virkning not null CHECK( (virkning).TimePeriod IS NOT NULL AND not isempty((virkning).TimePeriod) ),
  organisationfunktion_registrering_id bigint not null,
CONSTRAINT organisationfunktion_attr_egenskaber_pkey PRIMARY KEY (id),
CONSTRAINT organisationfunktion_attr_egenskaber_forkey_organisationfunktionregistrering  FOREIGN KEY (organisationfunktion_registrering_id) REFERENCES organisationfunktion_registrering (id) MATCH SIMPLE ON UPDATE NO ACTION ON DELETE NO ACTION,
CONSTRAINT organisationfunktion_attr_egenskaber_exclude_virkning_overlap EXCLUDE USING gist (organisationfunktion_registrering_id WITH =, _composite_type_to_time_range(virkning) WITH &&)
)
WITH (
  OIDS=FALSE
);
ALTER TABLE organisationfunktion_attr_egenskaber
  OWNER TO mox;

 
CREATE INDEX organisationfunktion_attr_egenskaber_pat_brugervendtnoegle
  ON organisationfunktion_attr_egenskaber
  USING gin
  (brugervendtnoegle gin_trgm_ops);

CREATE INDEX organisationfunktion_attr_egenskaber_idx_brugervendtnoegle
  ON organisationfunktion_attr_egenskaber
  USING btree
  (brugervendtnoegle); 

 
CREATE INDEX organisationfunktion_attr_egenskaber_pat_funktionsnavn
  ON organisationfunktion_attr_egenskaber
  USING gin
  (funktionsnavn gin_trgm_ops);

CREATE INDEX organisationfunktion_attr_egenskaber_idx_funktionsnavn
  ON organisationfunktion_attr_egenskaber
  USING btree
  (funktionsnavn); 




CREATE INDEX organisationfunktion_attr_egenskaber_idx_virkning_aktoerref
  ON organisationfunktion_attr_egenskaber
  USING btree
  (((virkning).aktoerref));

CREATE INDEX organisationfunktion_attr_egenskaber_idx_virkning_aktoertypekode
  ON organisationfunktion_attr_egenskaber
  USING btree
  (((virkning).aktoertypekode));

CREATE INDEX organisationfunktion_attr_egenskaber_idx_virkning_notetekst
  ON organisationfunktion_attr_egenskaber
  USING btree
  (((virkning).notetekst));

CREATE INDEX organisationfunktion_attr_egenskaber_pat_virkning_notetekst
  ON organisationfunktion_attr_egenskaber
  USING gin
  (((virkning).notetekst) gin_trgm_ops);



/****************************************************************************************************/



CREATE SEQUENCE organisationfunktion_tils_gyldighed_id_seq
  INCREMENT 1
  MINVALUE 1
  MAXVALUE 9223372036854775807
  START 1
  CACHE 1;
ALTER TABLE organisationfunktion_tils_gyldighed_id_seq
  OWNER TO mox;


CREATE TABLE organisationfunktion_tils_gyldighed
(
  id bigint NOT NULL DEFAULT nextval('organisationfunktion_tils_gyldighed_id_seq'::regclass),
  virkning Virkning  NOT NULL CHECK( (virkning).TimePeriod IS NOT NULL AND not isempty((virkning).TimePeriod) ),
  gyldighed OrganisationfunktionGyldighedTils NOT NULL, 
  organisationfunktion_registrering_id bigint not null,
  CONSTRAINT organisationfunktion_tils_gyldighed_pkey PRIMARY KEY (id),
  CONSTRAINT organisationfunktion_tils_gyldighed_forkey_organisationfunktionregistrering  FOREIGN KEY (organisationfunktion_registrering_id) REFERENCES organisationfunktion_registrering (id) MATCH SIMPLE ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT organisationfunktion_tils_gyldighed_exclude_virkning_overlap EXCLUDE USING gist (organisationfunktion_registrering_id WITH =, _composite_type_to_time_range(virkning) WITH &&)
)
 
WITH (
  OIDS=FALSE
);
ALTER TABLE organisationfunktion_tils_gyldighed
  OWNER TO mox;

CREATE INDEX organisationfunktion_tils_gyldighed_idx_gyldighed
  ON organisationfunktion_tils_gyldighed
  USING btree
  (gyldighed);
  

CREATE INDEX organisationfunktion_tils_gyldighed_idx_virkning_aktoerref
  ON organisationfunktion_tils_gyldighed
  USING btree
  (((virkning).aktoerref));

CREATE INDEX organisationfunktion_tils_gyldighed_idx_virkning_aktoertypekode
  ON organisationfunktion_tils_gyldighed
  USING btree
  (((virkning).aktoertypekode));

CREATE INDEX organisationfunktion_tils_gyldighed_idx_virkning_notetekst
  ON organisationfunktion_tils_gyldighed
  USING btree
  (((virkning).notetekst));

CREATE INDEX organisationfunktion_tils_gyldighed_pat_virkning_notetekst
  ON organisationfunktion_tils_gyldighed
  USING gin
  (((virkning).notetekst) gin_trgm_ops);

  

/****************************************************************************************************/

CREATE SEQUENCE organisationfunktion_relation_id_seq
  INCREMENT 1
  MINVALUE 1
  MAXVALUE 9223372036854775807
  START 1
  CACHE 1;
ALTER TABLE organisationfunktion_relation_id_seq
  OWNER TO mox;


CREATE TABLE organisationfunktion_relation
(
  id bigint NOT NULL DEFAULT nextval('organisationfunktion_relation_id_seq'::regclass),
  organisationfunktion_registrering_id bigint not null,
  virkning Virkning not null CHECK( (virkning).TimePeriod IS NOT NULL AND not isempty((virkning).TimePeriod) ),
  rel_maal_uuid uuid NULL, --we have to allow null values (for now at least), as it is needed to be able to clear/overrule previous registered relations.
  rel_maal_urn text null,
  rel_type OrganisationfunktionRelationKode not null,
  objekt_type text null,
 CONSTRAINT organisationfunktion_relation_forkey_organisationfunktionregistrering  FOREIGN KEY (organisationfunktion_registrering_id) REFERENCES organisationfunktion_registrering (id) MATCH SIMPLE ON UPDATE NO ACTION ON DELETE NO ACTION,
 CONSTRAINT organisationfunktion_relation_pkey PRIMARY KEY (id),
 CONSTRAINT organisationfunktion_relation_no_virkning_overlap EXCLUDE USING gist (organisationfunktion_registrering_id WITH =, _as_convert_organisationfunktion_relation_kode_to_txt(rel_type) WITH =, _composite_type_to_time_range(virkning) WITH &&)  WHERE ( rel_type<>('adresser'::OrganisationfunktionRelationKode ) AND rel_type<>('opgaver'::OrganisationfunktionRelationKode ) AND rel_type<>('tilknyttedebrugere'::OrganisationfunktionRelationKode ) AND rel_type<>('tilknyttedeenheder'::OrganisationfunktionRelationKode ) AND rel_type<>('tilknyttedeorganisationer'::OrganisationfunktionRelationKode ) AND rel_type<>('tilknyttedeitsystemer'::OrganisationfunktionRelationKode ) AND rel_type<>('tilknyttedeinteressefaellesskaber'::OrganisationfunktionRelationKode ) AND rel_type<>('tilknyttedepersoner'::OrganisationfunktionRelationKode )) ,-- no overlapping virkning except for 0..n --relations
 CONSTRAINT organisationfunktion_relation_either_uri_or_urn CHECK (NOT (rel_maal_uuid IS NOT NULL AND (rel_maal_urn IS NOT NULL AND rel_maal_urn<>'')))
);


CREATE INDEX organisationfunktion_relation_idx_rel_maal_obj_uuid
  ON organisationfunktion_relation
  USING btree
  (rel_type,objekt_type,rel_maal_uuid);

CREATE INDEX organisationfunktion_relation_idx_rel_maal_obj_urn
  ON organisationfunktion_relation
  USING btree
  (rel_type,objekt_type,rel_maal_urn);

CREATE INDEX organisationfunktion_relation_idx_rel_maal_uuid
  ON organisationfunktion_relation
  USING btree
  (rel_type, rel_maal_uuid);

CREATE INDEX organisationfunktion_relation_idx_rel_maal_uuid_isolated
  ON organisationfunktion_relation
  USING btree
  (rel_maal_uuid);

CREATE INDEX organisationfunktion_relation_idx_rel_maal_urn_isolated
  ON organisationfunktion_relation
  USING btree
  (rel_maal_urn);

CREATE INDEX organisationfunktion_relation_idx_rel_maal_urn
  ON organisationfunktion_relation
  USING btree
  (rel_type, rel_maal_urn);

CREATE INDEX organisationfunktion_relation_idx_virkning_aktoerref
  ON organisationfunktion_relation
  USING btree
  (((virkning).aktoerref));

CREATE INDEX organisationfunktion_relation_idx_virkning_aktoertypekode
  ON organisationfunktion_relation
  USING btree
  (((virkning).aktoertypekode));

CREATE INDEX organisationfunktion_relation_idx_virkning_notetekst
  ON organisationfunktion_relation
  USING btree
  (((virkning).notetekst));

CREATE INDEX organisationfunktion_relation_pat_virkning_notetekst
  ON organisationfunktion_relation
  USING gin
  (((virkning).notetekst) gin_trgm_ops);




