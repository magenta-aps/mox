

/*
DROP FUNCTION actual_state_create_facet(facet_registrering FacetRegistreringType);
DROP FUNCTION actual_state_update_facet(facet_uuid uuid,brugerref uuid,note text,livscykluskode Livscykluskode,attrEgenskaber FacetAttrEgenskaberType[],tilsPubliceretStatus FacetTilsPubliceretType[],relationer FacetRelationType[]);
DROP FUNCTION _actual_state_create_facet_registrering(facet_uuid uuid,livscykluskode Livscykluskode, brugerref uuid, note text);
DROP FUNCTION _actual_state_get_prev_facet_registrering(facet_registrering);

DROP TABLE facet_attr_egenskaber ;
DROP TABLE facet_tils_publiceret ;
DROP TABLE facet_relation ;
DROP TABLE facet_registrering;
DROP TABLE facet ;

DROP FUNCTION _actual_state_convert_facet_relation_kode_to_txt(FacetRelationKode);

DROP SEQUENCE facet_attr_egenskaber_id_seq ;
DROP SEQUENCE facet_tils_publiceret_id_seq ;
DROP SEQUENCE facet_relation_id_seq ;
DROP SEQUENCE facet_registrering_id_seq ;



DROP TYPE Facettype;
DROP TYPE FacetRegistreringType ;
DROP TYPE registreringbase;
DROP TYPE FacetAttrEgenskaberType ;
DROP TYPE FacetTilsPubliceretType ;
DROP TYPE FacetTilsPubliceretStatus ;
DROP TYPE FacetRelationType ;
DROP TYPE Facetrelationkode;
*/

/*
The order to create functions in:
_actual_state_get_prev_facet_registrering
_actual_state_create_facet_registrering
_actual_state_create_facet
_actual_state_update_facet

*/



CREATE TYPE FacetTilsPubliceretStatus AS ENUM ('','Publiceret', 'IkkePubliceret'); --'' means undefined (which is needed to clear previous defined value in an already registered virksnings-periode)


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

CREATE TYPE FacetRelationKode AS ENUM ('Ejer', 'Ansvarlig','Facettilhoer','Redaktoer');  --WARNING: Changes to enum names requires MANUALLY rebuilding indexes where _actual_state_convert_facet_relation_kode_to_txt is invoked.

CREATE TYPE FacetRelationType AS (
  relation_navn FacetRelationKode,
  virkning Virkning,
  relMaal uuid 
)
;


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
relationer FacetRelationType[]
);

CREATE TYPE FacetType AS
(
  id uuid,
  registrering FacetRegistreringType[]
);  

/******************** FUNCTIONS (NEEDED FOR TABLE/INDEX-DEFS) DEFS ***********************************/

CREATE or replace FUNCTION _actual_state_convert_facet_relation_kode_to_txt (
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
 registrering RegistreringBase NOT NULL CHECK( not isempty((registrering).timeperiod) ),
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
   virkning Virkning not null CHECK( not isempty((virkning).TimePeriod) ),
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
  virkning Virkning  NOT NULL CHECK( not isempty((virkning).TimePeriod) ),
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
  virkning Virkning not null CHECK( not isempty((virkning).TimePeriod) ),
  rel_maal uuid NULL, --we have to allow null values (for now at least), as it is needed to be able to clear/overrule previous registered relations.
  rel_type FacetRelationKode not null,
 CONSTRAINT facet_relation_forkey_facetregistrering  FOREIGN KEY (facet_registrering_id) REFERENCES facet_registrering (id) MATCH SIMPLE ON UPDATE NO ACTION ON DELETE NO ACTION,
 CONSTRAINT facet_relation_pkey PRIMARY KEY (id),
 CONSTRAINT facet_relation_no_virkning_overlap EXCLUDE USING gist (facet_registrering_id WITH =, _actual_state_convert_facet_relation_kode_to_txt(rel_type) WITH =, composite_type_to_time_range(virkning) WITH &&) WHERE  (rel_type<>('Redaktoer'::FacetRelationKode ))-- no overlapping virkning except for 0..n --relations
);







