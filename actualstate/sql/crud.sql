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

CREATE OR REPLACE FUNCTION _ACTUAL_STATE_NEW_REGISTRATION(
  inputID UUID,
  LivscyklusKode LivscyklusKode,
  BrugerRef UUID,
  doCopy BOOLEAN DEFAULT FALSE
) RETURNS Registrering AS $$
DECLARE
  registreringTime        TIMESTAMPTZ := transaction_timestamp();
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


CREATE OR REPLACE FUNCTION ACTUAL_STATE_UPDATE(
  inputID UUID,
  Attributter AttributterType[],
  Tilstande TilstandeType[],
  Relationer RelationerType[]
)
  RETURNS Registrering AS $$
DECLARE
  result Registrering;
  newRegistreringID BIGINT;
BEGIN
  result := _ACTUAL_STATE_NEW_REGISTRATION(
      inputID, 'Rettet', NULL, doCopy := TRUE
  );

  newRegistreringID := result.ID;

-- --   Loop through attributes and add them to the registration
--   DECLARE
--     attr EgenskaberType;
--     newEgenskaberID BIGINT;
--   BEGIN
--     FOREACH attr in ARRAY Attributter
--     LOOP
-- --  Insert into our view which has a trigger which handles updating ranges
-- --  if the new values overlap the old
--       INSERT INTO EgenskaberUpdateView (RegistreringsID, Virkning, BrugervendtNoegle)
--       VALUES (newRegistreringID, attr.Virkning, attr.BrugervendtNoegle)
--       RETURNING ID INTO newEgenskaberID;
--
--       DECLARE
--         prop EgenskabsType;
--       BEGIN
--         FOREACH prop in ARRAY attr.Properties
--         LOOP
-- --           Update existing properties if we can
--           UPDATE Egenskab SET Value = prop.Value
--             WHERE EgenskaberID = newEgenskaberID AND Name = prop.Name;
--           IF NOT FOUND THEN
-- --             If we didn't update anything, we have to insert new properties
--             INSERT INTO Egenskab (EgenskaberID, Name, Value)
--             VALUES (newEgenskaberID, prop.Name, prop.Value);
--           END IF;
--         END LOOP;
--       END;
--     END LOOP;
--   END;

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
