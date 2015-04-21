-- DROP TABLE facet;

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


CREATE TYPE FacetType AS
(
	id uuid,
	registrering FacetRegistreringType
);  