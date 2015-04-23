


CREATE TYPE FacetRelationType AS ENUM ('Ansvarlig', 'Ejer','Facettilbehør','Redaktør');

-- Sequence: facet_relation_id_seq

-- DROP SEQUENCE facet_relation_id_seq;

CREATE SEQUENCE facet_relationer_id_seq
  INCREMENT 1
  MINVALUE 1
  MAXVALUE 9223372036854775807
  START 1
  CACHE 1;
  
ALTER TABLE facet_relationer_id_seq
  OWNER TO mox;



CREATE TABLE facet_relationer
(
   id bigint NOT NULL DEFAULT nextval('facet_relationer_id_seq'::regclass),
   rel_type FacetRelationType NOT NULL,
   rel_maal uuid NOT NULL,
   facet_relation_liste_id bigint NOT NULL,
CONSTRAINT facet_relationer_pkey PRIMARY KEY (id),
 CONSTRAINT facet_relationer_forkey_facet_relation_liste  FOREIGN KEY (facet_relation_liste_id) REFERENCES facet_relation_liste (id) MATCH SIMPLE ON UPDATE NO ACTION ON DELETE NO ACTION
)
WITH (
  OIDS=FALSE
);
ALTER TABLE facet_relation_liste
  OWNER TO mox;

--create custom type sans db-ids to be able to do "clean" function signatures for "the outside world".
CREATE TYPE FacetRelationerType AS
(
   relType FacetRelationType,
   relMaal uuid 
)


