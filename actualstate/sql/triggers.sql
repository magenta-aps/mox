-- Registrering
CREATE OR REPLACE FUNCTION registrering_insert_trigger()
  RETURNS TRIGGER AS $$
DECLARE
  tableName REGCLASS;
  result RECORD;
BEGIN
--   Get the name of the table that the object references
  SELECT tableoid
  FROM objekt
  WHERE ID = NEW.ObjektID
  INTO tableName;

  EXECUTE 'INSERT INTO ' || tableName || 'Registrering VALUES ($1.*)'
  USING NEW;
  RETURN NULL;
END;
$$
LANGUAGE plpgsql;

CREATE TRIGGER registrering_insert_trigger
BEFORE INSERT ON registrering
FOR EACH ROW EXECUTE PROCEDURE registrering_insert_trigger();

-- Egenskaber
CREATE OR REPLACE FUNCTION egenskaber_insert_trigger()
  RETURNS TRIGGER AS $$
DECLARE
  tableName REGCLASS;
BEGIN
--   Get the name of the table that the object references
  SELECT o.tableoid
  FROM objekt o, registrering r
  WHERE r.ObjektID = o.ID
        AND r.ID = NEW.RegistreringsID
  INTO tableName;
  EXECUTE 'INSERT INTO ' || tableName || 'Egenskaber VALUES ($1.*)'
  USING NEW;
  RETURN NULL;
END;
$$
LANGUAGE plpgsql;

CREATE TRIGGER egenskaber_insert_trigger
BEFORE INSERT ON egenskaber
FOR EACH ROW EXECUTE PROCEDURE egenskaber_insert_trigger();


-- Egenskab
CREATE OR REPLACE FUNCTION egenskab_insert_trigger()
  RETURNS TRIGGER AS $$
DECLARE
  tableName REGCLASS;
BEGIN
--   Get the name of the table that the object references
  SELECT o.tableoid
  FROM objekt o JOIN registrering r ON r.ObjektID = o.ID JOIN
  egenskaber e ON r.ID = e.RegistreringsID WHERE e.ID = NEW.EgenskaberID
  INTO tableName;
  EXECUTE 'INSERT INTO ' || tableName || 'Egenskab VALUES ($1.*)'
  USING NEW;
  RETURN NULL;
END;
$$
LANGUAGE plpgsql;

CREATE TRIGGER egenskab_insert_trigger
BEFORE INSERT ON egenskab
FOR EACH ROW EXECUTE PROCEDURE egenskab_insert_trigger();

-- Tilstand
CREATE OR REPLACE FUNCTION tilstand_insert_trigger()
  RETURNS TRIGGER AS $$
DECLARE
  tableName REGCLASS;
BEGIN
--   Get the name of the table that the object references
  SELECT o.tableoid
  FROM objekt o, registrering r
  WHERE r.ObjektID = o.ID
        AND r.ID = NEW.RegistreringsID
  INTO tableName;
  EXECUTE 'INSERT INTO ' || tableName || 'Tilstand VALUES ($1.*)'
  USING NEW;
  RETURN NULL;
END;
$$
LANGUAGE plpgsql;

CREATE TRIGGER tilstand_insert_trigger
BEFORE INSERT ON tilstand
FOR EACH ROW EXECUTE PROCEDURE tilstand_insert_trigger();

-- RelationsListe
CREATE OR REPLACE FUNCTION relationsliste_insert_trigger()
  RETURNS TRIGGER AS $$
DECLARE
  tableName REGCLASS;
BEGIN
--   Get the name of the table that the object references
  SELECT o.tableoid
  FROM objekt o, registrering r
  WHERE r.ObjektID = o.ID
        AND r.ID = NEW.RegistreringsID
  INTO tableName;
  EXECUTE 'INSERT INTO ' || tableName || 'RelationsListe VALUES ($1.*)'
  USING NEW;
  RETURN NULL;
END;
$$
LANGUAGE plpgsql;

CREATE TRIGGER relationsliste_insert_trigger
BEFORE INSERT ON relationsliste
FOR EACH ROW EXECUTE PROCEDURE relationsliste_insert_trigger();


-- Relation
CREATE OR REPLACE FUNCTION relation_insert_trigger()
  RETURNS TRIGGER AS $$
DECLARE
  tableName REGCLASS;
BEGIN
--   Get the name of the table that the object references
  SELECT o.tableoid
  FROM objekt o, registrering r, relationsliste rl
  WHERE r.ObjektID = o.ID AND r.ID = rl.RegistreringsID
        AND rl.ID = NEW.RelationsListeID
  INTO tableName;
  EXECUTE 'INSERT INTO ' || tableName || 'Relation VALUES ($1.*)'
  USING NEW;
  RETURN NULL;
END;
$$
LANGUAGE plpgsql;

CREATE TRIGGER relation_insert_trigger
BEFORE INSERT ON relation
FOR EACH ROW EXECUTE PROCEDURE relation_insert_trigger();
