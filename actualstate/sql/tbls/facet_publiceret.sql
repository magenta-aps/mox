
CREATE TYPE FacetPubliceretStatus AS ENUM ('Publiceret', 'IkkePubliceret');

-- Sequence: facetregistrering_id_seq

-- DROP SEQUENCE facetregistrering_id_seq;


CREATE SEQUENCE facet_publiceret_id_seq
  INCREMENT 1
  MINVALUE 1
  MAXVALUE 9223372036854775807
  START 1
  CACHE 1;
ALTER TABLE facet_publiceret_id_seq
  OWNER TO mox;



-- Table: facet_publiceret

-- DROP TABLE facet_publiceret;

CREATE TABLE facet_publiceret
(
  id bigint NOT NULL DEFAULT nextval('facet_publiceret_id_seq'::regclass),
  virkning Virkning  NOT NULL,
  publiceret_status FacetPubliceretStatus NOT NULL, 
  facet_registrering_id bigint not null,
  CONSTRAINT facet_publiceret_pkey PRIMARY KEY (id),
  CONSTRAINT facet_publiceret_forkey_facetregistrering  FOREIGN KEY (facet_registrering_id) REFERENCES facet_registrering (id) MATCH SIMPLE ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT facet_publiceret_exclude_virkning_overlap EXCLUDE USING gist (facet_registrering_id WITH =, composite_type_to_time_range(virkning) WITH &&)
)
 
WITH (
  OIDS=FALSE
);
ALTER TABLE facet_publiceret
  OWNER TO mox;

--create custom type sans db-ids to be able to do "clean" function signatures "for the outside world".
CREATE TYPE FacetPubliceretType AS (
    virkning Virkning,
    publiceret_status FacetPubliceretStatus 
)

