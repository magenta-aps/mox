CREATE OR REPLACE FUNCTION ACTUAL_STATE_CREATE(
    ObjektType REGCLASS,
    Attributter EgenskaberType[],
    Tilstande TilstandsType[]
--   TODO: Accept relations
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


--   Loop through attributes and add them to the registration
  DECLARE
    attr EgenskaberType;
    egenskaberID BIGINT;
  BEGIN
    FOREACH attr in ARRAY Attributter
    LOOP
      INSERT INTO Egenskaber (RegistreringsID, Virkning, BrugervendtNoegle)
      VALUES (registreringResult.ID, attr.Virkning, attr.BrugervendtNoegle);

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
      VALUES (registreringResult.ID, state.Virkning, state.Status);
    END LOOP;
  END;
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
  BrugerRef UUID
--   doCopyOld BOOLEAN DEFAULT FALSE
) RETURNS Registrering AS $$
DECLARE
  registreringTime        TIMESTAMPTZ := transaction_timestamp();
  result                  Registrering;
  newRegistreringID       BIGINT;
  oldBrugerRegistreringID BIGINT;
BEGIN
-- Update previous Registrering's time range to end now, exclusive
  UPDATE Registrering
    SET TimePeriod =
      TSTZRANGE(lower(TimePeriod), registreringTime)
    WHERE ObjektID = inputID AND upper(TimePeriod) = 'infinity'
    RETURNING ID INTO oldBrugerRegistreringID;
--   Create Registrering starting from now until infinity
  INSERT INTO Registrering (ObjektID, TimePeriod, Livscykluskode, BrugerRef)
  VALUES (
    inputID,
    TSTZRANGE(registreringTime, 'infinity', '[]'), LivscyklusKode, BrugerRef
  );

  SELECT * FROM Registrering WHERE ID = lastval() INTO result;

  newRegistreringID := result.ID;
--
--   IF doCopyOld
--   THEN
--     DECLARE
--       r RECORD;
--     BEGIN
--       FOR r in SELECT virkning, brugervendtnoegle, brugernavn, brugertype
--                FROM brugeregenskaber WHERE brugerregistreringid =
--                                            oldBrugerRegistreringID
--       LOOP
--         INSERT INTO BrugerEgenskaber (BrugerRegistreringID, Virkning, BrugervendtNoegle, Brugernavn, Brugertype)
--         VALUES (newRegistreringID, r.Virkning, r.BrugervendtNoegle,
--                 r.Brugernavn, r.Brugertype);
--       END LOOP;
--     END;
--
--     DECLARE
--       r RECORD;
--     BEGIN
--       FOR r in SELECT virkning, status
--                FROM brugertilstand WHERE brugerregistreringid =
--                                            oldBrugerRegistreringID
--       LOOP
--         INSERT INTO BrugerTilstand (BrugerRegistreringID, Virkning, Status)
--         VALUES (newRegistreringID, r.Virkning, r.Status);
--       END LOOP;
--     END;
--   END IF;

  RETURN result;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION _ACTUAL_STATE_COPY_INTO_REGISTRATION(
  inputRegistreringsID BIGINT,
  Attributter EgenskaberType[],
  Tilstande TilstandsType[]
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
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION ACTUAL_STATE_UPDATE(
  inputID UUID,
  Attributter EgenskaberType[],
  Tilstande TilstandsType[]
)
  RETURNS Registrering AS $$
DECLARE
  result Registrering;
BEGIN
  result := _ACTUAL_STATE_NEW_REGISTRATION(
      inputID, 'Rettet', NULL
  );

  PERFORM _ACTUAL_STATE_COPY_INTO_REGISTRATION(result.ID, Attributter, Tilstande);

  RETURN result;
END;
$$ LANGUAGE plpgsql;
--
--
-- CREATE OR REPLACE FUNCTION ACTUAL_STATE_DELETE_BRUGER(
--   inputID UUID
-- )
--   RETURNS BrugerRegistrering AS $$
-- BEGIN
--   RETURN _ACTUAL_STATE_NEW_REGISTRATION(
--       inputID, 'Slettet', NULL, doCopy := TRUE
--   );
-- END;
-- $$ LANGUAGE plpgsql;
--
--
--
-- CREATE OR REPLACE FUNCTION ACTUAL_STATE_PASSIVE_BRUGER(
--   inputID UUID
-- )
--   RETURNS BrugerRegistrering AS $$
-- BEGIN
--   RETURN _ACTUAL_STATE_NEW_REGISTRATION(
--       inputID, 'Passiveret', NULL, doCopy := TRUE
--   );
-- END;
-- $$ LANGUAGE plpgsql;
