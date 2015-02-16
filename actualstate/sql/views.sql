CREATE VIEW AttributUpdateView AS SELECT * FROM Attribut;
CREATE VIEW TilstandUpdateView AS SELECT * FROM Tilstand;
CREATE VIEW RelationUpdateView AS SELECT * FROM Relation;

--
-- -- EgenskaberView
-- CREATE OR REPLACE FUNCTION egenskaber_update_view_insert_trigger()
--   RETURNS TRIGGER AS $$
-- DECLARE
--   tableName REGCLASS;
--   a RECORD;
-- BEGIN
--
-- --     Input
-- --     | A |
-- --   |   B   |
-- -------------------
-- --   |   B   |  Result
-- --     Delete old entries which are fully contained by the new range
--     DELETE FROM Egenskaber WHERE
--       RegistreringsID = NEW.RegistreringsID
--       AND (NEW.Virkning).TimePeriod @>
--           (Virkning).TimePeriod;
--
-- --     Input
-- --         |  A  |
-- --   |   B   |
-- -------------------
-- --   |   B   | A |  Result
-- --     The old entry's lower bound is contained within the new range
-- --     Update the old entry's lower bound
--     UPDATE Egenskaber SET Virkning.TimePeriod =
--       TSTZRANGE(UPPER((NEW.Virkning).TimePeriod), UPPER((Virkning).TimePeriod),
--                 '[)')
--     WHERE
--       RegistreringsID = NEW.RegistreringsID
--         AND (NEW.Virkning).TimePeriod @> LOWER((Virkning).TimePeriod);
--
-- --     Input
-- --   |  A  |
-- --       |   B   |
-- -------------------
-- --   | A |   B   |  Result
-- --     The old entry's upper bound is contained within the new range
-- --     Update the old entry's upper bound
--     UPDATE Egenskaber SET Virkning.TimePeriod =
--       TSTZRANGE(LOWER((Virkning).TimePeriod), LOWER((NEW.Virkning).TimePeriod),
--                 '[)')
--     WHERE
--       RegistreringsID = NEW.RegistreringsID
--         AND (NEW.Virkning).TimePeriod @> UPPER((Virkning).TimePeriod);
--
-- --       Input
-- --   |     A     |
-- --       | B |
-- -------------------
-- --   | A'| B |A''|  Result
-- --     The new range is completely contained by the old range
-- --   Store and delete the old A
-- --   Insert the lower old entry to become A'
-- --   Insert two upper old entry to become A''
--   DECLARE
--     old RECORD;
--     newLeftRange TSTZRANGE;
--     newRightRange TSTZRANGE;
--   BEGIN
--     DELETE FROM Egenskaber WHERE
--       RegistreringsID = NEW.RegistreringsID
--       AND (NEW.Virkning).TimePeriod <@ (Virkning).TimePeriod
--     RETURNING * INTO old;
--
--     IF old IS NOT NULL THEN
--       newLeftRange := TSTZRANGE(
--           LOWER((old.Virkning).TimePeriod),
--           LOWER((NEW.Virkning).TimePeriod)
--       );
--
-- --       Don't insert an empty range
--       IF newLeftRange != 'empty' THEN
--         INSERT INTO Egenskaber (RegistreringsID, Virkning, BrugervendtNoegle)
--           VALUES (NEW.RegistreringsID,
--                   ROW(
--                     newLeftRange,
--                     (old.Virkning).AktoerRef,
--                     (old.Virkning).AktoertypeKode,
--                     (old.Virkning).NoteTekst
--                   )::Virkning
--             , old.BrugervendtNoegle);
--       END IF;
--
--       newRightRange := TSTZRANGE(
--           UPPER((NEW.Virkning).TimePeriod),
--           UPPER((old.Virkning).TimePeriod)
--       );
--
-- --       Don't insert an empty range
--       IF newRightRange != 'empty' THEN
--         INSERT INTO Egenskaber (RegistreringsID, Virkning, BrugervendtNoegle)
--           VALUES (NEW.RegistreringsID,
--                   ROW(
--                     newRightRange,
--                     (old.Virkning).AktoerRef,
--                     (old.Virkning).AktoertypeKode,
--                     (old.Virkning).NoteTekst
--                   )::Virkning
--             , old.BrugervendtNoegle);
--       END IF;
--     END IF;
--   END;
--
--   NEW.ID := nextval('egenskaber_id_seq');
--   INSERT INTO Egenskaber VALUES (NEW.*);
--   RETURN NEW;
-- END;
-- $$
-- LANGUAGE plpgsql;
--
-- CREATE TRIGGER egenskaber_update_view_insert_trigger
-- INSTEAD OF INSERT ON EgenskaberUpdateView
-- FOR EACH ROW EXECUTE PROCEDURE egenskaber_update_view_insert_trigger();


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
      TilstandeID = NEW.TilstandeID
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
      TilstandeID = NEW.TilstandeID
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
      TilstandeID = NEW.TilstandeID
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
      TilstandeID = NEW.TilstandeID
      AND (NEW.Virkning).TimePeriod <@ (Virkning).TimePeriod
    RETURNING * INTO old;

    IF old IS NOT NULL THEN
      newLeftRange := TSTZRANGE(
          LOWER((old.Virkning).TimePeriod),
          LOWER((NEW.Virkning).TimePeriod)
      );

--       Don't insert an empty range
      IF newLeftRange != 'empty' THEN
        INSERT INTO Tilstand (TilstandeID, Virkning, Status)
          VALUES (NEW.TilstandeID,
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
        INSERT INTO Tilstand (TilstandeID, Virkning, Status)
          VALUES (NEW.TilstandeID,
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


-- Relation view

CREATE OR REPLACE FUNCTION relation_update_view_insert_trigger()
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
    DELETE FROM Relation WHERE
      RelationerID = NEW.RelationerID
      AND (NEW.Virkning).TimePeriod @>
          (Virkning).TimePeriod;

--     Input
--         |  A  |
--   |   B   |
-------------------
--   |   B   | A |  Result
--     The old entry's lower bound is contained within the new range
--     Update the old entry's lower bound
    UPDATE Relation SET Virkning.TimePeriod =
      TSTZRANGE(UPPER((NEW.Virkning).TimePeriod), UPPER((Virkning).TimePeriod),
                '[)')
    WHERE
      RelationerID = NEW.RelationerID 
        AND (NEW.Virkning).TimePeriod @> LOWER((Virkning).TimePeriod);

--     Input
--   |  A  |
--       |   B   |
-------------------
--   | A |   B   |  Result
--     The old entry's upper bound is contained within the new range
--     Update the old entry's upper bound
    UPDATE Relation SET Virkning.TimePeriod =
      TSTZRANGE(LOWER((Virkning).TimePeriod), LOWER((NEW.Virkning).TimePeriod),
                '[)')
    WHERE
      RelationerID = NEW.RelationerID 
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
    DELETE FROM Relation WHERE
      RelationerID = NEW.RelationerID 
      AND (NEW.Virkning).TimePeriod <@ (Virkning).TimePeriod
    RETURNING * INTO old;

    IF old IS NOT NULL THEN
      newLeftRange := TSTZRANGE(
          LOWER((old.Virkning).TimePeriod),
          LOWER((NEW.Virkning).TimePeriod)
      );

--       Don't insert an empty range
      IF newLeftRange != 'empty' THEN
        INSERT INTO Relation (RelationerID, Virkning)
          VALUES (NEW.RelationerID,
                  ROW(
                    newLeftRange,
                    (old.Virkning).AktoerRef,
                    (old.Virkning).AktoertypeKode,
                    (old.Virkning).NoteTekst
                  )::Virkning);
      END IF;

      newRightRange := TSTZRANGE(
          UPPER((NEW.Virkning).TimePeriod),
          UPPER((old.Virkning).TimePeriod)
      );

--       Don't insert an empty range
      IF newRightRange != 'empty' THEN
        INSERT INTO Relation (RelationerID, Virkning)
          VALUES (NEW.RelationerID,
                  ROW(
                    newRightRange,
                    (old.Virkning).AktoerRef,
                    (old.Virkning).AktoertypeKode,
                    (old.Virkning).NoteTekst
                  )::Virkning);
      END IF;
    END IF;
  END;

  NEW.ID := nextval('relation_id_seq');
  INSERT INTO Relation VALUES (NEW.*);
  RETURN NEW;
END;
$$
LANGUAGE plpgsql;

CREATE TRIGGER relation_update_view_insert_trigger
INSTEAD OF INSERT ON RelationUpdateView
FOR EACH ROW EXECUTE PROCEDURE relation_update_view_insert_trigger();



-- -- RelationsListeUpdateView
-- CREATE OR REPLACE FUNCTION relationsliste_update_view_insert_trigger()
--   RETURNS TRIGGER AS $$
-- BEGIN
--
-- --     Input
-- --     | A |
-- --   |   B   |
-- -------------------
-- --   |   B   |  Result
-- --     Delete old entries which are fully contained by the new range
--     DELETE FROM RelationsListe WHERE
--       RegistreringsID = NEW.RegistreringsID
--       AND (NEW.Virkning).TimePeriod @>
--           (Virkning).TimePeriod;
--
-- --     Input
-- --         |  A  |
-- --   |   B   |
-- -------------------
-- --   |   B   | A |  Result
-- --     The old entry's lower bound is contained within the new range
-- --     Update the old entry's lower bound
--     UPDATE RelationsListe SET Virkning.TimePeriod =
--       TSTZRANGE(UPPER((NEW.Virkning).TimePeriod), UPPER((Virkning).TimePeriod),
--                 '[)')
--     WHERE
--       RegistreringsID = NEW.RegistreringsID
--         AND (NEW.Virkning).TimePeriod @> LOWER((Virkning).TimePeriod);
--
-- --     Input
-- --   |  A  |
-- --       |   B   |
-- -------------------
-- --   | A |   B   |  Result
-- --     The old entry's upper bound is contained within the new range
-- --     Update the old entry's upper bound
--     UPDATE RelationsListe SET Virkning.TimePeriod =
--       TSTZRANGE(LOWER((Virkning).TimePeriod), LOWER((NEW.Virkning).TimePeriod),
--                 '[)')
--     WHERE
--       RegistreringsID = NEW.RegistreringsID
--         AND (NEW.Virkning).TimePeriod @> UPPER((Virkning).TimePeriod);
--
-- --       Input
-- --   |     A     |
-- --       | B |
-- -------------------
-- --   | A'| B |A''|  Result
-- --     The new range is completely contained by the old range
-- --   Store and delete the old A
-- --   Insert the lower old entry to become A'
-- --   Insert two upper old entry to become A''
--   DECLARE
--     old RECORD;
--     newLeftRange TSTZRANGE;
--     newRightRange TSTZRANGE;
--   BEGIN
--     DELETE FROM RelationsListe WHERE
--       RegistreringsID = NEW.RegistreringsID
--       AND (NEW.Virkning).TimePeriod <@ (Virkning).TimePeriod
--     RETURNING * INTO old;
--
--     IF old IS NOT NULL THEN
--       newLeftRange := TSTZRANGE(
--           LOWER((old.Virkning).TimePeriod),
--           LOWER((NEW.Virkning).TimePeriod)
--       );
--
-- --       Don't insert an empty range
--       IF newLeftRange != 'empty' THEN
--         INSERT INTO RelationsListe (RegistreringsID, Virkning, BrugervendtNoegle)
--           VALUES (NEW.RegistreringsID,
--                   ROW(
--                     newLeftRange,
--                     (old.Virkning).AktoerRef,
--                     (old.Virkning).AktoertypeKode,
--                     (old.Virkning).NoteTekst
--                   )::Virkning
--             , old.BrugervendtNoegle);
--       END IF;
--
--       newRightRange := TSTZRANGE(
--           UPPER((NEW.Virkning).TimePeriod),
--           UPPER((old.Virkning).TimePeriod)
--       );
--
-- --       Don't insert an empty range
--       IF newRightRange != 'empty' THEN
--         INSERT INTO RelationsListe (RegistreringsID, Virkning, BrugervendtNoegle)
--           VALUES (NEW.RegistreringsID,
--                   ROW(
--                     newRightRange,
--                     (old.Virkning).AktoerRef,
--                     (old.Virkning).AktoertypeKode,
--                     (old.Virkning).NoteTekst
--                   )::Virkning
--             , old.BrugervendtNoegle);
--       END IF;
--     END IF;
--   END;
--
--   NEW.ID := nextval('relationsliste_id_seq');
--   INSERT INTO RelationsListe VALUES (NEW.*);
--   RETURN NEW;
-- END;
-- $$
-- LANGUAGE plpgsql;
--
-- CREATE TRIGGER relationsliste_update_view_insert_trigger
-- INSTEAD OF INSERT ON RelationsListeUpdateView
-- FOR EACH ROW EXECUTE PROCEDURE relationsliste_update_view_insert_trigger();
