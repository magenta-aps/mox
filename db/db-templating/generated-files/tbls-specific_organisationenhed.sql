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

CREATE or replace FUNCTION _as_convert_organisationenhed_relation_kode_to_txt (
  OrganisationenhedRelationKode
    ) 
RETURNS TEXT 
LANGUAGE sql STRICT IMMUTABLE 
AS $$
        SELECT $1::text;
   $$;

/******************** TBLS DEFS ***********************************/


CREATE TABLE organisationenhed
(
 id uuid NOT NULL,
  CONSTRAINT organisationenhed_pkey PRIMARY KEY (id)
)
WITH (
  OIDS=FALSE
);
ALTER TABLE organisationenhed
  OWNER TO mox;

/****************************************************************************************************/
CREATE SEQUENCE organisationenhed_registrering_id_seq
  INCREMENT 1
  MINVALUE 1
  MAXVALUE 9223372036854775807
  START 1
  CACHE 1;
ALTER TABLE organisationenhed_registrering_id_seq
  OWNER TO mox;


CREATE TABLE organisationenhed_registrering
(
 id bigint NOT NULL DEFAULT nextval('organisationenhed_registrering_id_seq'::regclass),
 organisationenhed_id uuid NOT NULL ,
 registrering RegistreringBase NOT NULL CHECK( (registrering).TimePeriod IS NOT NULL AND not isempty((registrering).timeperiod) ),
  CONSTRAINT organisationenhed_registrering_pkey PRIMARY KEY (id),
  CONSTRAINT organisationenhed_registrering_organisationenhed_fkey FOREIGN KEY (organisationenhed_id)
      REFERENCES organisationenhed (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT organisationenhed_registrering__uuid_to_text_timeperiod_excl EXCLUDE 
  USING gist (_uuid_to_text(organisationenhed_id) WITH =, _composite_type_to_time_range(registrering) WITH &&)
)
WITH (
  OIDS=FALSE
);
ALTER TABLE organisationenhed_registrering
  OWNER TO mox;

CREATE INDEX organisationenhed_registrering_idx_livscykluskode
  ON organisationenhed_registrering
  USING btree
  (((registrering).livscykluskode));

CREATE INDEX organisationenhed_registrering_idx_brugerref
  ON organisationenhed_registrering
  USING btree
  (((registrering).brugerref));

CREATE INDEX organisationenhed_registrering_idx_note
  ON organisationenhed_registrering
  USING btree
  (((registrering).note));

CREATE INDEX organisationenhed_registrering_pat_note
  ON organisationenhed_registrering
  USING  gin
  (((registrering).note) gin_trgm_ops);



/****************************************************************************************************/


CREATE SEQUENCE organisationenhed_attr_egenskaber_id_seq
  INCREMENT 1
  MINVALUE 1
  MAXVALUE 9223372036854775807
  START 1
  CACHE 1;
ALTER TABLE organisationenhed_attr_egenskaber_id_seq
  OWNER TO mox;




CREATE TABLE organisationenhed_attr_egenskaber
(
  id bigint NOT NULL DEFAULT nextval('organisationenhed_attr_egenskaber_id_seq'::regclass), 
   brugervendtnoegle text null, 
   enhedsnavn text null, 
   virkning Virkning not null CHECK( (virkning).TimePeriod IS NOT NULL AND not isempty((virkning).TimePeriod) ),
  organisationenhed_registrering_id bigint not null,
CONSTRAINT organisationenhed_attr_egenskaber_pkey PRIMARY KEY (id),
CONSTRAINT organisationenhed_attr_egenskaber_forkey_organisationenhedregistrering  FOREIGN KEY (organisationenhed_registrering_id) REFERENCES organisationenhed_registrering (id) MATCH SIMPLE ON UPDATE NO ACTION ON DELETE NO ACTION,
CONSTRAINT organisationenhed_attr_egenskaber_exclude_virkning_overlap EXCLUDE USING gist (organisationenhed_registrering_id WITH =, _composite_type_to_time_range(virkning) WITH &&)
)
WITH (
  OIDS=FALSE
);
ALTER TABLE organisationenhed_attr_egenskaber
  OWNER TO mox;

 
CREATE INDEX organisationenhed_attr_egenskaber_pat_brugervendtnoegle
  ON organisationenhed_attr_egenskaber
  USING gin
  (brugervendtnoegle gin_trgm_ops);

CREATE INDEX organisationenhed_attr_egenskaber_idx_brugervendtnoegle
  ON organisationenhed_attr_egenskaber
  USING btree
  (brugervendtnoegle); 

 
CREATE INDEX organisationenhed_attr_egenskaber_pat_enhedsnavn
  ON organisationenhed_attr_egenskaber
  USING gin
  (enhedsnavn gin_trgm_ops);

CREATE INDEX organisationenhed_attr_egenskaber_idx_enhedsnavn
  ON organisationenhed_attr_egenskaber
  USING btree
  (enhedsnavn); 




CREATE INDEX organisationenhed_attr_egenskaber_idx_virkning_aktoerref
  ON organisationenhed_attr_egenskaber
  USING btree
  (((virkning).aktoerref));

CREATE INDEX organisationenhed_attr_egenskaber_idx_virkning_aktoertypekode
  ON organisationenhed_attr_egenskaber
  USING btree
  (((virkning).aktoertypekode));

CREATE INDEX organisationenhed_attr_egenskaber_idx_virkning_notetekst
  ON organisationenhed_attr_egenskaber
  USING btree
  (((virkning).notetekst));

CREATE INDEX organisationenhed_attr_egenskaber_pat_virkning_notetekst
  ON organisationenhed_attr_egenskaber
  USING gin
  (((virkning).notetekst) gin_trgm_ops);






/****************************************************************************************************/



CREATE SEQUENCE organisationenhed_tils_gyldighed_id_seq
  INCREMENT 1
  MINVALUE 1
  MAXVALUE 9223372036854775807
  START 1
  CACHE 1;
ALTER TABLE organisationenhed_tils_gyldighed_id_seq
  OWNER TO mox;


CREATE TABLE organisationenhed_tils_gyldighed
(
  id bigint NOT NULL DEFAULT nextval('organisationenhed_tils_gyldighed_id_seq'::regclass),
  virkning Virkning  NOT NULL CHECK( (virkning).TimePeriod IS NOT NULL AND not isempty((virkning).TimePeriod) ),
  gyldighed OrganisationenhedGyldighedTils NOT NULL, 
  organisationenhed_registrering_id bigint not null,
  CONSTRAINT organisationenhed_tils_gyldighed_pkey PRIMARY KEY (id),
  CONSTRAINT organisationenhed_tils_gyldighed_forkey_organisationenhedregistrering  FOREIGN KEY (organisationenhed_registrering_id) REFERENCES organisationenhed_registrering (id) MATCH SIMPLE ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT organisationenhed_tils_gyldighed_exclude_virkning_overlap EXCLUDE USING gist (organisationenhed_registrering_id WITH =, _composite_type_to_time_range(virkning) WITH &&)
)
 
WITH (
  OIDS=FALSE
);
ALTER TABLE organisationenhed_tils_gyldighed
  OWNER TO mox;

CREATE INDEX organisationenhed_tils_gyldighed_idx_gyldighed
  ON organisationenhed_tils_gyldighed
  USING btree
  (gyldighed);
  

CREATE INDEX organisationenhed_tils_gyldighed_idx_virkning_aktoerref
  ON organisationenhed_tils_gyldighed
  USING btree
  (((virkning).aktoerref));

CREATE INDEX organisationenhed_tils_gyldighed_idx_virkning_aktoertypekode
  ON organisationenhed_tils_gyldighed
  USING btree
  (((virkning).aktoertypekode));

CREATE INDEX organisationenhed_tils_gyldighed_idx_virkning_notetekst
  ON organisationenhed_tils_gyldighed
  USING btree
  (((virkning).notetekst));

CREATE INDEX organisationenhed_tils_gyldighed_pat_virkning_notetekst
  ON organisationenhed_tils_gyldighed
  USING gin
  (((virkning).notetekst) gin_trgm_ops);

  

/****************************************************************************************************/

CREATE SEQUENCE organisationenhed_relation_id_seq
  INCREMENT 1
  MINVALUE 1
  MAXVALUE 9223372036854775807
  START 1
  CACHE 1;
ALTER TABLE organisationenhed_relation_id_seq
  OWNER TO mox;


CREATE TABLE organisationenhed_relation
(
  id bigint NOT NULL DEFAULT nextval('organisationenhed_relation_id_seq'::regclass),
  organisationenhed_registrering_id bigint not null,
  virkning Virkning not null CHECK( (virkning).TimePeriod IS NOT NULL AND not isempty((virkning).TimePeriod) ),
  rel_maal_uuid uuid NULL, --we have to allow null values (for now at least), as it is needed to be able to clear/overrule previous registered relations.
  rel_maal_urn text null,
  rel_type OrganisationenhedRelationKode not null,
  objekt_type text null,

 CONSTRAINT organisationenhed_relation_forkey_organisationenhedregistrering  FOREIGN KEY (organisationenhed_registrering_id) REFERENCES organisationenhed_registrering (id) MATCH SIMPLE ON UPDATE NO ACTION ON DELETE NO ACTION,
 CONSTRAINT organisationenhed_relation_pkey PRIMARY KEY (id),
 CONSTRAINT organisationenhed_relation_no_virkning_overlap EXCLUDE USING gist (organisationenhed_registrering_id WITH =, _as_convert_organisationenhed_relation_kode_to_txt(rel_type) WITH =, _composite_type_to_time_range(virkning) WITH &&)  WHERE ( rel_type<>('adresser'::OrganisationenhedRelationKode ) AND rel_type<>('ansatte'::OrganisationenhedRelationKode ) AND rel_type<>('opgaver'::OrganisationenhedRelationKode ) AND rel_type<>('tilknyttedebrugere'::OrganisationenhedRelationKode ) AND rel_type<>('tilknyttedeenheder'::OrganisationenhedRelationKode ) AND rel_type<>('tilknyttedefunktioner'::OrganisationenhedRelationKode ) AND rel_type<>('tilknyttedeinteressefaellesskaber'::OrganisationenhedRelationKode ) AND rel_type<>('tilknyttedeorganisationer'::OrganisationenhedRelationKode ) AND rel_type<>('tilknyttedepersoner'::OrganisationenhedRelationKode ) AND rel_type<>('tilknyttedeitsystemer'::OrganisationenhedRelationKode )) ,-- no overlapping virkning except for 0..n --relations
 CONSTRAINT organisationenhed_relation_either_uri_or_urn CHECK (NOT (rel_maal_uuid IS NOT NULL AND (rel_maal_urn IS NOT NULL AND rel_maal_urn<>'')))
);



CREATE INDEX organisationenhed_relation_idx_rel_maal_obj_uuid
  ON organisationenhed_relation
  USING btree
  (rel_type,objekt_type,rel_maal_uuid);



CREATE INDEX organisationenhed_relation_idx_rel_maal_obj_urn
  ON organisationenhed_relation
  USING btree
  (rel_type,objekt_type,rel_maal_urn);

CREATE INDEX organisationenhed_relation_idx_rel_maal_uuid
  ON organisationenhed_relation
  USING btree
  (rel_type, rel_maal_uuid);

CREATE INDEX organisationenhed_relation_idx_rel_maal_uuid_isolated
  ON organisationenhed_relation
  USING btree
  (rel_maal_uuid);

CREATE INDEX organisationenhed_relation_idx_rel_maal_urn_isolated
  ON organisationenhed_relation
  USING btree
  (rel_maal_urn);

CREATE INDEX organisationenhed_relation_idx_rel_maal_urn
  ON organisationenhed_relation
  USING btree
  (rel_type, rel_maal_urn);

CREATE INDEX organisationenhed_relation_idx_virkning_aktoerref
  ON organisationenhed_relation
  USING btree
  (((virkning).aktoerref));

CREATE INDEX organisationenhed_relation_idx_virkning_aktoertypekode
  ON organisationenhed_relation
  USING btree
  (((virkning).aktoertypekode));

CREATE INDEX organisationenhed_relation_idx_virkning_notetekst
  ON organisationenhed_relation
  USING btree
  (((virkning).notetekst));

CREATE INDEX organisationenhed_relation_pat_virkning_notetekst
  ON organisationenhed_relation
  USING gin
  (((virkning).notetekst) gin_trgm_ops);




