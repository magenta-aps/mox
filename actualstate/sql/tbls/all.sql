

/*
DROP FUNCTION actual_state_create_facet (registrering FacetRegistreringType);
  


DROP TABLE facet_attr_egenskaber ;
DROP TABLE facet_tils_publiceret ;
DROP TABLE facet_rel_ansvarlig ;
DROP TABLE facet_rel_ejer ;
DROP TABLE facet_rel_facettilhoer ;
DROP TABLE facet_rel_redaktoerer ;
DROP TABLE facet_registrering ;
DROP TABLE facet ;

DROP SEQUENCE facet_attr_egenskaber_id_seq ;
DROP SEQUENCE facet_tils_publiceret_id_seq ;
DROP SEQUENCE facet_rel_ansvarlig_id_seq ;
DROP SEQUENCE facet_rel_ejer_id_seq ;
DROP SEQUENCE facet_rel_facettilhoer_id_seq ;
DROP SEQUENCE facet_rel_redaktoerer_id_seq ;
DROP SEQUENCE facet_registrering_id_seq ;



DROP TYPE Facettype;
DROP TYPE FacetRegistreringType ;
DROP TYPE registreringbase;
DROP TYPE FacetAttrEgenskaberType ;
DROP TYPE FacetTilsPubliceretType ;
DROP TYPE FacetTilsPubliceretStatus ;
DROP TYPE FacetRelAnsvarligType ;
DROP TYPE FacetRelEjerType ;
DROP TYPE FacetRelFacettilhoerType ;
DROP TYPE FacetRelRedaktoererType ;

*/




CREATE TYPE FacetTilsPubliceretStatus AS ENUM ('Publiceret', 'IkkePubliceret');


CREATE TYPE FacetTilsPubliceretType AS (
    virkning Virkning,
    publiceret_status FacetTilsPubliceretStatus 
)
;

--create custom type sans db-ids to be able to do "clean" function signatures "for the outside world".

CREATE TYPE FacetAttrEgenskaberType AS (
   brugervendt_noegle text,
   facetbeskrivelse text,
   facetplan text,
   facetopbygning text,
   facetophavsret text,
   facetsupplement text,
   retskilde text,
   virkning Virkning
);


CREATE TYPE FacetRelAnsvarligType AS (
  virkning Virkning,
  relMaal uuid 
)
;

CREATE TYPE FacetRelEjerType AS (
  virkning Virkning,
  relMaal uuid 
)
;


CREATE TYPE FacetRelFacettilhoerType AS (
  virkning Virkning,
  relMaal uuid 
);

CREATE TYPE FacetRelRedaktoererType AS (
  virkning Virkning,
  relMaal uuid 
);


CREATE TYPE RegistreringBase AS --should be renamed to Registrering, when the old 'Registrering'-type is replaced
(
timeperiod tstzrange,
livscykluskode livscykluskode,
brugerref uuid,
note text
);

CREATE TYPE FacetRegistreringType AS
(
registrering RegistreringBase,
tilsPubliceretStatus FacetTilsPubliceretType[],
attrEgenskaber FacetAttrEgenskaberType[],
relAnsvarlig FacetRelAnsvarligType[],
relEjer FacetRelEjerType[],
relFacettilhoer FacetRelFacettilhoerType[],
relRedaktoerer FacetRelRedaktoererType[]
);

CREATE TYPE FacetType AS
(
  id uuid,
  registrering FacetRegistreringType
);  



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
 facet_id uuid,
 registrering RegistreringBase,
  CONSTRAINT facet_registrering_pkey PRIMARY KEY (id),
  CONSTRAINT facet_registrering_facet_fkey FOREIGN KEY (facet_id)
      REFERENCES facet (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT facet_registrering_uuid_to_text_timeperiod_excl EXCLUDE 
  USING gist (uuid_to_text(facet_id) WITH =, composite_type_to_time_range(registrering) WITH &&)
)
WITH (
  OIDS=FALSE
);
ALTER TABLE facet_registrering
  OWNER TO mox;

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
   brugervendt_noegle text not null,
   facetbeskrivelse text null,
   facetplan text null,
   facetopbygning text null,
   facetophavsret text null,
   facetsupplement text null,
   retskilde text null,
   virkning Virkning not null,
   facet_registrering_id bigint not null,
CONSTRAINT facet_attr_egenskaber_pkey PRIMARY KEY (id),
CONSTRAINT facet_attr_egenskaber_forkey_facetregistrering  FOREIGN KEY (facet_registrering_id) REFERENCES facet_registrering (id) MATCH SIMPLE ON UPDATE NO ACTION ON DELETE NO ACTION,
CONSTRAINT facet_attr_egenskaber_exclude_virkning_overlap EXCLUDE USING gist (facet_registrering_id WITH =, composite_type_to_time_range(virkning) WITH &&)
)
WITH (
  OIDS=FALSE
);
ALTER TABLE facet_attr_egenskaber
  OWNER TO mox;



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
  virkning Virkning  NOT NULL,
  publiceret_status FacetTilsPubliceretStatus NOT NULL, 
  facet_registrering_id bigint not null,
  CONSTRAINT facet_tils_publiceret_pkey PRIMARY KEY (id),
  CONSTRAINT facet_tils_publiceret_forkey_facetregistrering  FOREIGN KEY (facet_registrering_id) REFERENCES facet_registrering (id) MATCH SIMPLE ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT facet_tils_publiceret_exclude_virkning_overlap EXCLUDE USING gist (facet_registrering_id WITH =, composite_type_to_time_range(virkning) WITH &&)
)
 
WITH (
  OIDS=FALSE
);
ALTER TABLE facet_tils_publiceret
  OWNER TO mox;



/****************************************************************************************************/

CREATE SEQUENCE facet_rel_ansvarlig_id_seq
  INCREMENT 1
  MINVALUE 1
  MAXVALUE 9223372036854775807
  START 1
  CACHE 1;
ALTER TABLE facet_rel_ansvarlig_id_seq
  OWNER TO mox;



CREATE TABLE facet_rel_ansvarlig
(
  id bigint NOT NULL DEFAULT nextval('facet_rel_ansvarlig_id_seq'::regclass),
  facet_registrering_id bigint not null,
  virkning Virkning not null,
  rel_maal uuid NOT NULL,
 CONSTRAINT facet_rel_ansvarlig_forkey_facetregistrering  FOREIGN KEY (facet_registrering_id) REFERENCES facet_registrering (id) MATCH SIMPLE ON UPDATE NO ACTION ON DELETE NO ACTION,
 CONSTRAINT facet_rel_ansvarlig_pkey PRIMARY KEY (id)
);




/****************************************************************************************************/

CREATE SEQUENCE facet_rel_ejer_id_seq
  INCREMENT 1
  MINVALUE 1
  MAXVALUE 9223372036854775807
  START 1
  CACHE 1;
ALTER TABLE facet_rel_ejer_id_seq
  OWNER TO mox;



CREATE TABLE facet_rel_ejer
(
  id bigint NOT NULL DEFAULT nextval('facet_rel_ejer_id_seq'::regclass),
  facet_registrering_id bigint not null,
  virkning Virkning not null,
  rel_maal uuid NOT NULL,
 CONSTRAINT facet_rel_ejer_forkey_facetregistrering  FOREIGN KEY (facet_registrering_id) REFERENCES facet_registrering (id) MATCH SIMPLE ON UPDATE NO ACTION ON DELETE NO ACTION,
 CONSTRAINT facet_rel_ejer_pkey PRIMARY KEY (id)
);




/****************************************************************************************************/

CREATE SEQUENCE facet_rel_facettilhoer_id_seq
  INCREMENT 1
  MINVALUE 1
  MAXVALUE 9223372036854775807
  START 1
  CACHE 1;
ALTER TABLE facet_rel_facettilhoer_id_seq
  OWNER TO mox;



CREATE TABLE facet_rel_facettilhoer
(
  id bigint NOT NULL DEFAULT nextval('facet_rel_facettilhoer_id_seq'::regclass),
  facet_registrering_id bigint not null,
  virkning Virkning not null,
  rel_maal uuid NOT NULL,
 CONSTRAINT facet_rel_facettilhoer_forkey_facetregistrering  FOREIGN KEY (facet_registrering_id) REFERENCES facet_registrering (id) MATCH SIMPLE ON UPDATE NO ACTION ON DELETE NO ACTION,
 CONSTRAINT facet_rel_facettilhoer_pkey PRIMARY KEY (id)
);





/****************************************************************************************************/


CREATE SEQUENCE facet_rel_redaktoerer_id_seq
  INCREMENT 1
  MINVALUE 1
  MAXVALUE 9223372036854775807
  START 1
  CACHE 1;
ALTER TABLE facet_rel_redaktoerer_id_seq
  OWNER TO mox;



CREATE TABLE facet_rel_redaktoerer
(
  id bigint NOT NULL DEFAULT nextval('facet_rel_redaktoerer_id_seq'::regclass),
  facet_registrering_id bigint not null,
  virkning Virkning not null,
  rel_maal uuid NOT NULL,
 CONSTRAINT facet_rel_redaktoerer_forkey_facetregistrering  FOREIGN KEY (facet_registrering_id) REFERENCES facet_registrering (id) MATCH SIMPLE ON UPDATE NO ACTION ON DELETE NO ACTION,
 CONSTRAINT facet_rel_redaktoerer_pkey PRIMARY KEY (id)
);






