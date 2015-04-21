
CREATE SEQUENCE facet_relation_liste_id_seq
  INCREMENT 1
  MINVALUE 1
  MAXVALUE 9223372036854775807
  START 1
  CACHE 1;
  
ALTER TABLE facet_relation_liste_id_seq
  OWNER TO mox;



CREATE TABLE facet_relation_liste
(
  id bigint NOT NULL DEFAULT nextval('facet_relation_liste_id_seq'::regclass),
  facet_registrering_id bigint not null,
  virkning Virkning not null,
  CONSTRAINT facet_relation_liste_pkey PRIMARY KEY (id),
  CONSTRAINT facet_relation_liste_forkey_facetregistrering  FOREIGN KEY (facet_registrering_id) REFERENCES facet_registrering (id) MATCH SIMPLE ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT facet_relation_exclude_virkning_overlap EXCLUDE USING gist (facet_registrering_id WITH =, composite_type_to_time_range(virkning) WITH &&)
);


--create custom type sans db-ids to be able to do "clean" function signatures for "the outside world".
CREATE TYPE FacetRelationListeType AS
(
relationer FacetRelationerType[],	
virkning Virkning
);
