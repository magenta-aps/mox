-- Table: facet_registrering

-- DROP TABLE facet_registrering;

-- Sequence: facet_registrering_id_seq

-- DROP SEQUENCE facet_registrering_id_seq;


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
 registrering RegistreringBasis,
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


--create custom type sans db-ids to be able to do "clean" function signatures for "the outside world".
CREATE TYPE FacetRegistreringType AS
(
registrering RegistreringBasis,
relationLister FacetRelationListeType[],
publiceretStatuser FacetPubliceretType[],
egenskaber FacetEgenskaberType[]
);
