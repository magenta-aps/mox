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

CREATE or replace FUNCTION _as_convert_organisation_relation_kode_to_txt (
  OrganisationRelationKode
    ) 
RETURNS TEXT 
LANGUAGE sql STRICT IMMUTABLE 
AS $$
        SELECT $1::text;
   $$;

/******************** TBLS DEFS ***********************************/


CREATE TABLE organisation
(
 id uuid NOT NULL,
  CONSTRAINT organisation_pkey PRIMARY KEY (id)
)
WITH (
  OIDS=FALSE
);
ALTER TABLE organisation
  OWNER TO mox;

/****************************************************************************************************/
CREATE SEQUENCE organisation_registrering_id_seq
  INCREMENT 1
  MINVALUE 1
  MAXVALUE 9223372036854775807
  START 1
  CACHE 1;
ALTER TABLE organisation_registrering_id_seq
  OWNER TO mox;


CREATE TABLE organisation_registrering
(
 id bigint NOT NULL DEFAULT nextval('organisation_registrering_id_seq'::regclass),
 organisation_id uuid NOT NULL ,
 registrering RegistreringBase NOT NULL CHECK( (registrering).TimePeriod IS NOT NULL AND not isempty((registrering).timeperiod) ),
  CONSTRAINT organisation_registrering_pkey PRIMARY KEY (id),
  CONSTRAINT organisation_registrering_organisation_fkey FOREIGN KEY (organisation_id)
      REFERENCES organisation (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT organisation_registrering__uuid_to_text_timeperiod_excl EXCLUDE 
  USING gist (_uuid_to_text(organisation_id) WITH =, _composite_type_to_time_range(registrering) WITH &&)
)
WITH (
  OIDS=FALSE
);
ALTER TABLE organisation_registrering
  OWNER TO mox;

CREATE INDEX organisation_registrering_idx_livscykluskode
  ON organisation_registrering
  USING btree
  (((registrering).livscykluskode));

CREATE INDEX organisation_registrering_idx_brugerref
  ON organisation_registrering
  USING btree
  (((registrering).brugerref));

CREATE INDEX organisation_registrering_idx_note
  ON organisation_registrering
  USING btree
  (((registrering).note));

CREATE INDEX organisation_registrering_pat_note
  ON organisation_registrering
  USING  gin
  (((registrering).note) gin_trgm_ops);



/****************************************************************************************************/


CREATE SEQUENCE organisation_attr_egenskaber_id_seq
  INCREMENT 1
  MINVALUE 1
  MAXVALUE 9223372036854775807
  START 1
  CACHE 1;
ALTER TABLE organisation_attr_egenskaber_id_seq
  OWNER TO mox;




CREATE TABLE organisation_attr_egenskaber
(
  id bigint NOT NULL DEFAULT nextval('organisation_attr_egenskaber_id_seq'::regclass), 
   brugervendtnoegle text null, 
   organisationsnavn text null, 
   virkning Virkning not null CHECK( (virkning).TimePeriod IS NOT NULL AND not isempty((virkning).TimePeriod) ),
  organisation_registrering_id bigint not null,
CONSTRAINT organisation_attr_egenskaber_pkey PRIMARY KEY (id),
CONSTRAINT organisation_attr_egenskaber_forkey_organisationregistrering  FOREIGN KEY (organisation_registrering_id) REFERENCES organisation_registrering (id) MATCH SIMPLE ON UPDATE NO ACTION ON DELETE NO ACTION,
CONSTRAINT organisation_attr_egenskaber_exclude_virkning_overlap EXCLUDE USING gist (organisation_registrering_id WITH =, _composite_type_to_time_range(virkning) WITH &&)
)
WITH (
  OIDS=FALSE
);
ALTER TABLE organisation_attr_egenskaber
  OWNER TO mox;

 
CREATE INDEX organisation_attr_egenskaber_pat_brugervendtnoegle
  ON organisation_attr_egenskaber
  USING gin
  (brugervendtnoegle gin_trgm_ops);

CREATE INDEX organisation_attr_egenskaber_idx_brugervendtnoegle
  ON organisation_attr_egenskaber
  USING btree
  (brugervendtnoegle); 

 
CREATE INDEX organisation_attr_egenskaber_pat_organisationsnavn
  ON organisation_attr_egenskaber
  USING gin
  (organisationsnavn gin_trgm_ops);

CREATE INDEX organisation_attr_egenskaber_idx_organisationsnavn
  ON organisation_attr_egenskaber
  USING btree
  (organisationsnavn); 




CREATE INDEX organisation_attr_egenskaber_idx_virkning_aktoerref
  ON organisation_attr_egenskaber
  USING btree
  (((virkning).aktoerref));

CREATE INDEX organisation_attr_egenskaber_idx_virkning_aktoertypekode
  ON organisation_attr_egenskaber
  USING btree
  (((virkning).aktoertypekode));

CREATE INDEX organisation_attr_egenskaber_idx_virkning_notetekst
  ON organisation_attr_egenskaber
  USING btree
  (((virkning).notetekst));

CREATE INDEX organisation_attr_egenskaber_pat_virkning_notetekst
  ON organisation_attr_egenskaber
  USING gin
  (((virkning).notetekst) gin_trgm_ops);






/****************************************************************************************************/



CREATE SEQUENCE organisation_tils_gyldighed_id_seq
  INCREMENT 1
  MINVALUE 1
  MAXVALUE 9223372036854775807
  START 1
  CACHE 1;
ALTER TABLE organisation_tils_gyldighed_id_seq
  OWNER TO mox;


CREATE TABLE organisation_tils_gyldighed
(
  id bigint NOT NULL DEFAULT nextval('organisation_tils_gyldighed_id_seq'::regclass),
  virkning Virkning  NOT NULL CHECK( (virkning).TimePeriod IS NOT NULL AND not isempty((virkning).TimePeriod) ),
  gyldighed OrganisationGyldighedTils NOT NULL, 
  organisation_registrering_id bigint not null,
  CONSTRAINT organisation_tils_gyldighed_pkey PRIMARY KEY (id),
  CONSTRAINT organisation_tils_gyldighed_forkey_organisationregistrering  FOREIGN KEY (organisation_registrering_id) REFERENCES organisation_registrering (id) MATCH SIMPLE ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT organisation_tils_gyldighed_exclude_virkning_overlap EXCLUDE USING gist (organisation_registrering_id WITH =, _composite_type_to_time_range(virkning) WITH &&)
)
 
WITH (
  OIDS=FALSE
);
ALTER TABLE organisation_tils_gyldighed
  OWNER TO mox;

CREATE INDEX organisation_tils_gyldighed_idx_gyldighed
  ON organisation_tils_gyldighed
  USING btree
  (gyldighed);
  

CREATE INDEX organisation_tils_gyldighed_idx_virkning_aktoerref
  ON organisation_tils_gyldighed
  USING btree
  (((virkning).aktoerref));

CREATE INDEX organisation_tils_gyldighed_idx_virkning_aktoertypekode
  ON organisation_tils_gyldighed
  USING btree
  (((virkning).aktoertypekode));

CREATE INDEX organisation_tils_gyldighed_idx_virkning_notetekst
  ON organisation_tils_gyldighed
  USING btree
  (((virkning).notetekst));

CREATE INDEX organisation_tils_gyldighed_pat_virkning_notetekst
  ON organisation_tils_gyldighed
  USING gin
  (((virkning).notetekst) gin_trgm_ops);

  

/****************************************************************************************************/

CREATE SEQUENCE organisation_relation_id_seq
  INCREMENT 1
  MINVALUE 1
  MAXVALUE 9223372036854775807
  START 1
  CACHE 1;
ALTER TABLE organisation_relation_id_seq
  OWNER TO mox;


CREATE TABLE organisation_relation
(
  id bigint NOT NULL DEFAULT nextval('organisation_relation_id_seq'::regclass),
  organisation_registrering_id bigint not null,
  virkning Virkning not null CHECK( (virkning).TimePeriod IS NOT NULL AND not isempty((virkning).TimePeriod) ),
  rel_maal_uuid uuid NULL, --we have to allow null values (for now at least), as it is needed to be able to clear/overrule previous registered relations.
  rel_maal_urn text null,
  rel_type OrganisationRelationKode not null,
  objekt_type text null,

 CONSTRAINT organisation_relation_forkey_organisationregistrering  FOREIGN KEY (organisation_registrering_id) REFERENCES organisation_registrering (id) MATCH SIMPLE ON UPDATE NO ACTION ON DELETE NO ACTION,
 CONSTRAINT organisation_relation_pkey PRIMARY KEY (id),
 CONSTRAINT organisation_relation_no_virkning_overlap EXCLUDE USING gist (organisation_registrering_id WITH =, _as_convert_organisation_relation_kode_to_txt(rel_type) WITH =, _composite_type_to_time_range(virkning) WITH &&)  WHERE ( rel_type<>('adresser'::OrganisationRelationKode ) AND rel_type<>('ansatte'::OrganisationRelationKode ) AND rel_type<>('opgaver'::OrganisationRelationKode ) AND rel_type<>('tilknyttedebrugere'::OrganisationRelationKode ) AND rel_type<>('tilknyttedeenheder'::OrganisationRelationKode ) AND rel_type<>('tilknyttedefunktioner'::OrganisationRelationKode ) AND rel_type<>('tilknyttedeinteressefaellesskaber'::OrganisationRelationKode ) AND rel_type<>('tilknyttedeorganisationer'::OrganisationRelationKode ) AND rel_type<>('tilknyttedepersoner'::OrganisationRelationKode ) AND rel_type<>('tilknyttedeitsystemer'::OrganisationRelationKode )) ,-- no overlapping virkning except for 0..n --relations
 CONSTRAINT organisation_relation_either_uri_or_urn CHECK (NOT (rel_maal_uuid IS NOT NULL AND (rel_maal_urn IS NOT NULL AND rel_maal_urn<>'')))
);



CREATE INDEX organisation_relation_idx_rel_maal_obj_uuid
  ON organisation_relation
  USING btree
  (rel_type,objekt_type,rel_maal_uuid);



CREATE INDEX organisation_relation_idx_rel_maal_obj_urn
  ON organisation_relation
  USING btree
  (rel_type,objekt_type,rel_maal_urn);

CREATE INDEX organisation_relation_idx_rel_maal_uuid
  ON organisation_relation
  USING btree
  (rel_type, rel_maal_uuid);

CREATE INDEX organisation_relation_idx_rel_maal_uuid_isolated
  ON organisation_relation
  USING btree
  (rel_maal_uuid);

CREATE INDEX organisation_relation_idx_rel_maal_urn_isolated
  ON organisation_relation
  USING btree
  (rel_maal_urn);

CREATE INDEX organisation_relation_idx_rel_maal_urn
  ON organisation_relation
  USING btree
  (rel_type, rel_maal_urn);

CREATE INDEX organisation_relation_idx_virkning_aktoerref
  ON organisation_relation
  USING btree
  (((virkning).aktoerref));

CREATE INDEX organisation_relation_idx_virkning_aktoertypekode
  ON organisation_relation
  USING btree
  (((virkning).aktoertypekode));

CREATE INDEX organisation_relation_idx_virkning_notetekst
  ON organisation_relation
  USING btree
  (((virkning).notetekst));

CREATE INDEX organisation_relation_pat_virkning_notetekst
  ON organisation_relation
  USING gin
  (((virkning).notetekst) gin_trgm_ops);




