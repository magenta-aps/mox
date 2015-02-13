CREATE OR REPLACE FUNCTION ACTUAL_STATE_CREATE(
    ObjektType REGCLASS,
    Attributter EgenskaberType[],
    Tilstande TilstandsType[],
    Relationer RelationsListeType[] = ARRAY[]::RelationsListeType[]
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
--
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
      r Egenskaber;
      newEgenskaberID BIGINT;
      s Egenskab;
    BEGIN
      FOR r in SELECT * FROM Egenskaber WHERE RegistreringsID =
                                              oldRegistreringsID
      LOOP
        INSERT INTO Egenskaber (RegistreringsID, Virkning, BrugervendtNoegle)
        VALUES (newRegistreringsID, r.Virkning, r.BrugervendtNoegle);

        newEgenskaberID := lastval();

        FOR s in SELECT * FROM Egenskab e1
          JOIN Egenskaber e2 ON e1.EgenskaberID = e2.ID WHERE
          e2.ID = r.ID
        LOOP
          INSERT INTO Egenskab (EgenskaberID, Name, Value) VALUES
            (newEgenskaberID, s.Name, s.Value);
        END LOOP;

      END LOOP;
    END;

    DECLARE
      r RECORD;
    BEGIN
      FOR r in SELECT Virkning, Status
               FROM Tilstand WHERE RegistreringsID = oldRegistreringsID
      LOOP
        INSERT INTO Tilstand (RegistreringsID, Virkning, Status)
        VALUES (newRegistreringsID, r.Virkning, r.Status);
      END LOOP;
    END;

    DECLARE
      relList RelationsListe;
      newRelationsListeID BIGINT;
      rel Relation;
    BEGIN
      FOR relList in SELECT * FROM RelationsListe WHERE RegistreringsID =
                                              oldRegistreringsID
      LOOP
        INSERT INTO RelationsListe (RegistreringsID, Name)
        VALUES (newRegistreringsID, relList.Name);

        newRelationsListeID := lastval();

        FOR rel in SELECT * FROM Relation r1
          JOIN RelationsListe r2 ON r1.RelationsListeID = r2.ID WHERE
          r2.ID = relList.ID
        LOOP
          INSERT INTO Relation (RelationsListeID, Virkning, Relation) VALUES
            (newRelationsListeID, rel.Virkning, rel.relation);
        END LOOP;

      END LOOP;
    END;
  END IF;

  RETURN result;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION _ACTUAL_STATE_COPY_INTO_REGISTRATION(
  inputRegistreringsID BIGINT,
  Attributter EgenskaberType[],
  Tilstande TilstandsType[],
  Relationer RelationsListeType[]
)
  RETURNS VOID AS $$
DECLARE
BEGIN
--   Loop through attributes and add them to the registration
  DECLARE
    attr EgenskaberType;
    egenskaberID BIGINT;
  BEGIN
    FOREACH attr in ARRAY Attributter
    LOOP
      INSERT INTO Egenskaber (RegistreringsID, Virkning, BrugervendtNoegle)
      VALUES (inputRegistreringsID, attr.Virkning, attr.BrugervendtNoegle);

      egenskaberID := lastval();

      DECLARE
        prop EgenskabsType;
      BEGIN
        FOREACH prop in ARRAY attr.Properties
        LOOP
          INSERT INTO Egenskab (EgenskaberID, Name, Value)
          VALUES (egenskaberID, prop.Name, prop.Value);
        END LOOP;
      END;
    END LOOP;
  END;

--   Loop through states and add them to the registration
  DECLARE
    state TilstandsType;
  BEGIN
    FOREACH state in ARRAY Tilstande
    LOOP
      INSERT INTO Tilstand (RegistreringsID, Virkning, Status)
      VALUES (inputRegistreringsID, state.Virkning, state.Status);
    END LOOP;
  END;

--   Loop through relations and add them to the registration
  DECLARE
    relationList RelationsListeType;
    relationsListeID BIGINT;
  BEGIN
    FOREACH relationList in ARRAY Relationer
    LOOP
      INSERT INTO RelationsListe (RegistreringsID, Name)
      VALUES (inputRegistreringsID, relationList.Name);

      relationsListeID := lastval();

      DECLARE
        rel RelationsType;
      BEGIN
        FOREACH rel in ARRAY relationList.Relations
        LOOP
          INSERT INTO Relation (RelationsListeID, Virkning, Relation)
          VALUES (relationsListeID, rel.Virkning, rel.Relation);
        END LOOP;
      END;
    END LOOP;
  END;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION ACTUAL_STATE_UPDATE(
  inputID UUID,
  Attributter EgenskaberType[],
  Tilstande TilstandsType[],
  Relationer RelationsListeType[]
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

--   Loop through attributes and add them to the registration
  DECLARE
    attr EgenskaberType;
    newEgenskaberID BIGINT;
  BEGIN
    FOREACH attr in ARRAY Attributter
    LOOP
--  Insert into our view which has a trigger which handles updating ranges
--  if the new values overlap the old
      INSERT INTO EgenskaberUpdateView (RegistreringsID, Virkning, BrugervendtNoegle)
      VALUES (newRegistreringID, attr.Virkning, attr.BrugervendtNoegle)
      RETURNING ID INTO newEgenskaberID;

      DECLARE
        prop EgenskabsType;
      BEGIN
        FOREACH prop in ARRAY attr.Properties
        LOOP
--           Update existing properties if we can
          UPDATE Egenskab SET Value = prop.Value
            WHERE EgenskaberID = newEgenskaberID AND Name = prop.Name;
          IF NOT FOUND THEN
--             If we didn't update anything, we have to insert new properties
            INSERT INTO Egenskab (EgenskaberID, Name, Value)
            VALUES (newEgenskaberID, prop.Name, prop.Value);
          END IF;
        END LOOP;
      END;
    END LOOP;
  END;

--   Loop through states and add them to the registration
  DECLARE
    state TilstandsType;
  BEGIN
    FOREACH state in ARRAY Tilstande
    LOOP
--  Insert into our view which has a trigger which handles updating ranges
--  if the new values overlap the old
      INSERT INTO TilstandUpdateView (RegistreringsID, Virkning, Status)
      VALUES (newRegistreringID, state.Virkning, state.Status);
    END LOOP;
  END;

--   Loop through relations and add them to the registration
  DECLARE
    relationList RelationsListeType;
    relationsListeID BIGINT;
  BEGIN
    FOREACH relationList in ARRAY Relationer
    LOOP
--  Insert into our view which has a trigger which handles updating ranges
--  if the new values overlap the old
      INSERT INTO RelationsListe (RegistreringsID, Name)
      VALUES (newRegistreringID, relationList.Name);

      relationsListeID := lastval();

      DECLARE
        rel RelationsType;
      BEGIN
        FOREACH rel in ARRAY relationList.Relations
        LOOP
          INSERT INTO RelationsUpdateView (RelationsListeID, Virkning,
                                           Relation)
          VALUES (relationsListeID, rel.Virkning, rel.Relation);
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
