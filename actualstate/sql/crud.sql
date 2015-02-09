CREATE OR REPLACE FUNCTION ACTUAL_STATE_CREATE(
    ObjektType TEXT,
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
  EXECUTE 'INSERT INTO ' || ObjektType::Regclass || '(ID) VALUES($1)
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
      VALUES (registreringResult.ID, attr.Virkning, attr.BrugervendtNoegle)
      RETURNING ID INTO egenskaberID;

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
-- CREATE OR REPLACE FUNCTION ACTUAL_STATE_READ_BRUGER(
--     ID UUID,
--     VirkningPeriod TSTZRANGE,
--     RegistreringPeriod TSTZRANGE,
--     filteredAttributesRef REFCURSOR,
--     filteredStatesRef REFCURSOR
-- )
--   RETURNS SETOF REFCURSOR AS $$
-- DECLARE
--   inputID UUID := ID;
--   result BrugerRegistrering;
-- BEGIN
--   -- Get the whole registrering which overlaps with the registrering (system)
--   -- time period.
--   SELECT * FROM BrugerRegistrering
--     JOIN Bruger ON Bruger.ID = BrugerRegistrering.BrugerID
--   WHERE Bruger.ID = inputID AND
--         -- && operator means ranges overlap
--         (BrugerRegistrering.Registrering).TimePeriod && RegistreringPeriod
--     -- We only want the first result
--     LIMIT 1
--   INTO result;
--
--   -- Filter the attributes' registrering by the virkning (application) time
--   -- period
--   OPEN filteredAttributesRef FOR SELECT * FROM brugeregenskaber
--   WHERE brugerregistreringid = result.id AND
--         (virkning).TimePeriod && VirkningPeriod;
--
--   ---
--   OPEN filteredStatesRef FOR SELECT * FROM brugertilstand
--   WHERE brugerregistreringid = result.id AND
--         (virkning).TimePeriod && VirkningPeriod;
--   RETURN;
-- END;
-- $$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION _ACTUAL_STATE_NEW_REGISTRATION(
  inputID UUID,
  LivscyklusKode LivscyklusKode,
  BrugerRef UUID,
  doCopy BOOLEAN DEFAULT FALSE
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
  )
  RETURNING * INTO result;

  newRegistreringID := result.ID;

--   IF doCopy
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


-- CREATE OR REPLACE FUNCTION ACTUAL_STATE_UPDATE_BRUGER(
--   inputID UUID,
--   Attributter BrugerEgenskaberType[],
--   Tilstande BrugerTilstandType[]
-- )
--   RETURNS BrugerRegistrering AS $$
-- DECLARE
--   result BrugerRegistrering;
-- BEGIN
--   result := _ACTUAL_STATE_NEW_REGISTRATION(
--       inputID, 'Rettet', NULL
--   );
-- --   Loop through attributes and add them to the registration
--   DECLARE
--     attr BrugerEgenskaberType;
--   BEGIN
--     FOREACH attr in ARRAY Attributter
--     LOOP
--       INSERT INTO BrugerEgenskaber (BrugerRegistreringID, Virkning, BrugervendtNoegle, Brugernavn, Brugertype)
--       VALUES (result.ID, attr.Virkning, attr.BrugervendtNoegle,
--               attr.Brugernavn, attr.Brugertype);
--     END LOOP;
--   END;
--
-- --   Loop through states and add them to the registration
--   DECLARE
--     state BrugerTilstandType;
--   BEGIN
--     FOREACH state in ARRAY Tilstande
--     LOOP
--       INSERT INTO BrugerTilstand (BrugerRegistreringID, Virkning, Status)
--       VALUES (result.ID, state.Virkning, state.Status);
--     END LOOP;
--   END;
--
--   RETURN result;
-- END;
-- $$ LANGUAGE plpgsql;
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
