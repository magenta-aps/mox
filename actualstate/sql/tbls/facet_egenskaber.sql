
-- Table: facetregistrering

-- DROP TABLE facetregistrering;

-- Sequence: facetregistrering_id_seq

-- DROP SEQUENCE facetregistrering_id_seq;


CREATE SEQUENCE facet_egenskaber_id_seq
  INCREMENT 1
  MINVALUE 1
  MAXVALUE 9223372036854775807
  START 1
  CACHE 1;
ALTER TABLE facet_egenskaber_id_seq
  OWNER TO mox;


-- Table: facet_egenskaber

-- DROP TABLE facet_egenskaber;

CREATE TABLE facet_egenskaber
(
   id bigint NOT NULL DEFAULT nextval('facet_egenskaber_id_seq'::regclass),
   brugervendt_noegle text not null,
   facetbeskrivelse text null,
   facetplan text null,
   facetopbygning text null,
   facetophavsret text null,
   facetsupplement text null,
   retskilde text null,
   virkning Virkning not null,
   facet_registrering_id bigint not null,
CONSTRAINT facet_egenskaber_pkey PRIMARY KEY (id),
CONSTRAINT facet_egenskaber_forkey_facetregistrering  FOREIGN KEY (facet_registrering_id) REFERENCES facet_registrering (id) MATCH SIMPLE ON UPDATE NO ACTION ON DELETE NO ACTION,
CONSTRAINT facet_egenskaber_exclude_virkning_overlap EXCLUDE USING gist (facet_registrering_id WITH =, composite_type_to_time_range(virkning) WITH &&)
)
WITH (
  OIDS=FALSE
);
ALTER TABLE facet_egenskaber
  OWNER TO mox;

--create custom type sans db-ids to be able to do "clean" function signatures "for the outside world".
CREATE TYPE FacetEgenskaberType AS (
   brugervendt_noegle text,
   facetbeskrivelse text,
   facetplan text,
   facetopbygning text,
   facetophavsret text,
   facetsupplement text,
   retskilde text,
   virkning Virkning
)