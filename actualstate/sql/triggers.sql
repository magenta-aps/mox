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

-- Attributter
CREATE OR REPLACE FUNCTION attributter_insert_trigger()
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
  EXECUTE 'INSERT INTO ' || tableName || 'Attributter VALUES ($1.*)'
  USING NEW;
  RETURN NULL;
END;
$$
LANGUAGE plpgsql;

CREATE TRIGGER attributter_insert_trigger
BEFORE INSERT ON attributter
FOR EACH ROW EXECUTE PROCEDURE attributter_insert_trigger();


-- Attribut
CREATE OR REPLACE FUNCTION attribut_insert_trigger()
  RETURNS TRIGGER AS $$
DECLARE
  tableName REGCLASS;
BEGIN
--   Get the name of the table that the object references
  SELECT o.tableoid
  FROM objekt o JOIN registrering r ON r.ObjektID = o.ID JOIN
  attributter a ON r.ID = a.RegistreringsID WHERE a.ID = NEW.AttributterID
  INTO tableName;
  EXECUTE 'INSERT INTO ' || tableName || 'Attribut VALUES ($1.*)'
  USING NEW;
  RETURN NULL;
END;
$$
LANGUAGE plpgsql;

CREATE TRIGGER attribut_insert_trigger
BEFORE INSERT ON attribut
FOR EACH ROW EXECUTE PROCEDURE attribut_insert_trigger();


-- Tilstande
CREATE OR REPLACE FUNCTION tilstande_insert_trigger()
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
  EXECUTE 'INSERT INTO ' || tableName || 'Tilstande VALUES ($1.*)'
  USING NEW;
  RETURN NULL;
END;
$$
LANGUAGE plpgsql;

CREATE TRIGGER tilstande_insert_trigger
BEFORE INSERT ON tilstande
FOR EACH ROW EXECUTE PROCEDURE tilstande_insert_trigger();

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
  SELECT o.tableoid
  FROM objekt o JOIN registrering r ON r.ObjektID = o.ID JOIN
    Tilstande t ON r.ID = t.RegistreringsID WHERE t.ID = NEW.TilstandeID
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

-- Relationer
CREATE OR REPLACE FUNCTION relationer_insert_trigger()
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
  EXECUTE 'INSERT INTO ' || tableName || 'Relationer VALUES ($1.*)'
  USING NEW;
  RETURN NULL;
END;
$$
LANGUAGE plpgsql;

CREATE TRIGGER relationer_insert_trigger
BEFORE INSERT ON relationer
FOR EACH ROW EXECUTE PROCEDURE relationer_insert_trigger();


-- Relation
CREATE OR REPLACE FUNCTION relation_insert_trigger()
  RETURNS TRIGGER AS $$
DECLARE
  tableName REGCLASS;
BEGIN
--   Get the name of the table that the object references
  SELECT o.tableoid
  FROM objekt o, registrering r, Relationer rl
  WHERE r.ObjektID = o.ID AND r.ID = rl.RegistreringsID
        AND rl.ID = NEW.RelationerID
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

-- Reference
CREATE OR REPLACE FUNCTION reference_insert_trigger()
  RETURNS TRIGGER AS $$
DECLARE
  tableName REGCLASS;
BEGIN
--   Get the name of the table that the object references
  SELECT o.tableoid
  FROM objekt o, registrering r, Relationer relr, Relation rel
  WHERE r.ObjektID = o.ID AND r.ID = relr.RegistreringsID
        AND rl.ID = rel.RelationerID AND rel.ID = NEW.RelationID
  INTO tableName;
  EXECUTE 'INSERT INTO ' || tableName || 'Reference VALUES ($1.*)'
  USING NEW;
  RETURN NULL;
END;
$$
LANGUAGE plpgsql;

CREATE TRIGGER reference_insert_trigger
BEFORE INSERT ON reference
FOR EACH ROW EXECUTE PROCEDURE reference_insert_trigger();
