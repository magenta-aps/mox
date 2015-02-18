CREATE OR REPLACE FUNCTION ACTUAL_STATE_CREATE(
    ObjektType REGCLASS,
    Attributter AttributterType[],
    Tilstande TilstandeType[],
    Relationer RelationerType[] = ARRAY[]::RelationerType[]
)
  RETURNS Objekt AS $$
DECLARE
  objektUUID         uuid;
  result             Objekt;
  registreringResult Registrering;
BEGIN
  objektUUID := uuid_generate_v4();

--   Create object
  EXECUTE 'INSERT INTO ' || ObjektType || '(ID) VALUES($1)
  RETURNING *' INTO result USING objektUUID;

--   Create Registrering
--   TODO: Insert Note into registrering?
  registreringResult := _ACTUAL_STATE_NEW_REGISTRATION(
      objektUUID, 'Opstaaet', NULL
  );

  PERFORM _ACTUAL_STATE_COPY_INTO_REGISTRATION(registreringResult.ID,
                                               Attributter, Tilstande, Relationer);
  RETURN result;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION ACTUAL_STATE_READ(
    ObjektType REGCLASS,
    ID UUID,
    VirkningPeriod TSTZRANGE,
    RegistreringPeriod TSTZRANGE,
    filteredAttributesRef REFCURSOR,
    filteredStatesRef REFCURSOR
)
  RETURNS SETOF REFCURSOR AS $$
DECLARE
  inputID UUID := ID;
  result Registrering;
BEGIN
  -- Get the whole registrering which overlaps with the registrering (system)
  -- time period.
  SELECT * FROM Registrering
    JOIN Objekt ON Objekt.ID = Registrering.ObjektID
  WHERE Objekt.ID = inputID AND
      -- Make sure the object is of the type we want
      Objekt.tableoid = ObjektType AND
      -- && operator means ranges overlap
        Registrering.TimePeriod && RegistreringPeriod
    -- We only want the first result
    LIMIT 1
  INTO result;

  -- Filter the attributes' registrering by the virkning (application) time
  -- period
  OPEN filteredAttributesRef FOR SELECT * FROM Egenskaber
  WHERE RegistreringsID = result.ID AND
        (Virkning).TimePeriod && VirkningPeriod;

  ---
  OPEN filteredStatesRef FOR SELECT * FROM Tilstand
  WHERE RegistreringsID = result.ID AND
        (Virkning).TimePeriod && VirkningPeriod;
  RETURN;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION _ACTUAL_STATE_COPY_ATTRIBUTTER(
  oldRegistreringsID BIGINT,
  newRegistreringsID BIGINT
) RETURNS VOID AS $$
DECLARE
  r Attributter;
  newAttributterID BIGINT;

  s Attribut;
  newAttributID BIGINT;

  t AttributFelt;
BEGIN
  FOR r in SELECT * FROM Attributter WHERE RegistreringsID =
                                           oldRegistreringsID
  LOOP
    INSERT INTO Attributter (RegistreringsID, Name)
    VALUES (newRegistreringsID, r.Name);

    newAttributterID := lastval();

    FOR s in SELECT * FROM Attribut a1
      JOIN Attributter a2 ON a1.AttributterID = a2.ID WHERE
      a2.ID = r.ID
    LOOP
      INSERT INTO Attribut (AttributterID, Virkning) VALUES
        (newAttributterID, s.Virkning);

      newAttributID := lastval();

      FOR t in SELECT * FROM AttributFelt af
        JOIN Attribut a1 ON af.AttributID = a1.ID
        JOIN Attributter a2 ON a1.AttributterID = a2.ID WHERE
        a2.ID = r.ID
      LOOP
        INSERT INTO AttributFelt (AttributID, Name, Value) VALUES
          (newAttributID, t.Name, t.Value);
      END LOOP;
    END LOOP;

  END LOOP;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION _ACTUAL_STATE_COPY_TILSTANDE(
  oldRegistreringsID BIGINT,
  newRegistreringsID BIGINT
) RETURNS VOID AS $$
DECLARE
  r Tilstande;
  newTilstandeID BIGINT;
  s Tilstand;
BEGIN
  FOR r in SELECT *
           FROM Tilstande WHERE RegistreringsID = oldRegistreringsID
  LOOP
    INSERT INTO Tilstande (RegistreringsID, Name)
    VALUES (newRegistreringsID, r.Name);

    newTilstandeID := lastval();

    FOR s in SELECT *
             FROM Tilstand t1 JOIN Tilstande t2 ON t1.TilstandeID = t2.ID
             WHERE t2.RegistreringsID = oldRegistreringsID
    LOOP
      INSERT INTO Tilstand (TilstandeID, Virkning, Status)
      VALUES (newTilstandeID, s.Virkning, s.Status);
    END LOOP;
  END LOOP;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION _ACTUAL_STATE_COPY_RELATIONER(
  oldRegistreringsID BIGINT,
  newRegistreringsID BIGINT
) RETURNS VOID AS $$
DECLARE
  rels Relationer;
  newRelationerID BIGINT;

  rel Relation;
  newRelationID BIGINT;

  ref Reference;
BEGIN
  FOR rels in SELECT * FROM Relationer WHERE RegistreringsID =
                                             oldRegistreringsID
  LOOP
    INSERT INTO Relationer (RegistreringsID, Name)
    VALUES (newRegistreringsID, rels.Name);

    newRelationerID := lastval();

    FOR rel in SELECT * FROM Relation r1
      JOIN Relationer r2 ON r1.RelationerID = r2.ID
    WHERE r2.ID = rels.ID
    LOOP
      INSERT INTO Relation (RelationerID, Virkning) VALUES
        (newRelationerID, rel.Virkning);

      newRelationID := lastval();

      FOR ref in SELECT * FROM Reference rf
        JOIN Relation r1 ON rf.RelationID = r1.ID
        JOIN Relationer r2 ON r1.RelationerID = r2.ID
      WHERE r2.ID = rels.ID
      LOOP
        INSERT INTO Reference (RelationID, ReferenceID) VALUES
          (newRelationID, ref.ReferenceID);
      END LOOP;
    END LOOP;
  END LOOP;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION _ACTUAL_STATE_COPY_REGISTRERING(
  oldRegistreringsID BIGINT,
  newRegistreringsID BIGINT
) RETURNS VOID AS $$
BEGIN
  PERFORM _ACTUAL_STATE_COPY_ATTRIBUTTER(oldRegistreringsID,
                                         newRegistreringsID);

  PERFORM _ACTUAL_STATE_COPY_TILSTANDE(oldRegistreringsID,
                                       newRegistreringsID);

  PERFORM _ACTUAL_STATE_COPY_RELATIONER(oldRegistreringsID,
                                        newRegistreringsID);
END;
$$ LANGUAGE plpgsql;

-- Creates a new registrering and optionally copies the data (attributter,
-- tilstande, relationer) from the previous registrering into the new one.
-- The upper bounds of the previous registrering are set to be the lower
-- bounds of the new one.
CREATE OR REPLACE FUNCTION _ACTUAL_STATE_NEW_REGISTRATION(
  inputID UUID,
  LivscyklusKode LivscyklusKode,
  BrugerRef UUID,
  doCopy BOOLEAN DEFAULT FALSE
) RETURNS Registrering AS $$
DECLARE
  registreringTime        TIMESTAMPTZ := clock_timestamp();
  result                  Registrering;
  newRegistreringsID       BIGINT;
  oldRegistreringsID BIGINT;
BEGIN
-- Update previous Registrering's time range to end now, exclusive
  UPDATE Registrering
    SET TimePeriod =
      TSTZRANGE(lower(TimePeriod), registreringTime)
    WHERE ObjektID = inputID AND upper(TimePeriod) = 'infinity'
    RETURNING ID INTO oldRegistreringsID;
--   Create Registrering starting from now until infinity
  INSERT INTO Registrering (ObjektID, TimePeriod, Livscykluskode, BrugerRef)
  VALUES (
    inputID,
    TSTZRANGE(registreringTime, 'infinity', '[]'), LivscyklusKode, BrugerRef
  );

  SELECT * FROM Registrering WHERE ID = lastval() INTO result;

  newRegistreringsID := result.ID;

  IF doCopy
  THEN
    PERFORM _ACTUAL_STATE_COPY_REGISTRERING(oldRegistreringsID,
                                            newRegistreringsID);
  END IF;

  RETURN result;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION _ACTUAL_STATE_COPY_INTO_REGISTRATION(
  inputRegistreringsID BIGINT,
  Attributter AttributterType[],
  Tilstande TilstandeType[],
  Relationer RelationerType[]
)
  RETURNS VOID AS $$
DECLARE
BEGIN
--   Loop through attributes and add them to the registration
  DECLARE
    attrs AttributterType;
    newAttributterID BIGINT;
  BEGIN
    FOREACH attrs in ARRAY Attributter
    LOOP
      INSERT INTO Attributter (RegistreringsID, Name)
      VALUES (inputRegistreringsID, attrs.Name);

      newAttributterID := lastval();

      DECLARE
        attr AttributType;
        newAttributID BIGINT;
      BEGIN
        FOREACH attr in ARRAY attrs.Attributter
        LOOP
          INSERT INTO Attribut (AttributterID, Virkning)
          VALUES (newAttributterID, attr.Virkning);

          newAttributID = lastval();

          DECLARE
            felt AttributFeltType;
          BEGIN
            FOREACH felt in ARRAY attr.AttributFelter
            LOOP
              INSERT INTO AttributFelt (AttributID, Name, Value)
              VALUES (newAttributID, felt.Name, felt.Value);
            END LOOP;
          END;
        END LOOP;
      END;
    END LOOP;
  END;

--   Loop through states and add them to the registration
  DECLARE
    states TilstandeType;
    newTilstandeID BIGINT;
  BEGIN
    FOREACH states in ARRAY Tilstande
    LOOP
      INSERT INTO Tilstande (RegistreringsID, Name)
      VALUES (inputRegistreringsID, states.Name);

      newTilstandeID := lastval();

      DECLARE
        state TilstandType;
      BEGIN
        FOREACH state in ARRAY states.Tilstande
        LOOP
          INSERT INTO Tilstand (TilstandeID, Virkning, Status)
          VALUES (newTilstandeID, state.Virkning, state.Status);
        END LOOP;
      END;
    END LOOP;
  END;

--   Loop through relations and add them to the registration
  DECLARE
    rels RelationerType;
    newRelationerID BIGINT;
  BEGIN
    FOREACH rels in ARRAY Relationer
    LOOP
      INSERT INTO Relationer (RegistreringsID, Name)
      VALUES (inputRegistreringsID, rels.Name);

      newRelationerID := lastval();

      DECLARE
        rel RelationType;
        newRelationID BIGINT;
      BEGIN
        FOREACH rel in ARRAY rels.Relationer
        LOOP
          INSERT INTO Relation (RelationerID, Virkning)
          VALUES (newRelationerID, rel.Virkning);

          newRelationID := lastval();

          INSERT INTO Reference (RelationID, ReferenceID)
          SELECT newRelationID, * FROM UNNEST(rel.ReferenceIDer);
        END LOOP;
      END;
    END LOOP;
  END;
END;
$$ LANGUAGE plpgsql;

-- Merges the attributter contained in inputAttributID into a new Attribut
CREATE OR REPLACE FUNCTION _ACTUAL_STATE_MERGE_ATTR(
  newAttributterID BIGINT,
  newPeriod TSTZRANGE,
  inputAttribut AttributType,
  oldAttributID BIGINT
) RETURNS VOID AS $$
DECLARE
  attrFelt AttributFeltType;
  newAttributID BIGINT;
BEGIN
  INSERT INTO Attribut (AttributterID, Virkning) VALUES
    (newAttributterID,
     ROW(
       newPeriod,
       (inputAttribut.Virkning).AktoerRef,
       (inputAttribut.Virkning).AktoertypeKode,
       (inputAttribut.Virkning).NoteTekst
     )::Virkning
    );

  newAttributID := lastval();

  INSERT INTO AttributFelt (AttributID, Name, Value)
  WITH newFields(Name, Value) AS
        (SELECT f.Name, f.Value FROM UNNEST(inputAttribut.AttributFelter) AS f),
       oldFields AS (SELECT Name, Value FROM AttributFelt af JOIN Attribut at
                     ON af.AttributID = at.ID
                     WHERE at.ID = oldAttributID)
  SELECT newAttributID, Name, Value FROM newFields
  UNION
  SELECT newAttributID, Name, Value FROM oldFields WHERE (
    NOT Name IN (SELECT Name FROM newFields)
  );
END;
$$ LANGUAGE plpgsql;

-- Copies the attribut contained in oldAttributID into a new Attribut with
-- new period and newAttributterID
CREATE OR REPLACE FUNCTION _ACTUAL_STATE_COPY_ATTR(
  newAttributterID BIGINT,
  newPeriod TSTZRANGE,
  oldAttributID BIGINT
) RETURNS VOID AS $$
DECLARE
  attrFelt AttributFeltType;
  newAttributID BIGINT;
  oldVirkning Virkning;
BEGIN
  RAISE NOTICE 'COPY ATTR FROM %', oldAttributID;

  INSERT INTO Attribut (AttributterID, Virkning)
  SELECT newAttributterID,
    ROW(
      newPeriod,
      (a.Virkning).AktoerRef,
      (a.Virkning).AktoertypeKode,
      (a.Virkning).NoteTekst
    )::Virkning
  FROM Attribut a WHERE a.ID = oldAttributID;

  newAttributID := lastval();

  INSERT INTO AttributFelt (AttributID, Name, Value)
    SELECT newAttributID, Name, Value FROM AttributFelt af JOIN Attribut at
        ON af.AttributID = at.ID
    WHERE at.ID = oldAttributID;
END;
$$ LANGUAGE plpgsql;

-- Returns the registrering immediately previous to the one given
CREATE OR REPLACE FUNCTION _ACTUAL_STATE_GET_PREV_REGISTRERING(Registrering)
  RETURNS Registrering AS
  'SELECT * FROM Registrering WHERE
    ObjektID = $1.ObjektID AND UPPER(TimePeriod) = LOWER($1.TimePeriod)'
LANGUAGE sql IMMUTABLE;

CREATE OR REPLACE FUNCTION ACTUAL_STATE_UPDATE(
  inputID UUID,
  Attributter AttributterType[],
  Tilstande TilstandeType[],
  Relationer RelationerType[]
)
  RETURNS Registrering AS $$
DECLARE
  result Registrering;
  oldRegistreringID BIGINT;
  newRegistreringID BIGINT;
BEGIN
  result := _ACTUAL_STATE_NEW_REGISTRATION(
      inputID, 'Rettet', NULL
  );

  newRegistreringID := result.ID;

  SELECT ID FROM _ACTUAL_STATE_GET_PREV_REGISTRERING(result) INTO
    oldRegistreringID;

--   Copy Tilstande and Relationer
--   NOTE: Attributter are not copied directly and are handled differently
  PERFORM _ACTUAL_STATE_COPY_TILSTANDE(oldRegistreringID,
                                       newRegistreringID);
  PERFORM _ACTUAL_STATE_COPY_RELATIONER(oldRegistreringID,
                                        newRegistreringID);

--   Loop through attributes and add them to the registration
  DECLARE
    attrs AttributterType;
    newAttributterID BIGINT;
    attr AttributType;
  BEGIN
--     Copy the old attributter into the new registrering
    INSERT INTO Attributter (RegistreringsID, Name)
      SELECT newRegistreringId, Name FROM Attributter WHERE RegistreringsID =
                                                            oldRegistreringID;

--     Loop through each new attributter
    FOREACH attrs in ARRAY Attributter
    LOOP
      SELECT ID from Attributter
      WHERE RegistreringsID = newRegistreringID AND Name = attrs.Name
      INTO newAttributterID;
      IF newAttributterID IS NULL THEN
        INSERT INTO Attributter (RegistreringsID, Name) VALUES
            (newRegistreringID, attrs.Name);
        newAttributterID := lastval();
      END IF;

      FOREACH attr in ARRAY attrs.Attributter
      LOOP
        DECLARE
          r RECORD;
          lastPeriod TSTZRANGE := NULL;
          insertPeriods TSTZRANGE[];
        BEGIN
          RAISE NOTICE 'Adding attr %', attr;
          FOR r IN
            WITH cte(r) AS (SELECT (attr.Virkning).TimePeriod),
            t AS (SELECT (Virkning).TimePeriod AS period, at.ID AS attrID FROM
                Attribut at
                JOIN Attributter att ON at.AttributterID = att.ID,
                cte c
                WHERE att.RegistreringsID = oldRegistreringID
                      AND att.Name = attrs.Name
                      AND at.period && c.r
              )
            SELECT * FROM (
              SELECT t.period * tstzrange(NULL, lower(c.r), '(]') - c.r AS period,
                     FALSE AS merge,
                     t.attrID AS attrID
              FROM t, cte c
              UNION ALL
              SELECT t.period * c.r AS period,
                     TRUE AS merge,
                     t.attrID AS attrID
              FROM t, cte c
              UNION ALL
              SELECT t.period * tstzrange(upper(c.r), NULL, '[)') - c.r AS period,
                     FALSE AS merge,
                     t.attrID AS attrID
              FROM t, cte c
            ) sub WHERE period <> 'empty' ORDER BY period LOOP

            IF r.merge THEN
--                 DO merge into new Attribut based on old (r.attrID)
              RAISE NOTICE 'Merge % into %', attr, r.period;
              PERFORM _ACTUAL_STATE_MERGE_ATTR(newAttributterID,
                                                r.period,
                                                attr, r.attrID);
            ELSE
              RAISE NOTICE 'Copy OLD attr %', r.period;
--                 Copy old values from r.attrID into new Attribut
              PERFORM _ACTUAL_STATE_COPY_ATTR(newAttributterID,
                                              r.period,
                                              r.attrID);
            END IF;

--               If this is the first range being looped through AND
--                 the new range is lower than the old
            IF lastPeriod IS NULL AND LOWER((attr.Virkning).TimePeriod) <
                                      LOWER(r.period) THEN
--               Add the first new range to our array
              insertPeriods = insertPeriods ||
                              (attr.Virkning).TimePeriod *
                              TSTZRANGE(NULL, lower(r.period), '(]') - r.period;
--               If the last period is NOT adjacent to this period
            ELSEIF NOT r.period -|- lastPeriod THEN
--                 Add the period in between (the hole) to our array
              insertPeriods = insertPeriods || TSTZRANGE(
                  upper(lastPeriod), lower(r.period),
--                       The bounds are the complement of the original bounds
                      concat(
                        CASE WHEN upper_inc(lastPeriod) THEN '(' ELSE '[' END,
                        CASE WHEN lower_inc(r.period) THEN ')' ELSE ']' END
                      )
              );
            END IF;
            lastPeriod := r.period;
          END LOOP;

--             If the new range extends past the last range, add the period
--               that extends after
          IF lastPeriod IS NOT NULL AND UPPER((attr.Virkning).TimePeriod)
                                        > UPPER(lastPeriod) THEN
            insertPeriods = insertPeriods ||
                            (attr.Virkning).TimePeriod *
                            TSTZRANGE(upper(lastPeriod), NULL, '[)') - lastPeriod;
          END IF;

--           Insert new values into holes based on insertPeriods array
          DECLARE
            section TSTZRANGE;
            newAttributID BIGINT;
            BEGIN
            FOREACH section IN ARRAY insertPeriods LOOP
              INSERT INTO Attribut (AttributterID, Virkning) VALUES
                (newAttributterID,
                 ROW(
                  section,
                   (attr.Virkning).AktoerRef,
                   (attr.Virkning).AktoertypeKode,
                   (attr.Virkning).NoteTekst
                 )::Virkning
                );

              newAttributID := lastval();

              INSERT INTO AttributFelt (AttributID, Name, Value)
              WITH newFields(Name, Value) AS
                (SELECT f.Name, f.Value FROM UNNEST(attr.AttributFelter) AS f)
                SELECT newAttributID, Name, Value FROM newFields;
            END LOOP;
          END;

--           TODO: Insert non-overlapping old values
        END;
      END LOOP;
    END LOOP;
  END;

--   Loop through states and add them to the registration
  DECLARE
    states TilstandeType;
    newTilstandeID BIGINT;
    state TilstandType;
  BEGIN
    FOREACH states in ARRAY Tilstande
    LOOP
      SELECT ID FROM Tilstande
        WHERE RegistreringsID = newRegistreringID
              AND Name = states.Name INTO newTilstandeID;
      IF newTilstandeID IS NULL THEN
        INSERT INTO Tilstande (RegistreringsID, Name)
          VALUES (newRegistreringID, states.Name);
        newTilstandeID := lastval();
      END IF;

      FOREACH state in ARRAY states.Tilstande
      LOOP
--  Insert into our view which has a trigger which handles updating ranges
--  if the new values overlap the old
        INSERT INTO TilstandUpdateView (TilstandeID, Virkning, Status)
        VALUES (newTilstandeID, state.Virkning, state.Status);
      END LOOP;
    END LOOP;
  END;

--   Loop through relations and add them to the registration
  DECLARE
    rels RelationerType;
    newRelationerID BIGINT;
  BEGIN
    FOREACH rels in ARRAY Relationer
    LOOP
      SELECT ID FROM Relationer
      WHERE RegistreringsID = newRegistreringID
            AND Name = rels.Name INTO newRelationerID;
      IF newRelationerID IS NULL THEN
        INSERT INTO Tilstande (RegistreringsID, Name)
        VALUES (newRegistreringID, rels.Name);
        newRelationerID := lastval();
      END IF;

      DECLARE
        rel RelationType;
        newRelationID BIGINT;
      BEGIN
        FOREACH rel in ARRAY rels.Relationer
        LOOP
          INSERT INTO RelationUpdateView (RelationerID, Virkning)
          VALUES (newRelationerID, rel.Virkning);

          newRelationID := lastval();

          INSERT INTO Reference (RelationID, ReferenceID)
            SELECT newRelationID, * FROM UNNEST(rel.ReferenceIDer);
        END LOOP;
      END;
    END LOOP;
  END;

  RETURN result;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION ACTUAL_STATE_DELETE(
  ObjektType REGCLASS,
  inputID UUID
)
  RETURNS Registrering AS $$
DECLARE
  result Registrering;
BEGIN
  RETURN _ACTUAL_STATE_NEW_REGISTRATION(
      inputID, 'Slettet', NULL, doCopy := TRUE
  );
END;
$$ LANGUAGE plpgsql;



CREATE OR REPLACE FUNCTION ACTUAL_STATE_PASSIVE(
  ObjektType REGCLASS,
  inputID UUID
)
  RETURNS Registrering AS $$
BEGIN
  RETURN _ACTUAL_STATE_NEW_REGISTRATION(
      inputID, 'Passiveret', NULL, doCopy := TRUE
  );
END;
$$ LANGUAGE plpgsql;
