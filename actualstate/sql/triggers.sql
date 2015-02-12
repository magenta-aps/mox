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

-- EgenskaberView
CREATE OR REPLACE FUNCTION egenskaber_update_view_insert_trigger()
  RETURNS TRIGGER AS $$
DECLARE
  tableName REGCLASS;
  a RECORD;
BEGIN

--     Input
--     | A |
--   |   B   |
-------------------
--   |   B   |  Result
--     Delete old entries which are fully contained by the new range
    DELETE FROM Egenskaber WHERE
      RegistreringsID = NEW.RegistreringsID
      AND (NEW.Virkning).TimePeriod @>
          (Virkning).TimePeriod;

--     Input
--         |  A  |
--   |   B   |
-------------------
--   |   B   | A |  Result
--     The old entry's lower bound is contained within the new range
--     Update the old entry's lower bound
    UPDATE Egenskaber SET Virkning.TimePeriod =
      TSTZRANGE(UPPER((NEW.Virkning).TimePeriod), UPPER((Virkning).TimePeriod),
                '[)')
    WHERE
      RegistreringsID = NEW.RegistreringsID
        AND (NEW.Virkning).TimePeriod @> LOWER((Virkning).TimePeriod);

--     Input
--   |  A  |
--       |   B   |
-------------------
--   | A |   B   |  Result
--     The old entry's upper bound is contained within the new range
--     Update the old entry's upper bound
    UPDATE Egenskaber SET Virkning.TimePeriod =
      TSTZRANGE(LOWER((Virkning).TimePeriod), LOWER((NEW.Virkning).TimePeriod),
                '[)')
    WHERE
      RegistreringsID = NEW.RegistreringsID
        AND (NEW.Virkning).TimePeriod @> UPPER((Virkning).TimePeriod);

--       Input
--   |     A     |
--       | B |
-------------------
--   | A'| B |A''|  Result
--     The new range is completely contained by the old range
--   Store and delete the old A
--   Insert the lower old entry to become A'
--   Insert two upper old entry to become A''
  DECLARE
    old RECORD;
    newLeftRange TSTZRANGE;
    newRightRange TSTZRANGE;
  BEGIN
    DELETE FROM Egenskaber WHERE
      RegistreringsID = NEW.RegistreringsID
      AND (NEW.Virkning).TimePeriod <@ (Virkning).TimePeriod
    RETURNING * INTO old;

    IF old IS NOT NULL THEN
      newLeftRange := TSTZRANGE(
          LOWER((old.Virkning).TimePeriod),
          LOWER((NEW.Virkning).TimePeriod)
      );

--       Don't insert an empty range
      IF newLeftRange != 'empty' THEN
        INSERT INTO Egenskaber (RegistreringsID, Virkning, BrugervendtNoegle)
          VALUES (NEW.RegistreringsID,
                  ROW(
                    newLeftRange,
                    (old.Virkning).AktoerRef,
                    (old.Virkning).AktoertypeKode,
                    (old.Virkning).NoteTekst
                  )::Virkning
            , old.BrugervendtNoegle);
      END IF;

      newRightRange := TSTZRANGE(
          UPPER((NEW.Virkning).TimePeriod),
          UPPER((old.Virkning).TimePeriod)
      );

--       Don't insert an empty range
      IF newRightRange != 'empty' THEN
        INSERT INTO Egenskaber (RegistreringsID, Virkning, BrugervendtNoegle)
          VALUES (NEW.RegistreringsID,
                  ROW(
                    newRightRange,
                    (old.Virkning).AktoerRef,
                    (old.Virkning).AktoertypeKode,
                    (old.Virkning).NoteTekst
                  )::Virkning
            , old.BrugervendtNoegle);
      END IF;
    END IF;
  END;

  NEW.ID := nextval('egenskaber_id_seq');
  INSERT INTO Egenskaber VALUES (NEW.*);
  RETURN NEW;
END;
$$
LANGUAGE plpgsql;

CREATE TRIGGER egenskaber_update_view_insert_trigger
INSTEAD OF INSERT ON EgenskaberUpdateView
FOR EACH ROW EXECUTE PROCEDURE egenskaber_update_view_insert_trigger();

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

-- Tilstand view
CREATE OR REPLACE FUNCTION tilstand_update_view_insert_trigger()
  RETURNS TRIGGER AS $$
DECLARE
  tableName REGCLASS;
  a RECORD;
BEGIN

--     Input
--     | A |
--   |   B   |
-------------------
--   |   B   |  Result
--     Delete old entries which are fully contained by the new range
    DELETE FROM Tilstand WHERE
      RegistreringsID = NEW.RegistreringsID
      AND (NEW.Virkning).TimePeriod @>
          (Virkning).TimePeriod;

--     Input
--         |  A  |
--   |   B   |
-------------------
--   |   B   | A |  Result
--     The old entry's lower bound is contained within the new range
--     Update the old entry's lower bound
    UPDATE Tilstand SET Virkning.TimePeriod =
      TSTZRANGE(UPPER((NEW.Virkning).TimePeriod), UPPER((Virkning).TimePeriod),
                '[)')
    WHERE
      RegistreringsID = NEW.RegistreringsID
        AND (NEW.Virkning).TimePeriod @> LOWER((Virkning).TimePeriod);

--     Input
--   |  A  |
--       |   B   |
-------------------
--   | A |   B   |  Result
--     The old entry's upper bound is contained within the new range
--     Update the old entry's upper bound
    UPDATE Tilstand SET Virkning.TimePeriod =
      TSTZRANGE(LOWER((Virkning).TimePeriod), LOWER((NEW.Virkning).TimePeriod),
                '[)')
    WHERE
      RegistreringsID = NEW.RegistreringsID
        AND (NEW.Virkning).TimePeriod @> UPPER((Virkning).TimePeriod);

--       Input
--   |     A     |
--       | B |
-------------------
--   | A'| B |A''|  Result
--     The new range is completely contained by the old range
--   Store and delete the old A
--   Insert the lower old entry to become A'
--   Insert two upper old entry to become A''
  DECLARE
    old RECORD;
    newLeftRange TSTZRANGE;
    newRightRange TSTZRANGE;
  BEGIN
    DELETE FROM Tilstand WHERE
      RegistreringsID = NEW.RegistreringsID
      AND (NEW.Virkning).TimePeriod <@ (Virkning).TimePeriod
    RETURNING * INTO old;

    IF old IS NOT NULL THEN
      newLeftRange := TSTZRANGE(
          LOWER((old.Virkning).TimePeriod),
          LOWER((NEW.Virkning).TimePeriod)
      );

--       Don't insert an empty range
      IF newLeftRange != 'empty' THEN
        INSERT INTO Tilstand (RegistreringsID, Virkning, Status)
          VALUES (NEW.RegistreringsID,
                  ROW(
                    newLeftRange,
                    (old.Virkning).AktoerRef,
                    (old.Virkning).AktoertypeKode,
                    (old.Virkning).NoteTekst
                  )::Virkning
            , old.Status);
      END IF;

      newRightRange := TSTZRANGE(
          UPPER((NEW.Virkning).TimePeriod),
          UPPER((old.Virkning).TimePeriod)
      );

--       Don't insert an empty range
      IF newRightRange != 'empty' THEN
        INSERT INTO Tilstand (RegistreringsID, Virkning, Status)
          VALUES (NEW.RegistreringsID,
                  ROW(
                    newRightRange,
                    (old.Virkning).AktoerRef,
                    (old.Virkning).AktoertypeKode,
                    (old.Virkning).NoteTekst
                  )::Virkning
            , old.Status);
      END IF;
    END IF;
  END;

  NEW.ID := nextval('tilstand_id_seq');
  INSERT INTO Tilstand VALUES (NEW.*);
  RETURN NEW;
END;
$$
LANGUAGE plpgsql;

CREATE TRIGGER tilstand_update_view_insert_trigger
INSTEAD OF INSERT ON TilstandUpdateView
FOR EACH ROW EXECUTE PROCEDURE tilstand_update_view_insert_trigger();

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
